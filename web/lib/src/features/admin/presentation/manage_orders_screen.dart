import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface_card.dart';
import '../../../models/order_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  late Future<List<OrderModel>> _future;

  static const _statuses = [
    'Pending',
    'Preparing',
    'Shipped',
    'Completed',
    'Cancelled',
  ];

  String _statusLabel(String status) {
    const statusMap = {
      'Pending': 'Beklemede',
      'Preparing': 'Hazırlanıyor',
      'Shipped': 'Kargoda',
      'Completed': 'Tamamlandı',
      'Cancelled': 'İptal',
    };
    return statusMap[status] ?? status;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OrderModel>> _load() {
    final auth = context.read<AuthService>();
    return OrderService(auth).getAdminOrders();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
    'completed' => Colors.green,
    'shipped' => Colors.blue,
    'cancelled' => Colors.red,
    'preparing' => Colors.orange,
    _ => AppTheme.primaryDark,
  };

  void _showOrderDetail(
    BuildContext context,
    OrderModel order,
    OrderService orderService,
  ) {
    final statusColor = _statusColor(order.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (ctx, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: statusColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sipariş #${order.id}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₺${order.totalAmount.toStringAsFixed(2)} • ${_statusLabel(order.status)}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Ürünler
                            _sectionTitle('🛍️ Sipariş Ürünleri'),
                            const SizedBox(height: 10),
                            if (order.items.isEmpty)
                              const Text('Ürün bilgisi bulunamadı.')
                            else
                              ...order.items.map(
                                (item) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.pets,
                                          color: AppTheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${item.quantity} adet × ₺${item.unitPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₺${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Müşteri Bilgileri
                            _sectionTitle('👤 Müşteri Bilgileri'),
                            const SizedBox(height: 10),
                            _detailRow(
                              Icons.person_outline,
                              'Ad Soyad',
                              order.customerName,
                            ),
                            _detailRow(
                              Icons.email_outlined,
                              'E-posta',
                              order.customerEmail,
                            ),
                            _detailRow(
                              Icons.phone_outlined,
                              'Telefon',
                              order.customerPhone,
                            ),
                            const SizedBox(height: 16),
                            // Teslimat Adresi
                            _sectionTitle('📍 Teslimat Adresi'),
                            const SizedBox(height: 10),
                            _detailRow(
                              Icons.home_outlined,
                              'Adres Başlığı',
                              order.addressTitle,
                            ),
                            _detailRow(
                              Icons.location_on_outlined,
                              'Adres',
                              '${order.deliveryAddressLine}, ${order.deliveryNeighborhood}',
                            ),
                            _detailRow(
                              Icons.map_outlined,
                              'İlçe/Şehir',
                              '${order.deliveryDistrict}/${order.deliveryCity}',
                            ),
                            if (order.postalCode.isNotEmpty)
                              _detailRow(
                                Icons.markunread_mailbox_outlined,
                                'Posta Kodu',
                                order.postalCode,
                              ),
                            const SizedBox(height: 16),
                            // Ödeme & Not
                            _sectionTitle('💳 Ödeme Bilgileri'),
                            const SizedBox(height: 10),
                            _detailRow(
                              Icons.payment_outlined,
                              'Ödeme Yöntemi',
                              order.paymentMethod,
                            ),
                            _detailRow(
                              Icons.receipt_outlined,
                              'Toplam',
                              '₺${order.totalAmount.toStringAsFixed(2)}',
                            ),
                            if (order.orderNote != null &&
                                order.orderNote!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _sectionTitle('📝 Sipariş Notu'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Text(
                                  order.orderNote!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            // Durum değiştirici
                            _sectionTitle('📦 Durum Güncelle'),
                            const SizedBox(height: 10),
                            StatefulBuilder(
                              builder: (ctx2, setLocal) {
                                String local =
                                    _statuses.contains(order.status)
                                        ? order.status
                                        : 'Pending';
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _statuses.map((s) {
                                        final isSelected = local == s;
                                        final c = _statusColor(s);
                                        return GestureDetector(
                                          onTap: () async {
                                            setLocal(() => local = s);
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final error = await orderService
                                                .updateOrderStatus(
                                                  orderId: order.id,
                                                  status: s,
                                                );
                                            if (!context.mounted) return;
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  error ??
                                                      'Sipariş güncellendi',
                                                ),
                                              ),
                                            );
                                            if (error == null) {
                                              _refresh();
                                              if (ctx.mounted)
                                                Navigator.of(ctx).pop();
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? c
                                                      : c.withValues(
                                                        alpha: 0.08,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: c.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              _statusLabel(s),
                                              style: TextStyle(
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : c,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  void _confirmDelete(
    BuildContext context,
    OrderModel order,
    OrderService orderService,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Siparişi Sil'),
            content: Text(
              'Sipariş #${order.id} kalıcı olarak silinecek. Emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await orderService.deleteOrder(order.id);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Sipariş silindi'),
                      backgroundColor:
                          error != null ? Colors.red : Colors.green,
                    ),
                  );
                  if (error == null) _refresh();
                },
                child: const Text('Sil', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final orderService = OrderService(auth);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Siparişler',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Yenile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Siparişler alınamadı: ${snapshot.error}'),
                  );
                }

                final orders = snapshot.data ?? const [];
                if (orders.isEmpty) {
                  return const AppSurfaceCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 40),
                          SizedBox(height: 8),
                          Text('Henüz sipariş yok.'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final currentStatus =
                        _statuses.contains(order.status)
                            ? order.status
                            : 'Pending';
                    final statusColor = _statusColor(order.status);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap:
                            () =>
                                _showOrderDetail(context, order, orderService),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Üst satır: İkon + Sipariş No + Tutar
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: statusColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Sipariş #${order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₺${order.totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  // Sil butonu (sadece tamamlandı/iptal)
                                  if (order.status.toLowerCase() ==
                                          'completed' ||
                                      order.status.toLowerCase() == 'cancelled')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: GestureDetector(
                                        onTap:
                                            () => _confirmDelete(
                                              context,
                                              order,
                                              orderService,
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.person_outline,
                                '${order.customerName} • ${order.customerEmail}',
                              ),
                              const SizedBox(height: 4),
                              _infoRow(
                                Icons.phone_outlined,
                                order.customerPhone,
                              ),
                              const SizedBox(height: 4),
                              _infoRow(
                                Icons.location_on_outlined,
                                '${order.addressTitle} - ${order.deliveryDistrict}/${order.deliveryCity}',
                              ),
                              const SizedBox(height: 4),
                              _infoRow(
                                Icons.payment_outlined,
                                '${order.paymentMethod} • ${order.items.length} ürün',
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Text(
                                    'Durum:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentStatus,
                                        isDense: true,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        dropdownColor: Colors.white,
                                        items:
                                            _statuses
                                                .map(
                                                  (s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(
                                                      _statusLabel(s),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) async {
                                          if (value == null) return;
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final error = await orderService
                                              .updateOrderStatus(
                                                orderId: order.id,
                                                status: value,
                                              );
                                          if (!context.mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                error ?? 'Sipariş güncellendi',
                                              ),
                                            ),
                                          );
                                          if (error == null) _refresh();
                                        },
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Detay için tıkla →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
