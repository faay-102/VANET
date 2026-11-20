class ApiEndpoints {
  static const String baseUrl = "http://localhost:8000/api/v1";

  // Auth Endpoints
  static const String register = "/auth/register";
  static const String login = "/auth/login";

  // Vehicles Endpoints
  static const String vehicles = "/vehicles";

  // Predictions & XAI Endpoints
  static const String checkTelemetry = "/prediction/analyze";
  static const String getExplanation = "/xai/explanation"; // Append: /{id}

  // Trust Endpoints
  static const String trustScore = "/trust"; // Append: /{id}

  // Emergency Priority Endpoints
  static const String authorizeEmergency = "/emergency/register";
  static const String requestPriority = "/emergency/verify";

  // Routes Endpoints
  static const String routes = "/routing/recommend";

  // Reports Endpoints
  static const String reports = "/reports";

  // Notifications Endpoints
  static const String registerToken = "/notifications/register-token";

  // Analytics Endpoints
  static const String overview = "/analytics/overview";
}
