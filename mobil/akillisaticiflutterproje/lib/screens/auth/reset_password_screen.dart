import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final Future<String?> Function(String email, String code, String newPassword)
  onReset;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.onReset,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordAgainCtrl = TextEditingController();
  bool _showPassword = false;
  bool _isSubmitting = false;
  bool _done = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordAgainCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kod gerekli.')));
      return;
    }
    if (_passwordCtrl.text.length < 6 ||
        _passwordCtrl.text != _passwordAgainCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şifreler geçersiz.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await widget.onReset(
      widget.email,
      _codeCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;
    if (error != null && error.isNotEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _isSubmitting = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientBackground(
            alignment: Alignment.centerLeft,
            child: Text(
              'Şifreyi Sıfırla',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _done ? _successView() : _formView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Center(
          child: Icon(Icons.lock_reset, color: Color(0xFFB658FF), size: 60),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Kod ve Yeni Şifre',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Sana gönderilen kodu ve yeni şifreni gir.\nE-posta: ${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sıfırlama Kodu',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Yeni Şifre',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordAgainCtrl,
          obscureText: !_showPassword,
          decoration: const InputDecoration(
            labelText: 'Yeni Şifre (Tekrar)',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: _isSubmitting ? 'Kaydediliyor...' : 'Şifreyi Güncelle',
          onPressed: _isSubmitting ? () {} : _submit,
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF4CAF50),
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Şifre Başarıyla Güncellendi!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Artık yeni şifrenle giriş yapabilirsin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Giriş Sayfasına Dön',
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/login'));
          },
        ),
      ],
    );
  }
}
