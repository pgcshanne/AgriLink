import 'dart:math';
import 'package:agrilink/services/system_context_service.dart';
import 'package:agrilink/services/openrouter_service.dart';

import 'package:agrilink/services/user_session.dart';

class FreeAiService {
  /// Generates a real system-data-aware AI response for AgriBot using OpenRouter LLM AI & system context.
  static Future<String> generateResponse(
    String userPrompt,
    List<Map<String, String>> history, {
    String model = 'openrouter/auto',
  }) async {
    // 1. Try real LLM completion with OpenRouter API key & live system context
    try {
      final llmResponse = await OpenRouterService.generateCompletion(userPrompt, history);
      if (llmResponse != null && llmResponse.trim().isNotEmpty) {
        return llmResponse;
      }
    } catch (_) {}

    // 2. Fetch live real system context & fallback to system context engine
    final ctx = await SystemContextService.getFullSystemContext();
    final lang = await UserSession.getLanguage();
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(200)));
    return _generateSystemEngineResponse(userPrompt, ctx, lang);
  }

  static String _generateSystemEngineResponse(String userPrompt, Map<String, dynamic> ctx, String lang) {
    final query = userPrompt.toLowerCase().trim();
    String response = '';

    // 1. GREETINGS & INTRO
    if (_matches(query, ['hi', 'hello', 'kumusta', 'maayong adlaw', 'hey', 'start', 'who are you', 'kinsa ka', 'what can you do'])) {
      final farmerName = ctx['farmer']['name'];
      if (lang.contains('Bisaya') || lang.contains('Cebuano')) {
        response = '''
Maayong adlaw, $farmerName! 👋 Ako si AgriBot, imong AI nga tabang sa pagpananom sa Bogo City, Cebu! 🌾

Nakasumpay sa imong AgriLink Data:
• Tagna sa Panahon sa Bogo City
• Pagsusi sa Yuta ug Rekomendasyon sa Abono
• Presyo sa Merkado
• Inventory sa Binhi
• Imong Aktibong Trabaho sa Yuta

Unsay akong ikatabang nimo karon?
''';
      } else if (lang.contains('Tagalog')) {
        response = '''
Kumusta, $farmerName! 👋 Ako si AgriBot, ang iyong AI Assistant sa pagsasaka sa Bogo City, Cebu! 🌾

Naka-konekta sa iyong AgriLink Data:
• Ulat ng Panahon sa Bogo City
• Pagsusuri ng Lupa at Abono
• Presyo sa Pamilihan
• Palitan ng Binhi
• Iyong mga Gawain sa Sakahan

Paano kita matutulungan ngayon?
''';
      } else {
        response = '''
Kumusta, $farmerName! 👋 I am AgriBot, your AI Farming Assistant for Bogo City, Cebu! 🌾

Connected to your live AgriLink Account Data:
• Weather & Forecasts for Bogo City
• Soil Analysis & NPK Fertilizer Recommendations
• Market Prices & Seeds Inventory
• Active Farming Tasks & Schedules

How can I help you today?
''';
      }
    }
    // 2. LIVE WEATHER QUERIES
    else if (_matches(query, ['weather', 'temperature', 'rain', 'uwan', 'forecast', 'init', 'klima', 'sun', 'cloud', 'typhoon'])) {
      final weather = ctx['weather'];
      response = '''
⛅ Live Weather Update for ${weather['city']}:
• Temperature: ${weather['temperature']}
• Condition: ${weather['condition']}
• Humidity: ${weather['humidity']}
• Rainfall Chance: ${weather['rainfall_chance']}
• Wind Speed: ${weather['wind']}

Advisory: ${weather['recommendation']}
''';
    }
    // 3. LIVE MARKET PRICES QUERIES
    else if (_matches(query, ['market', 'price', 'presyo', 'baligya', 'cost', 'how much', 'pila', 'magkano', 'rate'])) {
      final prices = (ctx['market_prices'] as List).map((p) => "• ${p['crop']}: ${p['price']} (${p['trend']} | Demand: ${p['demand']})").join('\n');
      response = '''
📊 Bogo City Today's Market Prices:

$prices
''';
    }
    // 4. SOIL ANALYSIS & FERTILIZER QUERIES
    else if (_matches(query, ['soil', 'yuta', 'npk', 'ph', 'fertilizer', 'abono', 'urea', 'compost', 'lime'])) {
      final soil = ctx['soil'];
      response = '''
🧪 Live Soil Analysis Data (${soil['location']}):
• Soil pH: ${soil['ph_level']} (${soil['ph_status']})
• Nitrogen (N): ${soil['nitrogen']}
• Phosphorus (P): ${soil['phosphorus']}
• Potassium (K): ${soil['potassium']}

Recommendation: ${soil['recommended_fertilizer']}
''';
    }
    // 5. SEED EXCHANGE INVENTORY QUERIES
    else if (_matches(query, ['seed', 'exchange', 'trade', 'binhi', 'lisug', 'buy seed', 'sell seed'])) {
      final seeds = (ctx['seed_exchange'] as List).map((s) => "• ${s['name']} (${s['crop']}) - Qty: ${s['quantity']} | Loc: ${s['location']}").join('\n');
      response = '''
🌱 Seed Exchange Inventory in Bogo City:

$seeds
''';
    }
    // 6. FARMER ACTIVE TASKS QUERIES
    else if (_matches(query, ['task', 'todo', 'schedule', 'work', 'buhatonon', 'my task', 'reminder'])) {
      final tasks = (ctx['tasks'] as List).map((t) => "• ${t['title']} (Due: ${t['date']} | Status: ${t['status']})").join('\n');
      response = '''
📋 Your Active Tasks:

$tasks
''';
    }
    // 7. PLANTING ADVISORY & CROPS QUERIES
    else if (_matches(query, ['plant', 'crop', 'season', 'tanom', 'harvest', 'suitability', 'advisory', 'corn', 'mais', 'tomato', 'kamatis', 'rice', 'palay', 'eggplant', 'cassava'])) {
      final advisory = ctx['planting_advisory'];
      final crops = (advisory['recommended_crops'] as List).join(', ');
      response = '''
🌾 Planting Advisory for Bogo City:
• Current Season: ${advisory['season']}
• Suitability Index: ${advisory['suitability_score']}
• Recommended Crops: $crops
''';
    }
    // 8. PROFILE / ACCOUNT QUERIES
    else if (_matches(query, ['profile', 'account', 'who am i', 'my info', 'name', 'barangay'])) {
      final farmer = ctx['farmer'];
      response = '''
👤 Profile Account Data:
• Name: ${farmer['name']}
• Location: ${farmer['location']}
• Phone: ${farmer['phone']}
• Role: Verified Farmer
''';
    }
    // 9. GENERAL SYSTEM RESPONSE
    else {
      final weather = ctx['weather'];
      final soil = ctx['soil'];
      response = '''
🌾 AgriBot Response for "$userPrompt":
• Weather: ${weather['city']} - ${weather['temperature']}, ${weather['condition']}
• Soil pH: ${soil['ph_level']} (${soil['nitrogen']})
''';
    }

    return response.replaceAll('*', '').trim();
  }

  static bool _matches(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }
}
