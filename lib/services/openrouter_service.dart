import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agrilink/services/system_context_service.dart';
import 'package:agrilink/services/user_session.dart';

class OpenRouterService {
  static String get defaultKey => utf8.decode(base64.decode('c2stb3ItdjEtNWY1MGFmZjZiM2ViYjNmZWVkNDJiMDI2ZjMxMTg2YjBhNGRlODg3Yzk0MzE5YjZmMDMxZGMzMjBkNDUwNTgwZQ=='));


  /// Generates a real LLM AI completion using OpenRouter API and live AgriLink system context data.
  static Future<String?> generateCompletion(
    String userPrompt,
    List<Map<String, String>> history,
  ) async {
    try {
      // Check saved key or use default provided key
      final savedKey = await UserSession.getOpenRouterKey();
      final apiKey = (savedKey != null && savedKey.isNotEmpty) ? savedKey : defaultKey;

      // 1. Fetch live system context & saved language preference
      final ctx = await SystemContextService.getFullSystemContext();
      final systemContextText = SystemContextService.formatContextForAi(ctx);
      final currentLang = await UserSession.getLanguage();

      // 2. Build system instructions with real system data & active language
      final systemPrompt = '''
You are AgriBot, the official AI farming assistant of AgriLink for Bogo City, Cebu, Philippines.
Use the following REAL-TIME AGRILINK FARMER ACCOUNT DATA to answer the farmer's question accurately:

$systemContextText

CRITICAL STRICT RULES:
1. LANGUAGE REQUIREMENT: The user has selected their preferred language as "$currentLang". YOU MUST ANSWER STICRLTY IN "$currentLang" (Cebuano/Bisaya, Tagalog, or English). If "$currentLang" is Cebuano (Bisaya), answer in natural conversational Cebuano/Bisaya. If Tagalog, answer in natural Tagalog.
2. DO NOT USE ANY ASTERISKS (*) IN YOUR OUTPUT. Do not use markdown bold/italic asterisks. Write clean plain text with simple lines and emojis if needed.
3. ANSWER ONLY WHAT IS EXPLICITLY ASKED. Be concise, direct, and focused. Do NOT output unrequested summaries, unasked advice, or unnecessary extra details.
4. Ensure all numbers, names, barangays, tasks, soil readings, weather conditions, and market prices match the logged-in farmer account context exactly.
''';

      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
        ...history,
        {'role': 'user', 'content': userPrompt},
      ];

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://agrilink.app',
          'X-Title': 'AgriLink',
        },
        body: json.encode({
          'model': 'openrouter/auto',
          'messages': messages,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            final text = message['content'].toString();
            // Remove any remaining asterisks cleanly
            return text.replaceAll('*', '').trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
