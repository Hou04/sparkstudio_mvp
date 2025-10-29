import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/supabase/auth_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'data/repositories/supabase/creative_service.dart';
import 'data/repositories/ai/ai_generation_service.dart';
import 'features/creative/providers/creative_provider.dart';

final GetIt getIt = GetIt.instance;

class InjectionContainer {
  static Future<void> init() async {
    // Register Supabase client
    getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

    // Register services
    getIt.registerLazySingleton<AuthService>(
      () => AuthService(client: getIt<SupabaseClient>()),
    );
    // Register repositories
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(authService: getIt<AuthService>()),
    );
    getIt.registerLazySingleton<AiGenerationService>(
      () => AiGenerationService(apiKey: 'your-api-key-here'),
    );
    getIt.registerLazySingleton<CreativeService>(
      () => CreativeService(
        client: getIt<SupabaseClient>(),
        aiService: getIt<AiGenerationService>(),
      ),
    );

    // Register providers
    getIt.registerLazySingleton<CreativeProvider>(
      () => CreativeProvider(
        creativeService: getIt<CreativeService>(),
        aiService: getIt<AiGenerationService>(),
      ),
    );
  }
}
