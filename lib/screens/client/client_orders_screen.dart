import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';

class ClientOrdersScreen extends ConsumerWidget {
  const ClientOrdersScreen({super.key});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente:
        return Colors.orange;
      case OrderStatus.enPreparation:
        return Colors.blue;
      case OrderStatus.pret:
        return Colors.purple;
      case OrderStatus.livree:
        return AppTheme.success;
      case OrderStatus.annulee:
        return AppTheme.error;
    }
  }

  int _getStatusStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.enAttente:
        return 0;
      case OrderStatus.enPreparation:
        return 1;
      case OrderStatus.pret:
        return 2;
      case OrderStatus.livree:
        return 3;
      case OrderStatus.annulee:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(clientOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suivi de mes Commandes 🛍️',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune commande en cours',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passez une commande depuis votre panier pour la suivre ici.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
              final statusColor = _getStatusColor(order.status);
              final currentStep = _getStatusStepIndex(order.status);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                dateStr,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              order.status.label,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Live Status Stepper (if not cancelled)
                      if (order.status != OrderStatus.annulee) ...[
                        _buildStatusStepper(context, currentStep),
                        const SizedBox(height: 20),
                      ],

                      // Items List Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails :',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map((item) {
                              final title = item['title'] as String? ?? 'Produit';
                              final subtitle = item['subtitle'] as String? ?? '';
                              final qty = item['quantity'] ?? 1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Text('$qty x ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                    Expanded(
                                      child: Text(
                                        title + (subtitle.isNotEmpty ? ' ($subtitle)' : ''),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Footer Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            '${order.totalPrice.toStringAsFixed(0)} DA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  Widget _buildStatusStepper(BuildContext context, int currentStep) {
    final steps = [
      {'title': 'En attente', 'icon': Icons.hourglass_top_rounded},
      {'title': 'En préparation', 'icon': Icons.soup_kitchen_rounded},
      {'title': 'Prêt !', 'icon': Icons.shopping_bag_rounded},
      {'title': 'Livrée', 'icon': Icons.check_circle_rounded},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentStep;
        final isCurrent = index == currentStep;
        final stepColor = isDone ? (isCurrent ? Theme.of(context).primaryColor : AppTheme.success) : Colors.grey[400]!;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0 ? Colors.transparent : (index <= currentStep ? AppTheme.success : Colors.grey[300]),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 36 : 28,
                    height: isCurrent ? 36 : 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? stepColor : Theme.of(context).colorScheme.surface,
                      border: Border.all(color: stepColor, width: 2),
                    ),
                    child: Icon(
                      steps[index]['icon'] as IconData,
                      size: isCurrent ? 20 : 16,
                      color: isDone ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == steps.length - 1 ? Colors.transparent : (index < currentStep ? AppTheme.success : Colors.grey[300]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index]['title'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Theme.of(context).primaryColor : (isDone ? Theme.of(context).textTheme.bodySmall?.color : Colors.grey),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
