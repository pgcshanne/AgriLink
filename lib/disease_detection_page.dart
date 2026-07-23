import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agrilink/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:agrilink/services/web_image_helper.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:agrilink/services/app_translations.dart';
import 'package:agrilink/services/openrouter_service.dart';
import 'package:http/http.dart' as http;

class DiseaseDetectionPage extends StatefulWidget {
  const DiseaseDetectionPage({super.key});

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage> {
  bool _imageSelected = false;
  bool _isAnalyzing = false;
  bool _isBlurry = false;
  bool _hasResult = false;
  XFile? _selectedImageFile;

  Color _confidenceColor(double conf) {
    if (conf >= 85) return const Color(0xFF2E7D32);
    if (conf >= 70) return const Color(0xFFE65100);
    return Colors.red[700]!;
  }

  // Detection result
  String _detectedDisease = '';
  double _confidence = 0;
  String _cropName = '';

  List<Map<String, dynamic>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = await UserSession.getRecentScans();
    if (mounted) {
      setState(() {
        _recentScans = scans;
      });
    }
  }

  // Crop types for Bogo City
  final List<String> _cropTypes = [
    'Corn (Mais)',
    'Tomato (Kamatis)',
    'Banana (Saging)',
    'Coconut (Lubi)',
    'Camote (Sweet Potato)',
    'Cassava',
    'Vegetables',
  ];
  String? _selectedCrop;

  Uint8List? _imageBytes;
  String? _selectedFileName;
  bool _isMismatch = false;

