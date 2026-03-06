class AppConfig {
  static const String appName = 'Kala App';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Utiliser l'IP de la machine hôte pour accéder au backend (SEYDOU)
  // static const String baseUrl = 'http://192.168.100.167:3000';
  static const String baseUrl = 'http://localhost:3000';
  static const String apiUrl = '$baseUrl/api';

  // Endpoints
  static const String authEndpoint = '$apiUrl/auth';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String userTypeKey = 'user_type';

  // Timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration visionApiTimeout = Duration(seconds: 75);
}
