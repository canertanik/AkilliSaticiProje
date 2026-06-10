class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pointed-bring-dried.ngrok-free.dev',
  );
  static const String products = '/api/products';
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String aiSuggest = '/api/ai/suggest';
  static const String aiPriceScrape = '/api/ai/price-scrape';
}
