import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int currentPage = 1;
  late Future<SalesListResponse> _salesFuture;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    final auth = context.read<AuthService>();
    final orderService = OrderService(auth);
    _salesFuture = orderService.getSalesList(page: currentPage, pageSize: 20);
  }

  String _statusLabel(String status) {
    const statusMap = {
      'Pending': 'Beklemede',
      'Preparing': 'Hazırlanıyor',
      'Shipped': 'Kargo',
      'Completed': 'Tamamlandı',
      'Cancelled': 'İptal',
    };
    return statusMap[status] ?? status;
  }

  String _formatUtcAsLocal(DateTime utc) {
    final local = utc.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _formatCurrency(double amount) {
    return '₺${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    const colors = {
      'Pending': Colors.amber,
      'Preparing': Colors.blue,
      'Shipped': Colors.purple,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
    };
    return colors[status] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    const icons = {
      'Pending': Icons.schedule,
      'Preparing': Icons.build,
      'Shipped': Icons.local_shipping,
      'Completed': Icons.check_circle,
      'Cancelled': Icons.cancel,
    };
    return icons[status] ?? Icons.info;
  }

  void _confirmDelete(SalesListItem sale) {
    final auth = context.read<AuthService>();
    final orderService = OrderService(auth);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Satışı Sil'),
            content: Text(
              'Sipariş #${sale.orderId} (${sale.customerName}) kaydı silinecek. Emin misiniz?',
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
                  final error = await orderService.deleteOrder(sale.orderId);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Sipariş silindi'),
                      backgroundColor:
                          error != null ? Colors.red : Colors.green,
                    ),
                  );
                  if (error == null) {
                    setState(() {
                      _loadSales();
                    });
                  }
                },
                child: const Text('Sil', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satış Yönetimi'), elevation: 0),
      body: FutureBuilder<SalesListResponse>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentPage = 1;
                        _loadSales();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Veri yüklenemedi'));
          }

          final response = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Toplam: ${response.totalCount} satış',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      'Sayfa ${response.page} / ${response.totalPages}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    response.items.isEmpty
                        ? const Center(child: Text('Henüz satış kaydı yok.'))
                        : ListView.builder(
                          itemCount: response.items.length,
                          itemBuilder: (context, index) {
                            final sale = response.items[index];
                            return _buildSalesCard(sale);
                          },
                        ),
              ),
              _buildPaginationControls(response),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesCard(SalesListItem sale) {
    final canDelete = sale.status == 'Completed' || sale.status == 'Cancelled';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sale.customerEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(sale.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(sale.status),
                    size: 16,
                    color: _getStatusColor(sale.status),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel(sale.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(sale.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Sil butonu — sadece tamamlandı/iptal
            if (canDelete) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(sale),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ürün Sayısı: ${sale.itemsCount}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Tutar: ${_formatCurrency(sale.totalAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Text(
                _formatUtcAsLocal(sale.createdAtUtc),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Ürünler:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...sale.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: idx < sale.items.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${item.quantity} adet × ${_formatCurrency(item.unitPrice)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(item.lineTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatCurrency(sale.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(SalesListResponse response) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() {
                        currentPage--;
                        _loadSales();
                      });
                    }
                    : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Önceki'),
          ),
          const SizedBox(width: 16),
          Text(
            '${response.page} / ${response.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed:
                currentPage < response.totalPages
                    ? () {
                      setState(() {
                        currentPage++;
                        _loadSales();
                      });
                    }
                    : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sonraki'),
          ),
        ],
      ),
    );
  }
}
