import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // ============================================
  // AUTHENTICATION
  // ============================================

  // Register new user
  // Upload valid ID image to Supabase Storage
  static Future<String?> uploadIdImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final String path = '$userId/$fileName';
      await Supabase.instance.client.storage
          .from('valid-ids')
          .uploadBinary(path, imageBytes, fileOptions: const FileOptions(upsert: true));

      final String publicUrl = Supabase.instance.client.storage
          .from('valid-ids')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String fullName,
    String? email,
    required String password,
    required String phone,
    required String location,
    String userType = 'farmer',
    String? birthdate,
    String? idType,
    Uint8List? idImageBytes,
    String? idFileName,
  }) async {
    try {
      // Generate a mock email for farmers who don't provide one
      final String authEmail = (userType == 'farmer' && (email == null || email.isEmpty))
          ? '${fullName.replaceAll(' ', '.').toLowerCase()}@agrilink.mock'
          : email!;

      // Supabase requires minimum 6 character passwords.
      // We seamlessly pad the 4-digit PIN for Farmers behind the scenes.
      final String finalPassword = (userType == 'farmer' && password.length == 4)
          ? '${password}00'
          : password;

      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: authEmail,
        password: finalPassword,
      );

      if (res.user != null) {
        // Upload ID image if provided
        String? idImageUrl;
        if (idImageBytes != null && idFileName != null) {
          idImageUrl = await uploadIdImage(
            userId: res.user!.id,
            imageBytes: idImageBytes,
            fileName: idFileName,
          );
        }

        await Supabase.instance.client.from('profiles').insert({
          'id': res.user!.id,
          'full_name': fullName,
          'email': authEmail,
          'phone': phone,
          'location': location,
          'user_type': userType,
          if (birthdate != null) 'birthdate': birthdate,
          if (idType != null) 'id_type': idType,
          if (idImageUrl != null) 'id_image_url': idImageUrl,
        });

        return {
          'success': true,
          'message': 'Registration successful!',
          'user': {
            'id': res.user!.id,
            'full_name': fullName,
            'email': authEmail,
            'phone': phone,
            'location': location,
            'user_type': userType,
          }
        };
      } else {
        return {'success': false, 'message': 'Registration failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    String? email,
    String? fullName,
    required String password,
  }) async {
    try {
      // If logging in as farmer using Name, construct the mock email
      String authEmail = email ?? '';
      if (fullName != null && fullName.isNotEmpty) {
         authEmail = '${fullName.replaceAll(' ', '.').toLowerCase()}@agrilink.mock';
      }

      // If they logged in as a farmer and used a 4 digit PIN, pad it to match the registration hash
      final String finalPassword = (fullName != null && password.length == 4)
          ? '${password}00'
          : password;

      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: authEmail,
        password: finalPassword,
      );

      if (res.user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', res.user!.id)
            .single();

        return {
          'success': true,
          'message': 'Login successful!',
          'user': {
            'id': res.user!.id,
            'full_name': profile['full_name'],
            'email': res.user!.email,
            'phone': profile['phone'],
            'location': profile['location'],
            'user_type': profile['user_type'],
          }
        };
      } else {
        return {'success': false, 'message': 'Login failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
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
      var query = Supabase.instance.client
          .from('seeds')
          .select('*, profiles:user_id(full_name)');

      if (cropType != null && cropType != 'All') {
        query = query.eq('crop_type', cropType);
      }

      if (search != null && search.isNotEmpty) {
        query = query.ilike('seed_name', '%$search%');
      }

      final data = await query.order('created_at', ascending: false);

      final List<Map<String, dynamic>> seeds = List<Map<String, dynamic>>.from(data).map((seed) {
        final profile = seed['profiles'] as Map<String, dynamic>?;
        seed['seller_name'] = profile?['full_name'] ?? 'Unknown';
        return seed;
      }).toList();

      return {'success': true, 'seeds': seeds};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Add new seed
  static Future<Map<String, dynamic>> addSeed({
    required String userId,
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
      final data = await Supabase.instance.client.from('seeds').insert({
        'user_id': userId,
        'seed_name': seedName,
        'crop_type': cropType,
        'quantity': quantity,
        'quantity_unit': quantityUnit ?? 'kg',
        'exchange_type': exchangeType ?? 'sell',
        'price': price ?? 0.0,
        'description': description ?? '',
        'location': location,
        'is_free': isFree,
        'status': 'available',
      }).select().single();

      return {'success': true, 'seed': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Request seed exchange
  static Future<Map<String, dynamic>> requestSeed({
    required int seedId,
    required String requesterId,
    String? message,
  }) async {
    try {
      final data = await Supabase.instance.client.from('seed_requests').insert({
        'seed_id': seedId,
        'requester_id': requesterId,
        'message': message ?? '',
      }).select().single();

      return {'success': true, 'request': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Delete a seed
  static Future<Map<String, dynamic>> deleteSeed({
    required int seedId,
    required String userId,
  }) async {
    try {
      await Supabase.instance.client
          .from('seeds')
          .delete()
          .eq('id', seedId)
          .eq('user_id', userId);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update a seed
  static Future<Map<String, dynamic>> updateSeed({
    required int seedId,
    required String userId,
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
      Map<String, dynamic> updates = {};
      if (seedName != null) updates['seed_name'] = seedName;
      if (cropType != null) updates['crop_type'] = cropType;
      if (quantity != null) updates['quantity'] = quantity;
      if (quantityUnit != null) updates['quantity_unit'] = quantityUnit;
      if (price != null) updates['price'] = price;
      if (exchangeType != null) updates['exchange_type'] = exchangeType;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (status != null) updates['status'] = status;

      final data = await Supabase.instance.client
          .from('seeds')
          .update(updates)
          .eq('id', seedId)
          .eq('user_id', userId)
          .select()
          .single();

      return {'success': true, 'seed': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // WEATHER
  // ============================================

  // Get weather locations
  static Future<Map<String, dynamic>> getWeatherLocations() async {
    try {
      final data = await Supabase.instance.client.from('weather_locations').select();
      return {'success': true, 'locations': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // DISEASE DETECTION
  // ============================================

  // Get diseases list
  static Future<Map<String, dynamic>> getDiseases() async {
    try {
      final data = await Supabase.instance.client.from('diseases').select();
      return {'success': true, 'diseases': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Save detection result
  static Future<Map<String, dynamic>> saveDetection({
    required String userId,
    required String diseaseName,
    required double confidence,
    String? imagePath,
  }) async {
    try {
      final data = await Supabase.instance.client.from('detections').insert({
        'user_id': userId,
        'disease_name': diseaseName,
        'confidence': confidence,
        'image_path': imagePath ?? '',
      }).select().single();

      return {'success': true, 'detection': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get detection history
  static Future<Map<String, dynamic>> getDetectionHistory(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('detections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return {'success': true, 'history': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // LEARNING HUB
  // ============================================

  // Get learning categories
  static Future<Map<String, dynamic>> getLearningCategories() async {
    try {
      final data = await Supabase.instance.client.from('learning_categories').select();
      return {'success': true, 'categories': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get learning articles
  static Future<Map<String, dynamic>> getLearningArticles({
    int? categoryId,
    String? search,
  }) async {
    try {
      var query = Supabase.instance.client.from('learning_articles').select();
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }
      final data = await query;
      return {'success': true, 'articles': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get single article
  static Future<Map<String, dynamic>> getLearningArticle(int articleId) async {
    try {
      final data = await Supabase.instance.client
          .from('learning_articles')
          .select()
          .eq('id', articleId)
          .single();
      return {'success': true, 'article': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // FARM ACTIVITIES
  // ============================================

  // Get activities
  static Future<Map<String, dynamic>> getActivities(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('activity_date', ascending: false);
      return {'success': true, 'activities': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Add activity
  static Future<Map<String, dynamic>> addActivity({
    required String userId,
    required String activityType,
    required String title,
    String? description,
    required String activityDate,
  }) async {
    try {
      final data = await Supabase.instance.client.from('activities').insert({
        'user_id': userId,
        'activity_type': activityType,
        'title': title,
        'description': description ?? '',
        'activity_date': activityDate,
      }).select().single();
      return {'success': true, 'activity': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  // Get notifications
  static Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return {'success': true, 'notifications': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationRead(
    int notificationId,
  ) async {
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .select()
          .single();
      return {'success': true, 'notification': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get user learning progress
  static Future<Map<String, dynamic>> getLearningProgress(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('learning_progress')
          .select()
          .eq('user_id', userId);
      return {'success': true, 'progress': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update learning progress
  static Future<Map<String, dynamic>> updateLearningProgress({
    required String userId,
    required int articleId,
    bool? isCompleted,
    bool? isDownloaded,
    int? progressPercent,
    int? timeSpentMinutes,
  }) async {
    try {
      final updates = {
        'user_id': userId,
        'article_id': articleId,
        'is_completed': isCompleted ?? false,
        'is_downloaded': isDownloaded ?? false,
        'progress_percent': progressPercent ?? 0,
        'time_spent_minutes': timeSpentMinutes ?? 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final data = await Supabase.instance.client
          .from('learning_progress')
          .upsert(updates, onConflict: 'user_id,article_id')
          .select()
          .single();

      return {'success': true, 'progress': data};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
