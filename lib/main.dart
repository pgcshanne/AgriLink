import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/login_page.dart';
import 'package:agrilink/disease_detection_page.dart';
import 'package:agrilink/soil_analysis_page.dart';
import 'package:agrilink/weather_page.dart';
import 'package:agrilink/planting_advisory_page.dart';
import 'package:agrilink/tasks_page.dart';
import 'package:agrilink/analytics_page.dart';
import 'package:agrilink/seed_exchange_page.dart';
import 'package:agrilink/profile_page.dart';
import 'package:agrilink/market_price_page.dart';
import 'package:agrilink/widgets/ai_chat_overlay.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agrilink/services/app_translations.dart';
import 'package:agrilink/services/firebase_service.dart';

// =====================================================
// GLOBAL THEME COLORS
// =====================================================
const Color kPrimaryGreen = Color(0xFF147A4A); // Deep, rich forest green
const Color kSecondaryGreen = Color(0xFF0F6039); // Darker shade for contrast
const Color kAccentGreen = Color(0xFF229658); // Lighter accent green
const Color kLightGreen = Color(
  0xFFE8F3ED,
); // Pale tinted green for backgrounds
const Color kBackground = Color(0xFFF7F9F8); // Soft off-white background

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  await Supabase.initialize(
    url: 'https://pywfzeguozjuyrfztwpu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5d2Z6ZWd1b3pqdXlyZnp0d3B1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0NzMyMDMsImV4cCI6MjA5OTA0OTIwM30.f4QIcS0MIukfr0ULQ7n720qnxuwCkp_gp2-7bZ6C1Eo',
  );
  await AppTranslations.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLanguage,
      builder: (context, language, child) {
        return MaterialApp(
      title: 'AgriLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryGreen,
          primary: kPrimaryGreen,
          secondary: kAccentGreen,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      home: const AuthCheck(),
        );
      },
    );
  }
}

// =====================================================
// AUTH CHECK
// =====================================================
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await UserSession.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kPrimaryGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture, color: Colors.white, size: 72),
              SizedBox(height: 18),
              Text(
                'AgriLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Smart Farming for Bogo City',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ],
          ),
        ),
      );
    }
    return _isLoggedIn ? const MainScaffold() : const LoginPage();
  }
}

// =====================================================
// MAIN SCAFFOLD WITH BOTTOM NAVIGATION
// =====================================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    TasksPage(),
    AnalyticsPage(),
    ProfilePage(),
  ];

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          const AiChatOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, AppTranslations.getText('home')),
            _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, AppTranslations.getText('tasks')),
            _buildNavItem(2, Icons.analytics_outlined, Icons.analytics, AppTranslations.getText('farm_analytics')),
            _buildNavItem(3, Icons.person_outline, Icons.person, AppTranslations.getText('profile')),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HOME PAGE
