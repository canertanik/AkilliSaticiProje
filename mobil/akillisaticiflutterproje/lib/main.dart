import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/products/home_screen.dart';
import 'screens/products/add_product_screen.dart';
import 'screens/products/edit_product_screen.dart';
import 'core/constants/api_constants.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'screens/shop/shop_home.dart';
import 'screens/shop/cart_screen.dart';

void main() {
  runApp(const SmartProductApp());
}

class SmartProductApp extends StatefulWidget {
  const SmartProductApp({super.key});

  @override
  State<SmartProductApp> createState() => _SmartProductAppState();
}

class _SmartProductAppState extends State<SmartProductApp> {
  bool _loggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Product> _products = [];
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final ProductService _productService;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    _authService = AuthService(_apiClient);
    _productService = ProductService(_apiClient);
    // cart service lives at app-level via provider in runApp
  }

  Future<void> _loadProducts() async {
    if (!_loggedIn) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _productService.fetchProducts();
      setState(() {
        _products
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Ürünler yüklenemedi. API adresini kontrol et.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _login(String email, String password) async {
    try {
      final token = await _authService.login(email: email, password: password);
      if (token == null || token.isEmpty) {
        return 'Giriş başarısız.';
      }
      _apiClient.setAuthToken(token);
      setState(() => _loggedIn = true);
      await _loadProducts();
      return null;
    } catch (e) {
      return _readErrorMessage(e) ?? 'Giriş başarısız.';
    }
  }

  Future<String?> _register(
    String fullName,
    String storeName,
    String email,
    String password,
  ) async {
    try {
      await _authService.register(
        fullName: fullName,
        storeName: storeName,
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return _readErrorMessage(e) ?? 'Kayıt başarısız.';
    }
  }

  Future<String?> _resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      return _readErrorMessage(e) ?? 'Şifre sıfırlama başarısız.';
    }
  }

  Future<ForgotPasswordResult> _requestPasswordReset(String email) async {
    try {
      final data = await _authService.requestPasswordReset(email: email);
      String? message;
      String? code;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString();
        code =
            data['code']?.toString() ??
            data['resetCode']?.toString() ??
            data['otp']?.toString();
      } else if (data is String) {
        message = data;
      }
      return ForgotPasswordResult(message: message, debugCode: code);
    } catch (e) {
      return ForgotPasswordResult(
        error: _readErrorMessage(e) ?? 'Şifre sıfırlama isteği başarısız.',
      );
    }
  }

  String? _readErrorMessage(Object error) {
    if (error is ApiException) {
      final body = error.body;
      if (body == null || body.isEmpty) return null;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } catch (_) {
        return body;
      }
    }
    return null;
  }

  void _addProduct(Product product) {
    setState(() => _products.add(product));
  }

  void _updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      setState(() => _products[index] = updated);
    }
  }

  void _deleteProduct(String id) {
    setState(() => _products.removeWhere((p) => p.id == id));
  }

  Future<void> _deleteProductFromApi(BuildContext context, String id) async {
    try {
      await _productService.deleteProduct(id);
      _deleteProduct(id);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silme işlemi başarısız.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        title: 'Ürün Yöneticim',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF9C27F0),
          scaffoldBackgroundColor: const Color(0xFFF6F5FB),
          fontFamily: 'Roboto',
          useMaterial3: false,
        ),
        routes: {
          '/login': (_) => LoginScreen(onLogin: _login),
          '/register': (_) => RegisterScreen(onRegister: _register),
          '/forgot':
              (_) => ForgotPasswordScreen(
                onRequestReset: _requestPasswordReset,
                onReset: _resetPassword,
              ),
          '/home':
              (_) => HomeScreen(
                products: _products,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onAddProduct: (context) async {
                  final result = await Navigator.push<Product?>(
                    context,
                    MaterialPageRoute(builder: (_) => AddProductScreen()),
                  );
                  if (result != null) {
                    try {
                      final created = await _productService.createProduct(
                        result,
                      );
                      _addProduct(created);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ürün oluşturulamadı. API kontrol et.'),
                        ),
                      );
                    }
                  }
                },
                onEditProduct: (context, product) async {
                  final updated = await Navigator.push<Product?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductScreen(product: product),
                    ),
                  );
                  if (updated != null) {
                    try {
                      final saved = await _productService.updateProduct(
                        updated,
                      );
                      _updateProduct(saved);
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ürün güncellenemedi. API kontrol et.'),
                        ),
                      );
                    }
                  }
                },
                onDeleteProduct: (id) => _deleteProductFromApi(context, id),
              ),
        },
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          // fallback için
          return MaterialPageRoute(
            builder:
                (_) =>
                    _loggedIn ? const Placeholder() : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
