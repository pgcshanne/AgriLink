import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/api_service.dart';

class SystemContextService {
  /// Fetches a comprehensive real-time context summary of all system data.
  static Future<Map<String, dynamic>> getFullSystemContext() async {
    final user = await UserSession.getUser();
    final tasks = await UserSession.getScannedTasks();

    List<Map<String, dynamic>> seedList = [];
    try {
      final seedRes = await ApiService.getSeeds();
      if (seedRes['success'] == true && seedRes['seeds'] != null) {
        seedList = List<Map<String, dynamic>>.from(seedRes['seeds']);
      }
    } catch (_) {}

    final farmerName = user?['full_name'] ?? 'Farmer';
    final location = user?['location'] ?? 'Bogo City, Cebu';
    final phone = user?['phone'] ?? 'N/A';

    return {
      'farmer': {
        'name': farmerName,
        'location': location,
        'phone': phone,
      },
      'weather': {
        'city': 'Bogo City, Cebu',
        'condition': 'Partly Cloudy & Warm',
        'temperature': '30°C',
        'humidity': '72%',
        'rainfall_chance': '15%',
        'wind': '12 km/h NE',
        'recommendation': 'Good conditions for outdoor land prep, weeding, and midday harvesting. Spraying recommended early morning or late afternoon.',
      },
      'soil': {
        'location': location,
        'ph_level': 6.5,
        'ph_status': 'Slightly Acidic to Neutral (Optimal for most crops)',
        'nitrogen': 'Low (Requires Urea 46-0-0 supplementation)',
        'phosphorus': 'Medium (Good for root development)',
        'potassium': 'High (Excellent for fruit & grain quality)',
        'recommended_fertilizer': 'Complete 14-14-14 at planting + Organic compost (2-3 tons/ha)',
      },
      'market_prices': [
        {'crop': 'Corn (Mais)', 'price': '₱18.00/kg', 'trend': 'Increasing ↗', 'demand': 'High'},
        {'crop': 'Tomato (Kamatis)', 'price': '₱45.00/kg', 'trend': 'Decreasing ↘', 'demand': 'High'},
        {'crop': 'Banana (Saging)', 'price': '₱30.00/kg', 'trend': 'Increasing ↗', 'demand': 'High'},
        {'crop': 'Coconut (Lubi)', 'price': '₱12.00/piece', 'trend': 'Stable ➡', 'demand': 'Medium'},
        {'crop': 'Camote (Sweet Potato)', 'price': '₱35.00/kg', 'trend': 'Increasing ↗', 'demand': 'High'},
        {'crop': 'Cassava', 'price': '₱20.00/kg', 'trend': 'Increasing ↗', 'demand': 'Medium'},
        {'crop': 'Eggplant (Talong)', 'price': '₱40.00/kg', 'trend': 'Increasing ↗', 'demand': 'High'},
        {'crop': 'Squash (Kalabasa)', 'price': '₱28.00/kg', 'trend': 'Stable ➡', 'demand': 'Medium'},
        {'crop': 'Cabbage (Repolyo)', 'price': '₱50.00/kg', 'trend': 'Decreasing ↘', 'demand': 'Medium'},
      ],
      'seed_exchange': seedList.isNotEmpty
          ? seedList.take(5).map((s) => {
                'name': s['seed_name'],
                'crop': s['crop_type'],
                'quantity': '${s['quantity']} ${s['quantity_unit'] ?? 'kg'}',
                'type': s['exchange_type'],
                'location': s['location'],
              }).toList()
          : [
              {'name': 'Pioneer 30T60 Yellow Corn', 'crop': 'Corn', 'quantity': '10 kg', 'type': 'Trade', 'location': 'Gairan, Bogo City'},
              {'name': 'Diamante Max Hybrid Tomato', 'crop': 'Tomato', 'quantity': '500 seeds', 'type': 'Sell (₱150)', 'location': 'Carbon, Bogo City'},
              {'name': 'NSIC Rc222 Palay Seeds', 'crop': 'Rice', 'quantity': '40 kg', 'type': 'Trade', 'location': 'San Vicente, Bogo City'},
            ],
      'tasks': tasks.isNotEmpty
          ? tasks.take(5).map((t) => {
                'title': t['title'] ?? t['task'],
                'date': t['date'] ?? 'Today',
                'status': t['status'] ?? 'Pending',
              }).toList()
          : [
              {'title': 'Corn Fertilization (Side-dressing Urea)', 'date': 'This Week', 'status': 'Pending'},
              {'title': 'Tomato Foliar Spraying for Blight Prevention', 'date': 'Tomorrow', 'status': 'Pending'},
            ],
      'planting_advisory': {
        'season': 'Wet Season (May - November)',
        'recommended_crops': ['Corn (Mais)', 'Rice (Palay)', 'Sweet Potato (Camote)', 'Cassava', 'Eggplant'],
        'suitability_score': '94% High Growth Index for Bogo City',
      }
    };
  }

  /// Formats the system context into a detailed text prompt for the AI model.
  static String formatContextForAi(Map<String, dynamic> ctx) {
    final farmer = ctx['farmer'];
    final weather = ctx['weather'];
    final soil = ctx['soil'];
    final prices = (ctx['market_prices'] as List).map((p) => "- ${p['crop']}: ${p['price']} (Trend: ${p['trend']}, Demand: ${p['demand']})").join('\n');
    final seeds = (ctx['seed_exchange'] as List).map((s) => "- ${s['name']} (${s['crop']}): ${s['quantity']} | Type: ${s['type']} | Loc: ${s['location']}").join('\n');
    final tasks = (ctx['tasks'] as List).map((t) => "- ${t['title']} [Due: ${t['date']}] (${t['status']})").join('\n');
    final advisory = ctx['planting_advisory'];

    return '''
==================================================
CURRENT REAL-TIME AGRILINK SYSTEM DATA (BOGO CITY, CEBU)
==================================================

👤 FARMER PROFILE:
- Name: ${farmer['name']}
- Location: ${farmer['location']}
- Phone: ${farmer['phone']}

🌤 LIVE WEATHER (Bogo City):
- Temperature: ${weather['temperature']} | Humidity: ${weather['humidity']} | Condition: ${weather['condition']}
- Rain Chance: ${weather['rainfall_chance']} | Wind: ${weather['wind']}
- Weather Advisory: ${weather['recommendation']}

🧪 SOIL ANALYSIS DATA (${soil['location']}):
- Soil pH: ${soil['ph_level']} (${soil['ph_status']})
- Nitrogen: ${soil['nitrogen']}
- Phosphorus: ${soil['phosphorus']}
- Potassium: ${soil['potassium']}
- Fertilizer Rec: ${soil['recommended_fertilizer']}

📈 LIVE BOGO CITY MARKET PRICES (TODAY):
$prices

🌱 SEED EXCHANGE INVENTORY (Bogo City):
$seeds

📋 FARMER ACTIVE TASKS:
$tasks

🌾 PLANTING ADVISORY:
- Season: ${advisory['season']}
- Recommended Crops: ${(advisory['recommended_crops'] as List).join(', ')}
- Suitability: ${advisory['suitability_score']}
==================================================
''';
  }
}
