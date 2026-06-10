import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../state/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final productId = int.tryParse(id);
    if (productId == null) {
      return const Center(child: Text('Geçersiz ürün id'));
    }

    final auth = context.watch<AuthService>();
    final productService = ProductService(auth);

    return FutureBuilder<ProductModel>(
      future: productService.getPublishedProductDetail(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Ürün detayı alınamadı: ${snapshot.error ?? 'Bilinmeyen hata'}',
            ),
          );
        }

        final product = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 860;

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((product.category ?? '').isNotEmpty)
                    Text('Kategori: ${product.category}'),
                  const SizedBox(height: 16),
                  Text(
                    '₺${product.getDisplayPrice(auth.isLoggedIn).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.getOldPrice(auth.isLoggedIn) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '₺${product.getOldPrice(auth.isLoggedIn)!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    product.description?.trim().isNotEmpty == true
                        ? product.description!
                        : 'Bu ürün için henüz detay açıklaması eklenmedi.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text(
                        'Sepete Ekle',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        context.read<CartService>().add(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.title} sepete eklendi!'),
                          ),
                        );
                        context.go('/cart');
                      },
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductImage(url: product.imageUrl),
                    const SizedBox(height: 24),
                    content,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _ProductImage(url: product.imageUrl),
                  ),
                  const SizedBox(width: 40),
                  Expanded(flex: 1, child: content),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        url?.isNotEmpty == true
            ? url!
            : 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&q=80&w=1200';

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = MediaQuery.of(context).size.width * 0.42;
    final targetWidth = (logicalWidth * devicePixelRatio).round().clamp(
      720,
      2200,
    );

    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          cacheWidth: targetWidth,
          errorBuilder:
              (_, __, ___) => Container(
                color: const Color(0xFFE2E8F0),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 56,
                  color: Color(0xFF64748B),
                ),
              ),
        ),
      ),
    );
  }
}
