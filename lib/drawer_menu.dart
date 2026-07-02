import 'package:flutter/material.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/login_page.dart';
import 'disease_detection_page.dart';
import 'weather_page.dart';
import 'soil_analysis_page.dart';
import 'seed_exchange_page.dart';
import 'main.dart';

class DrawerMenu extends StatefulWidget {
  final String currentPage;

  const DrawerMenu({super.key, this.currentPage = 'Home'});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  String _userName = 'User';
  String _userEmail = '';
  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserSession.getUser();
    if (user != null) {
      setState(() {
        _userName = user['full_name'] ?? 'User';
        _userEmail = user['email'] ?? '';
        // Get initials from name
        final names = _userName.split(' ');
        if (names.length >= 2) {
          _userInitials = '${names[0][0]}${names[1][0]}'.toUpperCase();
        } else if (names.isNotEmpty) {
          _userInitials = names[0][0].toUpperCase();
        }
      });
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserSession.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.green[700],
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Agrilink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Menu Items
              _buildDrawerItem(
                context,
                Icons.home,
                'Home',
                widget.currentPage == 'Home',
              ),
              _buildDrawerItem(
                context,
                Icons.camera_alt,
                'Disease Detection',
                widget.currentPage == 'Disease Detection',
              ),
              _buildDrawerItem(
                context,
                Icons.wb_cloudy_outlined,
                'Weather',
                widget.currentPage == 'Weather',
              ),
              _buildDrawerItem(
                context,
                Icons.science,
                'Soil Analysis',
                widget.currentPage == 'Soil Analysis',
              ),
              _buildDrawerItem(
                context,
                Icons.swap_horiz,
                'Seed Exchange',
                widget.currentPage == 'Seed Exchange',
              ),

              const Spacer(),

              // Logout button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: _logout,
                ),
              ),

              // User profile at bottom
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen[300],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _userEmail,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.green[700] : Colors.white),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.green[700] : Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          if (title == widget.currentPage) {
            return;
          }

          if (title == 'Home') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } else if (title == 'Disease Detection') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DiseaseDetectionPage(),
              ),
            );
          } else if (title == 'Weather') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WeatherPage()),
            );
          } else if (title == 'Soil Analysis') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SoilAnalysisPage()),
            );
          } else if (title == 'Seed Exchange') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SeedExchangePage()),
            );
          }
        },
      ),
    );
  }
}
