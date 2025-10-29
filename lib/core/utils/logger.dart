import 'dart:developer' as developer;

class Logger {
  Logger._();

  static const String _appName = 'SparkStudio';

  // Info level logging
  static void info(String message, {String? tag}) {
    developer.log(
      '💡 $message',
      name: '$_appName${tag != null ? '/$tag' : ''}',
      level: 800,
      time: DateTime.now(),
    );
  }

  // Debug level logging
  static void debug(String message, {String? tag}) {
    developer.log(
      '🐛 $message',
      name: '$_appName${tag != null ? '/$tag' : ''}',
      level: 600,
      time: DateTime.now(),
    );
  }

  // Warning level logging
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '⚠️  $message',
      name: '$_appName${tag != null ? '/$tag' : ''}',
      level: 900,
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Error level logging
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '❌ $message',
      name: '$_appName${tag != null ? '/$tag' : ''}',
      level: 1000,
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Success level logging
  static void success(String message, {String? tag}) {
    developer.log(
      '✅ $message',
      name: '$_appName${tag != null ? '/$tag' : ''}',
      level: 800,
      time: DateTime.now(),
    );
  }

  // API request logging
  static void apiRequest(String method, String url, {dynamic body, Map<String, dynamic>? headers}) {
    developer.log(
      '🌐 $method $url',
      name: '$_appName/API',
      level: 700,
      time: DateTime.now(),
    );
    
    if (body != null) {
      developer.log(
        '📦 Request Body: $body',
        name: '$_appName/API',
        level: 700,
        time: DateTime.now(),
      );
    }
  }

  // API response logging
  static void apiResponse(String method, String url, int statusCode, {dynamic response}) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    developer.log(
      '$emoji $method $url → $statusCode',
      name: '$_appName/API',
      level: 700,
      time: DateTime.now(),
    );
    
    if (response != null) {
      developer.log(
        '📦 Response: $response',
        name: '$_appName/API',
        level: 700,
        time: DateTime.now(),
      );
    }
  }

  // AI generation logging
  static void aiGeneration(String type, String prompt, {String? result}) {
    developer.log(
      '🤖 AI $type: "$prompt"',
      name: '$_appName/AI',
      level: 700,
      time: DateTime.now(),
    );
    
    if (result != null) {
      developer.log(
        '🎨 Result: $result',
        name: '$_appName/AI',
        level: 700,
        time: DateTime.now(),
      );
    }
  }

  // User action logging
  static void userAction(String action, {Map<String, dynamic>? metadata}) {
    developer.log(
      '👤 $action',
      name: '$_appName/User',
      level: 600,
      time: DateTime.now(),
    );
    
    if (metadata != null) {
      developer.log(
        '📊 Metadata: $metadata',
        name: '$_appName/User',
        level: 600,
        time: DateTime.now(),
      );
    }
  }

  // Performance logging
  static void performance(String operation, Duration duration) {
    developer.log(
      '⚡ $operation took ${duration.inMilliseconds}ms',
      name: '$_appName/Performance',
      level: 500,
      time: DateTime.now(),
    );
  }
}

// Extension for easy logging
extension LoggingExtensions on Object {
  void logInfo(String message, {String? tag}) => Logger.info(message, tag: tag);
  void logDebug(String message, {String? tag}) => Logger.debug(message, tag: tag);
  void logWarning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      Logger.warning(message, tag: tag, error: error, stackTrace: stackTrace);
  void logError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      Logger.error(message, tag: tag, error: error, stackTrace: stackTrace);
  void logSuccess(String message, {String? tag}) => Logger.success(message, tag: tag);
}