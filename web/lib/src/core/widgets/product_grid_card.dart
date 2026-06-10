import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'hover_scale.dart';

class ProductGridCard extends StatefulWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  State<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<ProductGridCard> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    final imageUrl =
        p.imageUrl?.isNotEmpty == true
            ? p.imageUrl!
            : 'https://images.unsplash.com/photo-1601758174114-e711c0cbaa69?auto=format&fit=crop&q=80&w=900';
    final rating = 3.5 + ((p.id % 15) / 10.0);

    return HoverScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: const Color(0xFFE2E8F0),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                        ),
                      ),
                      if (p.getIsDiscounted(isLoggedIn))
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '%${p.getDiscountPercent(isLoggedIn)} İndirim',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _favorite = !_favorite),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    _favorite
                                        ? AppTheme.danger
                                        : const Color(0xFF64748B),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      _RatingRow(rating: rating),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '₺${p.getDisplayPrice(isLoggedIn).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (p.getOldPrice(isLoggedIn) != null)
                            Text(
                              '₺${p.getOldPrice(isLoggedIn)!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onAddToCart,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Sepete Ekle'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final isFilled = rating >= index + 1;
          return Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: 14,
            color: const Color(0xFFF59E0B),
          );
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}
