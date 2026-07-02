import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android emulator use: http://10.0.2.2/agrilink_api
  // For Chrome/Web use: http://localhost/agrilink_api
  static const String baseUrl = 'http://localhost/agrilink_api';

  // ============================================
  // AUTHENTICATION
  // ============================================

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String location,
    String userType = 'farmer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register.php'),
        body: {
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'location': location,
          'user_type': userType,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login.php'),
        body: {'email': email, 'password': password},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // SEEDS
  // ============================================

  // Get all seeds
  static Future<Map<String, dynamic>> getSeeds({
    String? cropType,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/seeds/get_seeds.php?';
      if (cropType != null) url += 'crop_type=$cropType&';
      if (search != null) url += 'search=$search&';

      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Add new seed
  static Future<Map<String, dynamic>> addSeed({
    required int userId,
    required String seedName,
    required String cropType,
    required int quantity,
    String? quantityUnit,
    String? exchangeType,
    double? price,
    String? description,
    required String location,
    bool isFree = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/seeds/add_seed.php'),
        body: {
          'user_id': userId.toString(),
          'seed_name': seedName,
          'crop_type': cropType,
          'quantity': quantity.toString(),
          'quantity_unit': quantityUnit ?? 'kg',
          'exchange_type': exchangeType ?? 'sell',
          'price': price?.toString() ?? '0',
          'description': description ?? '',
          'location': location,
          'is_free': isFree ? '1' : '0',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Request seed exchange
  static Future<Map<String, dynamic>> requestSeed({
    required int seedId,
    required int requesterId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/seeds/request_seed.php'),
        body: {
          'seed_id': seedId.toString(),
          'requester_id': requesterId.toString(),
          'message': message ?? '',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Delete a seed
  static Future<Map<String, dynamic>> deleteSeed({
    required int seedId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/seeds/delete_seed.php'),
        body: {'seed_id': seedId.toString(), 'user_id': userId.toString()},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Update a seed
  static Future<Map<String, dynamic>> updateSeed({
    required int seedId,
    required int userId,
    String? seedName,
    String? cropType,
    int? quantity,
    String? quantityUnit,
    double? price,
    String? exchangeType,
    String? description,
    String? location,
    String? status,
  }) async {
    try {
      Map<String, String> body = {
        'seed_id': seedId.toString(),
        'user_id': userId.toString(),
      };

      if (seedName != null) body['seed_name'] = seedName;
      if (cropType != null) body['crop_type'] = cropType;
      if (quantity != null) body['quantity'] = quantity.toString();
      if (quantityUnit != null) body['quantity_unit'] = quantityUnit;
      if (price != null) body['price'] = price.toString();
      if (exchangeType != null) body['exchange_type'] = exchangeType;
      if (description != null) body['description'] = description;
      if (location != null) body['location'] = location;
      if (status != null) body['status'] = status;

      final response = await http.post(
        Uri.parse('$baseUrl/seeds/update_seed.php'),
        body: body,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // WEATHER
  // ============================================

  // Get weather locations
  static Future<Map<String, dynamic>> getWeatherLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/get_locations.php'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // DISEASE DETECTION
  // ============================================

  // Get diseases list
  static Future<Map<String, dynamic>> getDiseases() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diseases/get_diseases.php'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Save detection result
  static Future<Map<String, dynamic>> saveDetection({
    required int userId,
    required String diseaseName,
    required double confidence,
    String? imagePath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/diseases/save_detection.php'),
        body: {
          'user_id': userId.toString(),
          'disease_name': diseaseName,
          'confidence': confidence.toString(),
          'image_path': imagePath ?? '',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get detection history
  static Future<Map<String, dynamic>> getDetectionHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diseases/get_history.php?user_id=$userId'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // LEARNING HUB
  // ============================================

  // Get learning categories
  static Future<Map<String, dynamic>> getLearningCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learning/get_categories.php'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get learning articles
  static Future<Map<String, dynamic>> getLearningArticles({
    int? categoryId,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/learning/get_articles.php?';
      if (categoryId != null) url += 'category_id=$categoryId&';
      if (search != null) url += 'search=$search&';

      final response = await http.get(Uri.parse(url));
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get single article
  static Future<Map<String, dynamic>> getLearningArticle(int articleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learning/get_article.php?id=$articleId'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // FARM ACTIVITIES
  // ============================================

  // Get activities
  static Future<Map<String, dynamic>> getActivities(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/get_activities.php?user_id=$userId'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Add activity
  static Future<Map<String, dynamic>> addActivity({
    required int userId,
    required String activityType,
    required String title,
    String? description,
    required String activityDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activities/add_activity.php'),
        body: {
          'user_id': userId.toString(),
          'activity_type': activityType,
          'title': title,
          'description': description ?? '',
          'activity_date': activityDate,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  // Get notifications
  static Future<Map<String, dynamic>> getNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/notifications/get_notifications.php?user_id=$userId',
        ),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationRead(
    int notificationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark_read.php'),
        body: {'notification_id': notificationId.toString()},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get user learning progress
  static Future<Map<String, dynamic>> getLearningProgress(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learning/get_progress.php?user_id=$userId'),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Update learning progress
  static Future<Map<String, dynamic>> updateLearningProgress({
    required int userId,
    required int articleId,
    bool? isCompleted,
    bool? isDownloaded,
    int? progressPercent,
    int? timeSpentMinutes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learning/update_progress.php'),
        body: {
          'user_id': userId.toString(),
          'article_id': articleId.toString(),
          'is_completed': (isCompleted ?? false) ? '1' : '0',
          'is_downloaded': (isDownloaded ?? false) ? '1' : '0',
          'progress_percent': (progressPercent ?? 0).toString(),
          'time_spent_minutes': (timeSpentMinutes ?? 0).toString(),
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
