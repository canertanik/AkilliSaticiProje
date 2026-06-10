import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../core/theme/app_theme.dart';
import '../models/product_model.dart';

import '../features/admin/presentation/admin_login_screen.dart';
import '../features/admin/presentation/dashboard_screen.dart';
import '../features/admin/presentation/manage_categories_screen.dart';
import '../features/admin/presentation/manage_orders_screen.dart';
import '../features/admin/presentation/manage_settings_screen.dart';
import '../features/admin/presentation/manage_products_screen.dart';
import '../features/admin/presentation/sales_screen.dart';
import '../features/admin/presentation/smart_product_screen.dart';
import '../features/shop/presentation/auth/login_register_screen.dart';
import '../features/shop/presentation/cart_screen.dart';
import '../features/shop/presentation/home_screen.dart';
import '../features/shop/presentation/product_detail_screen.dart';
import '../features/shop/presentation/product_list_screen.dart';
import '../features/shop/presentation/pet_profiles_screen.dart';
import '../features/shop/presentation/chat_bot_widget.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/store_settings_model.dart';

import '../services/product_service.dart';

class _KeepAliveFocusNode extends FocusNode {
  bool keepAlive = false;

  @override
  void unfocus({UnfocusDisposition disposition = UnfocusDisposition.scope}) {
    if (keepAlive) {
      keepAlive = false; // reset for next time, but block this unfocus
      return;
    }
    super.unfocus(disposition: disposition);
  }
}

