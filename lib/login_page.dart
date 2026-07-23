import 'package:flutter/material.dart';
import 'package:agrilink/services/api_service.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/register_page.dart';
import 'package:agrilink/main.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.login(
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
      );
      if (response['success'] == true) {
        await UserSession.clearLocalData(); // Clear old tasks if any
        await UserSession.saveUser(response['user']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScaffold()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // ── Green Header ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1605000797499-95a51c5269ae?q=80&w=800&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black45, // Dark tint for readability
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Custom Logo Image
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white, // White background to contrast the green logo
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/agrilink_logo.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Smart Farming for Bogo City, Cebu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form Section ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full Name field
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Juan Dela Cruz',
                          prefixIcon: Icon(
                            Icons.person_outlined,
                            color: kPrimaryGreen,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4-Digit PIN field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: '4-Digit PIN',
                          hintText: '••••',
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: kPrimaryGreen,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[500],
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your 4-digit PIN';
                          }
                          if (value.length != 4) {
                            return 'PIN must be exactly 4 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Register',
                                  style: GoogleFonts.poppins(
                                    color: kPrimaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
