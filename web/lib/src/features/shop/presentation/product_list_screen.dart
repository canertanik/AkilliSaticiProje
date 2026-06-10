import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_surface_card.dart';
import '../../../core/widgets/product_grid_card.dart';
import '../../../models/product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../state/cart_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  final String? initialCategory;
  final String? initialSearch;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _suggestionOverlay;
  List<ProductModel> _currentFilteredProducts = [];

  late Future<List<ProductModel>> _future;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'featured';
  double _priceStart = 0;
  double _priceEnd = 0;

  @override
  void initState() {
    super.initState();
    final initialCategory = widget.initialCategory;
    final initialSearch = widget.initialSearch;
    if (initialCategory != null && initialCategory.trim().isNotEmpty) {
      _selectedCategory = _normalizeForKey(initialCategory);
    }
    if (initialSearch != null && initialSearch.trim().isNotEmpty) {
      _searchQuery = initialSearch.trim();
      _searchController.text = _searchQuery;
    }
    _future = _load();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _searchController.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      if (_suggestionOverlay == null) {
        _suggestionOverlay = _createOverlay();
        Overlay.of(context).insert(_suggestionOverlay!);
      } else {
        _suggestionOverlay!.markNeedsBuild();
      }
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _searchLayerLink.leaderSize?.width ?? 300,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: TapRegion(
              groupId: 'productListSearch',
              onTapOutside: (_) => _searchFocusNode.unfocus(),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _buildSuggestionsContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsContent() {
    final Map<String, List<ProductModel>> grouped = {};
    for (final p in _currentFilteredProducts) {
      final rawCat = p.category ?? 'Diğer';
      grouped.putIfAbsent(rawCat, () => []).add(p);
    }
    
    if (grouped.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Öneri bulunamadı.'),
      );
    }

    final keys = grouped.keys.toList();
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final category = keys[index];
        final products = grouped[category]!.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            ...products.map((p) => ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('₺${p.getDisplayPrice(context.read<AuthService>().isLoggedIn).toStringAsFixed(2)}'),
              onTap: () {
                _searchFocusNode.unfocus();
                context.go('/products/${p.id}');
              },
            )),
            if (index < keys.length - 1)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categoryChanged = widget.initialCategory != oldWidget.initialCategory;
    final searchChanged = widget.initialSearch != oldWidget.initialSearch;

    if (categoryChanged) {
      final initialCategory = widget.initialCategory;
      _selectedCategory =
          (initialCategory != null && initialCategory.trim().isNotEmpty)
              ? _normalizeForKey(initialCategory)
              : 'all';
    }

    if (searchChanged) {
      final initialSearch = widget.initialSearch?.trim() ?? '';
      _searchQuery = initialSearch;
      _searchController.text = initialSearch;
    }

    if (categoryChanged || searchChanged) {
      _future = _load();
    }
  }

  Future<List<ProductModel>> _load() {
    final auth = context.read<AuthService>();
    return ProductService(auth).getPublishedProducts();
  }

  String _canonicalCategory(String? rawCategory) {
    final raw = (rawCategory ?? '').trim();
    if (raw.isEmpty) return 'Diger';

    // Keep the most specific part of hierarchical categories.
    final leaf =
        raw
            .split(RegExp(r'\s*>\s*|\s*/\s*|\s*\|\s*'))
            .where((part) => part.trim().isNotEmpty)
            .last
            .trim();
    final l = leaf.toLowerCase();

    if (l.contains('kedi')) return 'Kedi Urunleri';
    if (l.contains('kopek') || l.contains('köpek')) return 'Kopek Urunleri';
    if (l.contains('oyuncak')) return 'Oyuncaklar';
    if (l.contains('bakim') || l.contains('bakım')) return 'Bakim Urunleri';
    if (l.contains('kus') || l.contains('kuş')) return 'Kus Urunleri';

    return leaf;
  }

  String _displayCategory(String? rawCategory) {
    final canonical = _canonicalCategory(rawCategory);
    switch (canonical) {
      case 'Kedi Urunleri':
        return 'Kedi Ürünleri';
      case 'Kopek Urunleri':
        return 'Köpek Ürünleri';
      case 'Bakim Urunleri':
        return 'Bakım Ürünleri';
      case 'Kus Urunleri':
        return 'Kuş Ürünleri';
      case 'Diger':
        return 'Diğer';
      default:
        return canonical;
    }
  }

  String _normalizeForKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  String _categoryKey(String? rawCategory) {
    return _normalizeForKey(_displayCategory(rawCategory));
  }

  int _categoryOrder(String categoryLabel) {
    final key = _normalizeForKey(categoryLabel);
    switch (key) {
      case 'kedi urunleri':
        return 0;
      case 'kopek urunleri':
        return 1;
      case 'oyuncaklar':
        return 2;
      case 'kus urunleri':
        return 3;
      default:
        return 100;
    }
  }

  List<String> get _fixedCategoryOrder => const [
    'Kedi Ürünleri',
    'Köpek Ürünleri',
    'Oyuncaklar',
'Kuş Ürünleri',
  ];

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    final cs = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1280) {
      crossAxisCount = 4;
    } else if (screenWidth > 860) {
      crossAxisCount = 2;
    }
    final isDesktop = screenWidth > 980;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F8FF), Color(0xFFF3FBF7), Color(0xFFFFF8EE)],
        ),
      ),
      child: FutureBuilder<List<ProductModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    'Ürünler yüklenemedi: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => setState(() => _future = _load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? const <ProductModel>[];
          final categorySet = <String>{
            ..._fixedCategoryOrder,
            ...products
                .map((p) => _displayCategory(p.category))
                .where((c) => c.isNotEmpty),
          };
          final categories =
              categorySet.toList()..sort((a, b) {
                final orderCompare = _categoryOrder(
                  a,
                ).compareTo(_categoryOrder(b));
                if (orderCompare != 0) return orderCompare;
                return a.compareTo(b);
              });

          final dataMax = products.fold<double>(
            0,
            (max, p) => math.max(max, p.getDisplayPrice(isLoggedIn)),
          );
          final sliderMax =
              dataMax <= 0 ? 1000.0 : (dataMax * 1.2).ceilToDouble();
          final effectiveEnd = _priceEnd <= 0 ? sliderMax : _priceEnd;

          var filtered =
              products.where((p) {
                final matchesCategory =
                    _selectedCategory == 'all' ||
                    _categoryKey(p.category) == _selectedCategory;
                final matchesPrice =
                    p.getDisplayPrice(isLoggedIn) >= _priceStart &&
                    p.getDisplayPrice(isLoggedIn) <= effectiveEnd;
                if (!matchesCategory) return false;
                if (!matchesPrice) return false;
                if (_searchQuery.isEmpty) return true;
                final title = p.title.toLowerCase();
                final category = _normalizeForKey(p.category ?? '');
                final canonicalCategory = _categoryKey(p.category);
                final normalizedQuery = _normalizeForKey(_searchQuery);
                return title.contains(normalizedQuery) ||
                    category.contains(normalizedQuery) ||
                    canonicalCategory.contains(normalizedQuery);
              }).toList();
              
          _currentFilteredProducts = filtered;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _suggestionOverlay != null) {
              _suggestionOverlay!.markNeedsBuild();
            }
          });

          switch (_sortBy) {
            case 'priceAsc':
              filtered.sort((a, b) => a.getDisplayPrice(isLoggedIn).compareTo(b.getDisplayPrice(isLoggedIn)));
              break;
            case 'priceDesc':
              filtered.sort((a, b) => b.getDisplayPrice(isLoggedIn).compareTo(a.getDisplayPrice(isLoggedIn)));
              break;
            case 'name':
              filtered.sort(
                (a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );
              break;
            case 'featured':
              filtered.sort((a, b) {
                final orderCompare = _categoryOrder(
                  _displayCategory(a.category),
                ).compareTo(_categoryOrder(_displayCategory(b.category)));
                if (orderCompare != 0) return orderCompare;
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              });
              break;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSurfaceCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;

                      final searchField = TapRegion(
                        groupId: 'productListSearch',
                        onTapOutside: (_) => _searchFocusNode.unfocus(),
                        child: CompositedTransformTarget(
                          link: _searchLayerLink,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged:
                                (value) => setState(
                                  () => _searchQuery = value.trim().toLowerCase(),
                                ),
                            decoration: const InputDecoration(
                              hintText: 'Ürün adı veya kategori ara...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      );

                      final sortDropdown = SizedBox(
                        width:
                            isCompact
                                ? double.infinity
                                : (isDesktop ? 220 : 180),
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(
                              value: 'featured',
                              child: Text('Popüler'),
                            ),
                            DropdownMenuItem(
                              value: 'priceAsc',
                              child: Text('Fiyat Artan'),
                            ),
                            DropdownMenuItem(
                              value: 'priceDesc',
                              child: Text('Fiyat Azalan'),
                            ),
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('Yeni'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _sortBy = value);
                          },
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            searchField,
                            const SizedBox(height: 10),
                            sortDropdown,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 10),
                          sortDropdown,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Henüz yayınlanmış ürün bulunmuyor.'),
                    ),
                  )
                else if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Filtreye uygun ürün bulunamadı.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop)
                        SizedBox(
                          width: 280,
                          child: _buildFilterPanel(
                            categories: categories,
                            sliderMax: sliderMax,
                            effectiveEnd: effectiveEnd,
                            productCount: filtered.length,
                          ),
                        ),
                      if (isDesktop) const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isDesktop)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildFilterPanel(
                                  categories: categories,
                                  sliderMax: sliderMax,
                                  effectiveEnd: effectiveEnd,
                                  productCount: filtered.length,
                                ),
                              ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.63,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final product = filtered[index];
                                return ProductGridCard(
                                  product: product,
                                  onTap:
                                      () =>
                                          context.go('/products/${product.id}'),
                                  onAddToCart: () {
                                    context.read<CartService>().add(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.title} sepete eklendi!',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel({
    required List<String> categories,
    required double sliderMax,
    required double effectiveEnd,
    required int productCount,
  }) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtreler',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$productCount ürün',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip('Tüm Kategoriler', 'all'),
              for (final category in categories)
                _categoryChip(category, _normalizeForKey(category)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Fiyat Aralığı',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          RangeSlider(
            min: 0,
            max: sliderMax,
            values: RangeValues(_priceStart, effectiveEnd),
            labels: RangeLabels(
              '₺${_priceStart.toStringAsFixed(0)}',
              '₺${effectiveEnd.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() {
                _priceStart = values.start;
                _priceEnd = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₺${_priceStart.toStringAsFixed(0)}'),
              Text('₺${effectiveEnd.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'all';
                  _searchController.clear();
                  _searchQuery = '';
                  _priceStart = 0;
                  _priceEnd = sliderMax;
                });
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Filtreyi Temizle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      selectedColor: const Color(0xFF3D6CB9).withValues(alpha: 0.18),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF3D6CB9) : const Color(0xFFE2E8F0),
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1F3C88) : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedCategory = value),
    );
  }
}