void _showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Yardım & İletişim'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sorularınız ve destek için bize ulaşın:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text('canpet@gmail.com', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 8),
                Text('+90 555 123 4567', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      final rawLocation = state.uri.path;
      final location = _normalizeLocation(rawLocation);

      if (location != rawLocation) {
        return location;
      }

      final isAdminArea = location.startsWith('/admin');
      final isAdminLogin = location == '/admin/login';

      if (isAdminArea && !isAdminLogin && !authService.isAdmin) {
        return '/admin/login';
      }

      if (isAdminLogin && authService.isAdmin) {
        return '/admin';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final isAdminArea =
              location.startsWith('/admin') && location != '/admin/login';

          if (isAdminArea) {
            return _AdminShell(
              location: location,
              authService: authService,
              child: child,
            );
          }

          final isCompact = MediaQuery.of(context).size.width < 1000;

          if (isCompact) {
            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(270),
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.go('/'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFE53935),
                                  ),
                                  child: const Text(
                                    'canpet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => context.go('/cart'),
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color:
                                      location == '/cart'
                                          ? AppTheme.primaryDark
                                          : Colors.black87,
                                ),
                              ),
                              if (authService.isAdmin)
                                IconButton(
                                  onPressed: () => context.go('/admin'),
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _TopSearchBox(authService: authService),
                        ),
                        if (authService.isLoggedIn)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 14,
                                    color: Color(0xFF15795E),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Giriş yapıldı',
                                    style: TextStyle(
                                      color: Color(0xFF15795E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 42,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                if (!authService.isLoggedIn) ...[
                                  _TopNavButton(
                                    label: 'Üye Ol',
                                    selected: false,
                                    onTap: () => context.go('/login'),
                                  ),
                                  _TopNavButton(
                                    label: 'Giriş Yap',
                                    selected: false,
                                    onTap: () => context.go('/login'),
                                  ),
                                ] else ...[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'Hoşgeldin ${authService.currentUser?.fullName ?? ''}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                                if (authService.isLoggedIn)
                                  _TopNavButton(
                                    label: 'Çıkış Yap',
                                    selected: false,
                                    onTap: () => authService.logout(),
                                  ),
                                _TopNavButton(
                                  label: 'Yardım',
                                  selected: false,
                                  onTap: () => _showHelpDialog(context),
                                ),
                                  _TopNavButton(
                                    label: 'Evcil Hayvanlarım',
                                    selected: location == '/pet-profiles',
                                    onTap: () => context.go('/pet-profiles'),
                                  ),
                                  _TopNavButton(
                                    label: 'Sepetim',
                                    selected: location == '/cart',
                                    onTap: () => context.go('/cart'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 0),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _CategoryButton(
                                  label: 'Kedi Ürünleri',
                                  summaryTitle: 'Kedi Ürünleri Kategorileri',
                                  leftMenuItems: const [
                                    'Kedi Maması',
                                    'Kedi Konserve Maması',
                                    'Kedi Ödül Maması',
                                    'Kedi Kumu',
                                    'Vitaminler ve Ek Besinler',
                                    'Kedi Oyuncağı',
                                  ],
                                  featuredItems: const [
                                    'Tümünü Gör',
                                    'Kısırlaştırılmış Kedi Maması',
                                    'Yetişkin Kedi Maması',
                                    'Yavru Kedi Maması',
                                    'Veteriner Diyet',
                                    'Ödül Maması',
                                  ],
                                  onTap:
                                      () => context.go(
                                        '/products?category=Kedi Ürünleri',
                                      ),
                                ),
                                _CategoryButton(
                                  label: 'Köpek Ürünleri',
                                  summaryTitle: 'Köpek Ürünleri Öne Çıkanlar',
                                  leftMenuItems: const [
                                    'Köpek Maması',
                                    'Köpek Konserve Maması',
                                    'Köpek Ödül Maması',
                                    'Köpek Tasma ve Kayış',
                                    'Köpek Yatakları',
                                    'Köpek Oyuncakları',
                                  ],
                                  featuredItems: const [
                                    'Tümünü Gör',
                                    'Yavru Köpek Maması',
                                    'Yetişkin Köpek Maması',
                                    'Köpek Ödül Maması',
                                    'Köpek Tasması',
                                    'Köpek Oyuncakları',
                                  ],
                                  onTap:
                                      () => context.go(
                                        '/products?category=Köpek Ürünleri',
                                      ),
                                ),
                                _CategoryButton(
                                  label: 'Kuş Ürünleri',
                                  summaryTitle: 'Kuş Ürünleri Özet',
                                  leftMenuItems: const [
                                    'Kuş Yemleri',
                                    'Kuş Kafesleri',
                                    'Kuş Oyuncakları',
                                    'Kuş Vitaminleri',
                                    'Kuş Kumları',
                                  ],
                                  featuredItems: const [
                                    'Tümünü Gör',
                                    'Kuş Yemleri',
                                    'Kafes ve Aksesuar',
                                    'Kuş Oyuncakları',
                                    'Vitamin ve Mineraller',
                                  ],
                                  onTap:
                                      () => context.go(
                                        '/products?category=Kuş Ürünleri',
                                      ),
                                ),
                                _CategoryButton(
                                  label: 'Kemirgen Ürünleri',
                                  summaryTitle: 'Kemirgen Ürünleri Özet',
                                  leftMenuItems: const [
                                    'Kemirgen Yemleri',
                                    'Kemirgen Kafesleri',
                                    'Kemirgen Altlıkları',
                                    'Kemirme Taşları',
                                    'Kemirgen Oyuncakları',
                                  ],
                                  featuredItems: const [
                                    'Tümünü Gör',
                                    'Yem ve Mamalar',
                                    'Kafesler',
                                    'Altlıklar',
                                    'Kemirme Oyuncakları',
                                  ],
                                  onTap:
                                      () => context.go(
                                        '/products?category=Kemirgen Ürünleri',
                                      ),
                                ),
                                _CategoryButton(
                                  label: 'Bakım Ürünleri',
                                  summaryTitle: 'Bakım Ürünleri Özet',
                                  leftMenuItems: const [
                                    'Şampuan ve Temizlik',
                                    'Tüy Bakımı',
                                    'Ağız ve Diş Bakımı',
                                    'Tırnak ve Pati Bakımı',
                                    'Taşıma Ürünleri',
                                  ],
                                  featuredItems: const [
                                    'Tümünü Gör',
                                    'Şampuan ve Temizlik',
                                    'Tüy Bakımı',
                                    'Ağız ve Diş Bakımı',
                                    'Taşıma Çantaları',
                                  ],
                                  onTap:
                                      () => context.go(
                                        '/products?category=Bakım Ürünleri',
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
              ),
              floatingActionButton: const ChatBotFab(),
              body: child,
            );
          }

          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(140),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFE53935),
                            ),
                            child: const Text(
                              'canpet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _TopSearchBox(authService: authService),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            if (!authService.isLoggedIn) ...[
                              _TopNavButton(
                                label: 'Üye Ol',
                                selected: false,
                                onTap: () => context.go('/login'),
                              ),
                              _TopNavButton(
                                label: 'Giriş Yap',
                                selected: false,
                                onTap: () => context.go('/login'),
                              ),
                            ] else ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Hoşgeldin ${authService.currentUser?.fullName ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                            if (authService.isLoggedIn)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F8F1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Giriş yapıldı',
                                    style: TextStyle(
                                      color: Color(0xFF15795E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            if (authService.isLoggedIn)
                              _TopNavButton(
                                label: 'Çıkış Yap',
                                selected: false,
                                onTap: () => authService.logout(),
                              ),
                            _TopNavButton(
                              label: 'Yardım',
                              selected: false,
                              onTap: () => _showHelpDialog(context),
                            ),
                            if (authService.isLoggedIn)
                              _TopNavButton(
                                label: 'Evcil Hayvanlarım',
                                selected: location == '/pet-profiles',
                                onTap: () => context.go('/pet-profiles'),
                              ),
                            _TopNavButton(
                              label: 'Sepetim',
                              selected: location == '/cart',
                              onTap: () => context.go('/cart'),
                            ),
                            if (authService.isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: FilledButton.tonal(
                                  onPressed: () => context.go('/admin'),
                                  child: const Text('Admin'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryButton(
                            label: 'Kedi Ürünleri',
                            summaryTitle: 'Kedi Ürünleri Kategorileri',
                            leftMenuItems: const [
                              'Kedi Maması',
                              'Kedi Konserve Maması',
                              'Kedi Ödül Maması',
                              'Kedi Kumu',
                              'Vitaminler ve Ek Besinler',
                              'Kedi Oyuncağı',
                            ],
                            featuredItems: const [
                              'Tümünü Gör',
                              'Kısırlaştırılmış Kedi Maması',
                              'Yetişkin Kedi Maması',
                              'Yavru Kedi Maması',
                              'Veteriner Diyet',
                              'Ödül Maması',
                            ],
                            onTap:
                                () => context.go(
                                  '/products?category=Kedi Ürünleri',
                                ),
                          ),
                          _CategoryButton(
                            label: 'Köpek Ürünleri',
                            summaryTitle: 'Köpek Ürünleri Öne Çıkanlar',
                            leftMenuItems: const [
                              'Köpek Maması',
                              'Köpek Konserve Maması',
                              'Köpek Ödül Maması',
                              'Köpek Tasma ve Kayış',
                              'Köpek Yatakları',
                              'Köpek Oyuncakları',
                            ],
                            featuredItems: const [
                              'Tümünü Gör',
                              'Yavru Köpek Maması',
                              'Yetişkin Köpek Maması',
                              'Köpek Ödül Maması',
                              'Köpek Tasması',
                              'Köpek Oyuncakları',
                            ],
                            onTap:
                                () => context.go(
                                  '/products?category=Köpek Ürünleri',
                                ),
                          ),
                          _CategoryButton(
                            label: 'Kuş Ürünleri',
                            summaryTitle: 'Kuş Ürünleri Özet',
                            leftMenuItems: const [
                              'Kuş Yemleri',
                              'Kuş Kafesleri',
                              'Kuş Oyuncakları',
                              'Kuş Vitaminleri',
                              'Kuş Kumları',
                            ],
                            featuredItems: const [
                              'Tümünü Gör',
                              'Kuş Yemleri',
                              'Kafes ve Aksesuar',
                              'Kuş Oyuncakları',
                              'Vitamin ve Mineraller',
                            ],
                            onTap:
                                () => context.go(
                                  '/products?category=Kuş Ürünleri',
                                ),
                          ),
                          _CategoryButton(
                            label: 'Kemirgen Ürünleri',
                            summaryTitle: 'Kemirgen Ürünleri Özet',
                            leftMenuItems: const [
                              'Kemirgen Yemleri',
                              'Kemirgen Kafesleri',
                              'Kemirgen Altlıkları',
                              'Kemirme Taşları',
                              'Kemirgen Oyuncakları',
                            ],
                            featuredItems: const [
                              'Tümünü Gör',
                              'Yem ve Mamalar',
                              'Kafesler',
                              'Altlıklar',
                              'Kemirme Oyuncakları',
                            ],
                            onTap:
                                () => context.go(
                                  '/products?category=Kemirgen Ürünleri',
                                ),
                          ),
                          _CategoryButton(
                            label: 'Bakım Ürünleri',
                            summaryTitle: 'Bakım Ürünleri Özet',
                            leftMenuItems: const [
                              'Şampuan ve Temizlik',
                              'Tüy Bakımı',
                              'Ağız ve Diş Bakımı',
                              'Tırnak ve Pati Bakımı',
                              'Taşıma Ürünleri',
                            ],
                            featuredItems: const [
                              'Tümünü Gör',
                              'Şampuan ve Temizlik',
                              'Tüy Bakımı',
                              'Ağız ve Diş Bakımı',
                              'Taşıma Çantaları',
                            ],
                            onTap:
                                () => context.go(
                                  '/products?category=Bakım Ürünleri',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: const ChatBotFab(),
            body: child,
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder:
                (context, state) => ProductListScreen(
                  initialCategory: state.uri.queryParameters['category'],
                  initialSearch: state.uri.queryParameters['q'],
                ),
          ),
          GoRoute(
            path: '/products/:id',
            builder:
                (context, state) =>
                    ProductDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginRegisterScreen(),
          ),
          GoRoute(
            path: '/pet-profiles',
            builder: (context, state) => const PetProfilesScreen(),
          ),
          GoRoute(
            path: '/admin/login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const DashboardScreen(),
            routes: [
              GoRoute(
                path: 'products',
                builder: (context, state) => const ManageProductsScreen(),
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) => const ManageCategoriesScreen(),
              ),
              GoRoute(
                path: 'orders',
                builder: (context, state) => const ManageOrdersScreen(),
              ),
              GoRoute(
                path: 'sales',
                builder: (context, state) => const SalesScreen(),
              ),
              GoRoute(
                path: 'smart-product',
                builder: (context, state) => const SmartProductScreen(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const ManageSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String _normalizeLocation(String path) {
    var normalized = path;

    while (normalized.startsWith('/admin/admin')) {
      normalized = normalized.replaceFirst('/admin/admin', '/admin');
    }

    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }
}

class _TopNavButton extends StatelessWidget {
  const _TopNavButton({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? AppTheme.primaryDark : null,
          textStyle: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _TopSearchBox extends StatefulWidget {
  const _TopSearchBox({required this.authService});

  final AuthService authService;

  @override
  State<_TopSearchBox> createState() => _TopSearchBoxState();
}

class _TopSearchBoxState extends State<_TopSearchBox> {
  final TextEditingController _controller = TextEditingController();
  final _KeepAliveFocusNode _focusNode = _KeepAliveFocusNode();
  final LayerLink _layerLink = LayerLink();
  List<ProductModel> _products = const <ProductModel>[];
  StoreSettingsModel _storeSettings = const StoreSettingsModel(popularCategories: [], popularBrands: []);

  @override
  void initState() {
    super.initState();
    unawaited(Future.wait([
      _loadProducts(),
      _loadSettings(),
    ]));
  }

  Future<void> _loadSettings() async {
    try {
      final settingsService = SettingsService(widget.authService);
      final settings = await settingsService.getSettings();
      if (!mounted) return;
      setState(() => _storeSettings = settings);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final items =
          await ProductService(widget.authService).getPublishedProducts();
      if (!mounted) return;
      setState(() => _products = items);
    } catch (_) {
      // Suggestion box can stay empty if products cannot be loaded.
    }
  }

  List<ProductModel> _suggestions(String query) {
    final q = _normalize(query);
    if (q.isEmpty) {
      return _products.take(18).toList();
    }
    if (q.length < 2) return _products.take(10).toList();

    final results =
        _products.where((p) {
          final title = _normalize(p.title);
          final category = _normalize(p.category ?? '');
          return title.contains(q) || category.contains(q);
        }).toList();

    results.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return results.take(8).toList();
  }

  List<String> _popularCategories() {
    if (_storeSettings.popularCategories.isNotEmpty) {
      return _storeSettings.popularCategories;
    }

    final counts = <String, int>{};
    for (final p in _products) {
      final c = (p.category ?? '').trim();
      if (c.isEmpty) continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }

  String? _extractBrand(String title) {
    final t = _normalize(title);
    const brands = <String, String>{
      'royal canin': 'Royal Canin',
      'pro plan': 'Pro Plan',
      'purina': 'Purina',
      'n&d': 'N&D',
      'hills': "Hill's",
      'brit care': 'Brit Care',
      'acana': 'Acana',
      'gimcat': 'GimCat',
      'wanpy': 'Wanpy',
      'catlife': 'Catlife',
    };

    for (final entry in brands.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return null;
  }

  List<String> _popularBrands() {
    if (_storeSettings.popularBrands.isNotEmpty) {
      return _storeSettings.popularBrands;
    }

    final counts = <String, int>{};
    for (final p in _products) {
      final brand = _extractBrand(p.title);
      if (brand == null) continue;
      counts[brand] = (counts[brand] ?? 0) + 1;
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }

  List<ProductModel> _featuredProducts() {
    final withImage =
        _products
            .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
            .toList();
    withImage.sort((a, b) => b.getDisplayPrice(context.read<AuthService>().isLoggedIn).compareTo(a.getDisplayPrice(context.read<AuthService>().isLoggedIn)));
    return withImage.take(6).toList();
  }

  List<ProductModel> _bestSellerProducts() {
    final list = List<ProductModel>.from(_products);
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list.take(6).toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  InputDecoration _decoration() {
    return InputDecoration(
      hintText: 'Ürün, kategori ara...',
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<ProductModel>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.title,
      optionsBuilder: (textEditingValue) => _suggestions(textEditingValue.text),
      onSelected: (product) {
        if (!mounted) return;
        context.go('/products/${product.id}');
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TapRegion(
          groupId: 'topSearchBox',
          onTapOutside: (_) {
            _focusNode.keepAlive = false;
            focusNode.unfocus();
          },
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Color(0xFF111827)),
              cursorColor: AppTheme.primary,
              onSubmitted: (value) {
                final q = value.trim();
                if (q.isEmpty) {
                  context.go('/products');
                  return;
                }
                final encoded = Uri.encodeComponent(q);
                context.go('/products?q=$encoded');
              },
              decoration: _decoration(),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList(growable: false);
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }

        final isSummaryMode = _controller.text.trim().isEmpty;

        return Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: TapRegion(
              groupId: 'topSearchBox',
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSummaryMode ? 880 : 760,
                maxHeight: isSummaryMode ? 540 : 360,
              ),
              child:
                  isSummaryMode
                      ? NotificationListener<ScrollUpdateNotification>(
                          onNotification: (notification) {
                            if (notification.dragDetails != null) {
                              _focusNode.keepAlive = true;
                              SystemChannels.textInput.invokeMethod('TextInput.hide');
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Populer Kategoriler',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in _popularCategories())
                                  ActionChip(
                                    avatar: const Icon(Icons.search, size: 16),
                                    label: Text(c),
                                    onPressed: () {
                                      final encoded = Uri.encodeComponent(c);
                                      context.go('/products?category=$encoded');
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Populer Markalar',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final b in _popularBrands())
                                  ActionChip(
                                    avatar: const Icon(Icons.search, size: 16),
                                    label: Text(b),
                                    onPressed: () {
                                      final encoded = Uri.encodeComponent(b);
                                      context.go('/products?q=$encoded');
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Sizin Icin Sectiklerimiz',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final product in _featuredProducts())
                                  _SearchSummaryProductCard(
                                    product: product,
                                    onTap:
                                        () => context.go(
                                          '/products/${product.id}',
                                        ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Cok Satanlar',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final product in _bestSellerProducts())
                                  _SearchSummaryProductCard(
                                    product: product,
                                    onTap:
                                        () => context.go(
                                          '/products/${product.id}',
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    : NotificationListener<ScrollUpdateNotification>(
                          onNotification: (notification) {
                            if (notification.dragDetails != null) {
                              _focusNode.keepAlive = true;
                              SystemChannels.textInput.invokeMethod('TextInput.hide');
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = list[index];
                          return ListTile(
                            dense: true,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child:
                                    (product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty)
                                        ? Image.network(
                                          product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const ColoredBox(
                                                color: Color(0xFFF3F4F6),
                                                child: Icon(
                                                  Icons.pets_outlined,
                                                ),
                                              ),
                                        )
                                        : const ColoredBox(
                                          color: Color(0xFFF3F4F6),
                                          child: Icon(Icons.pets_outlined),
                                        ),
                              ),
                            ),
                            title: Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              product.category ?? 'Kategori yok',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${product.getDisplayPrice(context.read<AuthService>().isLoggedIn).toStringAsFixed(2)} TL',
                              style: const TextStyle(
                                color: Color(0xFF127F62),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => onSelected(product),
                          );
                        },
                      ),
            ),
          ),
          ),
          ),
          ),
        );
      },
    );
  }
}

class _SearchSummaryProductCard extends StatelessWidget {
  const _SearchSummaryProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 54,
                height: 54,
                child:
                    (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                        ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const ColoredBox(
                                color: Color(0xFFF3F4F6),
                                child: Icon(Icons.pets_outlined),
                              ),
                        )
                        : const ColoredBox(
                          color: Color(0xFFF3F4F6),
                          child: Icon(Icons.pets_outlined),
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.getDisplayPrice(context.read<AuthService>().isLoggedIn).toStringAsFixed(2)} TL',
                    style: const TextStyle(
                      color: Color(0xFF127F62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatefulWidget {
  const _CategoryButton({
    required this.label,
    required this.onTap,
    required this.summaryTitle,
    required this.leftMenuItems,
    required this.featuredItems,
  });

  final String label;
  final VoidCallback onTap;
  final String summaryTitle;
  final List<String> leftMenuItems;
  final List<String> featuredItems;

  @override
  State<_CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<_CategoryButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;
  bool _isHoveringButton = false;
  bool _isHoveringCard = false;
  int _activeLeftIndex = 0;
  double _overlayDx = -24;
  late final ProductService _productService;
  final Map<String, List<ProductModel>> _categoryProducts =
      <String, List<ProductModel>>{};
  final Set<String> _loadingCategories = <String>{};
  List<ProductModel>? _allPublishedProducts;
  bool _didInitService = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitService) return;
    _productService = ProductService(context.read<AuthService>());
    _didInitService = true;
    final initialCategory = _currentActiveLeftTitle;
    if (initialCategory != null) {
      unawaited(_ensureProductsLoaded(initialCategory));
    }
  }

  String? get _currentActiveLeftTitle {
    if (widget.leftMenuItems.isEmpty) return null;
    final safeIndex = _activeLeftIndex.clamp(
      0,
      widget.leftMenuItems.length - 1,
    );
    return widget.leftMenuItems[safeIndex];
  }

  Future<void> _ensureProductsLoaded(String category) async {
    if (_categoryProducts.containsKey(category) ||
        _loadingCategories.contains(category)) {
      return;
    }

    setState(() => _loadingCategories.add(category));

    try {
      var products = await _productService.getPublishedProducts(
        category: category,
      );
      products = _restrictByParentScope(products);
      products = _restrictByActiveCategory(products, category);

      if (products.isEmpty) {
        await _ensureAllProductsLoaded();
        products = _filterProductsByCategorySignals(category);
      }

      if (!mounted) return;
      setState(() {
        _categoryProducts[category] = products.take(8).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryProducts[category] = <ProductModel>[];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingCategories.remove(category));
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  Future<void> _ensureAllProductsLoaded() async {
    if (_allPublishedProducts != null) return;
    _allPublishedProducts = await _productService.getPublishedProducts();
  }

  List<ProductModel> _filterProductsByCategorySignals(String category) {
    final source = _allPublishedProducts ?? const <ProductModel>[];
    if (source.isEmpty) return const <ProductModel>[];

    final scopedSource = _restrictByParentScope(source);
    if (scopedSource.isEmpty) return const <ProductModel>[];

    final categorySignals = <String>{
      ..._extractSignals(category),
      ..._extractSignals(widget.label),
    }..removeWhere((s) => s.length < 3);

    final ranked =
        scopedSource.where((p) {
          final haystack = _normalizeText('${p.category ?? ''} ${p.title}');
          return categorySignals.any(haystack.contains);
        }).toList();

    ranked.sort((a, b) => b.getDisplayPrice(context.read<AuthService>().isLoggedIn).compareTo(a.getDisplayPrice(context.read<AuthService>().isLoggedIn)));
    return _restrictByActiveCategory(ranked, category);
  }

  List<ProductModel> _restrictByActiveCategory(
    List<ProductModel> products,
    String activeCategory,
  ) {
    final rule = _menuRuleFor(activeCategory);
    if (rule == null) {
      return products;
    }

    final filtered =
        products.where((p) {
          final haystack = _normalizeText('${p.category ?? ''} ${p.title}');
          final matchesRequired =
              rule.requiredAny.isEmpty ||
              rule.requiredAny.any(haystack.contains);
          final matchesForbidden = rule.forbiddenAny.any(haystack.contains);
          return matchesRequired && !matchesForbidden;
        }).toList();

    return filtered;
  }

  _MenuRule? _menuRuleFor(String raw) {
    final normalized = _normalizeText(raw);

    const foodForbidden = <String>{
      'oyuncak',
      'kum',
      'tasma',
      'kayis',
      'yatak',
      'kafes',
      'altlik',
    };

    if (normalized.contains('konserve')) {
      return const _MenuRule(requiredAny: {'konserve'});
    }
    if (normalized.contains('odul')) {
      return const _MenuRule(requiredAny: {'odul'}, forbiddenAny: {'konserve'});
    }
    if (normalized.contains('kumu') || normalized.contains('kum')) {
      return const _MenuRule(requiredAny: {'kum'}, forbiddenAny: {'mama'});
    }
    if (normalized.contains('oyuncak') || normalized.contains('oyuncag')) {
      return const _MenuRule(
        requiredAny: {'oyuncak'},
        forbiddenAny: {'mama', 'konserve', 'odul', 'kum'},
      );
    }
    if (normalized.contains('vitamin') || normalized.contains('ek besin')) {
      return const _MenuRule(
        requiredAny: {'vitamin', 'besin'},
        forbiddenAny: {'mama', 'konserve', 'oyuncak', 'kum'},
      );
    }
    if (normalized.contains('tasma') || normalized.contains('kayis')) {
      return const _MenuRule(
        requiredAny: {'tasma', 'kayis'},
        forbiddenAny: {'mama', 'konserve', 'odul'},
      );
    }
    if (normalized.contains('yatak')) {
      return const _MenuRule(requiredAny: {'yatak'}, forbiddenAny: {'mama'});
    }
    if (normalized.contains('kafes')) {
      return const _MenuRule(requiredAny: {'kafes'}, forbiddenAny: {'mama'});
    }
    if (normalized.contains('altlik')) {
      return const _MenuRule(requiredAny: {'altlik'});
    }
    if (normalized.contains('kemirme')) {
      return const _MenuRule(requiredAny: {'kemirme', 'kemirme tasi'});
    }
    if (normalized.contains('sampuan') || normalized.contains('temizlik')) {
      return const _MenuRule(
        requiredAny: {'sampuan', 'temizlik'},
        forbiddenAny: {'mama', 'konserve', 'odul'},
      );
    }
    if (normalized.contains('tuy')) {
      return const _MenuRule(requiredAny: {'tuy', 'tarak', 'firca'});
    }
    if (normalized.contains('agiz') || normalized.contains('dis')) {
      return const _MenuRule(requiredAny: {'dis', 'agiz'});
    }
    if (normalized.contains('tirnak') || normalized.contains('pati')) {
      return const _MenuRule(requiredAny: {'tirnak', 'pati'});
    }
    if (normalized.contains('tasima')) {
      return const _MenuRule(requiredAny: {'tasima', 'canta'});
    }

    if (normalized.contains('mamasi') || normalized.contains('mama')) {
      return const _MenuRule(
        requiredAny: {'mama'},
        forbiddenAny: foodForbidden,
      );
    }

    return null;
  }

  Set<String> _extractSignals(String raw) {
    final normalized = _normalizeText(raw);
    final tokens =
        normalized
            .split(RegExp(r'\s+'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .where(
              (t) =>
                  t != 've' &&
                  t != 'ile' &&
                  t != 'urunleri' &&
                  t != 'urunu' &&
                  t != 'urun' &&
                  t != 'tumunu' &&
                  t != 'gor',
            )
            .toSet();

    if (normalized.contains('kedi')) tokens.add('kedi');
    if (normalized.contains('kopek') || normalized.contains('köpek')) {
      tokens.add('kopek');
      tokens.add('köpek');
    }
    if (normalized.contains('kus') || normalized.contains('kuş')) {
      tokens.add('kus');
      tokens.add('kuş');
    }
    if (normalized.contains('kemirgen')) tokens.add('kemirgen');
    if (normalized.contains('bakim') || normalized.contains('bakım')) {
      tokens.add('bakim');
      tokens.add('bakım');
    }
    if (normalized.contains('mama')) tokens.add('mama');
    if (normalized.contains('oyuncak')) tokens.add('oyuncak');
    if (normalized.contains('kafes')) tokens.add('kafes');
    if (normalized.contains('kum')) tokens.add('kum');

    return tokens;
  }

  List<ProductModel> _restrictByParentScope(List<ProductModel> products) {
    final scope = _detectParentScope();
    if (scope == _ParentScope.bakim || scope == _ParentScope.none) {
      return products;
    }

    return products.where((p) {
      final haystack = _normalizeText('${p.category ?? ''} ${p.title}');
      return _matchesParentScope(haystack, scope);
    }).toList();
  }

  _ParentScope _detectParentScope() {
    final normalizedLabel = _normalizeText(widget.label);
    if (normalizedLabel.contains('kedi')) return _ParentScope.kedi;
    if (normalizedLabel.contains('kopek')) return _ParentScope.kopek;
    if (normalizedLabel.contains('kus')) return _ParentScope.kus;
    if (normalizedLabel.contains('kemirgen')) return _ParentScope.kemirgen;
    if (normalizedLabel.contains('bakim')) return _ParentScope.bakim;
    return _ParentScope.none;
  }

  bool _matchesParentScope(String haystack, _ParentScope scope) {
    switch (scope) {
      case _ParentScope.kedi:
        return haystack.contains('kedi') && !haystack.contains('kopek');
      case _ParentScope.kopek:
        return haystack.contains('kopek') && !haystack.contains('kedi');
      case _ParentScope.kus:
        return haystack.contains('kus');
      case _ParentScope.kemirgen:
        return haystack.contains('kemirgen');
      case _ParentScope.bakim:
      case _ParentScope.none:
        return true;
    }
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  void _setActiveLeftIndex(int index) {
    if (_activeLeftIndex == index) return;
    setState(() => _activeLeftIndex = index);
    final activeCategory = _currentActiveLeftTitle;
    if (activeCategory != null) {
      unawaited(_ensureProductsLoaded(activeCategory));
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _navigateToCategory(String category) {
    _removeOverlay();
    if (!mounted) return;
    final encoded = Uri.encodeComponent(category);
    context.go('/products?category=$encoded');
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final activeCategory = _currentActiveLeftTitle;
    if (activeCategory != null) {
      unawaited(_ensureProductsLoaded(activeCategory));
    }

    // Keep the mega menu inside the viewport for right-side categories.
    final buttonBox = context.findRenderObject() as RenderBox?;
    final buttonTopLeft =
        buttonBox?.localToGlobal(Offset.zero) ?? const Offset(0, 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = math.min(920.0, math.max(560.0, screenWidth - 64));
    const defaultDx = -24.0;
    const edgePadding = 16.0;
    final desiredLeft = buttonTopLeft.dx + defaultDx;
    final minLeft = edgePadding;
    final maxLeft = math.max(
      edgePadding,
      screenWidth - panelWidth - edgePadding,
    );
    final clampedLeft = desiredLeft.clamp(minLeft, maxLeft).toDouble();
    _overlayDx = clampedLeft - buttonTopLeft.dx;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(_overlayDx, 50),
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                onEnter: (_) {
                  _isHoveringCard = true;
                  _hideTimer?.cancel();
                },
                onExit: (_) {
                  _isHoveringCard = false;
                  _scheduleHide();
                },
                child: Material(
                  elevation: 14,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final safeIndex =
                          widget.leftMenuItems.isEmpty
                              ? 0
                              : _activeLeftIndex.clamp(
                                0,
                                widget.leftMenuItems.length - 1,
                              );
                      final activeLeftTitle =
                          widget.leftMenuItems.isEmpty
                              ? widget.summaryTitle
                              : widget.leftMenuItems[safeIndex];
                      final cachedProducts =
                          _categoryProducts[activeLeftTitle] ??
                          const <ProductModel>[];
                      final activeProducts = _restrictByActiveCategory(
                        _restrictByParentScope(cachedProducts),
                        activeLeftTitle,
                      );
                      final isLoadingProducts = _loadingCategories.contains(
                        activeLeftTitle,
                      );
                      final showRealProducts = activeProducts.isNotEmpty;
                      final activeFeaturedItems = _buildFeaturedItemsFor(
                        activeLeftTitle,
                      );
                      final panelWidth = math.min(
                        920.0,
                        math.max(560.0, screenWidth - 64),
                      );

                      return Container(
                        width: panelWidth,
                        constraints: const BoxConstraints(maxHeight: 430),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9E9E9)),
                          color: Colors.white,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 270,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F8F8),
                                border: Border(
                                  right: BorderSide(color: Color(0xFFE9E9E9)),
                                ),
                              ),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (
                                    var i = 0;
                                    i < widget.leftMenuItems.length;
                                    i++
                                  )
                                    _MegaMenuLeftItem(
                                      text: widget.leftMenuItems[i],
                                      active: i == safeIndex,
                                      onEnter: () => _setActiveLeftIndex(i),
                                      onTap:
                                          () => _navigateToCategory(
                                            widget.leftMenuItems[i],
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  18,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeLeftTitle,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 14,
                                          runSpacing: 14,
                                          children: [
                                            if (showRealProducts)
                                              for (final product
                                                  in activeProducts)
                                                _MegaMenuProductCard(
                                                  product: product,
                                                  onTap: () {
                                                    _removeOverlay();
                                                    if (!mounted) return;
                                                    context.go(
                                                      '/products/${product.id}',
                                                    );
                                                  },
                                                )
                                            else if (isLoadingProducts)
                                              for (var i = 0; i < 4; i++)
                                                const _MegaMenuLoadingCard()
                                            else
                                              for (final item
                                                  in activeFeaturedItems)
                                                _MegaMenuCard(
                                                  label: item,
                                                  icon: _iconForItem(item),
                                                  onTap:
                                                      () => _navigateToCategory(
                                                        item,
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  List<String> _buildFeaturedItemsFor(String activeLeftTitle) {
    final merged = <String>[activeLeftTitle, ...widget.featuredItems];
    final unique = <String>[];
    for (final item in merged) {
      if (!unique.contains(item)) {
        unique.add(item);
      }
    }
    return unique.take(8).toList();
  }

  IconData _iconForItem(String item) {
    final normalized = item.toLowerCase();
    if (normalized.contains('yem') ||
        normalized.contains('mama') ||
        normalized.contains('ödül')) {
      return Icons.restaurant_menu_outlined;
    }
    if (normalized.contains('kafes') || normalized.contains('taşıma')) {
      return Icons.home_work_outlined;
    }
    if (normalized.contains('oyuncak')) {
      return Icons.sports_esports_outlined;
    }
    if (normalized.contains('bakım') || normalized.contains('şampuan')) {
      return Icons.spa_outlined;
    }
    if (normalized.contains('veteriner') || normalized.contains('diyet')) {
      return Icons.medical_services_outlined;
    }
    return Icons.pets_outlined;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 120), () {
      if (!_isHoveringButton && !_isHoveringCard) {
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: MouseRegion(
          onEnter: (_) {
            _isHoveringButton = true;
            _hideTimer?.cancel();
            _showOverlay();
          },
          onExit: (_) {
            _isHoveringButton = false;
            _scheduleHide();
          },
          child: TextButton(
            onPressed: () {
              _removeOverlay();
              widget.onTap();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3D3D3D),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

enum _ParentScope { kedi, kopek, kus, kemirgen, bakim, none }

class _MenuRule {
  const _MenuRule({this.requiredAny = const {}, this.forbiddenAny = const {}});

  final Set<String> requiredAny;
  final Set<String> forbiddenAny;
}

class _MegaMenuLeftItem extends StatelessWidget {
  const _MegaMenuLeftItem({
    required this.text,
    required this.active,
    required this.onEnter,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onEnter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: active ? Colors.white : Colors.transparent,
      child: MouseRegion(
        onEnter: (_) => onEnter(),
        child: ListTile(
          onTap: onTap,
          dense: true,
          title: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: active ? const Color(0xFFDC3A32) : const Color(0xFF2F2F2F),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFF8A8A8A),
          ),
        ),
      ),
    );
  }
}

class _MegaMenuCard extends StatelessWidget {
  const _MegaMenuCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 98,
              width: 98,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 34, color: const Color(0xFF5F6368)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MegaMenuProductCard extends StatelessWidget {
  const _MegaMenuProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 98,
              width: 98,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.pets_outlined,
                              size: 34,
                              color: Color(0xFF5F6368),
                            ),
                      )
                      : const Icon(
                        Icons.pets_outlined,
                        size: 34,
                        color: Color(0xFF5F6368),
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2C2C2C),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.getDisplayPrice(context.read<AuthService>().isLoggedIn).toStringAsFixed(2)} TL',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF127F62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MegaMenuLoadingCard extends StatelessWidget {
  const _MegaMenuLoadingCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 98,
            width: 98,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminShell extends StatelessWidget {
  const _AdminShell({
    required this.location,
    required this.authService,
    required this.child,
  });

  final String location;
  final AuthService authService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 980;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petshop Admin Paneli'),
        leading:
            isMobile
                ? Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                )
                : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                await authService.logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıkış Yap'),
            ),
          ),
        ],
      ),
      drawer: isMobile ? _AdminDrawer(location: location) : null,
      body: Row(
        children: [
          if (!isMobile)
            SizedBox(width: 250, child: _AdminDrawer(location: location)),
          Expanded(child: Container(color: AppTheme.surfaceAlt, child: child)),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/admin'),
      (
        label: 'Ürünler',
        icon: Icons.inventory_2_outlined,
        route: '/admin/products',
      ),
      (
        label: 'Kategoriler',
        icon: Icons.category_outlined,
        route: '/admin/categories',
      ),
      (
        label: 'Siparişler',
        icon: Icons.receipt_long_outlined,
        route: '/admin/orders',
      ),
      (
        label: 'Satışlar',
        icon: Icons.trending_up_outlined,
        route: '/admin/sales',
      ),
      (
        label: 'AI Ürün Ekle',
        icon: Icons.auto_awesome_outlined,
        route: '/admin/smart-product',
      ),
    ];

    final drawerContent = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1726), Color(0xFF172B4D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 22),
              child: Row(
                children: [
                  Icon(Icons.pets, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Admin Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            for (final item in entries)
              _AdminNavTile(
                label: item.label,
                icon: item.icon,
                selected: location == item.route,
                onTap: () {
                  context.go(item.route);
                  Navigator.of(context).maybePop();
                },
              ),
          ],
        ),
      ),
    );

    final isDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    if (isDrawer) return Drawer(child: drawerContent);
    return drawerContent;
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0x3322D3EE) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.white70),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
