import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';
import '../../../services/product_service.dart';
import '../../../models/product_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  late Future<AdminDashboardMetrics> _metricsFuture;
  late Future<List<ProductModel>> _stockFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _metricsFuture = _loadMetrics();
    _stockFuture = _loadStock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      return; // initState already loaded
    }
    // Dashboard her aktif olduğunda (navigasyonla geri dönünce) yenile
    _refreshAll();
  }

  /// Uygulama arka plandan ön plana gelince yenile
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<AdminDashboardMetrics> _loadMetrics() async {
    final auth = context.read<AuthService>();
    final orderService = OrderService(auth);
    return orderService.getAdminDashboard();
  }

  Future<List<ProductModel>> _loadStock() async {
    final auth = context.read<AuthService>();
    return ProductService(auth).getAdminProducts();
  }

  void _refreshAll() {
    setState(() {
      _metricsFuture = _loadMetrics();
      _stockFuture = _loadStock();
    });
  }

  String _formatInt(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    return '₺${_formatInt(rounded)}';
  }

  String _formatUtcAsLocal(DateTime utc) {
    final local = utc.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy $hh:$min';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'shipped':
        return 'Kargoda';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardMetrics>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 34),
                const SizedBox(height: 10),
                Text(
                  'Dashboard verileri yüklenemedi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _metricsFuture = _loadMetrics();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final metrics = snapshot.data!;
        final trendLabels =
            metrics.statusDistribution
                .map((s) => _statusLabel(s.status))
                .toList();
        final trendValues =
            metrics.statusDistribution.map((s) => s.count.toDouble()).toList();

        final stats = [
          (
            title: 'Toplam Ürün',
            value: _formatInt(metrics.totalProducts),
            icon: Icons.inventory_2_outlined,
          ),
          (
            title: 'Satış Adedi',
            value: _formatInt(metrics.totalSalesCount),
            icon: Icons.shopping_bag_outlined,
          ),
          (
            title: 'Toplam Gelir',
            value: _formatCurrency(metrics.totalRevenue),
            icon: Icons.payments_outlined,
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Satış performansı ve hızlı yönetim aksiyonları',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Yenile',
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount =
                      width > 1100 ? 3 : (width > 760 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.8,
                    ),
                    itemBuilder: (context, i) {
                      final item = stats[i];
                      return AppSurfaceCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  item.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 980;

                  final trendCard = AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş Durum Dağılımı',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 260,
                          child: _TrendChart(
                            values: trendValues,
                            labels: trendLabels,
                          ),
                        ),
                      ],
                    ),
                  );

                  final quickActions = AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hızlı Erişim',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _quickAction(
                          context,
                          label: 'Ürün Yönetimi',
                          route: '/admin/products',
                          icon: Icons.inventory_2,
                        ),
                        _quickAction(
                          context,
                          label: 'Kategori Yönetimi',
                          route: '/admin/categories',
                          icon: Icons.category,
                        ),
                        _quickAction(
                          context,
                          label: 'Siparişler',
                          route: '/admin/orders',
                          icon: Icons.shopping_bag,
                        ),
                        _quickAction(
                          context,
                          label: 'AI Ürün Ekle',
                          route: '/admin/smart-product',
                          icon: Icons.auto_awesome,
                        ),
                        _quickAction(
                          context,
                          label: 'Arama Ayarları',
                          route: '/admin/settings',
                          icon: Icons.settings_suggest,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Kritik Stok Uyarıları',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<ProductModel>>(
                          future: _stockFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final lowStock = snapshot.data?.where((p) => p.stockQuantity < 5).toList() ?? [];
                            if (lowStock.isEmpty) {
                              return const Text('Tüm stoklar yeterli (5+)');
                            }
                            return Column(
                              children: lowStock.take(5).map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.title, 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${p.stockQuantity} Adet',
                                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              )).toList(),
                            );
                          }
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Son Satışlar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (metrics.recentSales.isEmpty)
                          const Text('Henüz satış kaydı yok.')
                        else
                          ...metrics.recentSales
                              .take(5)
                              .map(
                                (sale) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.sell_outlined,
                                        size: 16,
                                        color: Color(0xFF667085),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sale.productTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${sale.quantity} adet • ${_formatCurrency(sale.lineTotal)} • ${_formatUtcAsLocal(sale.soldAtUtc)}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelMedium?.copyWith(
                                                color: const Color(0xFF667085),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        trendCard,
                        const SizedBox(height: 12),
                        quickActions,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: trendCard),
                      const SizedBox(width: 12),
                      Expanded(child: quickActions),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          await context.push(route);
          // Geri dönünce stok ve metrikleri yenile
          if (mounted) _refreshAll();
        },
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryDark, size: 18),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('Grafik verisi yok'));
    }

    final max = values.reduce((a, b) => a > b ? a : b);
    final safeMax = max <= 0 ? 1.0 : max;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: (values[i] / safeMax) * 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppTheme.accent, AppTheme.primary],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < labels.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
