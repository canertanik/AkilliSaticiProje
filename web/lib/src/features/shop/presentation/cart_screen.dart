import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_surface_card.dart';
import '../../../models/product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';
import '../../../state/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const double _shippingFee = 39.9;
  static const double _freeShippingThreshold = 500;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final isMobile = MediaQuery.of(context).size.width < 920;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child:
            isMobile
                ? Column(
                  children: [
                    _buildCartList(context, cart),
                    const SizedBox(height: 16),
                    _buildSummary(context, cart),
                  ],
                )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildCartList(context, cart)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildSummary(context, cart)),
                  ],
                ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartService cart) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sepetim',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (cart.items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 74,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  const Text('Sepetiniz şu an boş.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/products'),
                    child: const Text('Alışverişe Devam Et'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(height: 22),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.product.imageUrl?.isNotEmpty == true
                            ? item.product.imageUrl!
                            : 'https://images.unsplash.com/photo-1601758174114-e711c0cbaa69?auto=format&fit=crop&q=80&w=600',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 88,
                              height: 88,
                              color: const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFF64748B),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₺${item.getLineTotal(context.watch<AuthService>().isLoggedIn).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _qtyButton(
                                icon: Icons.remove,
                                onTap: () => cart.decrease(item.product.id),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text('${item.quantity}'),
                              ),
                              _qtyButton(
                                icon: Icons.add,
                                onTap: () => cart.add(item.product),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => cart.remove(item.product.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 30,
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartService cart) {
    final isLoggedIn = context.watch<AuthService>().isLoggedIn;
    final subtotal = cart.getSubtotal(isLoggedIn);
    final discount = 0.0;
    final shipping = _calculateShipping(subtotal, discount);
    final total = subtotal + shipping;
    final remainingForFreeShipping =
        (_freeShippingThreshold - (subtotal - discount)).clamp(0, 999999);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sipariş Özeti',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.imageUrl?.isNotEmpty == true
                          ? item.product.imageUrl!
                          : 'https://images.unsplash.com/photo-1601758174114-e711c0cbaa69?auto=format&fit=crop&q=80&w=600',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFE2E8F0),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${item.quantity} adet x ₺${item.product.getDisplayPrice(isLoggedIn).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text('₺${item.getLineTotal(isLoggedIn).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          if (cart.items.isNotEmpty) const Divider(height: 26),
          _buildSummaryRow(
            'Ara Toplam',
            '₺${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Kargo',
            shipping == 0 ? 'Ücretsiz' : '₺${shipping.toStringAsFixed(2)}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('İndirim', '-₺${discount.toStringAsFixed(2)}'),
          ],
          const Divider(height: 26),
          _buildSummaryRow(
            'Genel Toplam',
            '₺${total.toStringAsFixed(2)}',
            isBold: true,
          ),
          const SizedBox(height: 10),
          Text(
            remainingForFreeShipping == 0
                ? 'Ücretsiz kargo aktif.'
                : 'Ücretsiz kargo için kalan tutar: ₺${remainingForFreeShipping.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  cart.items.isEmpty ? null : () => _showCheckoutSheet(context),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Siparişi Tamamla'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Alışverişe Devam Et'),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDiscount(double subtotal) {
    if (subtotal >= 1000) return 50;
    return 0;
  }

  double _calculateShipping(double subtotal, double discount) {
    if (subtotal <= 0) return 0;
    if (subtotal - discount >= _freeShippingThreshold) return 0;
    return _shippingFee;
  }

  Future<void> _showCheckoutSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return const _CheckoutSheet();
      },
    );
  }

  Widget _buildSummaryRow(String title, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet();

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mailController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressTitleController = TextEditingController(text: 'Ev');
  final _orderNoteController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _eftAccountHolderController = TextEditingController();
  final _eftBankNameController = TextEditingController();
  final _eftIbanController = TextEditingController();
  final _eftReferenceController = TextEditingController();

  bool _isSubmitting = false;
  bool _isFormValid = false;
  String _paymentMethod = 'KapidaOdeme';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _mailController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _addressTitleController.dispose();
    _orderNoteController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _eftAccountHolderController.dispose();
    _eftBankNameController.dispose();
    _eftIbanController.dispose();
    _eftReferenceController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _isFormValid) {
      setState(() {
        _isFormValid = valid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isNarrow = media.size.width < 980;
    final cart = context.watch<CartService>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: Color(0x33000000),
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: _validateForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Teslimat ve Ödeme',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isNarrow) ...[
                    _buildDeliveryForm(context),
                    const SizedBox(height: 18),
                    _buildCheckoutSummaryCard(context, cart),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildDeliveryForm(context)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCheckoutSummaryCard(context, cart),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (!_isFormValid || _isSubmitting) ? null : _submit,
                      child: Text(_isSubmitting ? 'Gönderiliyor...' : 'Onayla'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          controller: _nameController,
          label: 'Ad Soyad',
          validator: _requiredValidator('Ad Soyad zorunludur'),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _phoneController,
          label: 'Telefon numarası',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _PhoneMaskFormatter(),
          ],
          validator: (value) {
            final v = (value ?? '').trim();
            if (v.isEmpty) return 'Telefon zorunludur';

            var digits = v.replaceAll(RegExp(r'\D'), '');
            // Kullanıcı 0 ile başlatırsa (05XX...) bunu da kabul et.
            if (digits.length == 11 && digits.startsWith('0')) {
              digits = digits.substring(1);
            }

            if (digits.length != 10 || !digits.startsWith('5')) {
              return 'Telefon formatı hatalı (5XX XXX XX XX)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _field(
          controller: _mailController,
          label: 'E-Posta',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final v = (value ?? '').trim();
            if (v.isEmpty) return 'E-posta zorunludur';
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(v)) return 'Geçerli bir e-posta girin';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _cityController,
                label: 'İl',
                validator: _requiredValidator('İl zorunludur'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _districtController,
                label: 'İlçe',
                validator: _requiredValidator('İlçe zorunludur'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _neighborhoodController,
          label: 'Mahalle / Sokak',
          validator: _requiredValidator('Mahalle / Sokak zorunludur'),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _addressController,
          label: 'Açık adres',
          maxLines: 3,
          validator: _requiredValidator('Açık adres zorunludur'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _postalCodeController,
                label: 'Posta kodu',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Posta kodu zorunludur';
                  if (v.length < 5) return 'En az 5 haneli olmalı';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                controller: _addressTitleController,
                label: 'Adres başlığı (Ev, İş, Diğer)',
                validator: _requiredValidator('Adres başlığı zorunludur'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(
          controller: _orderNoteController,
          label: 'Sipariş notu (opsiyonel)',
          maxLines: 2,
          required: false,
        ),
        const SizedBox(height: 16),
        Text(
          'Ödeme Yöntemi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _paymentChip(
              'KapidaOdeme',
              'Kapıda ödeme',
              Icons.payments_outlined,
            ),
            _paymentChip(
              'KrediKartı',
              'Kredi / banka kartı',
              Icons.credit_card_outlined,
            ),
            _paymentChip(
              'HavaleEft',
              'Havale / EFT',
              Icons.account_balance_outlined,
            ),
          ],
        ),
        if (_paymentMethod == 'KrediKartı') ...[
          const SizedBox(height: 12),
          _field(
            controller: _cardHolderController,
            label: 'Kart üzerindeki isim',
            validator: _requiredValidator('Kart sahibi adı zorunludur'),
          ),
          const SizedBox(height: 12),
          _field(
            controller: _cardNumberController,
            label: 'Kart numarası',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberMaskFormatter(),
            ],
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length != 16) return '16 haneli kart numarası girin';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _cardExpiryController,
                  label: 'Son kullanma (AA/YY)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryMaskFormatter(),
                  ],
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (!RegExp(r'^(0[1-9]|1[0-2])/[0-9]{2}$').hasMatch(v)) {
                      return 'Geçerli tarih girin';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: _cardCvvController,
                  label: 'CVV',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.length != 3) return '3 haneli CVV girin';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
        if (_paymentMethod == 'HavaleEft') ...[
          const SizedBox(height: 12),
          _field(
            controller: _eftAccountHolderController,
            label: 'Hesap sahibi adı',
            validator: _requiredValidator('Hesap sahibi adı zorunludur'),
          ),
          const SizedBox(height: 12),
          _field(
            controller: _eftBankNameController,
            label: 'Banka adı',
            validator: _requiredValidator('Banka adı zorunludur'),
          ),
          const SizedBox(height: 12),
          _field(
            controller: _eftIbanController,
            label: 'IBAN (TR...)',
            validator: (value) {
              final v = (value ?? '').replaceAll(' ', '').toUpperCase();
              if (v.isEmpty) return 'IBAN zorunludur';
              if (!RegExp(r'^TR[0-9]{24}$').hasMatch(v)) {
                return 'Geçerli TR IBAN girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _field(
            controller: _eftReferenceController,
            label: 'Transfer referans no',
            validator: _requiredValidator('Transfer referans no zorunludur'),
          ),
        ],
      ],
    );
  }

  Widget _paymentChip(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return ChoiceChip(
      selected: selected,
      onSelected:
          _isSubmitting
              ? null
              : (_) {
                setState(() {
                  _paymentMethod = value;
                });
                _validateForm();
              },
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _buildCheckoutSummaryCard(BuildContext context, CartService cart) {
    const shippingFee = _CartScreenState._shippingFee;
    const threshold = _CartScreenState._freeShippingThreshold;
    final isLoggedIn = context.read<AuthService>().isLoggedIn;
    final subtotal = cart.getSubtotal(isLoggedIn);
    final shipping =
        subtotal > 0 && subtotal < threshold
            ? shippingFee
            : 0.0;
    final total = subtotal + shipping;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş Özeti',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.title} x${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('₺${item.getLineTotal(context.read<AuthService>().isLoggedIn).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const Divider(height: 22),
          _line('Ara toplam', subtotal),
          _line('Kargo', shipping),
          const Divider(height: 22),
          _line('Genel toplam', total, bold: true),
        ],
      ),
    );
  }

  Widget _line(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}₺${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: required ? validator : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if ((value ?? '').trim().isEmpty) return message;
      return null;
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _validateForm();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = context.read<AuthService>();
    final orderService = OrderService(auth);
    final cart = context.read<CartService>();
    final paymentNote = _buildPaymentInfoNote();
    final orderNoteBase = _orderNoteController.text.trim();
    final mergedOrderNote = [
      if (orderNoteBase.isNotEmpty) orderNoteBase,
      if (paymentNote.isNotEmpty) paymentNote,
    ].join('\n');

    final error = await orderService.createOrder(
      checkout: CheckoutDetails(
        customerName: _nameController.text.trim(),
        customerEmail: _mailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryCity: _cityController.text.trim(),
        deliveryDistrict: _districtController.text.trim(),
        deliveryNeighborhood: _neighborhoodController.text.trim(),
        deliveryAddressLine: _addressController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        addressTitle: _addressTitleController.text.trim(),
        orderNote: mergedOrderNote.isEmpty ? null : mergedOrderNote,
        paymentMethod: _paymentMethod,
      ),
      items: cart.items,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pop();
    if (error == null) {
      cart.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Siparişiniz alındı.')));
      context.go('/');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _buildPaymentInfoNote() {
    if (_paymentMethod == 'KrediKartı') {
      final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      final last4 =
          digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
      return 'Odeme Bilgisi: Kredi/Banka Karti - Kart Sahibi: ${_cardHolderController.text.trim()}, Kart Son 4: $last4';
    }

    if (_paymentMethod == 'HavaleEft') {
      final ibanRaw = _eftIbanController.text.replaceAll(' ', '').toUpperCase();
      final ibanMasked =
          ibanRaw.length >= 4
              ? '${ibanRaw.substring(0, 4)}****${ibanRaw.substring(ibanRaw.length - 4)}'
              : ibanRaw;
      return 'Odeme Bilgisi: Havale/EFT - Hesap Sahibi: ${_eftAccountHolderController.text.trim()}, Banka: ${_eftBankNameController.text.trim()}, IBAN: $ibanMasked, Referans: ${_eftReferenceController.text.trim()}';
    }

    return '';
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        buffer.write(' ');
      }
      buffer.write(trimmed[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CardNumberMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(trimmed[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(trimmed[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
