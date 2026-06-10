import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/services/auth_service.dart';
import 'src/state/cart_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: const AkilliSaticiWebApp(),
    ),
  );
}

class AkilliSaticiWebApp extends StatelessWidget {
  const AkilliSaticiWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(context.read<AuthService>());

    return MaterialApp.router(
      title: 'Akıllı Satıcı',
      theme: AppTheme.light(),
      routerConfig: appRouter.router,
    );
  }
}
