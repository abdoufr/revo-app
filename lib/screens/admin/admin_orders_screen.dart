import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _selectedStatusFilter;

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Commandes Clients 🛍️',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Toutes'),
                  selected: _selectedStatusFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatusFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.where((s) => s != OrderStatus.annulee).map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: isSelected,
                      selectedColor: _getStatusColor(status).withValues(alpha: 0.2),
                      checkmarkColor: _getStatusColor(status),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Orders List
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filteredOrders = _selectedStatusFilter == null
                    ? orders
                    : orders.where((o) => o.status == _selectedStatusFilter).toList();

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune commande trouvée.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
                    final statusColor = _getStatusColor(order.status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Order ID, Date & Status
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
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Client Details
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.clientName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if (order.clientPhone.isNotEmpty)
                                        Text(
                                          order.clientPhone,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ),
                                if (order.clientPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: AppTheme.success),
                                    onPressed: () => _makePhoneCall(order.clientPhone),
                                    tooltip: 'Appeler le client',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Order Items
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
                                    'Articles commandés :',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...order.items.map((item) {
                                    final title = item['title'] as String? ?? 'Produit';
                                    final subtitle = item['subtitle'] as String? ?? '';
                                    final qty = item['quantity'] ?? 1;
                                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$qty x ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                if (subtitle.isNotEmpty)
                                                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              ],
                                            ),
                                          ),
                                          Text('${price.toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Total Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total de la commande :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            const SizedBox(height: 16),

                            // Status Actions
                            Row(
                              children: [
                                if (order.status == OrderStatus.enAttente)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(orderActionsProvider).updateOrderStatus(order.id, OrderStatus.enPreparation);
                                      },
                                      icon: const Icon(Icons.soup_kitchen, color: Colors.white),
                                      label: const Text('En préparation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    ),
                                  ),
                                if (order.status == OrderStatus.enPreparation)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(orderActionsProvider).updateOrderStatus(order.id, OrderStatus.pret);
                                      },
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                      label: const Text('Marquer Prêt !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                    ),
                                  ),
                                if (order.status == OrderStatus.pret)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(orderActionsProvider).updateOrderStatus(order.id, OrderStatus.livree);
                                      },
                                      icon: const Icon(Icons.delivery_dining, color: Colors.white),
                                      label: const Text('Marquer Livrée', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                    ),
                                  ),
                                if (order.status == OrderStatus.livree)
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        'Commande Terminé ✅',
                                        style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                if (order.status != OrderStatus.livree && order.status != OrderStatus.annulee) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                                    onPressed: () {
                                      ref.read(orderActionsProvider).updateOrderStatus(order.id, OrderStatus.annulee);
                                    },
                                    tooltip: 'Annuler la commande',
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
