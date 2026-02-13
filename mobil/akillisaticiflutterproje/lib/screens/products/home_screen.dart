import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/gradient_button.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final Future<void> Function(BuildContext) onAddProduct;
  final Future<void> Function(BuildContext, Product) onEditProduct;
  final void Function(String id) onDeleteProduct;
  final bool isLoading;
  final String? errorMessage;

  const HomeScreen({
    super.key,
    required this.products,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final published = widget.products.where((p) => !p.isDraft).length;
    final drafts = widget.products.where((p) => p.isDraft).length;
    final filtered =
        _query.trim().isEmpty
              ? (widget.products.toList()..sort((a, b) {
                final aId = int.tryParse(a.id) ?? 0;
                final bId = int.tryParse(b.id) ?? 0;
                return bId.compareTo(aId);
              }))
              : widget.products.where((p) {
                final q = _query.toLowerCase();
                return p.title.toLowerCase().contains(q) ||
                    p.description.toLowerCase().contains(q) ||
                    p.category.toLowerCase().contains(q);
              }).toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );

    final visible =
        filtered.where((p) {
          switch (_filter) {
            case _ProductFilter.published:
              return !p.isDraft;
            case _ProductFilter.draft:
              return p.isDraft;
            case _ProductFilter.all:
              return true;
          }
        }).toList();

    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            height: 180,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 40),
                Text(
                  'Ürün Yöneticim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'AI Destekli Satıcı Platformu',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _statCard(
                        'Yayında',
                        published.toString(),
                        icon: Icons.check_circle_outline,
                        selected: _filter == _ProductFilter.published,
                        onTap:
                            () => setState(() {
                              _filter = _ProductFilter.published;
                            }),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        'Taslak',
                        drafts.toString(),
                        icon: Icons.insert_drive_file_outlined,
                        selected: _filter == _ProductFilter.draft,
                        onTap:
                            () => setState(() {
                              _filter = _ProductFilter.draft;
                            }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          _filter == _ProductFilter.all
                              ? null
                              : () => setState(() {
                                _filter = _ProductFilter.all;
                              }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tümü'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _query = val),
                    decoration: InputDecoration(
                      hintText: 'Ürün ara (başlık, açıklama, kategori)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _query.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => _query = '');
                                  _searchCtrl.clear();
                                },
                              )
                              : null,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        widget.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : (widget.errorMessage != null)
                            ? Center(child: Text(widget.errorMessage!))
                            : (visible.isEmpty
                                ? Center(
                                  child: Text(
                                    _query.trim().isEmpty
                                        ? (_filter == _ProductFilter.all
                                            ? 'Henüz ürün eklenmedi'
                                            : 'Seçilen filtrede ürün yok')
                                        : 'Arama sonucu bulunamadı',
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    final product = visible[index];
                                    return ProductCard(
                                      product: product,
                                      onEdit:
                                          () => widget.onEditProduct(
                                            context,
                                            product,
                                          ),
                                      onDelete:
                                          () => widget.onDeleteProduct(
                                            product.id,
                                          ),
                                    );
                                  },
                                )),
                  ),
                  GradientButton(
                    text: '+ Yeni Ürün Ekle',
                    onPressed: () => widget.onAddProduct(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value, {
    IconData? icon,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3E8FF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border:
                selected ? Border.all(color: const Color(0xFF7C3AED)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color:
                      selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF7C3AED),
                ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: selected ? const Color(0xFF7C3AED) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProductFilter { all, published, draft }
