import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:agrilink/services/api_service.dart';
import 'package:agrilink/services/firebase_service.dart';
import 'package:agrilink/services/web_image_helper.dart';
import 'package:agrilink/login_page.dart';
import 'package:agrilink/main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  // ── Step tracking ─────────────────────────────
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // ── Form keys per step ────────────────────────
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // ── State ─────────────────────────────────────
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedLocation;
  DateTime? _selectedBirthdate;

  // OTP
  String _generatedOtp = '';
  bool _otpSent = false;
  bool _otpVerified = false;

  // Valid ID
  String? _selectedIdType;
  Uint8List? _idImageBytes;
  String? _idFileName;

  final List<String> _idTypes = [
    'Philippine National ID',
    "Voter's ID",
    "Driver's License",
    'PhilHealth ID',
    'Postal ID',
    'Barangay ID',
    'SSS ID',
    'UMID',
    'Passport',
  ];

  final List<String> _barangays = [
    'Anonang Norte', 'Anonang Sur', 'Banban', 'Binabag', 'Bungtod', 'Carbon', 'Cayang',
    'Cogon', 'Dakit', 'Don Pedro Rodriguez', 'Gairan', 'Guadalupe', 'La Paz',
    'La Purisima Concepcion (LPC)', 'Libertad', 'Lourdes', 'Malingin', 'Marangog',
    'Nailon', 'Odlot', 'Pandan', 'Polambato', 'Sambag', 'San Vicente', 'Santo Niño',
    'Santo Rosario', 'Siocon', 'Sudlonon', 'Taytayan',
  ];

  final List<String> _stepLabels = [
    'Personal\nInfo',
    'Phone\nVerify',
    'Valid\nID',
    'Security\n& Location',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── OTP Logic ─────────────────────────────────
  String _firebaseVerificationId = '';

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();

    setState(() {
      _isLoading = true;
      _otpSent = true;
    });

    final formattedPhone = FirebaseService.formatPhilippinePhone(phone);

    await FirebaseService.sendSmsOtp(
      rawPhone: phone,
      generatedCode: _generatedOtp,
      onCodeSent: (vId) {
        if (mounted) {
          setState(() {
            _firebaseVerificationId = vId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Real SMS OTP sent to $formattedPhone! Check your phone.'),
              backgroundColor: kPrimaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      onAutoVerified: () {
        if (mounted) {
          setState(() {
            _otpVerified = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phone number auto-verified!'),
              backgroundColor: kPrimaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showFallbackOtpDialog(phone, err);
        }
      },
    );
  }

  void _showFallbackOtpDialog(String phone, String errorReason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kLightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sms_outlined, color: kPrimaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('SMS Sent / Test Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A verification code has been dispatched to $phone',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: kLightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key, color: kPrimaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _generatedOtp,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGreen,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Notice: $errorReason\n(Use code above to test verification)',
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyOtp() async {
    final userCode = _otpController.text.trim();
    if (userCode.isEmpty) return false;

    if (_firebaseVerificationId.isNotEmpty) {
      final verified = await FirebaseService.verifySmsCode(
        verificationId: _firebaseVerificationId,
        userSmsCode: userCode,
      );
      if (verified) {
        setState(() => _otpVerified = true);
        return true;
      }
    }

    if (userCode == _generatedOtp) {
      setState(() => _otpVerified = true);
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invalid OTP code. Please check your SMS and try again.'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return false;
  }

  // ── Image Picker ────────────────────────────
  Future<void> _pickIdImage(ImageSource source) async {
    try {
      if (kIsWeb) {
        // On Flutter Web, use native HTML <input type="file"> instead of image_picker.
        // This works 100% on iPhone Safari and Android Chrome.
        final bool useCamera = source == ImageSource.camera;
        final Uint8List? bytes = await pickWebImage(useCamera: useCamera);
        if (bytes != null && mounted) {
          setState(() {
            _idImageBytes = bytes;
            _idFileName = 'valid_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
          });
        }
      } else {
        // Native platforms — use image_picker
        final picker = ImagePicker();
        XFile? pickedFile;
        try {
          pickedFile = await picker.pickImage(
            source: source,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 85,
          );
        } catch (_) {
          pickedFile = await picker.pickImage(source: ImageSource.gallery);
        }
        if (pickedFile != null && mounted) {
          final file = pickedFile;
          final bytes = await file.readAsBytes();
          setState(() {
            _idImageBytes = bytes;
            _idFileName = 'valid_id_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload Valid ID',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how to provide your ID photo',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceCard(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      subtitle: 'Choose from\nyour photos',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickIdImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSourceCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      subtitle: 'Take a new\nphoto',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickIdImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: kLightGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGreen.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: kPrimaryGreen, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step Navigation ───────────────────────────
  Future<void> _nextStep() async {
    bool canProceed = false;

    switch (_currentStep) {
      case 0:
        canProceed = _step1FormKey.currentState?.validate() ?? false;
        if (canProceed && _selectedBirthdate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please select your birthdate'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          canProceed = false;
        }
        // Check minimum age (18)
        if (canProceed && _selectedBirthdate != null) {
          final age = DateTime.now().difference(_selectedBirthdate!).inDays ~/ 365;
          if (age < 18) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You must be at least 18 years old to register'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            canProceed = false;
          }
        }
        break;
      case 1:
        if (!_otpVerified) {
          final valid = await _verifyOtp();
          canProceed = valid;
        } else {
          canProceed = true;
        }
        break;
      case 2:
        if (_selectedIdType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please select your ID type'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          canProceed = false;
        } else if (_idImageBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please upload a photo of your valid ID'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          canProceed = false;
        } else {
          canProceed = true;
        }
        break;
    }

    if (canProceed) {
      _fadeController.reset();
      setState(() => _currentStep++);
      _fadeController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reset();
      setState(() => _currentStep--);
      _fadeController.forward();
    }
  }

  // ── Birthdate Picker ──────────────────────────
  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthdate = picked);
    }
  }

  // ── Register ──────────────────────────────────
  Future<void> _register() async {
    if (!(_step4FormKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        location: _selectedLocation ?? '',
        userType: 'farmer',
        birthdate: _selectedBirthdate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)
            : null,
        idType: _selectedIdType,
        idImageBytes: _idImageBytes,
        idFileName: _idFileName,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created! Please sign in.'),
              backgroundColor: kPrimaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ── Build Helpers ─────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool? showToggle,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryGreen),
        suffixIcon: showToggle == true
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[500],
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator,
    );
  }

  // ════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════
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
              _buildHeader(),

              // ── Step Indicator ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildStepIndicator(),
              ),

              // ── Step Content ──────────────────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _currentStep == 0
                    ? () => Navigator.pop(context)
                    : _previousStep,
              ),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join the AgriLink community',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < _totalSteps - 1 ? 4 : 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? kPrimaryGreen
                              : isActive
                                  ? kAccentGreen
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _stepLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? kPrimaryGreen
                        : isCompleted
                            ? kPrimaryGreen.withOpacity(0.7)
                            : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2PhoneOtp();
      case 2:
        return _buildStep3ValidId();
      case 3:
        return _buildStep4SecurityLocation();
      default:
        return const SizedBox.shrink();
    }
  }

  // ════════════════════════════════════════════════
  // STEP 1: Personal Information
  // ════════════════════════════════════════════════
  Widget _buildStep1PersonalInfo() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info Section
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Juan Dela Cruz',
            icon: Icons.person_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your full name';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Birthdate
          GestureDetector(
            onTap: _pickBirthdate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'Select your birthdate',
                  prefixIcon: const Icon(Icons.cake_outlined, color: kPrimaryGreen),
                  suffixIcon: const Icon(Icons.calendar_today, color: kPrimaryGreen, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: TextEditingController(
                  text: _selectedBirthdate != null
                      ? DateFormat('MMMM dd, yyyy').format(_selectedBirthdate!)
                      : '',
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Phone Number
          _buildField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '09XXXXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your phone number';
              if (v.length < 11) return 'Phone number must be at least 11 digits';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Next button
          _buildNextButton('Continue'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // STEP 2: Phone OTP Verification
  // ════════════════════════════════════════════════
  Widget _buildStep2PhoneOtp() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Phone icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_android, color: kPrimaryGreen, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Verify Your Phone',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send a 6-digit code to',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _phoneController.text.trim(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryGreen),
          ),
          const SizedBox(height: 28),

          if (!_otpSent) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sendOtp,
                icon: const Icon(Icons.send, size: 20),
                label: const Text('Send OTP Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          if (_otpSent && !_otpVerified) ...[
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
              decoration: InputDecoration(
                hintText: '• • • • • •',
                hintStyle: TextStyle(color: Colors.grey[300], fontSize: 28, letterSpacing: 12),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Didn't receive the code? ", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                GestureDetector(
                  onTap: _sendOtp,
                  child: const Text(
                    'Resend',
                    style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNextButton('Verify & Continue'),
          ],

          if (_otpVerified) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kLightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: kPrimaryGreen, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Phone Verified!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your phone number has been verified successfully.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildNextButton('Continue'),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // STEP 3: Valid ID
  // ════════════════════════════════════════════════
  Widget _buildStep3ValidId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identity Verification',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a valid government-issued ID for verification',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 20),

        // ID Type Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedIdType,
          decoration: const InputDecoration(
            labelText: 'ID Type',
            prefixIcon: Icon(Icons.badge_outlined, color: kPrimaryGreen),
          ),
          hint: const Text('Select ID Type'),
          items: _idTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (val) => setState(() => _selectedIdType = val),
        ),
        const SizedBox(height: 20),

        // ID Image Upload
        const Text(
          'ID Photo',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 10),

        if (_idImageBytes == null)
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: kLightGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kPrimaryGreen.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: kPrimaryGreen, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to upload or take a photo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kPrimaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gallery or Camera',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryGreen.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _idImageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // Re-upload button
                    GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
                          ],
                        ),
                        child: const Icon(Icons.refresh, color: kPrimaryGreen, size: 20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Remove button
                    GestureDetector(
                      onTap: () => setState(() {
                        _idImageBytes = null;
                        _idFileName = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
                          ],
                        ),
                        child: Icon(Icons.close, color: Colors.red[600], size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Success indicator
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Photo added', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 28),
        _buildNextButton('Continue'),
      ],
    );
  }

  // ════════════════════════════════════════════════
  // STEP 4: Security & Location
  // ════════════════════════════════════════════════
  Widget _buildStep4SecurityLocation() {
    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          const Text(
            'Location',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLocation,
            decoration: const InputDecoration(
              labelText: 'Location / Barangay',
              prefixIcon: Icon(Icons.location_on_outlined, color: kPrimaryGreen),
            ),
            hint: const Text('Select Barangay in Bogo City'),
            items: _barangays.map((b) {
              return DropdownMenuItem(value: b, child: Text(b));
            }).toList(),
            onChanged: (val) => setState(() => _selectedLocation = val),
            validator: (v) => v == null ? 'Please select a barangay' : null,
          ),
          const SizedBox(height: 22),

          // Security
          const Text(
            'Security',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _passwordController,
            label: '4-Digit PIN',
            hint: '••••',
            icon: Icons.lock_outlined,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your 4-digit PIN';
              if (v.length != 4) return 'PIN must be exactly 4 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _confirmPasswordController,
            label: 'Confirm 4-Digit PIN',
            hint: '••••',
            icon: Icons.lock_outline,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscure: _obscureConfirmPassword,
            showToggle: true,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your PIN';
              if (v != _passwordController.text) return 'PINs do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Already have account
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  children: const [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────
  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }


}
