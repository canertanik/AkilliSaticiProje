import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body:
          cart.items.isEmpty
              ? const Center(child: Text('Sepetiniz boş'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, i) {
                        final item = cart.items[i];
                        return ListTile(
                          leading:
                              item.product.imageUrl.isNotEmpty
                                  ? Image.network(
                                    item.product.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          title: Text(item.product.title),
                          subtitle: Text(
                            '${item.quantity} x ${item.product.priceRange}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cart.remove(item.product),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Toplam: ₺${cart.total.toStringAsFixed(2)}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Checkout flow placeholder
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkout - henüz implement edilmedi',
                                ),
                              ),
                            );
                          },
                          child: const Text('Ödeme'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
