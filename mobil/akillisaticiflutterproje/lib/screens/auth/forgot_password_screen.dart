import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordResult {
  final String? error;
  final String? message;
  final String? debugCode;

  const ForgotPasswordResult({this.error, this.message, this.debugCode});
}

class ForgotPasswordScreen extends StatefulWidget {
  final Future<ForgotPasswordResult> Function(String email) onRequestReset;
  final Future<String?> Function(String email, String code, String newPassword)
  onReset;
  const ForgotPasswordScreen({
    super.key,
    required this.onRequestReset,
    required this.onReset,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _isSubmitting = false;
  String? _debugCode;
  String? _serverMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('E-posta adresi gerekli.')));
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.onRequestReset(_emailCtrl.text.trim());
    if (!mounted) return;
    final error = result.error;
    if (error != null && error.isNotEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _isSubmitting = false;
      _sent = true;
      _debugCode = result.debugCode;
      _serverMessage = result.message;
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
              'Şifremi Unuttum',
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
              child: _sent ? _successView() : _formView(),
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
          child: Icon(Icons.mail_outline, color: Color(0xFFB658FF), size: 60),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'E-posta Adresini Gir',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Hesabına kayıtlı e-posta adresini gir. Şifre sıfırlama bağlantısı göndereceğiz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'E-posta adresini doğru yazdığından emin ol. Şifre sıfırlama bağlantısı bu adrese gönderilecek.',
            style: TextStyle(fontSize: 12, color: Color(0xFF4C1D95)),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text:
              _isSubmitting ? 'Gönderiliyor...' : 'Sıfırlama Bağlantısı Gönder',
          onPressed: _isSubmitting ? () {} : _send,
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
          'E-posta Başarıyla Gönderildi!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Şifre sıfırlama kodunu ${_emailCtrl.text} adresine gönderdik. Kod ile şifreni güncelleyebilirsin.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_serverMessage != null && _serverMessage!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _serverMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5B21B6)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_debugCode != null && _debugCode!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Test kodu: ${_debugCode!}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '💡 E-postayı göremiyorsan spam klasörünü kontrol etmeyi unutma!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5B21B6)),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Kod ile Şifreyi Sıfırla',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ResetPasswordScreen(
                      email: _emailCtrl.text.trim(),
                      onReset: widget.onReset,
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/login'));
          },
          child: const Text('Giriş Sayfasına Dön'),
        ),
      ],
    );
  }
}
