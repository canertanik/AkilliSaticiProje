import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../services/auth_service.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool _isRegisterMode = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerStoreController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerStoreController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    final textStyle = const TextStyle(color: Color(0xFF111827));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Center(
              child: SizedBox(
                width: 420,
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isRegisterMode ? 'Kullanıcı Kaydı' : 'Üye Girişi',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        if (_isRegisterMode) ...[
                          TextField(
                            controller: _registerNameController,
                            style: textStyle,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            decoration: const InputDecoration(
                              labelText: 'Ad Soyad',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerEmailController,
                            style: textStyle,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            decoration: const InputDecoration(
                              labelText: 'E-Posta',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _registerPasswordController,
                            style: textStyle,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Şifre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _loginEmailController,
                            style: textStyle,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            decoration: const InputDecoration(
                              labelText: 'E-Posta',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _loginPasswordController,
                            style: textStyle,
                            cursorColor: Theme.of(context).colorScheme.primary,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Şifre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                auth.isLoading
                                    ? null
                                    : () => _submit(context, auth),
                            child: Text(
                              _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed:
                              () => setState(
                                () => _isRegisterMode = !_isRegisterMode,
                              ),
                          child: Text(
                            _isRegisterMode
                                ? 'Hesabın var mı? Giriş Yap'
                                : 'Hesabın yok mu? Kayıt Ol',
                          ),
                        ),
                      ],
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

  Future<void> _submit(BuildContext context, AuthService auth) async {
    String? error;

    if (_isRegisterMode) {
      error = await auth.register(
        fullName: _registerNameController.text.trim(),
        storeName: 'Müşteri',
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );

      error ??= await auth.login(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
    } else {
      error = await auth.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
    }

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.go('/');
  }
}
