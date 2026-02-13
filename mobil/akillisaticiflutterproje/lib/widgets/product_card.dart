import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/utils/platform_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Basit image placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 72,
                  width: 72,
                  color: Colors.grey.shade200,
                  child: () {
                    final imageUrl = product.imageUrl.trim();
                    if (imageUrl.isEmpty && product.webImageBytes == null) {
                      return const Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey,
                      );
                    }
                    if (product.webImageBytes != null) {
                      return Image.memory(
                        product.webImageBytes!,
                        fit: BoxFit.cover,
                      );
                    }
                    final isRemote =
                        imageUrl.startsWith('http://') ||
                        imageUrl.startsWith('https://');
                    if (isRemote) {
                      return Image.network(imageUrl, fit: BoxFit.cover);
                    }
                    if (kIsWeb) {
                      return const Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey,
                      );
                    }
                    return buildFileImage(imageUrl, fit: BoxFit.cover);
                  }(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.priceRange,
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${product.category}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.aiGenerated)
                          const Text(
                            '✨ AI Üretildi',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
