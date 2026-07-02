import 'package:flutter/material.dart';
import 'drawer_menu.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'Weather',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      drawer: const DrawerMenu(currentPage: 'Weather'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Conditions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weather Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time weather data for Bogo City, Cebu',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Live Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current Weather Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weather',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '24°C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Partly Cloudy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like 26°C',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.wb_cloudy,
                      color: Colors.white.withOpacity(0.3),
                      size: 100,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Weather Details Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildWeatherDetailCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  label: 'Humidity',
                  value: '65%',
                  backgroundColor: Colors.blue[50]!,
                ),
                _buildWeatherDetailCard(
                  icon: Icons.air,
                  iconColor: Colors.grey,
                  label: 'Wind Speed',
                  value: '12 km/h',
                  backgroundColor: Colors.grey[100]!,
                ),
                _buildWeatherDetailCard(
                  icon: Icons.visibility,
                  iconColor: Colors.cyan,
                  label: 'Visibility',
                  value: '10 km',
                  backgroundColor: Colors.cyan[50]!,
                ),
                _buildWeatherDetailCard(
                  icon: Icons.wb_sunny,
                  iconColor: Colors.orange,
                  label: 'UV Index',
                  value: '6 (High)',
                  backgroundColor: Colors.orange[50]!,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Weather Alerts & Recommendations
            const Text(
              'Weather Alerts & Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildAlertCard(
              icon: Icons.water,
              iconColor: Colors.blue,
              title: 'Irrigation Recommendation',
              description: 'Light rain expected Thursday. Consider adjusting irrigation schedule.',
              backgroundColor: Colors.blue[50]!,
              borderColor: Colors.blue[200]!,
            ),
            const SizedBox(height: 12),
            
            _buildAlertCard(
              icon: Icons.warning,
              iconColor: Colors.red,
              title: 'Wind Advisory',
              description: 'Strong winds (25+ mph) expected Friday afternoon. Secure equipment.',
              backgroundColor: Colors.red[50]!,
              borderColor: Colors.red[200]!,
            ),
            const SizedBox(height: 24),
            
            // Soil & Environmental Conditions
            const Text(
              'Soil & Environmental Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSoilConditionCard(
              icon: Icons.water_drop_outlined,
              iconColor: Colors.blue,
              title: 'Soil Moisture',
              value: '68%',
              description: 'Optimal for current crops',
              backgroundColor: Colors.blue[50]!,
            ),
            const SizedBox(height: 12),
            
            _buildSoilConditionCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.yellow[700]!,
              title: 'Solar Radiation',
              value: '850 W/m²',
              description: 'Good for photosynthesis',
              backgroundColor: Colors.yellow[50]!,
            ),
            const SizedBox(height: 12),
            
            _buildSoilConditionCard(
              icon: Icons.thermostat,
              iconColor: Colors.green,
              title: 'Soil Temperature',
              value: '22°C',
              description: 'Ideal for root development',
              backgroundColor: Colors.green[50]!,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildSoilConditionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String description,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
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