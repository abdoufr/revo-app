import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_providers.dart';
import '../../providers/orders_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smart_image.dart';
import 'composer_screen.dart';
import 'client_orders_screen.dart';

class ClientCartScreen extends ConsumerWidget {
  const ClientCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalPrice = cartNotifier.totalPrice;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balance for trailing actions
                Text('Mon Panier', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: AppTheme.error),
                    tooltip: 'Vider le panier',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: const Text('Vider le panier ?'),
                          content: const Text('Êtes-vous sûr de vouloir vider tout votre panier ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              onPressed: () {
                                cartNotifier.clearCart();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Vider', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Votre panier est vide',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez des plats pour commencer votre commande.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Voir le menu', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                              ),
                              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SmartImage(item.imageUrl!, fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.fastfood_rounded, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(width: 12),
                            
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item.isComposition)
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ComposerScreen(
                                                      editingCartItemId: item.id,
                                                      initialCategoryKey: item.compositionCategoryKey,
                                                      initialIngredientIds: item.compositionIngredientIds,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () => cartNotifier.removeItem(item.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (item.subtitle.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.subtitle,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item.price.toStringAsFixed(0)} DA',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      // Quantity Controls
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 22),
                                            color: Colors.grey[600],
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () => cartNotifier.decrementQuantity(item.id),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 22),
                                            color: Theme.of(context).primaryColor,
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () => cartNotifier.incrementQuantity(item.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Checkout Bar
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total estimé', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${totalPrice.toStringAsFixed(0)} DA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showCheckoutBottomSheet(context, ref, totalPrice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Valider la commande',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCheckoutBottomSheet(BuildContext context, WidgetRef ref, double totalPrice) {
    final user = ref.read(authStateProvider).value;
    final userDoc = user != null ? ref.read(userDocStreamProvider(user.uid)).value?.data() : null;

    final nameController = TextEditingController(text: userDoc?['displayName'] ?? userDoc?['fullName'] ?? user?.displayName ?? '');
    final phoneController = TextEditingController(text: userDoc?['phone'] ?? userDoc?['phoneNumber'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool isLoading = false;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Validation de votre commande 🛍️',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez confirmer vos coordonnées pour que le restaurant puisse vous contacter.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom & Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Total recap
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à payer :', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${totalPrice.toStringAsFixed(0)} DA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(ctx).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm button
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez remplir votre nom et votre numéro de téléphone.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final cartItems = ref.read(cartProvider);
                            final userId = user?.uid ?? 'guest';

                            await ref.read(orderActionsProvider).createOrder(
                                  userId: userId,
                                  clientName: name,
                                  clientPhone: phone,
                                  items: cartItems,
                                  totalPrice: totalPrice,
                                );

                            ref.read(cartProvider.notifier).clearCart();

                            if (ctx.mounted) Navigator.pop(ctx); // Close sheet
                            if (context.mounted) Navigator.pop(context); // Close cart

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Commande envoyée au restaurant avec succès ! 🎉'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ClientOrdersScreen()),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmer la commande',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
