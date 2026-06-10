import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../models/category_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CategoryModel>> _load() {
    final auth = context.read<AuthService>();
    return CategoryService(auth).getCategories();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final categoryService = CategoryService(auth);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Kategori Yönetimi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Kategori'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => _showCategoryDialog(context, categoryService),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppSurfaceCard(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return AppSurfaceCard(
                    child: Center(
                      child: Text('Kategoriler alınamadı: ${snapshot.error}'),
                    ),
                  );
                }

                final categories = snapshot.data ?? const [];
                if (categories.isEmpty) {
                  return const AppSurfaceCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 30),
                          SizedBox(height: 8),
                          Text('Kategori bulunmuyor.'),
                        ],
                      ),
                    ),
                  );
                }

                return AppSurfaceCard(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.category),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle:
                            category.description != null &&
                                    category.description!.isNotEmpty
                                ? Text(
                                  category.description!,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                                : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed:
                                  () => _showCategoryDialog(
                                    context,
                                    categoryService,
                                    existing: category,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final error = await categoryService
                                    .deleteCategory(category.id);
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(error ?? 'Kategori silindi.'),
                                  ),
                                );
                                if (error == null) _refresh();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    CategoryService categoryService, {
    CategoryModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Yeni Kategori' : 'Kategori Güncelle'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Kategori adı'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final error =
                    existing == null
                        ? await categoryService.createCategory(
                          name: name,
                          description: descriptionController.text.trim(),
                        )
                        : await categoryService.updateCategory(
                          id: existing.id,
                          name: name,
                          description: descriptionController.text.trim(),
                        );

                if (!dialogContext.mounted || !mounted) return;
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(error ?? 'Kayıt başarılı')),
                );
                if (error == null) _refresh();
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
