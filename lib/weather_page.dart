import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/app_translations.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _forecast = [];
  
  String _currentHumidity = '...';
  String _currentWind = '...';
  String _currentUV = '...';
  String _currentVisibility = '...';
  String _currentSoilMoisture = '...';
  String _currentSoilTemp = '...';

  String _userLocation = 'Bogo City, Cebu';
  double _lat = 11.05;
  double _lon = 124.00;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = await UserSession.getUser();
    if (mounted && user != null && user['location'] != null) {
      setState(() {
        _userLocation = user['location'];
      });
      _setCoordinates(_userLocation);
    }
    await _fetchWeather();
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

  void _setCoordinates(String location) {
    if (_barangayCoordinates.containsKey(location)) {
      _lat = _barangayCoordinates[location]![0];
      _lon = _barangayCoordinates[location]![1];
    } else {
      // Default to Bogo City center if not found
      _lat = 11.05;
      _lon = 124.00;
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,is_day,weather_code,relative_humidity_2m,wind_speed_10m,visibility,soil_temperature_0cm,soil_moisture_0_to_1cm&daily=temperature_2m_max,weather_code,uv_index_max&timezone=Asia/Manila'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        final current = data['current'];
        
        List<Map<String, dynamic>> fetched = [];
        
        for (int i = 0; i < daily['time'].length; i++) {
          final dateStr = daily['time'][i];
          
          bool isToday = (i == 0);
          final parsedDate = DateTime.parse(dateStr);
          String dayLabel = isToday 
              ? 'Today, ${DateFormat('MMM d').format(parsedDate)}' 
              : DateFormat('EEE, MMM d').format(parsedDate);
          
          // For today, use exact current temperature and weather code
          final temp = isToday 
              ? current['temperature_2m'].round().toString() + '°C'
              : daily['temperature_2m_max'][i].round().toString() + '°C';
              
          final code = isToday ? current['weather_code'] : daily['weather_code'][i];
          final isDay = isToday ? (current['is_day'] == 1) : true;
          
          final weatherInfo = _mapWeatherCode(code, isDay);
          
          fetched.add({
            'day': dayLabel,
            'temp': temp,
            'icon': weatherInfo['icon'],
            'desc': weatherInfo['desc'],
          });
        }
        
        if (mounted) {
          setState(() {
            _forecast = fetched;
            
            // Populate exact details
            _currentHumidity = '${current['relative_humidity_2m']}%';
            _currentWind = '${current['wind_speed_10m']} km/h';
            
            // UV Index from daily max
            double uv = daily['uv_index_max'][0];
            String uvLevel = 'Low';
            if (uv >= 3 && uv < 6) uvLevel = 'Moderate';
            else if (uv >= 6 && uv < 8) uvLevel = 'High';
            else if (uv >= 8 && uv < 11) uvLevel = 'Very High';
            else if (uv >= 11) uvLevel = 'Extreme';
            _currentUV = '${uv.round()} ($uvLevel)';
            
            double visKm = current['visibility'] / 1000;
            _currentVisibility = '${visKm.round()} km';
            
            double soilMoistPercentage = current['soil_moisture_0_to_1cm'] * 100;
            _currentSoilMoisture = '${soilMoistPercentage.round()}%';
            _currentSoilTemp = '${current['soil_temperature_0cm'].round()}°C';
            
            _isLoading = false;
          });
        }
      } else {
        _useMockData();
      }
    } catch (e) {
      _useMockData();
    }
  }

  void _useMockData() {
    if (!mounted) return;
    
    final now = DateTime.now();
    String formatDay(int offset) {
      final date = now.add(Duration(days: offset));
      if (offset == 0) return 'Today, ${DateFormat('MMM d').format(date)}';
      return DateFormat('EEE, MMM d').format(date);
    }
    
    setState(() {
      _forecast = [
        {'day': formatDay(0), 'temp': '29°C', 'icon': Icons.wb_cloudy, 'desc': 'Partly Cloudy'},
        {'day': formatDay(1), 'temp': '28°C', 'icon': Icons.grain, 'desc': 'Light Showers'},
        {'day': formatDay(2), 'temp': '30°C', 'icon': Icons.wb_sunny, 'desc': 'Mostly Sunny'},
        {'day': formatDay(3), 'temp': '31°C', 'icon': Icons.wb_sunny, 'desc': 'Sunny'},
        {'day': formatDay(4), 'temp': '29°C', 'icon': Icons.cloud, 'desc': 'Cloudy'},
        {'day': formatDay(5), 'temp': '28°C', 'icon': Icons.thunderstorm, 'desc': 'Thunderstorm'},
        {'day': formatDay(6), 'temp': '30°C', 'icon': Icons.wb_cloudy, 'desc': 'Partly Cloudy'},
      ];
      _currentHumidity = '74%';
      _currentWind = '14 km/h';
      _currentUV = '8 (Very High)';
      _currentVisibility = '10 km';
      _currentSoilMoisture = '68%';
      _currentSoilTemp = '24°C';
      _isLoading = false;
    });
  }

  Map<String, dynamic> _mapWeatherCode(int code, bool isDay) {
    if (code == 0) return {'icon': isDay ? Icons.wb_sunny : Icons.nights_stay, 'desc': isDay ? 'Sunny' : 'Clear Night'};
    if (code == 1 || code == 2) return {'icon': isDay ? Icons.wb_cloudy : Icons.nights_stay, 'desc': isDay ? 'Partly Cloudy' : 'Partly Cloudy Night'};
    if (code == 3) return {'icon': Icons.cloud, 'desc': 'Cloudy'};
    if (code >= 45 && code <= 48) return {'icon': Icons.foggy, 'desc': 'Foggy'};
    if (code >= 51 && code <= 67) return {'icon': Icons.grain, 'desc': 'Light Showers'};
    if (code >= 71 && code <= 77) return {'icon': Icons.ac_unit, 'desc': 'Snow'};
    if (code >= 80 && code <= 82) return {'icon': Icons.water_drop, 'desc': 'Rain Showers'};
    if (code >= 95) return {'icon': Icons.thunderstorm, 'desc': 'Thunderstorm'};
    return {'icon': Icons.wb_cloudy, 'desc': 'Cloudy'};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Green Header ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              _userLocation.contains('Bogo City') ? _userLocation : '$_userLocation, Bogo City, Cebu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Live Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _forecast[_selectedDayIndex]['temp'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _forecast[_selectedDayIndex]['desc'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                ),
                            ),
                            Text(
                              'Humidity $_currentHumidity',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _forecast[_selectedDayIndex]['icon'] as IconData,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Weather Details Grid ───────────────
                    const Text(
                      'Weather Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildWeatherDetailCard(
                          icon: Icons.water_drop_outlined,
                          iconColor: const Color(0xFF0277BD),
                          label: 'Humidity',
                          value: _currentHumidity,
                          bgColor: const Color(0xFFE1F5FE),
                        ),
                        _buildWeatherDetailCard(
                          icon: Icons.air,
                          iconColor: Colors.blueGrey,
                          label: 'Wind Speed',
                          value: _currentWind,
                          bgColor: const Color(0xFFECEFF1),
                        ),
                        _buildWeatherDetailCard(
                          icon: Icons.wb_sunny_outlined,
                          iconColor: Colors.orange[800]!,
                          label: 'UV Index',
                          value: _currentUV,
                          bgColor: const Color(0xFFFFF3E0),
                        ),
                        _buildWeatherDetailCard(
                          icon: Icons.visibility_outlined,
                          iconColor: Colors.teal,
                          label: 'Visibility',
                          value: _currentVisibility,
                          bgColor: const Color(0xFFE0F2F1),
                        ),
                        _buildWeatherDetailCard(
                          icon: Icons.grass_outlined,
                          iconColor: const Color(0xFF2E7D32),
                          label: 'Soil Moisture',
                          value: _currentSoilMoisture,
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                        _buildWeatherDetailCard(
                          icon: Icons.thermostat_outlined,
                          iconColor: Colors.deepOrange,
                          label: 'Soil Temp',
                          value: _currentSoilTemp,
                          bgColor: Colors.deepOrange[50]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 7-Day Forecast ────────────────────
                    const Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: _forecast.asMap().entries.map((entry) {
                          final index = entry.key;
                          final f = entry.value;
                          final isSelected = index == _selectedDayIndex;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimaryGreen.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      f['day'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? kPrimaryGreen : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Icon(
                                          f['icon'] as IconData,
                                          color: isSelected ? kPrimaryGreen : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          f['desc'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected ? kPrimaryGreen : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    f['temp'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                      color: isSelected ? kPrimaryGreen : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Seasonal Insights ───────────────
                    _buildSeasonalInsights(),
                    const SizedBox(height: 20),

                    // ── AI Farming Weather Advisory ───────
                    _buildDynamicAdvisory(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAdvisory() {
    final String desc = _forecast[_selectedDayIndex]['desc'] as String;
    String bestToPlant = '';
    String plantCare = '';
    
    if (desc.contains('Sunny')) {
      bestToPlant = 'Corn (Mais), Tomato (Kamatis), Vegetables';
      plantCare = 'Water crops early morning or late afternoon to prevent evaporation. Apply mulch around Tomato plants.';
    } else if (desc.contains('Cloudy')) {
      bestToPlant = 'Banana (Saging), Cassava, Camote';
      plantCare = 'Ideal weather for transplanting seedlings or applying organic fertilizer to your Corn fields.';
    } else if (desc.contains('Showers') || desc.contains('Rain')) {
      bestToPlant = 'Camote (Sweet Potato), Coconut (Lubi)';
      plantCare = 'Avoid applying pesticides or fertilizers as they might wash away. Ensure drainage canals in Vegetable plots are clear.';
    } else if (desc.contains('Thunderstorm')) {
      bestToPlant = 'None (Wait for weather to clear)';
      plantCare = 'Secure young Banana (Saging) plants. Delay any planting or chemical application to prevent wash-off and crop damage.';
    } else {
      bestToPlant = 'Vegetables';
      plantCare = 'Monitor soil moisture and water as needed.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farming Advisory',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdvisoryCard(
          title: 'Best to Plant',
          desc: bestToPlant,
          icon: Icons.grass,
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
        ),
        const SizedBox(height: 10),
        _buildAdvisoryCard(
          title: 'Plant Care Advice',
          desc: plantCare,
          icon: Icons.medical_information_outlined,
          color: const Color(0xFF0277BD),
          bgColor: const Color(0xFFE1F5FE),
        ),
      ],
    );
  }

  Widget _buildSeasonalInsights() {
    final now = DateTime.now();
    final month = now.month; // 1-12
    final monthName = DateFormat('MMMM').format(now);
    
    // Wet season: Jun-Nov (6-11)
    final isWetSeason = month >= 6 && month <= 11;
    final seasonName = isWetSeason ? 'Wet Season' : 'Dry Season';
    
    String monthBestPlant = isWetSeason 
      ? 'Rice, Corn, Banana, Cassava' 
      : 'Vegetables, Tomato, Watermelon, Camote';
      
    // What best to plant this week based on the 7-day forecast summary
    int rainyDays = _forecast.where((f) => (f['desc'] as String).contains('Rain') || (f['desc'] as String).contains('Shower')).length;
    String weekBestPlant = '';
    if (rainyDays >= 4) {
      weekBestPlant = 'Coconut, Camote (High rain expected this week)';
    } else if (rainyDays == 0) {
      weekBestPlant = 'Tomato, Vegetables (Make sure to irrigate well)';
    } else {
      weekBestPlant = 'Corn, Banana (Optimal mixed weather)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seasonal Overview',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isWetSeason ? Icons.water_drop : Icons.wb_sunny, color: isWetSeason ? Colors.blue : Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Current Season: $monthName ($seasonName)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_month, color: kPrimaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Best to plant this month:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(monthBestPlant, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.date_range, color: kPrimaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Best to plant this week:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(weekBestPlant, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}