// ignore_for_file: deprecated_member_use
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_service.dart';
import '../../../services/product_service.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late Future<List<ProductModel>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _load() {
    final auth = context.read<AuthService>();
    final productService = ProductService(auth);
    return auth.isAdmin
        ? productService.getAdminProducts()
        : productService.getMyProducts();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final productService = ProductService(auth);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primary.withValues(alpha: 0.04), cs.surface],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 780;

                  final header = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.pets, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Petshop Ürün Yönetimi',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Ürünlerini daha hızlı düzenle, filtrele ve yayınla.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionButtons = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Ürün'),
                        onPressed:
                            () => _showProductDialog(context, productService),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Akıllı Ürün'),
                        onPressed: () => context.go('/admin/smart-product'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.percent),
                        label: const Text('Toplu Fiyat'),
                        onPressed: () => _showBulkPriceDialog(context, productService),
                      ),
                    ],
                  );

                  final searchAndFilter = LayoutBuilder(
                    builder: (context, rowConstraints) {
                      final rowCompact = rowConstraints.maxWidth < 720;

                      final searchField = TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Ürün adı veya kategori ara...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );

                      final statusFilter = DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tüm Durumlar'),
                          ),
                          DropdownMenuItem(
                            value: 'Published',
                            child: Text('Yayında'),
                          ),
                          DropdownMenuItem(
                            value: 'Draft',
                            child: Text('Taslak'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      );

                      if (rowCompact) {
                        return Column(
                          children: [
                            searchField,
                            const SizedBox(height: 12),
                            statusFilter,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 3, child: searchField),
                          const SizedBox(width: 12),
                          Expanded(child: statusFilter),
                        ],
                      );
                    },
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const SizedBox(height: 16),
                        actionButtons,
                        const SizedBox(height: 16),
                        searchAndFilter,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          header,
                          const SizedBox(width: 12),
                          actionButtons,
                        ],
                      ),
                      const SizedBox(height: 16),
                      searchAndFilter,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ProductModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Ürünler alınamadı: ${snapshot.error}'),
                    );
                  }

                  final products = snapshot.data ?? const <ProductModel>[];
                  final filteredProducts =
                      products.where((product) {
                        final matchesStatus =
                            _statusFilter == 'all' ||
                            product.status.toLowerCase() ==
                                _statusFilter.toLowerCase();
                        if (!matchesStatus) return false;
                        if (_searchQuery.isEmpty) return true;

                        final title = product.title.toLowerCase();
                        final category = (product.category ?? '').toLowerCase();
                        return title.contains(_searchQuery) ||
                            category.contains(_searchQuery);
                      }).toList();

                  if (products.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Henüz ürün yok. İlk ürünü ekleyin.'),
                      ),
                    );
                  }

                  if (filteredProducts.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_off,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            const Text('Filtreye uygun ürün bulunamadı.'),
                          ],
                        ),
                      ),
                    );
                  }

                  final compact = MediaQuery.of(context).size.width < 900;

                  return Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.inventory_2_outlined,
                            label: 'Toplam',
                            value: products.length.toString(),
                          ),
                          _InfoPill(
                            icon: Icons.visibility_outlined,
                            label: 'Yayında',
                            value:
                                products
                                    .where(
                                      (p) =>
                                          p.status.toLowerCase() == 'published',
                                    )
                                    .length
                                    .toString(),
                          ),
                          _InfoPill(
                            icon: Icons.edit_note_outlined,
                            label: 'Taslak',
                            value:
                                products
                                    .where(
                                      (p) => p.status.toLowerCase() == 'draft',
                                    )
                                    .length
                                    .toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filteredProducts.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _ProductListItem(
                              compact: compact,
                              product: product,
                              onEdit:
                                  () => _showProductDialog(
                                    context,
                                    productService,
                                    existing: product,
                                  ),
                              onToggleVisibility: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final newStatus =
                                    product.status.toLowerCase() == 'published'
                                        ? 'Draft'
                                        : 'Published';
                                final error = await productService
                                    .updateProduct(
                                      id: product.id,
                                      title: product.title,
                                      description: product.description ?? '',
                                      minPrice: product.basePrice,
                                      maxPrice:
                                          product.maxPrice ?? product.basePrice,
                                      category: product.category,
                                      imageUrl: product.imageUrl,
                                      status: newStatus,
                                    );

                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error ??
                                          (newStatus == 'Published'
                                              ? 'Ürün müşteride gösterilecek'
                                              : 'Ürün müşteriden gizlendi'),
                                    ),
                                  ),
                                );
                                if (error == null) _refresh();
                              },
                              onDelete: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final error = await productService
                                    .deleteProduct(product.id);
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(error ?? 'Ürün silindi.'),
                                  ),
                                );
                                if (error == null) _refresh();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    ProductService productService, {
    ProductModel? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final categoryService = CategoryService(context.read<AuthService>());
    List<CategoryModel> categories;
    try {
      categories = await categoryService.getCategories();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategoriler alınamadı. Lütfen tekrar deneyin.'),
          ),
        );
      }
      return;
    }

    final categoryNames =
        categories
            .map((c) => c.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (categoryNames.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün eklemek için önce Kategori Yönetimi ekranından kategori oluşturun.',
            ),
          ),
        );
      }
      return;
    }

    String? selectedCategory = existing?.category?.trim();
    if (selectedCategory == null || !categoryNames.contains(selectedCategory)) {
      selectedCategory = categoryNames.first;
    }

    final priceController = TextEditingController(
      text:
          existing?.minPrice?.toString() ??
          existing?.maxPrice?.toString() ??
          '',
    );
    final oldPriceController = TextEditingController(
      text: existing?.maxPrice?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: existing?.stockQuantity.toString() ?? '0',
    );
    final initialStatus = existing?.status.toLowerCase() == 'draft' ? 'Draft' : 'Published';
    String status = initialStatus;
    String? uploadedImageUrl = existing?.imageUrl;
    Uint8List? previewBytes;
    bool isUploading = false;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickImage() async {
              final picked = await _imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (picked == null) return;

              final bytes = await picked.readAsBytes();
              setDialogState(() {
                previewBytes = bytes;
                uploadedImageUrl = null;
                isUploading = true;
              });

              try {
                final url = await productService.uploadImage(
                  bytes: bytes,
                  fileName: picked.name,
                );
                setDialogState(() {
                  uploadedImageUrl = url;
                  isUploading = false;
                });
              } catch (e) {
                setDialogState(() => isUploading = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Resim yüklenemedi: $e')),
                  );
                }
              }
            }

            Future<void> save() async {
              final trimmedTitle = titleController.text.trim();
              if (trimmedTitle.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Ürün adı zorunlu.')),
                );
                return;
              }

              final minPrice = double.tryParse(priceController.text.trim().replaceAll(',', '.'));
              final maxPrice = double.tryParse(oldPriceController.text.trim().replaceAll(',', '.'));
              final stockQuantity = int.tryParse(stockController.text.trim()) ?? 0;
              final description =
                  descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim();

              final error =
                  existing == null
                      ? await productService.createProduct(
                        title: trimmedTitle,
                        description: description,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        category: selectedCategory,
                        imageUrl: uploadedImageUrl,
                        status: status,
                        stockQuantity: stockQuantity,
                      )
                      : await productService.updateProduct(
                        id: existing.id,
                        title: trimmedTitle,
                        description: description,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        category: selectedCategory,
                        imageUrl: uploadedImageUrl,
                        status: status,
                        stockQuantity: stockQuantity,
                      );

              if (!ctx.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    existing == null ? 'Ürün eklendi.' : 'Ürün güncellendi.',
                  ),
                ),
              );
              _refresh();
            }

            return AlertDialog(
              title: Text(existing == null ? 'Yeni Ürün' : 'Ürün Güncelle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Ürün adı'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                      ),
                      isExpanded: true,
                      items:
                          categoryNames
                              .map(
                                (name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (previewBytes != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Image.memory(
                                previewBytes!,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (uploadedImageUrl != null &&
                              uploadedImageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Image.network(
                                uploadedImageUrl!,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    isUploading
                                        ? 'Yükleniyor...'
                                        : uploadedImageUrl != null
                                        ? '✓ Resim yüklendi'
                                        : 'Resim seçilmedi',
                                  ),
                                ),
                                if (isUploading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: pickImage,
                                    icon: const Icon(Icons.upload_file),
                                    label: Text(
                                      previewBytes != null
                                          ? 'Değiştir'
                                          : 'Galeriden Seç',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (uploadedImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          uploadedImageUrl!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiyat'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: oldPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Eski Fiyat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok Miktarı',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Durum'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Published',
                          child: Text('Yayında'),
                        ),
                        DropdownMenuItem(value: 'Draft', child: Text('Taslak')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => status = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: isUploading ? null : save,
                  child: Text(existing == null ? 'Ekle' : 'Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBulkPriceDialog(BuildContext context, ProductService productService) async {
    final products = await _future;
    if (products.isEmpty) return;

    final percentController = TextEditingController();
    bool isIncrease = true;
    bool isSaving = false;
    
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Toplu Fiyat Güncelleme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tüm ürünlerin fiyatını yüzdelik olarak artırın veya azaltın.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Zam (%)'),
                          value: true,
                          groupValue: isIncrease,
                          onChanged: (val) => setDialogState(() => isIncrease = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('İndirim (%)'),
                          value: false,
                          groupValue: isIncrease,
                          onChanged: (val) => setDialogState(() => isIncrease = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: percentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Yüzde Oranı (Örn: 10)',
                      suffixText: '%',
                    ),
                  ),
                  if (isSaving) const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : () async {
                    final p = double.tryParse(percentController.text.trim());
                    if (p == null || p <= 0) return;
                    
                    setDialogState(() => isSaving = true);
                    final factor = isIncrease ? (1 + (p / 100)) : (1 - (p / 100));

                    for (var prod in products) {
                      final newMin = prod.minPrice != null ? double.parse((prod.minPrice! * factor).toStringAsFixed(2)) : null;
                      final newMax = prod.maxPrice != null ? double.parse((prod.maxPrice! * factor).toStringAsFixed(2)) : null;
                      
                      await productService.updateProduct(
                        id: prod.id,
                        title: prod.title,
                        description: prod.description,
                        minPrice: newMin,
                        maxPrice: newMax,
                        category: prod.category,
                        imageUrl: prod.imageUrl,
                        status: prod.status,
                        stockQuantity: prod.stockQuantity,
                      );
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tüm fiyatlar güncellendi!'))
                      );
                      _refresh();
                    }
                  },
                  child: const Text('Uygula'),
                )
              ],
            );
          }
        );
      }
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  const _ProductListItem({
    required this.compact,
    required this.product,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final bool compact;
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = compact || constraints.maxWidth < 620;
            final image = ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                        product.imageUrl!,
                        width: isCompact ? double.infinity : 72,
                        height: isCompact ? 180 : 72,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: isCompact ? double.infinity : 72,
                              height: isCompact ? 180 : 72,
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey.shade500,
                              ),
                            ),
                      )
                      : Container(
                        width: isCompact ? double.infinity : 72,
                        height: isCompact ? 180 : 72,
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade500,
                        ),
                      ),
            );

            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category ?? 'Kategori yok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _statusChip(product.status),
                    Text(
                      '₺${product.basePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        fontSize: 16,
                      ),
                    ),
                    if (product.maxPrice != null && product.maxPrice! > product.basePrice)
                      Text(
                        '₺${product.maxPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.stockQuantity < 5 ? Colors.red.shade50 : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stok: ${product.stockQuantity}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: product.stockQuantity < 5 ? Colors.red.shade700 : cs.onSurfaceVariant,
                          fontWeight: product.stockQuantity < 5 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

            final actions = Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                IconButton(
                  tooltip:
                      product.status.toLowerCase() == 'published'
                          ? 'Müşteriden gizle'
                          : 'Müşteride göster',
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    product.status.toLowerCase() == 'published'
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cs.primary,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Düzenle',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'Sil',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity, child: image),
                  const SizedBox(height: 12),
                  info,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 72, height: 72, child: image),
                const SizedBox(width: 12),
                Expanded(child: info),
                const SizedBox(width: 8),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();
    final isPublished = normalized == 'published';
    final bg = isPublished ? Colors.green.shade50 : Colors.orange.shade50;
    final fg = isPublished ? Colors.green.shade700 : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPublished ? 'Yayında' : 'Taslak',
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
