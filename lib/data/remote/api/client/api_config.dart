class ApiConfig {
  ApiConfig(this.baseUrl, {required this.apiKey, this.demoMode = false});

  final String baseUrl;

  String get apiUrl => baseUrl;
  final String apiKey;
  final bool demoMode;
}
