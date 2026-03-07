class AppConfig {
  static const String appName = 'Kala App';
  static const String appVersion = '1.0.0';

  // Compile-time override:
  // flutter run/build ... --dart-define=API_BASE_URL=https://your-backend.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String apiUrl = '$baseUrl/api';

  // Endpoints
  static const String authEndpoint = '$apiUrl/auth';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String userTypeKey = 'user_type';

  // Timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration visionApiTimeout = Duration(seconds: 75);
}
