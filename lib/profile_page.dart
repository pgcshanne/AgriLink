import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/login_page.dart';

import 'package:agrilink/services/app_translations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await UserSession.getUser();
    final lang = await UserSession.getLanguage();
    if (mounted) {
      setState(() {
        _user = user;
        _selectedLanguage = lang;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await UserSession.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppTranslations.getText('select_language'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English'),
              _buildLanguageOption('Cebuano (Bisaya)'),
              _buildLanguageOption('Tagalog'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTranslations.getText('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    return ListTile(
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? kPrimaryGreen : const Color(0xFF1A1A1A),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: kPrimaryGreen) : null,
      onTap: () async {
        setState(() => _selectedLanguage = language);
        await AppTranslations.setLanguage(language);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppTranslations.getText('language_switched')} $language'),
              backgroundColor: kPrimaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryGreen),
        ),
      );
    }

    final name = _user?['full_name'] ?? 'AgriLink User';
    final role = (_user?['user_type'] ?? 'farmer').toString().toUpperCase();
    final phone = _user?['phone'] ?? 'Not set';
    final location = _user?['location'] ?? 'Bogo City, Cebu';

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Green Header ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: kLightGreen,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryGreen,
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account Info ──────────────────
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        children: [
                          _buildInfoRow(Icons.phone_outlined, 'Phone Number', phone),
                          const Divider(height: 24, thickness: 0.8),
                          _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Settings ──────────────────────
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: kLightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.translate, color: kPrimaryGreen, size: 20),
                            ),
                            title: Text(
                              AppTranslations.getText('change_language'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _selectedLanguage,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _showLanguageDialog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Logout Button ─────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          AppTranslations.getText('logout'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: kLightGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
