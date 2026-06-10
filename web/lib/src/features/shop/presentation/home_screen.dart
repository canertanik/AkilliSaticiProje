import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../core/widgets/hover_scale.dart';
import '../../../core/widgets/product_grid_card.dart';
import '../../../models/product_model.dart';
import '../../../services/api_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../state/cart_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ProductModel>> _future;
  final PageController _discountPageController = PageController(
    viewportFraction: 0.92,
  );
  Timer? _discountTimer;
  int _discountPageIndex = 0;
  int _discountItemCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts();
  }

  @override
  void dispose() {
    _discountTimer?.cancel();
    _discountPageController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _loadProducts() {
    final auth = context.read<AuthService>();
    return ProductService(auth).getPublishedProducts();
  }

  void _ensureDiscountAutoSlide(int itemCount) {
    if (itemCount <= 1) {
      _discountTimer?.cancel();
      _discountTimer = null;
      _discountItemCount = itemCount;
      return;
    }

    if (_discountTimer != null && _discountItemCount == itemCount) {
      return;
    }

    _discountTimer?.cancel();
    _discountItemCount = itemCount;
    _discountTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_discountPageController.hasClients) return;
      final next = (_discountPageIndex + 1) % itemCount;
      _discountPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToDiscountPage(int index) {
    if (!_discountPageController.hasClients) return;
    _discountPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousDiscountPage() {
    if (_discountItemCount <= 1) return;
    final prev =
        (_discountPageIndex - 1 + _discountItemCount) % _discountItemCount;
    _goToDiscountPage(prev);
  }

  void _goToNextDiscountPage() {
    if (_discountItemCount <= 1) return;
    final next = (_discountPageIndex + 1) % _discountItemCount;
    _goToDiscountPage(next);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        const heroImageAsset = 'assets/images/anasayfaresim.jpg';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProducts = snapshot.data ?? const <ProductModel>[];
        final discountedProducts =
            allProducts.where((p) => p.getIsDiscounted(isLoggedIn)).toList();
        final bestSellers = allProducts.take(4).toList();
        final newArrivals = allProducts.reversed.take(4).toList();

        _ensureDiscountAutoSlide(discountedProducts.length);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 440,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      heroImageAsset,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: const Color(0xFF334155),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 42,
                              color: Colors.white70,
                            ),
                          ),
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Premium Petshop Deneyimi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Dostunuz İçin\nDoğru Ürün,\nHızlı Teslimat',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Mama, oyuncak, bakım ve daha fazlası. Güvenli ödeme ve hızlı kargo ile.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.go('/products'),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Hemen Al'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _TrustBadge(
                      icon: Icons.local_shipping_outlined,
                      title: 'Ücretsiz Kargo',
                      subtitle: '750 TL ve üzeri',
                    ),
                    _TrustBadge(
                      icon: Icons.lock_outline,
                      title: 'Güvenli Ödeme',
                      subtitle: '256-bit SSL',
                    ),
                  ],
                ),
              ),

              if (discountedProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haftanın İndirimleri',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _discountPageController,
                              itemCount: discountedProducts.length,
                              onPageChanged: (index) {
                                if (!mounted) return;
                                setState(() => _discountPageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                final p = discountedProducts[index];
                                return _buildDiscountSlide(context, p);
                              },
                            ),
                            if (discountedProducts.length > 1)
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: _buildSliderArrowButton(
                                    icon: Icons.chevron_left_rounded,
                                    onTap: _goToPreviousDiscountPage,
                                  ),
                                ),
                              ),
                            if (discountedProducts.length > 1)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: _buildSliderArrowButton(
                                    icon: Icons.chevron_right_rounded,
                                    onTap: _goToNextDiscountPage,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (discountedProducts.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(discountedProducts.length, (
                              i,
                            ) {
                              final active = i == _discountPageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: active ? 24 : 8,
                                decoration: BoxDecoration(
                                  color:
                                      active
                                          ? const Color(0xFF1F8A70)
                                          : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildCategoryCard(context, 'Kedi Ürünleri', 'Kedi Ürünleri', Icons.pets),
                        _buildCategoryCard(
                          context,
                          'Köpek Ürünleri',
                          'Köpek Ürünleri',
                          Icons.cruelty_free,
                        ),
                        _buildCategoryCard(context, 'Oyuncaklar', 'Oyuncaklar', Icons.toys),
                        _buildCategoryCard(
                          context,
                          'Bakım Ürünleri',
                          'Bakım Ürünleri',
                          Icons.clean_hands,
                        ),
                        _buildCategoryCard(
                          context,
                          'Kuş Ürünleri',
                          'Kuş Ürünleri',
                          Icons.flutter_dash,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (bestSellers.isNotEmpty)
                _HomeSection(
                  title: 'En Çok Satanlar',
                  subtitle: 'Müşterilerimizin en çok tercih ettiği ürünler',
                  child: _buildProductRow(bestSellers),
                ),

              if (newArrivals.isNotEmpty)
                _HomeSection(
                  title: 'Yeni Gelenler',
                  subtitle: 'Stoklarımıza yeni giren ürünleri kaçırmayın',
                  child: _buildProductRow(newArrivals),
                ),

              if (discountedProducts.isNotEmpty)
                _HomeSection(
                  title: 'İndirimli Ürünler',
                  subtitle: 'Sınırlı süreli fırsatlar',
                  child: _buildProductRow(discountedProducts.take(4).toList()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountSlide(BuildContext context, ProductModel product) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    final imageUrl =
        product.imageUrl?.isNotEmpty == true
            ? product.imageUrl!
            : '${ApiConfig.normalizedBaseUrl}/images/2da19b38-f2b9-49dd-a9e2-13e49b62d90c.jpg';

    return GestureDetector(
      onTap: () => context.go('/products/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFFF2F4F7),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    errorBuilder:
                        (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 38,
                            color: Color(0xFF64748B),
                          ),
                        ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.68),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '%${product.getDiscountPercent(isLoggedIn)} INDIRIM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₺${product.getDisplayPrice(isLoggedIn).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF74E6C0),
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.getOldPrice(isLoggedIn) != null)
                          Text(
                            '₺${product.getOldPrice(isLoggedIn)!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String category, IconData icon) {
    final encodedCategory = Uri.encodeComponent(category);
    return HoverScale(
      child: AppSurfaceCard(
        onTap: () => context.go('/products?category=$encodedCategory'),
        child: SizedBox(
          width: 208,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppTheme.accent),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(List<ProductModel> items) {
    return SizedBox(
      height: 380,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = items[index];
          return SizedBox(
            width: 280,
            child: ProductGridCard(
              product: product,
              onTap: () => context.go('/products/${product.id}'),
              onAddToCart: () {
                context.read<CartService>().add(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.title} sepete eklendi!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryDark),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
