import 'package:flutter/material.dart';
import '../features/auth/presentation/auth_wrapper.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/creative/presentation/creative_home_screen.dart';
import '../features/creative/presentation/creative_studio_screen.dart';
import '../features/creative/presentation/creative_feed_screen.dart';
import '../data/models/creative_models.dart';
import '../screen/submission_form.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/submission':
        return MaterialPageRoute(
          builder: (_) => const SubmissionForm(challengeId: 'default'),
        );
      // Creative module routes
      case '/creative':
        return MaterialPageRoute(builder: (_) => const CreativeHomeScreen());
      case '/creative/studio':
        return MaterialPageRoute(
          builder: (_) => CreativeStudioScreen(
            prompt: settings.arguments as CreativePrompt?,
          ),
        );
      case '/creative/feed':
        return MaterialPageRoute(builder: (_) => const CreativeFeedScreen());
      default:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
    }
  }
}