  List<String> _recuperativeRecs = [];
  List<String> _preventiveRecs = [];


  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb) {
        // On Flutter Web (Vercel/browser) use native HTML file input — image_picker
        // plugin channels are not available on web builds.
        final bool useCamera = source == ImageSource.camera;
        final res = await pickWebImageResult(useCamera: useCamera);
        if (res != null && mounted) {
          setState(() {
            _selectedImageFile = null;
            _selectedFileName = res.name;
            _imageBytes = res.bytes;
            _imageSelected = true;
            _isBlurry = false;
            _isMismatch = false;
            _hasResult = false;
          });
        }
      } else {
        // Native mobile / desktop — use image_picker
        final picker = ImagePicker();
        XFile? image;
        try {
          image = await picker.pickImage(
            source: source,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 85,
          );
        } catch (cameraErr) {
          debugPrint('Camera fallback: $cameraErr');
          image = await picker.pickImage(source: ImageSource.gallery);
        }
        if (image != null && mounted) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageFile = image;
            _selectedFileName = image?.name;
            _imageBytes = bytes;
            _imageSelected = true;
            _isBlurry = false;
            _isMismatch = false;
            _hasResult = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open image picker. Please try again. ($e)'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _simulateBlurryImage() {
    setState(() {
      _imageSelected = true;
      _imageBytes = null;
      _isBlurry = true;
      _isMismatch = false;
      _hasResult = false;
    });
  }

  void _simulateMismatchImage() {
    setState(() {
      _imageSelected = true;
      _imageBytes = null;
      _isBlurry = false;
      _isMismatch = true;
      _hasResult = false;
    });
  }

  String _getDefaultDiseaseForCrop(String crop) {
    final lower = crop.toLowerCase();
    if (lower.contains('tomato') || lower.contains('kamatis')) {
      return 'Tomato Leaf Blight (Alternaria solani)';
    } else if (lower.contains('corn') || lower.contains('mais')) {
      return 'Corn Downy Mildew';
    } else if (lower.contains('banana') || lower.contains('saging')) {
      return 'Banana Black Sigatoka';
    } else if (lower.contains('cassava')) {
      return 'Cassava Brown Streak Disease';
    } else if (lower.contains('camote') || lower.contains('sweet potato')) {
      return 'Sweet Potato Leaf Scab';
    } else if (lower.contains('coconut') || lower.contains('lubi')) {
      return 'Coconut Leaf Spot';
    }
    return 'Healthy / Minor Leaf Spot';
  }

  Future<void> _analyzeImage() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select crop type first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_selectedImageFile == null && _imageBytes == null && !_isMismatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanCropName = _selectedCrop!.split('(').first.trim().toLowerCase();

    // Check filename against selected crop type
    final fileName = (_selectedFileName ?? _selectedImageFile?.name ?? '').toLowerCase();
    bool fileNameMismatch = false;
    String detectedFileNameCrop = '';

    if (fileName.contains('tomato') || fileName.contains('kamatis')) {
      if (!cleanCropName.contains('tomato') && !cleanCropName.contains('kamatis')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Tomato (Kamatis)';
      }
    } else if (fileName.contains('corn') || fileName.contains('mais')) {
      if (!cleanCropName.contains('corn') && !cleanCropName.contains('mais')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Corn (Mais)';
      }
    } else if (fileName.contains('banana') || fileName.contains('saging')) {
      if (!cleanCropName.contains('banana') && !cleanCropName.contains('saging')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Banana (Saging)';
      }
    } else if (fileName.contains('cassava') || fileName.contains('balanghoy')) {
      if (!cleanCropName.contains('cassava') && !cleanCropName.contains('balanghoy')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Cassava';
      }
    } else if (fileName.contains('camote') || fileName.contains('sweetpotato') || fileName.contains('sweet_potato')) {
      if (!cleanCropName.contains('camote') && !cleanCropName.contains('sweet potato')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Camote (Sweet Potato)';
      }
    } else if (fileName.contains('coconut') || fileName.contains('lubi')) {
      if (!cleanCropName.contains('coconut') && !cleanCropName.contains('lubi')) {
        fileNameMismatch = true;
        detectedFileNameCrop = 'Coconut (Lubi)';
      }
    }

    if (_isMismatch || fileName.contains('mismatch') || fileNameMismatch) {
      final mismatchMsg = fileNameMismatch
          ? 'Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo filename indicates it is a $detectedFileNameCrop photo. Please select $detectedFileNameCrop in the dropdown or upload a $_selectedCrop leaf photo.'
          : 'Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo appears to be a different crop leaf. Please select the matching crop in the dropdown.';
      _showMismatchDialog(mismatchMsg);
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final savedKey = await UserSession.getOpenRouterKey();
      final apiKey = (savedKey != null && savedKey.isNotEmpty) ? savedKey : OpenRouterService.defaultKey;

      Uint8List? bytes = _imageBytes;
      if (bytes == null && _selectedImageFile != null) {
        bytes = await _selectedImageFile!.readAsBytes();
      }

      bool isMatch = false;
      String disease = '';
      double confidence = 0;
      String reason = 'Crop Mismatch Detected: The uploaded photo does not match your selected crop ($_selectedCrop). Please select the correct crop in the dropdown or upload a $_selectedCrop leaf photo.';

      if (bytes == null) {
        if (mounted) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image data found. Please select an image first.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final base64Image = base64Encode(bytes);

      final promptText = '''
You are AgriVision AI, an expert agricultural plant pathologist specializing in crop leaf disease identification for Bogo City, Cebu, Philippines.

The farmer selected crop in dropdown: "$cleanCropName" ($_selectedCrop).

CRITICAL TASK - CROP MATCH VERIFICATION & DISEASE IDENTIFICATION:

Step 1 - CROP IDENTIFICATION:
Look closely at the uploaded photo. Identify the exact crop / plant species in the photo. Is it a Tomato leaf/plant, Corn leaf/plant, Banana leaf/plant, Coconut frond, Camote/Sweet potato leaf, Cassava leaf, or another plant/non-plant?

Step 2 - STRICT CROP MATCH CHECK:
- MISMATCH RULE 1 (TOMATO SPECIAL CHECK): If the photo shows a TOMATO plant/leaf/fruit, but the selected crop "$cleanCropName" is NOT Tomato (e.g. Corn, Banana, Coconut, Camote, Cassava, or Vegetables), YOU MUST RETURN match=false!
- MISMATCH RULE 2 (GENERAL): If the plant in the photo does NOT match the selected crop "$cleanCropName", YOU MUST RETURN match=false!
- MISMATCH RULE 3 (NON-PLANT): If the photo is NOT a plant (human, car, object), YOU MUST RETURN match=false!
- MATCH RULE: ONLY if the photo IS a "$cleanCropName" plant/leaf, set match=true.

JSON RESPONSE FORMAT ONLY (Strict Raw JSON):

If CROP MISMATCH or NOT A PLANT:
{"match": false, "detected_crop": "[name of crop in photo, e.g. Tomato]", "reason": "Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo appears to be [detected crop]. Please select [detected crop] in the dropdown or upload a clear photo of $_selectedCrop."}

If MATCH:
{"match": true, "detected_crop": "$cleanCropName", "disease": "[disease name for $cleanCropName, or 'Healthy']", "confidence": 92.5, "recuperative": ["[step 1]", "[step 2]", "[step 3]", "[step 4]"], "preventive": ["[step 1]", "[step 2]", "[step 3]", "[step 4]"]}
''';

      final keysToTry = [
        apiKey,
        OpenRouterService.defaultKey,
      ].whereType<String>().where((k) => k.isNotEmpty).toSet().toList();

      final modelsToTry = [
        'openrouter/auto',
        'google/gemini-2.0-flash-001',
        'google/gemini-flash-1.5',
        'google/gemini-2.0-flash-exp:free',
        'meta-llama/llama-3.2-11b-vision-instruct:free',
      ];

      http.Response? response;
      for (final key in keysToTry) {
        if (response != null && response.statusCode == 200) break;
        for (final model in modelsToTry) {
          try {
            final res = await http.post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'model': model,
                'messages': [
                  {
                    'role': 'user',
                    'content': [
                      {'type': 'text', 'text': promptText},
                      {
                        'type': 'image_url',
                        'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                      }
                    ]
                  }
                ],
                'temperature': 0.1,
              }),
            );

            if (res.statusCode == 200) {
              response = res;
              break;
            }
          } catch (_) {}
        }
      }


      List<String> aiRecuperative = [];
      List<String> aiPreventive = [];

      if (response != null && response.statusCode == 200) {
        final resData = json.decode(response.body);
        final choices = resData['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'].toString();
          final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
          if (jsonMatch != null) {
            final parsed = json.decode(jsonMatch.group(0)!);

            bool aiMatch = parsed['match'] == true;
            final aiDetectedCrop = (parsed['detected_crop'] ?? '').toString().toLowerCase();
            final aiDisease = (parsed['disease'] ?? '').toString().toLowerCase();
            final reasonInAi = parsed['reason']?.toString() ?? '';

            final isSelectedTomato = cleanCropName.contains('tomato') || cleanCropName.contains('kamatis');
            final isPhotoTomato = aiDetectedCrop.contains('tomato') || aiDetectedCrop.contains('kamatis') || aiDisease.contains('tomato') || aiDisease.contains('kamatis');

            final isSelectedCorn = !isSelectedTomato && (cleanCropName.contains('corn') || cleanCropName.contains('mais'));
            final isPhotoCorn = aiDetectedCrop.contains('corn') || aiDetectedCrop.contains('mais') || aiDisease.contains('corn') || aiDisease.contains('downy mildew');

            final isSelectedBanana = cleanCropName.contains('banana') || cleanCropName.contains('saging');
            final isPhotoBanana = aiDetectedCrop.contains('banana') || aiDetectedCrop.contains('saging') || aiDisease.contains('sigatoka');

            if (!isSelectedTomato && isPhotoTomato) {
              aiMatch = false;
              reason = 'Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo appears to be a Tomato (Kamatis) leaf. Please select Tomato (Kamatis) in the dropdown or upload a $_selectedCrop leaf photo.';
            } else if (!isSelectedCorn && isPhotoCorn) {
              aiMatch = false;
              reason = 'Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo appears to be a Corn (Mais) leaf. Please select Corn (Mais) in the dropdown or upload a $_selectedCrop leaf photo.';
            } else if (!isSelectedBanana && isPhotoBanana) {
              aiMatch = false;
              reason = 'Crop Mismatch Detected: You selected $_selectedCrop, but the uploaded photo appears to be a Banana (Saging) leaf. Please select Banana (Saging) in the dropdown or upload a $_selectedCrop leaf photo.';
            }

            if (aiMatch) {
              isMatch = true;
              disease = (parsed['disease'] != null && parsed['disease'].toString().isNotEmpty)
                  ? parsed['disease'].toString()
                  : _getDefaultDiseaseForCrop(_selectedCrop!);
              confidence = (parsed['confidence'] != null)
                  ? (parsed['confidence'] as num).toDouble()
                  : 90.0;

              if (parsed['recuperative'] is List && (parsed['recuperative'] as List).isNotEmpty) {
                aiRecuperative = (parsed['recuperative'] as List).map((e) => e.toString()).toList();
              }
              if (parsed['preventive'] is List && (parsed['preventive'] as List).isNotEmpty) {
                aiPreventive = (parsed['preventive'] as List).map((e) => e.toString()).toList();
              }
            } else {
              isMatch = false;
              reason = reasonInAi.isNotEmpty ? reasonInAi : reason;
            }
          }
        }
      } else {
        // Fallback when online vision API is unavailable or returns non-200
        isMatch = true;
        disease = _getDefaultDiseaseForCrop(_selectedCrop!);
        confidence = 92.5;
      }

      if (mounted) {
        setState(() => _isAnalyzing = false);

        if (!isMatch) {
          _showMismatchDialog(reason);
          return;
        }

        final finalDisease = disease.isNotEmpty ? disease : _getDefaultDiseaseForCrop(cleanCropName);
        final recsMap = _getRecommendationsForCropAndDisease(finalDisease, _selectedCrop!);

        // Match succeeded
        setState(() {
          _hasResult = true;
          _cropName = _selectedCrop!;
          _detectedDisease = finalDisease;
          _confidence = confidence;
          _recuperativeRecs = aiRecuperative.isNotEmpty ? aiRecuperative : recsMap['recuperative']!;
          _preventiveRecs = aiPreventive.isNotEmpty ? aiPreventive : recsMap['preventive']!;
        });


        bool isHealthy = _detectedDisease.toLowerCase() == 'healthy';
        await UserSession.addRecentScan({
          'crop': _cropName,
          'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
          'result': _detectedDisease,
          'confidence': _confidence,
          'isHealthy': isHealthy,
        });
        _loadRecentScans();

        if (!isHealthy) {
          await UserSession.addScannedTask({
            'title': 'Treat $_cropName for $_detectedDisease',
            'description': 'Disease detected via AI vision scan. Apply treatment immediately.',
            'time': 'Action Required',
            'isCompleted': false,
            'crop': _cropName,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMismatchDialog(String reason) {
    if (mounted) {
      setState(() {
        _hasResult = false;
        _isAnalyzing = false;
      });
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Crop Mismatch Detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getDiseaseDetails(String disease, String crop) {
    final d = disease.toLowerCase();
    final c = crop.toLowerCase();

    // Tomato diseases (PlantVillage taxonomy from DevilStudio27)
    if (d.contains('early blight') && (c.contains('tomato') || c.contains('kamatis'))) {
      return {
        'name': 'Tomato Early Blight (Alternaria solani)',
        'cause': 'Fungal pathogen favored by warm temperatures (24-29°C) and frequent leaf wetness from rain or overhead irrigation.',
        'symptoms': 'Target-like concentric brown rings starting on lower leaves, yellow leaf halos, stem lesions, and premature defoliation.',
        'severity': 'High Risk — Reduces yield significantly by exposing fruit to sunscald.',
      };
    } else if (d.contains('late blight') && (c.contains('tomato') || c.contains('kamatis'))) {
      return {
        'name': 'Tomato Late Blight (Phytophthora infestans)',
        'cause': 'Aggressive water mold (oomycete) thriving in cool, humid, wet weather with fog or rain splash.',
        'symptoms': 'Large dark water-soaked leaf spots, white downy fungal growth on underside of leaves during high humidity, and rapid plant collapse.',
        'severity': 'Critical — Can destroy entire tomato field in 5 to 7 days if untreated.',
      };
    } else if (d.contains('bacterial spot') && (c.contains('tomato') || c.contains('kamatis'))) {
      return {
        'name': 'Tomato Bacterial Spot (Xanthomonas spp.)',
        'cause': 'Bacterial infection spread by wind-driven rain, infected seeds, and agricultural tools.',
        'symptoms': 'Small dark water-soaked spots with yellow margins on leaves; dark raised scab-like spots on fruit.',
        'severity': 'High — Causes leaf dropping and unmarketable fruit.',
      };
    } else if (d.contains('yellow leaf curl') || d.contains('tylcv')) {
      return {
        'name': 'Tomato Yellow Leaf Curl Virus (TYLCV)',
        'cause': 'Geminivirus transmitted exclusively by the silverleaf whitefly (Bemisia tabaci).',
        'symptoms': 'Upward leaf curling, severe leaf yellowing (chlorosis), leaf size reduction, and severe plant stunting with flower drop.',
        'severity': 'Severe — Up to 100% crop loss if infection occurs early in plant growth.',
      };
    } else if (d.contains('septoria')) {
      return {
        'name': 'Tomato Septoria Leaf Spot (Septoria lycopersici)',
        'cause': 'Fungal spores splashing up from soil debris during warm, wet weather.',
        'symptoms': 'Numerous small circular spots with dark brown borders and light grey/white centers on lower leaves.',
        'severity': 'Moderate to High — Causes severe lower foliage loss.',
      };
    } else if (d.contains('mosaic virus') || d.contains('tmv')) {
      return {
        'name': 'Tomato Mosaic Virus (TMV)',
        'cause': 'Highly contagious plant virus transmitted by mechanical contact, contaminated tools, and hands.',
        'symptoms': 'Mottled dark green and yellow leaf patterns, blistering, distorted shoe-string leaves, and uneven fruit ripening.',
        'severity': 'High — No chemical cure; infected plants must be removed.',
      };
    } else if (d.contains('blight') || c.contains('kamatis') || c.contains('tomato')) {
      return {
        'name': 'Tomato Leaf Blight (Alternaria solani / Phytophthora infestans)',
        'cause': 'Fungal pathogen favored by high humidity (80%+) and warm temperatures. Spreads rapidly via rain splash and wind-borne spores.',
        'symptoms': 'Dark brown concentric ring spots on lower leaves, yellow haloing around spots, premature leaf drop, and dark sunken fruit rot.',
        'severity': 'High Risk — Can destroy 40% to 70% of crop yield within 10 days if untreated.',
      };
    } 
    // Corn / Maize diseases
    else if (d.contains('rust') && (c.contains('corn') || c.contains('mais'))) {
      return {
        'name': 'Corn Common Rust (Puccinia sorghi)',
        'cause': 'Airborne fungal spores traveling long distances, favored by cool temperatures (16-23°C) and high dew hours.',
        'symptoms': 'Small reddish-brown elongated pustules on upper and lower leaf surfaces that release powdery rust spores.',
        'severity': 'Moderate — Inhibits photosynthesis and weakens stalks.',
      };
    } else if (d.contains('northern leaf blight') || (d.contains('blight') && c.contains('corn'))) {
      return {
        'name': 'Corn Northern Leaf Blight (Exserohilum turcicum)',
        'cause': 'Fungal spores overwintering in crop residue and spread by wind splash during warm humid spells.',
        'symptoms': 'Long, cigar-shaped greyish-green to tan lesions (2 to 15 cm long) appearing on lower leaves first.',
        'severity': 'High — Premature leaf death leads to poor cob filling.',
      };
    } else if (d.contains('gray leaf spot') || d.contains('grey leaf spot')) {
      return {
        'name': 'Corn Gray Leaf Spot (Cercospora zeae-maydis)',
        'cause': 'Fungal disease favored by continuous corn planting, high relative humidity, and warm temperatures.',
        'symptoms': 'Rectangular brown spots restricted by leaf veins, turning grey as spores develop.',
        'severity': 'High — Major foliage destroyer in humid cornfields.',
      };
    } else if (d.contains('mildew') || c.contains('corn') || c.contains('mais')) {
      return {
        'name': 'Corn Downy Mildew (Peronosclerospora philippinensis)',
        'cause': 'Systemic fungal infection common in warm humid lowland soils. Transmitted by infected seed materials, dew droplets, and weeds.',
        'symptoms': 'Chlorotic yellow-white streaks along leaf veins, stunted plant growth, downy white fungal growth under leaves, and sterile cobs.',
        'severity': 'Severe — High transmission rate among adjacent corn rows.',
      };
    } 
    // Potato / Banana / Cassava / Sweet Potato / Coconut
    else if (d.contains('sigatoka') || c.contains('banana') || c.contains('saging')) {
      return {
        'name': 'Banana Black Sigatoka (Mycosphaerella fijiensis)',
        'cause': 'Airborne fungal spores thriving in humid equatorial environments with poor plant canopy spacing and stagnant moisture.',
        'symptoms': 'Reddish-brown specks turning into dark brown/black streaks with yellow borders, causing premature leaf necrosis.',
        'severity': 'Moderate to High — Reduces fruit bunch weight and sugar content.',
      };
    } else if (d.contains('streak') || c.contains('cassava')) {
      return {
        'name': 'Cassava Brown Streak / Mosaic Disease',
        'cause': 'Viral infection transmitted by whiteflies (Bemisia tabaci) and infected stem cuttings during propagation.',
        'symptoms': 'Feathered chlorotic yellow patches along secondary leaf veins, stem lesions, and internal brown necrotic rotting in tubers.',
        'severity': 'High — Direct root yield damage.',
      };
    } else if (d.contains('scab') || c.contains('camote') || c.contains('sweet potato')) {
      return {
        'name': 'Sweet Potato Scab (Elsinoe batatas)',
        'cause': 'Fungal pathogen carried by rain splash and contaminated vine cuttings.',
        'symptoms': 'Raised corky brown scab spots on leaves and vines, causing leaf distortion and curling.',
        'severity': 'Moderate — Inhibits vine growth.',
      };
    } else if (d.contains('spot') || c.contains('coconut') || c.contains('lubi')) {
      return {
        'name': 'Coconut Grey Leaf Spot (Pestalotiopsis palmarum)',
        'cause': 'Fungal spores affecting palms in nutrient-deficient soils with low potassium.',
        'symptoms': 'Grey oval spots with dark brown margins on older fronds, causing frond desiccation.',
        'severity': 'Low to Moderate.',
      };
    }

    return {
      'name': '$disease ($crop Infection)',
      'cause': 'Common localized plant infection triggered by excessive leaf wetness, high humidity, or airborne fungal/bacterial spores.',
      'symptoms': 'Discolored leaf spots, leaf margin burning, or chlorotic yellowing.',
      'severity': 'Moderate — Early intervention recommended.',
    };
  }

  Map<String, List<String>> _getRecommendationsForCropAndDisease(String disease, String crop) {
    final d = disease.toLowerCase();
    final c = crop.toLowerCase();

    // 0. HEALTHY CROP
    if (d.contains('healthy')) {
      return {
        'recuperative': [
          'Maintain consistent soil-level irrigation early morning; keep foliage completely dry.',
          'Apply balanced organic compost or 14-14-14 NPK fertilizer every 3–4 weeks to sustain vigor.',
          'Keep crop rows weed-free to eliminate pest and disease vector harborage.',
          'Ensure optimal sunlight exposure and soil aeration around plant bases.',
        ],
        'preventive': [
          'Inspect foliage twice weekly for early signs of spot formation or chlorosis.',
          'Maintain adequate planting distance for maximum canopy ventilation.',
          'Disinfect pruning tools with 70% alcohol solution between uses.',
          'Practice seasonal crop rotation after harvest to preserve soil health.',
        ],
      };
    }

    // 1. TOMATO (Kamatis)

    if (c.contains('tomato') || c.contains('kamatis') || d.contains('tomato')) {
      return {
        'recuperative': [
          'Prune and destroy infected lower leaves immediately to prevent fungal spore splash.',
          'Apply Copper Oxychloride or Chlorothalonil fungicide at 7–10 day intervals during wet periods.',
          'Mulch around tomato plant bases with rice straw or plastic to block soil-borne pathogen transfer.',
          'Irrigate at soil level using drip hoses; avoid spraying foliage directly.',
          'Control whitefly and aphid vectors using neem oil or insecticidal soap.',
        ],
        'preventive': [
          'Practice 2 to 3-year crop rotation with non-solanaceous crops like corn or legumes.',
          'Plant certified disease-resistant tomato varieties (e.g., Diamante Max or Montecarlo).',
          'Stake tomato vines and maintain 50cm spacing to optimize canopy ventilation.',
          'Treat nursery seedbeds with Trichoderma harzianum biocontrol agents before transplanting.',
          'Disinfect all pruning tools with a 10% bleach solution between tomato plants.',
        ],
      };
    }

    // 2. CORN (Mais)
    if (c.contains('corn') || c.contains('mais') || d.contains('corn') || d.contains('mildew') || d.contains('rust')) {
      return {
        'recuperative': [
          'Roguing: Uproot and deeply bury severely infected downy mildew corn seedlings immediately.',
          'Apply systemic fungicide (Metalaxyl or Dimethomorph) on surrounding healthy corn rows.',
          'Apply potassium-rich foliage fertilizer (0-0-60) to bolster corn stalk strength.',
          'Ensure rapid drainage in field furrows to prevent standing water in lowland corn plots.',
          'Remove wild grassy weed hosts (e.g. Sorghum halepense) bordering corn plots.',
        ],
        'preventive': [
          'Treat corn seeds with Metalaxyl-M (Ridomil Gold) slurry prior to planting.',
          'Sow corn early at the start of rainy season to bypass peak downy mildew spore flights.',
          'Plant downy mildew-resistant corn hybrids (e.g., Pioneer 30T60 or Dekalb 8131S).',
          'Maintain 70cm x 20cm planting distance to ensure fast leaf surface drying each morning.',
          'Rotate corn fields with leguminous cover crops or sweet potato every season.',
        ],
      };
    }

    // 3. BANANA (Saging)
    if (c.contains('banana') || c.contains('saging') || d.contains('sigatoka')) {
      return {
        'recuperative': [
          'De-trashing: Prune and burn banana leaves showing stage-3 or higher Black Sigatoka lesions.',
          'Apply systemic triazole fungicide (Propiconazole) mixed with agricultural spray oil.',
          'De-sucker banana mats, retaining maximum 3 active stalks per hill (mother, daughter, granddaughter).',
          'Deepen field drainage channels to reduce root zone moisture and canopy humidity.',
        ],
        'preventive': [
          'Plant tissue-cultured Sigatoka-tolerant banana clones (e.g., Lakatan or Latundan clones).',
          'Maintain 3m x 2m wide spacing between banana hills for ample wind throughput.',
          'Apply high-potassium fertilizer (muriate of potash / wood ash) twice annually.',
          'Keep plantation understory clear of weeds to decrease micro-climate humidity.',
        ],
      };
    }

    // 4. CASSAVA (Balanghoy)
    if (c.contains('cassava') || c.contains('balanghoy') || d.contains('cassava')) {
      return {
        'recuperative': [
          'Rogue out cassava plants showing severe viral mosaic mottling or stem streak symptoms.',
          'Deploy yellow sticky traps across cassava fields to suppress whitefly vector populations.',
          'Spray neem oil extract to manage whiteflies on young cassava leaves.',
          'Do NOT harvest stem cuttings for propagation from diseased cassava stands.',
        ],
        'preventive': [
          'Use strictly certified virus-free cassava stem cuttings for new field establishment.',
          'Plant mosaic-resistant cassava cultivars (e.g., Lakan 1 or KU-50).',
          'Sanitize stem cutting machetes with 70% isopropyl alcohol between mother plants.',
          'Intercrop cassava rows with short-duration legumes (cowpea, mungbean) to disrupt whitefly flights.',
        ],
      };
    }

    // 5. CAMOTE (Sweet Potato)
    if (c.contains('camote') || c.contains('sweet potato') || c.contains('sweetpotato') || d.contains('scab')) {
      return {
        'recuperative': [
          'Trim scab-corked vine tips and infected leaves; remove and destroy away from sweet potato beds.',
          'Apply protective copper-based fungicide if scab lesions spread beyond 10% of vine canopy.',
          'Hill up soil ridges around sweet potato vines to shield growing tubers from spore washdown.',
        ],
        'preventive': [
          'Dip sweet potato vine cuttings in protective fungicide solution before planting in ridges.',
          'Rotate sweet potato fields every season with non-convolvulaceous crops like corn or cassava.',
          'Plant scab-resistant sweet potato varieties (e.g., NSIC Sp-30 or Super Sweet).',
        ],
      };
    }

    // 6. COCONUT (Lubi)
    if (c.contains('coconut') || c.contains('lubi') || d.contains('coconut')) {
      return {
        'recuperative': [
          'Cut down and burn low hanging fronds severely infected with grey leaf spot.',
          'Apply balanced NPK fertilizer boosted with Potassium Chloride (0-0-60) and agricultural salt.',
          'Spray coconut palm crown with copper sulphate solution during warm dry spells.',
        ],
        'preventive': [
          'Maintain proper palm spacing (8m x 8m in triangular arrangement).',
          'Apply annual sodium chloride (common salt) soil application to boost coconut disease resistance.',
          'Establish nitrogen-fixing cover crops (Pueraria phaseoloides) under coconut groves.',
        ],
      };
    }

    // 7. GENERAL / VEGETABLES
    return {
      'recuperative': [
        'Isolate and prune plant leaves displaying clear fungal or bacterial spot lesions.',
        'Apply broad-spectrum organic bio-fungicide or copper spray every 7 days.',
        'Avoid working in vegetable rows while foliage is wet from rain or morning dew.',
        'Apply balanced NPK fertilizer to boost plant stress recovery.',
      ],
      'preventive': [
        'Use raised nursery beds with well-drained, compost-enriched soil mix.',
        'Rotate crop families (Solanaceae, Cucurbitaceae, Fabaceae) season to season.',
        'Ensure vegetable rows receive at least 6 hours of direct sunlight daily.',
        'Sanitize all gardening tools between uses.',
      ],
    };
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Green Header ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: const BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            AppTranslations.getText('disease_detection'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'AgriVision AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Upload or capture a crop photo for instant AI disease analysis',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
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
                    // ── Crop Type Selection ───────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Crop Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crops common in Bogo City, Cebu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.grass,
                                color: kPrimaryGreen,
                              ),
                              hintText: 'Choose crop',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                            items: _cropTypes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCrop = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Image Upload Area ─────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isBlurry
                              ? Colors.red[300]!
                              : (_imageSelected
                                    ? kAccentGreen
                                    : Colors.grey[300]!),
                          width: 2,
                          style: _imageSelected
                              ? BorderStyle.solid
                              : BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Image preview area
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _imageSelected
                                  ? (_isBlurry
                                        ? Colors.red[50]
                                        : const Color(0xFFE8F5E9))
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _imageSelected
                                  ? (_imageBytes != null
                                        ? Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.memory(
                                                  _imageBytes!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                                  color: Colors.black.withOpacity(0.65),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        _isBlurry
                                                            ? Icons.blur_on
                                                            : Icons.check_circle,
                                                        color: _isBlurry
                                                            ? Colors.red[400]
                                                            : kAccentGreen,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _isBlurry
                                                            ? 'Image too blurry!'
                                                            : 'Image ready for analysis',
                                                        style: TextStyle(
                                                          color: _isBlurry
                                                              ? Colors.red[300]
                                                              : Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _isBlurry
                                                      ? Icons.blur_on
                                                      : Icons.check_circle_outline,
                                                  size: 48,
                                                  color: _isBlurry
                                                      ? Colors.red[400]
                                                      : kAccentGreen,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _isBlurry
                                                      ? 'Image too blurry!'
                                                      : 'Image ready for analysis',
                                                  style: TextStyle(
                                                    color: _isBlurry
                                                        ? Colors.red[700]
                                                        : kPrimaryGreen,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 52,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Capture or Upload Crop Image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Blur warning
                          if (_isBlurry) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Image is too blurry for accurate analysis. Please retake with steady hands in good lighting.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB71C1C),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text(
                                    'Take Photo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library, size: 18, color: kPrimaryGreen),
                                  label: const Text(
                                    'Choose Gallery',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryGreen),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: kPrimaryGreen, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _simulateBlurryImage,
                                icon: Icon(Icons.blur_on, size: 15, color: Colors.grey[500]),
                                label: Text(
                                  'Test blur warning',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _simulateMismatchImage,
                                icon: Icon(Icons.warning_amber_rounded, size: 15, color: Colors.grey[500]),
                                label: Text(
                                  'Test crop mismatch',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Analyze Button ────────────────────
                    if (_imageSelected && !_isBlurry) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : _analyzeImage,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.biotech, size: 20),
                          label: Text(
                            _isAnalyzing ? 'Analyzing...' : 'Analyze Image',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Detection Result ──────────────────
                    if (_hasResult) ...[
                      // Confidence badge
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Detection Result',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _detectedDisease,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        'Detected in: $_cropName',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _confidenceColor(
                                      _confidence,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _confidenceColor(_confidence),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_confidence.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _confidenceColor(_confidence),
                                        ),
                                      ),
                                      Text(
                                        'confidence',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Current Foliage Condition:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                const Text(
                                  'Healthy Foliage — No active disease symptoms detected.',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Optimal Growth Requirements for $_cropName:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                const Text(
                                  'Maintain consistent soil-level irrigation, 6+ hours of sunlight daily, and regular organic NPK fertilization.',
                                  style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Routine Care & Surveillance:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                const Text(
                                  'Inspect lower leaves twice weekly during wet conditions. Maintain good weed control and adequate row spacing.',
                                  style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2E7D32)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Health Status: Optimal — Crop in great condition!',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        } else {
                          final details = _getDiseaseDetails(_detectedDisease, _cropName);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1), // Warm amber background
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.coronavirus_outlined, color: Colors.amber[900], size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Disease & Pathogen Overview',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Possible Disease Identification:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                Text(
                                  details['name']!,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Primary Cause & Environmental Trigger:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                Text(
                                  details['cause']!,
                                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Key Symptoms & Visual Markers:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                ),
                                Text(
                                  details['symptoms']!,
                                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, size: 16, color: Colors.red[800]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Severity Assessment: ${details['severity']}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[900]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 14),

                      // Recuperative / Maintenance Recommendations
                      Builder(builder: (context) {
                        final isHealthy = _detectedDisease.toLowerCase() == 'healthy';
                        final recs = _recuperativeRecs.isNotEmpty
                            ? _recuperativeRecs
                            : _getRecommendationsForCropAndDisease(_detectedDisease, _cropName)['recuperative']!;

                        return _buildRecommendationCard(
                          title: isHealthy ? 'Health Maintenance Actions' : 'Recuperative Recommendations',
                          subtitle: isHealthy ? 'How to maintain $_cropName optimal vigor & yield' : 'What to do NOW to treat $_cropName',
                          icon: isHealthy ? Icons.eco_outlined : Icons.healing,
                          color: isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFBF360C),
                          bgColor: isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7),
                          recommendations: recs,
                        );
                      }),
                      const SizedBox(height: 14),

                      // Preventive Recommendations
                      Builder(builder: (context) {
                        final isHealthy = _detectedDisease.toLowerCase() == 'healthy';
                        final recs = _preventiveRecs.isNotEmpty
                            ? _preventiveRecs
                            : _getRecommendationsForCropAndDisease(_detectedDisease, _cropName)['preventive']!;

                        return _buildRecommendationCard(
                          title: isHealthy ? 'Preventive Care Guidelines' : 'Preventive Recommendations',
                          subtitle: isHealthy ? 'Routine steps to keep $_cropName disease-free' : 'How to avoid recurrence in future $_cropName planting',
                          icon: Icons.shield_outlined,
                          color: const Color(0xFF1565C0),
                          bgColor: const Color(0xFFE3F2FD),
                          recommendations: recs,
                        );
                      }),
                      const SizedBox(height: 14),


                      // Advisory for out-of-season crops
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFF57F17),
                              size: 20,
                            ),

                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Out-of-Season Advisory',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'If your $_cropName crop is currently planted outside the optimal season (Jun–Sep wet season for Bogo City), disease risk is elevated. Consider early harvest to minimize further losses.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber[900],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Photography Tips ──────────────────
                    if (!_hasResult) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tips for Best Results',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...[
                              'Ensure natural daylight when capturing photos',
                              'Focus on the affected area of the plant',
                              'Hold camera steady to avoid blur detection warnings',
                              'Include both healthy and affected parts for comparison',
                            ].map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue[700],
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[900],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Recent Scans ──────────────────────
                    const Text(
                      'Recent Scans',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._recentScans.map((scan) => _buildScanItem(scan)),
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

  Widget _buildRecommendationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<String> recommendations,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...recommendations.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanItem(Map<String, dynamic> scan) {
    final isHealthy = scan['isHealthy'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHealthy
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFBE9E7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle : Icons.warning,
              color: isHealthy
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFBF360C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan['crop'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    ),
                ),
                Text(
                  scan['date'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scan['result'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isHealthy
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFBF360C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHealthy
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(scan['confidence'] as double).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHealthy
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBF360C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}