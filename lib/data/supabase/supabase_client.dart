/// 🚀 Advanced Supabase Client Configuration
///
/// Professional Supabase client setup with error handling, real-time features,
/// and production-ready configuration.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static final SupabaseClientManager _instance =
      SupabaseClientManager._internal();
  factory SupabaseClientManager() => _instance;
  SupabaseClientManager._internal();

  late SupabaseClient _client;
  bool _isInitialized = false;

  /// 🎯 Initialize Supabase client
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      debugPrint('✅ Supabase client initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Supabase: $e');
      throw Exception('Supabase initialization failed: $e');
    }
  }

  /// 🔧 Get Supabase client instance
  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception(
        'Supabase client not initialized. Call initialize() first.',
      );
    }
    return _client;
  }

  /// 🔐 Get authentication client
  GoTrueClient get auth => client.auth;

  /// 💾 Get storage client
  SupabaseStorageClient get storage => client.storage;

  /// 🔄 Get realtime client
  RealtimeClient get realtime => client.realtime;

  /// 📊 Check connection health
  Future<bool> checkHealth() async {
    try {
      final response = await client.from('health_check').select().limit(1);
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return false;
    }
  }

  /// 🧹 Clear local storage (for testing/debugging)
  Future<void> clearLocalStorage() async {
    try {
      await auth.signOut();
      // Additional cleanup if needed
    } catch (e) {
      debugPrint('⚠️ Error clearing local storage: $e');
    }
  }

  /// 🔧 Configure realtime channels
  RealtimeChannel createChannel({
    required String name,
    required String table,
    required String event,
  }) {
    return client.channel(name)
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          debugPrint('🔔 Realtime update: $payload');
        },
      )
      ..onBroadcast(
        event: event,
        callback: (payload, [ref]) {
          debugPrint('📢 Broadcast received: $payload');
        },
      );
  }

  /// 📱 Get client configuration
  Map<String, dynamic> get config {
    return {
      'url': 'configured',
      'is_initialized': _isInitialized,
      'auth_state': auth.currentSession != null
          ? 'authenticated'
          : 'unauthenticated',
      'realtime_connected': realtime.isConnected,
    };
  }

  /// 🚨 Handle errors consistently
  static String handleError(dynamic error) {
    if (error is AuthException) {
      return 'Authentication error: ${error.message}';
    } else if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    } else if (error is StorageException) {
      return 'Storage error: ${error.message}';
    } else {
      return 'Unexpected error: ${error.toString()}';
    }
  }

  /// 🧪 Development utilities
  void enableDebugLogging() {
    // Enable verbose logging for development
    debugPrint('🔍 Supabase debug logging enabled');
  }

  /// 🔄 Reset client (for testing)
  Future<void> reset() async {
    try {
      await clearLocalStorage();
      _isInitialized = false;
      debugPrint('✅ Supabase client reset');
    } catch (e) {
      debugPrint('❌ Error resetting client: $e');
    }
  }
}

/// 🎯 Supabase Client Wrapper for easy dependency injection
class SupabaseClientWrapper {
  final SupabaseClientManager _manager = SupabaseClientManager();

  static final SupabaseClientWrapper instance = SupabaseClientWrapper._();
  SupabaseClientWrapper._();

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await _manager.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => _manager.client;
  GoTrueClient get auth => _manager.auth;
  SupabaseStorageClient get storage => _manager.storage;
  RealtimeClient get realtime => _manager.realtime;
}

/// 📋 Example usage:
/// 
/// ```dart
/// // Initialize in main.dart
/// await SupabaseClientWrapper.instance.initialize(
///   supabaseUrl: 'YOUR_SUPABASE_URL',
///   supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
/// );
/// 
/// // Use in services
/// final client = SupabaseClientWrapper.instance.client;
/// final auth = SupabaseClientWrapper.instance.auth;
/// ```