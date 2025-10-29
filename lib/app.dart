import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'features/creative/providers/creative_provider.dart';
import 'features/auth/logic/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'injection_container.dart';

class SparkStudioApp extends StatelessWidget {
  const SparkStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(repository: getIt<AuthRepository>()),
        ),
        ChangeNotifierProvider<CreativeProvider>(
          create: (_) => getIt<CreativeProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'SparkStudio',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: AppRouter.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