// =====================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Farmer';
  String _userLocation = 'Bogo City, Cebu';
  String _selectedCategory = 'Seeds';

  // Localized mock products matching Bogo City agricultural feeds and seeds
  final Map<String, List<Map<String, dynamic>>> _categoryProducts = {
    'Seeds': [
      {
        'title': 'Palay (Rice) Seeds',
        'desc': 'Certified High Yielding Variety',
        'unit': '25.00 kg',
        'price': 23.50,
        'oldPrice': 26.00,
        'image': Icons.grass,
      },
      {
        'title': 'Sweet Corn Seeds',
        'desc': 'F1 Hybrid Sweet Corn',
        'unit': '1.00 kg',
        'price': 180.00,
        'oldPrice': 200.00,
        'image': Icons.grain,
      },
    ],
    'Fertilizers': [
      {
        'title': 'Urea Fertilizer',
        'desc': '46-0-0 Nitrogen Booster',
        'unit': '50.00 kg',
        'price': 1200.00,
        'oldPrice': 1350.00,
        'image': Icons.science,
      },
      {
        'title': 'Complete Fertilizer',
        'desc': '14-14-14 Balanced NPK',
        'unit': '50.00 kg',
        'price': 1450.00,
        'oldPrice': 1600.00,
        'image': Icons.compost,
      },
    ],
    'Feeds': [
      {
        'title': 'Beef Feed (Hubbard)',
        'desc': 'Premium cattle finisher feed',
        'unit': '25.00 kg',
        'price': 23.00,
        'oldPrice': 25.00,
        'image': Icons.bakery_dining,
      },
      {
        'title': 'Cattle Feed (Precon)',
        'desc': 'Starter complete formula feed',
        'unit': '22.67 kg',
        'price': 20.00,
        'oldPrice': 22.00,
        'image': Icons.pets,
      },
    ],
  };

  // Dynamic state
  int _waterDepth = 71;
  int _soilMoisture = 47;
  int _plantHealth = 89;
  List<Map<String, dynamic>> _homeTasks = [];
  List<Map<String, dynamic>> _activityHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  static const Map<String, List<double>> _barangayCoordinates = {
    'Anonang Norte': [11.074, 124.001],
    'Anonang Sur': [11.065, 124.002],
    'Banban': [11.085, 123.995],
    'Binabag': [11.035, 123.980],
    'Bungtod': [11.055, 123.998],
    'Carbon': [11.050, 124.010],
    'Cayang': [11.060, 123.985],
    'Cogon': [11.052, 124.003],
    'Dakit': [11.045, 124.008],
    'Don Pedro Rodriguez': [11.090, 123.980],
    'Gairan': [11.040, 124.015],
    'Guadalupe': [11.004, 124.012],
    'La Paz': [11.025, 124.020],
    'La Purisima Concepcion (LPC)': [11.048, 124.001],
    'Libertad': [11.015, 124.018],
    'Lourdes': [11.051, 123.999],
    'Malingin': [11.070, 123.975],
    'Marangog': [11.080, 123.985],
    'Nailon': [11.065, 124.025],
    'Odlot': [11.095, 124.030],
    'Pandan': [11.055, 124.005],
    'Polambato': [11.085, 124.015],
    'Sambag': [11.048, 123.995],
    'San Vicente': [11.042, 124.001],
    'Santo Niño': [11.053, 124.007],
    'Santo Rosario': [11.054, 124.004],
    'Siocon': [11.030, 124.010],
    'Sudlonon': [11.045, 123.990],
    'Taytayan': [11.035, 123.995],
  };

  Future<void> _loadDashboardData() async {
    final user = await UserSession.getUser();
    final tasks = await UserSession.getScannedTasks();
    final activities = await UserSession.getActivities();

    int water = 71;
    int health = 89;
    int soil = 47;

    double lat = 11.05;
    double lon = 124.00;
    
    if (user != null && user['location'] != null) {
      String loc = user['location'];
      if (_barangayCoordinates.containsKey(loc)) {
        lat = _barangayCoordinates[loc]![0];
        lon = _barangayCoordinates[loc]![1];
      }
    }

    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=relative_humidity_2m,soil_moisture_0_to_1cm,precipitation&timezone=Asia/Manila'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        water = current['precipitation'] > 0 ? 95 : 45;
        soil = (current['soil_moisture_0_to_1cm'] * 100).round();
        health = (100 - (current['relative_humidity_2m'] > 80 ? 20 : 0)).round();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (user != null) {
          _userName = user['full_name'] ?? 'Farmer';
          _userLocation = user['location'] ?? 'Bogo City, Cebu';
        }
        _waterDepth = water;
        _plantHealth = health;
        _soilMoisture = soil;
        _homeTasks = tasks.take(2).toList();
        _activityHistory = activities.take(5).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProducts = _categoryProducts[_selectedCategory] ?? [];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        image: DecorationImage(
          image: const AssetImage('assets/images/home_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.50),
            BlendMode.lighten,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: kPrimaryGreen,
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header Row ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: kLightGreen,
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'F',
                                style: const TextStyle(
                                  color: kPrimaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello 👋',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Cart removed
                      ],
                    ),
                  ),

                  // ── Localized Weather ────────────────────
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WeatherPage()),
                      );
                    },
                    child: _buildWeatherWidget(),
                  ),

                  // ── Quick Actions ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 12) / 2;
                        final cardHeight = cardWidth / 1.15;

                        Widget buildCard(Widget card) {
                          return SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: card,
                          );
                        }

                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            buildCard(
                              HoverableModuleCard(
                                icon: Icons.biotech,
                                label: AppTranslations.getText('disease_detection'),
                                color: const Color(0xFF2E7D32),
                                bgColor: const Color(0xFFE8F5E9),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DiseaseDetectionPage(),
                                  ),
                                ),
                              ),
                            ),
                            buildCard(
                              HoverableModuleCard(
                                icon: Icons.grass,
                                label: AppTranslations.getText('planting_advisory'),
                                color: const Color(0xFF0277BD),
                                bgColor: const Color(0xFFE1F5FE),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PlantingAdvisoryPage(),
                                  ),
                                ),
                              ),
                            ),
                            buildCard(
                              HoverableModuleCard(
                                icon: Icons.science,
                                label: AppTranslations.getText('soil_analysis'),
                                color: const Color(0xFF6A1B9A),
                                bgColor: const Color(0xFFF3E5F5),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SoilAnalysisPage(),
                                  ),
                                ),
                              ),
                            ),

                            buildCard(
                              HoverableModuleCard(
                                icon: Icons.trending_up,
                                label: AppTranslations.getText('market_prices'),
                                color: const Color(0xFFBF360C),
                                bgColor: const Color(0xFFFBE9E7),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MarketPricePage(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── AI Advisory ───────────────────────────
                  _buildAIAdvisoryWidget(),
                  const SizedBox(height: 12),

                  // ── Recent Activity ───────────────────────
                  _buildRecentActivityWidget(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    final formattedDate = '${weekdays[now.weekday - 1]} ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final currentMonthName = months[now.month - 1];
    
    String formatHour(DateTime d) {
      int h = d.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      if (h == 0) h = 12;
      if (h > 12) h -= 12;
      return '$h $period';
    }

    final isWetSeason = now.month >= 6 && now.month <= 11;
    final seasonName = isWetSeason ? 'Wet Season' : 'Dry Season';
    final cropRecs = isWetSeason 
      ? 'Rice, Eggplant, Squash, and Leafy Greens' 
      : 'Corn, Watermelon, Tomatoes, and Root crops';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPrimaryGreen,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userLocation.contains('Bogo City') ? _userLocation : '$_userLocation, Bogo City, Cebu',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '26°',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.wb_cloudy,
                          color: Colors.white.withOpacity(0.9),
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cloudy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWeatherStat('Humidity', '78%', Icons.water_drop),
                    const SizedBox(height: 12),
                    _buildWeatherStat('Rainfall', '20%', Icons.umbrella),
                    const SizedBox(height: 12),
                    _buildWeatherStat('Wind', '12 km/h', Icons.air),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHourlyForecast('Now', '26°', Icons.wb_cloudy, true),
                  _buildHourlyForecast(formatHour(now.add(const Duration(hours: 1))), '25°', Icons.grain, false),
                  _buildHourlyForecast(formatHour(now.add(const Duration(hours: 2))), '24°', Icons.umbrella, false),
                  _buildHourlyForecast(
                    formatHour(now.add(const Duration(hours: 3))),
                    '24°',
                    Icons.thunderstorm,
                    false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Crop Recommendation ───────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seasonal Crop Recommendation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ideal for $currentMonthName ($seasonName): $cropRecs.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, color: Colors.white70, size: 16),
      ],
    );
  }

  Widget _buildHourlyForecast(
    String time,
    String temp,
    IconData icon,
    bool isActive,
  ) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          temp,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAdvisoryWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Analytic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnalyticItem(
                  'Water depth',
                  '$_waterDepth%',
                  Icons.water,
                  Colors.blue,
                ),
                _buildAnalyticItem(
                  'Plant Health',
                  '$_plantHealth%',
                  Icons.local_florist,
                  kPrimaryGreen,
                ),
                _buildAnalyticItem(
                  'Soil Fertility',
                  '$_soilMoisture%',
                  Icons.science,
                  Colors.orange,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),
            const Text(
              'AI Planting & Harvest Advisory',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            if (_homeTasks.isEmpty)
              const Text(
                'No active crops or tasks generated yet. Visit the Planting Advisory module to start!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              ..._homeTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAdvisoryTask(
                      task['title'],
                      task['time'],
                      Icons.spa,
                      kPrimaryGreen,
                      true,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          if (_activityHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'No recent activity. Actions you take in the app will appear here.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._activityHistory.map((activity) {
              final DateTime? date = activity['timestamp'] != null
                  ? DateTime.tryParse(activity['timestamp'])
                  : null;
              final String timeStr = date != null
                  ? DateFormat('MMM d, h:mm a').format(date)
                  : 'Just now';

              IconData iconData = Icons.history;
              if (activity['icon'] == 'assessment') iconData = Icons.assessment;
              if (activity['icon'] == 'camera_alt') iconData = Icons.camera_alt;

              Color color = Colors.grey;
              if (activity['color'] == 'blue') color = Colors.blue;
              if (activity['color'] == 'orange') color = Colors.orange;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? 'Activity',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisoryTask(
    String title,
    String time,
    IconData icon,
    Color color,
    bool isPending,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Icon(
          isPending ? Icons.radio_button_unchecked : Icons.check_circle,
          color: isPending ? Colors.grey[300] : kPrimaryGreen,
          size: 20,
        ),
      ],
    );
  }
}

class HoverableModuleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const HoverableModuleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<HoverableModuleCard> createState() => _HoverableModuleCardState();
}

