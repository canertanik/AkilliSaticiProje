import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _priceRangeCtrl;
  late TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.product.title);
    _descriptionCtrl = TextEditingController(text: widget.product.description);
    _priceRangeCtrl = TextEditingController(text: widget.product.priceRange);
    _categoryCtrl = TextEditingController(text: widget.product.category);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceRangeCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.product.copyWith(
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      priceRange: _priceRangeCtrl.text,
      category: _categoryCtrl.text,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            height: 120,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ürünü Düzenle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ürün Başlığı'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Açıklama'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Fiyat Aralığı'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceRangeCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Kategori'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(text: 'Kaydet', onPressed: _save),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
