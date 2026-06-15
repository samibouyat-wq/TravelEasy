class ApiConstants {
  // En production, remplacez par l'URL de votre serveur
  // Pour Android physique sur le même réseau WiFi : http://192.168.1.182:8000/api/v1
  // Pour émulateur Android : http://10.0.2.2:8000/api/v1
  // Pour web local : http://localhost:8000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
}