class _HoverableModuleCardState extends State<HoverableModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : kPrimaryGreen.withOpacity(0.2),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 9),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MODULES PAGE
// =====================================================
class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Modules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Access all AgriLink AI-powered features',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildModuleRow(
                      context,
                      number: '01',
                      icon: Icons.biotech,
                      title: 'Disease Detection',
                      subtitle:
                          'AI crop disease diagnosis with 80–90% confidence, recuperative & preventive recommendations',
                      color: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DiseaseDetectionPage(),
                        ),
                      ),
                    ),
                    _buildModuleRow(
                      context,
                      number: '02',
                      icon: Icons.grass,
                      title: 'Planting Advisory',
                      subtitle:
                          'Optimal planting & harvest timing, plant growth tracking, weather-linked advisory',
                      color: const Color(0xFF0277BD),
                      bgColor: const Color(0xFFE1F5FE),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlantingAdvisoryPage(),
                        ),
                      ),
                    ),
                    _buildModuleRow(
                      context,
                      number: '03',
                      icon: Icons.science,
                      title: 'Soil Analysis',
                      subtitle:
                          'NPK detection, soil color & type analysis, fertilizer recommendations',
                      color: const Color(0xFF6A1B9A),
                      bgColor: const Color(0xFFF3E5F5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SoilAnalysisPage(),
                        ),
                      ),
                    ),
                    _buildModuleRow(
                      context,
                      number: '04',
                      icon: Icons.cloud,
                      title: 'Weather Monitor',
                      subtitle:
                          'Real-time localized weather for Bogo City barangays, linked to advisories',
                      color: const Color(0xFF01579B),
                      bgColor: const Color(0xFFE3F2FD),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WeatherPage()),
                      ),
                    ),
                    _buildModuleRow(
                      context,
                      number: '05',
                      icon: Icons.trending_up,
                      title: 'Market Price Costing',
                      subtitle:
                          'Predictive crop pricing, income estimates, cost-benefit analysis',
                      color: const Color(0xFFBF360C),
                      bgColor: const Color(0xFFFBE9E7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MarketPricePage(),
                        ),
                      ),
                    ),
                    _buildModuleRow(
                      context,
                      number: '06',
                      icon: Icons.swap_horiz,
                      title: 'Seed Exchange',
                      subtitle:
                          'Buy, sell, and trade seeds with other farmers in Bogo City',
                      color: const Color(0xFF33691E),
                      bgColor: const Color(0xFFF1F8E9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SeedExchangePage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleRow(
    BuildContext context, {
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module $number',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
