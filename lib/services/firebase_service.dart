import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  static bool _isInitialized = false;

  // Set your Firebase Web config keys here if using Firebase Auth
  static const String apiKey = "AIzaSyBlW_S2hGNPolpBLnzP0uaQFMQp7ta9toE";
  static const String appId = "1:942501712792:web:59b94a276c0332ae3fd1ed";
  static const String messagingSenderId = "942501712792";
  static const String projectId = "agrilink-9f6f1";
  static const String authDomain = "agrilink-9f6f1.firebaseapp.com";
  static const String storageBucket = "agrilink-9f6f1.firebasestorage.app";

  // Set your Semaphore API key here if using Semaphore SMS for PH numbers
  static const String semaphoreApiKey = "";

  static Future<void> init() async {
    if (_isInitialized && Firebase.apps.isNotEmpty) return;
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: apiKey,
              appId: appId,
              messagingSenderId: messagingSenderId,
              projectId: projectId,
              authDomain: authDomain,
              storageBucket: storageBucket,
            ),
          );
        } else {
          await Firebase.initializeApp();
        }
      }
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  /// Formats raw phone strings (e.g., "09123456789", "9123456789") into E.164 (+639123456789)
  static String formatPhilippinePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    if (clean.startsWith('+63')) {
      return clean;
    }
    if (clean.startsWith('63')) {
      return '+$clean';
    }
    if (clean.startsWith('0')) {
      return '+63${clean.substring(1)}';
    }
    return '+63$clean';
  }

  /// Sends a real SMS OTP via Firebase Auth or Semaphore SMS to a Philippine mobile number
  static Future<void> sendSmsOtp({
    required String rawPhone,
    required String generatedCode,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMsg) onError,
    required Function() onAutoVerified,
  }) async {
    final formattedPhone = formatPhilippinePhone(rawPhone);
    debugPrint('Sending SMS OTP to: $formattedPhone');

    await init();

    // 1. Try Semaphore SMS API if Semaphore API key is set
    if (semaphoreApiKey.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('https://api.semaphore.co/api/v4/messages'),
          body: {
            'apikey': semaphoreApiKey,
            'number': formattedPhone,
            'message': 'Your AgriLink verification code is $generatedCode. Valid for 10 minutes.',
          },
        );
        if (res.statusCode == 200) {
          onCodeSent('SEMAPHORE_SENT');
          return;
        }
      } catch (e) {
        debugPrint('Semaphore SMS Error: $e');
      }
    }

    // 2. Try Firebase Auth SMS
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            onAutoVerified();
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Firebase SMS error: ${e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verifies the 6-digit SMS code entered by the user
  static Future<bool> verifySmsCode({
    required String verificationId,
    required String userSmsCode,
  }) async {
    if (verificationId == 'SEMAPHORE_SENT') {
      return true;
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: userSmsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }
}
