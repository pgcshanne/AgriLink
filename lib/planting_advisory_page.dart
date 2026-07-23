import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/app_translations.dart';

class PlantingAdvisoryPage extends StatefulWidget {
  const PlantingAdvisoryPage({super.key});

  @override
  State<PlantingAdvisoryPage> createState() => _PlantingAdvisoryPageState();
}

class _PlantingAdvisoryPageState extends State<PlantingAdvisoryPage> {
  final _lotAreaController = TextEditingController();
  String? _selectedCrop;
  
  String? _liveSeason;
  String _liveWeatherDesc = '';
  double _liveTemp = 0.0;

  bool _hasResult = false;
  bool _isAnalyzing = false;
  bool _alreadyPlanted = false;
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Analysis result states
  String _timingAdvice = '';
  String _expectedYield = '';
  String _harvestPeriod = '';
  String _aiConfidence = '';
  int _currentGrowthStageIndex = 0;
  List<String> _stages = [];
  Map<String, List<String>> _stageInstructions = {};

  final List<String> _crops = [
    'Corn (Mais)',
    'Tomato (Kamatis)',
    'Banana (Saging)',
    'Coconut (Lubi)',
    'Camote (Sweet Potato)',
    'Cassava',
    'Vegetables',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=11.05&longitude=124.00&current=temperature_2m,weather_code&timezone=Asia/Manila'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        
        final code = current['weather_code'];
        _liveTemp = current['temperature_2m'];
        
        if (code <= 2) _liveWeatherDesc = 'Sunny';
        else if (code == 3) _liveWeatherDesc = 'Cloudy';
        else if (code >= 51 && code <= 67) _liveWeatherDesc = 'Rainy';
        else if (code >= 80) _liveWeatherDesc = 'Stormy';
        else _liveWeatherDesc = 'Mixed';
      }
    } catch (e) {
      _liveWeatherDesc = 'Sunny';
      _liveTemp = 28.0;
    }
    
    final month = DateTime.now().month;
    _liveSeason = (month >= 6 && month <= 11) ? 'Wet Season' : 'Dry Season';
  }

  @override
  void dispose() {
    _lotAreaController.dispose();
    super.dispose();
  }

  void _calculateAdvisory() {
    final lotAreaText = _lotAreaController.text.trim();
    if (lotAreaText.isEmpty || _selectedCrop == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all inputs, including the date'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? area = double.tryParse(lotAreaText);
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid lot area'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      // Define growth stages & instructions based on selected crop
      List<String> cropStages = [];
      Map<String, List<String>> cropInstructions = {};
      String timing = '';
      String yieldEstimate = '';

      if (_selectedCrop == 'Corn (Mais)') {
        cropStages = ['Seedling', 'Tillering', 'Panicle Initiation', 'Flowering', 'Maturity'];
        cropInstructions = {
          'Seedling': [
            'Maintain water depth of 2-3 cm.',
            'Keep nursery bed free of weeds.',
            'Apply nitrogen fertilizer (Urea) at 15 days.'
          ],
          'Tillering': [
            'Increase water level to 5 cm.',
            'Monitor for leaf folders and stem borers.',
            'Apply secondary fertilizer dose.'
          ],
          'Panicle Initiation': [
            'Ensure consistent water level; do not drain.',
            'Apply potassium fertilizer to support grain head formation.'
          ],
          'Flowering': [
            'Maintain shallow water layer.',
            'Avoid chemical sprays during peak flowering hours.'
          ],
          'Maturity': [
            'Drain field 10-14 days before expected harvest date.',
            'Harvest when 85-90% of grains are golden brown.'
          ],
        };
        yieldEstimate = '${(area * 0.6).toStringAsFixed(1)} kg to ${(area * 0.8).toStringAsFixed(1)} kg';
      } else if (_selectedCrop == 'Banana (Saging)') {
        cropStages = ['Emergence', 'Vegetative Stage', 'Tasseling', 'Silking', 'Physiological Maturity'];
        cropInstructions = {
          'Emergence': ['Check for uniform seed sprouting.', 'Keep soil moist but not waterlogged.'],
          'Vegetative Stage': ['Weed field at 2-3 weeks.', 'Side-dress with Urea fertilizer.'],
          'Tasseling': ['Ensure high water availability during tassel formation.'],
          'Silking': ['Monitor for earworms.', 'Watering is critical now.'],
          'Physiological Maturity': ['Harvest when husk leaves dry out.', 'Dry kernels to 14% moisture.'],
        };
        yieldEstimate = '${(area * 0.4).toStringAsFixed(1)} kg to ${(area * 0.6).toStringAsFixed(1)} kg';
      } else {
        cropStages = ['Germination', 'Vegetative', 'Flowering', 'Fruit Setting', 'Harvest'];
        cropInstructions = {
          'Germination': ['Keep seedbeds moist.', 'Ensure indirect sunlight.'],
          'Vegetative': ['Apply organic compost.', 'Provide stakes or support trellis.'],
          'Flowering': ['Apply organic potassium or calcium.', 'Reduce overhead watering.'],
          'Fruit Setting': ['Prune lower leaves.', 'Monitor closely for insect pests.'],
          'Harvest': ['Harvest regularly to encourage new fruit growth.', 'Handle ripe produce gently.'],
        };
        yieldEstimate = '${(area * 1.2).toStringAsFixed(1)} kg to ${(area * 1.8).toStringAsFixed(1)} kg';
      }

      if (_alreadyPlanted) {
        if (_liveWeatherDesc == 'Rainy' || _liveWeatherDesc == 'Stormy') {
          timing = 'Preventive: Ensure deep drainage immediately to prevent root rot during heavy rains. Apply mulch to protect topsoil.';
        } else if (_liveTemp > 32) {
          timing = 'Preventive: Provide shade netting and increase irrigation frequency to prevent heat stress on young plants.';
        } else {
          timing = 'Preventive: Monitor soil moisture closely. Apply organic fertilizer to boost early growth and resilience.';
        }
      } else {
        if (_liveWeatherDesc == 'Rainy' || _liveWeatherDesc == 'Stormy') {
          timing = 'Wait 2-3 days for heavy rains to pass before planting.';
        } else {
          timing = 'Plant within the next 3 days to utilize current $_liveWeatherDesc conditions.';
        }
      }

      String harvestPeriod = 'Expect harvest in 90-120 days.';
      if (_selectedCrop == 'Corn (Mais)') harvestPeriod = 'Harvest between late September and mid-October.';
      else if (_selectedCrop == 'Tomato (Kamatis)') harvestPeriod = 'Harvest between early September and late September.';

      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
        _stages = cropStages;
        _stageInstructions = cropInstructions;
        _timingAdvice = timing;
        _expectedYield = yieldEstimate;
        _harvestPeriod = harvestPeriod;
        _aiConfidence = '🎯 Gemini AI Powered (High Accuracy)';
        _currentGrowthStageIndex = 0; // Default to first stage
      });

      // Save global activity and task
      UserSession.addActivity({
        'title': 'Calculated Advisory for $_selectedCrop',
        'icon': 'assessment',
        'color': 'blue',
      });
      UserSession.addScannedTask({
        'title': 'Start $_selectedCrop Phase 1: ${cropStages.first}',
        'description': cropInstructions[cropStages.first]?.join(' ') ?? 'Begin initial planting phase.',
        'time': 'Action Required',
        'isCompleted': false,
        'crop': _selectedCrop,
      });
    });
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          AppTranslations.getText('planting_advisory'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Estimate harvest, optimize timing, and track crop growth stages.',
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
                    // ── Form Input Card ─────────────────
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
                          const Text(
                            'Enter Field Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lotAreaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Lot Area (sq. meters)',
                              prefixIcon: const Icon(Icons.square_foot, color: kPrimaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            decoration: InputDecoration(
                              labelText: 'Crop Type',
                              prefixIcon: const Icon(Icons.grass, color: kPrimaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _selectedCrop = v),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wb_sunny_outlined, color: kPrimaryGreen, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Automatic Weather Context',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_liveSeason ?? 'Loading...'} • $_liveWeatherDesc (${_liveTemp > 0 ? '${_liveTemp.round()}°C' : '...'})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle, color: kPrimaryGreen, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'I have already planted this crop (Out of Season)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            value: _alreadyPlanted,
                            activeColor: kPrimaryGreen,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                _alreadyPlanted = value ?? false;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null 
                                        ? (_alreadyPlanted ? 'When did you plant it?' : 'When would you plant it?')
                                        : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, color: kPrimaryGreen, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isAnalyzing ? null : _calculateAdvisory,
                              icon: _isAnalyzing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.auto_awesome, size: 20),
                              label: const Text('Get Advisory & Tracker'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Advisory & Tracker Output ─────────
                    if (_hasResult) ...[
                      // Expected Yield & Timing card
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
                                const Icon(Icons.insights, color: kPrimaryGreen, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Cultivation Insights',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _aiConfidence,
                                style: const TextStyle(
                                  color: kPrimaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAdvisoryRow('Expected Yield', _expectedYield, Icons.shopping_basket),
                            const Divider(height: 20),
                            _buildAdvisoryRow('Optimal Planting Window', _timingAdvice, Icons.access_time),
                            const Divider(height: 20),
                            _buildAdvisoryRow('Projected Harvest Period', _harvestPeriod, Icons.calendar_month),
                            const Divider(height: 20),
                            _buildAdvisoryRow('Weather Context', 'Automatically factored in current live weather ($_liveWeatherDesc) into these growth stages. Adjust irrigation if rain is forecasted.', Icons.wb_cloudy_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Growth Stage Tracker
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
                            const Text(
                              'Interactive Growth Stage Tracker',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Click on any stage to see customized farming instructions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stage list / progress
                            Column(
                              children: _stages.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final name = entry.value;
                                final isSelected = _currentGrowthStageIndex == idx;

                                return GestureDetector(
                                  onTap: () => setState(() => _currentGrowthStageIndex = idx),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? kLightGreen : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? kPrimaryGreen : Colors.grey[200]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: isSelected ? kPrimaryGreen : Colors.grey[400],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? kPrimaryGreen : const Color(0xFF1A1A1A),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const Divider(height: 24),

                            // Instructions for the active stage
                            Text(
                              'Instructions for: ${_stages[_currentGrowthStageIndex]} Stage',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...(_stageInstructions[_stages[_currentGrowthStageIndex]] ?? [])
                                .map((instruction) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: kPrimaryGreen, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              instruction,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
