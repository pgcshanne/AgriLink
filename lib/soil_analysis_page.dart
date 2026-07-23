import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'package:agrilink/services/app_translations.dart';

class SoilAnalysisPage extends StatefulWidget {
  const SoilAnalysisPage({super.key});

  @override
  State<SoilAnalysisPage> createState() => _SoilAnalysisPageState();
}

class _SoilAnalysisPageState extends State<SoilAnalysisPage> {
  final _phController = TextEditingController();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();

  String? _selectedSoilType;
  String? _selectedSoilColor;
  double _moisture = 50;
  bool _analyzed = false;
  bool _isAnalyzing = false;

  // Results
  String _soilHealthScore = '';
  String _cropRecommendation = '';
  String _fertilizerRecommendation = '';
  String _aiInsights = '';
  String _nitrogenStatus = '';
  String _phosphorusStatus = '';
  String _potassiumStatus = '';
  String _phStatus = '';
  String _soilImprovementPractice = '';

  final List<String> _soilTypes = [
    'Clay',
    'Sandy',
    'Loam',
    'Silty',
    'Peaty',
    'Chalky',
  ];

  final List<Map<String, dynamic>> _soilColors = [
    {'label': 'Dark Brown', 'color': const Color(0xFF4E342E), 'hex': 'Dark Brown'},
    {'label': 'Brown', 'color': const Color(0xFF795548), 'hex': 'Brown'},
    {'label': 'Light Brown', 'color': const Color(0xFFA1887F), 'hex': 'Light Brown'},
    {'label': 'Red', 'color': const Color(0xFFC62828), 'hex': 'Red'},
    {'label': 'Yellow', 'color': const Color(0xFFF9A825), 'hex': 'Yellow'},
    {'label': 'Grey', 'color': const Color(0xFF757575), 'hex': 'Grey'},
    {'label': 'Black', 'color': const Color(0xFF212121), 'hex': 'Black'},
  ];

  void _analyzeSoil() {
    if (_selectedSoilType == null || _selectedSoilColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select soil type and color'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final ph = double.tryParse(_phController.text) ?? 6.5;
      final n = int.tryParse(_nitrogenController.text) ?? 50;
      final p = int.tryParse(_phosphorusController.text) ?? 30;
      final k = int.tryParse(_potassiumController.text) ?? 50;

      // NPK status
      String nStatus = n < 40 ? 'Low' : (n > 80 ? 'High' : 'Normal');
      String pStatus = p < 40 ? 'Low' : (p > 80 ? 'High' : 'Normal');
      String kStatus = k < 40 ? 'Low' : (k > 80 ? 'High' : 'Normal');

      String phStat;
      String crop;
      if (ph >= 5.5 && ph <= 6.5) {
        phStat = 'Optimal';
        crop = 'Banana (Saging)';
      } else if (ph > 6.5 && ph <= 7.5) {
        phStat = 'Slightly Alkaline';
        crop = 'Corn (Mais)';
      } else if (ph > 7.5) {
        phStat = 'Alkaline';
        crop = 'Coconut (Lubi)';
      } else {
        phStat = 'Acidic';
        crop = 'Tomato (Kamatis)';
      }

      // Soil color insights
      String colorInsight = '';
      if (_selectedSoilColor == 'Dark Brown' || _selectedSoilColor == 'Black') {
        colorInsight = 'Dark soil color indicates high organic matter content, excellent for most crops.';
      } else if (_selectedSoilColor == 'Red') {
        colorInsight = 'Red soil suggests iron oxide presence. Good drainage but may need pH adjustment.';
      } else if (_selectedSoilColor == 'Yellow') {
        colorInsight = 'Yellow soil indicates iron compounds — moderate drainage, suitable for root crops.';
      } else if (_selectedSoilColor == 'Grey') {
        colorInsight = 'Grey soil may indicate poor drainage or waterlogging. Improve drainage before planting.';
      } else {
        colorInsight = 'Brown soil is generally fertile and suitable for a wide range of crops.';
      }

      // Soil type insights
      String typeInsight = '';
      if (_selectedSoilType == 'Clay') {
        typeInsight = 'Clay soil retains moisture well but may compact. Add organic matter to improve structure.';
      } else if (_selectedSoilType == 'Sandy') {
        typeInsight = 'Sandy soil drains quickly. Frequent irrigation and organic amendments are recommended.';
      } else if (_selectedSoilType == 'Loam') {
        typeInsight = 'Loam is the ideal soil type — excellent balance of drainage, aeration, and nutrients.';
      } else if (_selectedSoilType == 'Silty') {
        typeInsight = 'Silty soil is fertile and holds moisture well. Suitable for most field crops.';
      } else {
        typeInsight = 'This soil type requires specific management. Consult a local agricultural extension officer.';
      }

      // Fertilizer recommendation
      String fertilizer = '';
      if (nStatus == 'Low') fertilizer += 'Apply Urea (46-0-0) to boost nitrogen. ';
      if (pStatus == 'Low') fertilizer += 'Apply Triple Superphosphate for phosphorus. ';
      if (kStatus == 'Low') fertilizer += 'Apply Muriate of Potash for potassium. ';
      if (fertilizer.isEmpty) fertilizer = 'Apply balanced NPK fertilizer (14-14-14) for maintenance.';

      // Soil improvement
      String improvement = '';
      if (ph < 5.5) {
        improvement = 'Apply agricultural lime to raise soil pH.';
      } else if (ph > 7.5) {
        improvement = 'Apply elemental sulfur or organic matter to lower soil pH.';
      } else {
        improvement = 'Maintain pH by adding compost and following crop rotation practices.';
      }

      // Health score (simple formula)
      int healthScore = 70;
      if (ph >= 5.5 && ph <= 6.5) healthScore += 10;
      if (nStatus == 'Normal') healthScore += 5;
      if (pStatus == 'Normal') healthScore += 5;
      if (kStatus == 'Normal') healthScore += 5;
      if (_selectedSoilType == 'Loam') healthScore += 5;
      if (healthScore > 100) healthScore = 100;

      setState(() {
        _isAnalyzing = false;
        _analyzed = true;
        _nitrogenStatus = nStatus;
        _phosphorusStatus = pStatus;
        _potassiumStatus = kStatus;
        _phStatus = phStat;
        _cropRecommendation = crop;
        _fertilizerRecommendation = fertilizer.trim();
        _soilImprovementPractice = improvement;
        _soilHealthScore = '$healthScore%';
        _aiInsights =
            'Based on your soil analysis: $_selectedSoilType soil with $_selectedSoilColor color, pH $ph, and NPK values (N:$n, P:$p, K:$k).\n\n$colorInsight\n\n$typeInsight\n\nRecommended crop: $crop. $fertilizer';
      });
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.red[700]!;
      case 'High':
        return Colors.orange[700]!;
      case 'Normal':
      case 'Optimal':
        return const Color(0xFF2E7D32);
      default:
        return Colors.orange[700]!;
    }
  }

  @override
  void dispose() {
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
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
                  color: Color(0xFF6A1B9A),
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
                          AppTranslations.getText('soil_analysis'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Agrilink Soil-Net (ResNet-50)',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 11, ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Enter your soil data for AI-driven crop & fertilizer recommendations',
                        style: TextStyle(
                          color: Colors.white70, fontSize: 13, ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Soil Type & Color ─────────────────
                    _buildCard(
                      title: 'Soil Characteristics',
                      icon: Icons.science,
                      iconColor: const Color(0xFF6A1B9A),
                      child: Column(
                        children: [
                          // Soil Type dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedSoilType,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Soil Type',
                              prefixIcon: const Icon(Icons.terrain, color: Color(0xFF6A1B9A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _soilTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => _selectedSoilType = v),
                          ),
                          const SizedBox(height: 14),

                          // Soil Color
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Soil Color',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _soilColors.map((sc) {
                              final isSelected = _selectedSoilColor == sc['label'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSoilColor = sc['label'] as String),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? (sc['color'] as Color) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? (sc['color'] as Color) : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: sc['color'] as Color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sc['label'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Moisture Slider
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Soil Moisture',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_moisture.round()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF0277BD),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF6A1B9A),
                                  thumbColor: const Color(0xFF6A1B9A),
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                                child: Slider(
                                  value: _moisture,
                                  min: 0,
                                  max: 100,
                                  onChanged: (v) => setState(() => _moisture = v),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Dry', style: TextStyle(fontSize: 11, color: Colors.grey[500], )),
                                  Text('Optimal', style: TextStyle(fontSize: 11, color: Colors.grey[500], )),
                                  Text('Wet', style: TextStyle(fontSize: 11, color: Colors.grey[500], )),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── NPK & pH Input ────────────────────
                    _buildCard(
                      title: 'NPK & pH Values',
                      icon: Icons.bar_chart,
                      iconColor: const Color(0xFF6A1B9A),
                      child: Column(
                        children: [
                          _buildNpkField('Soil pH (0–14)', Icons.water_drop_outlined, _phController,
                              hint: '6.5'),
                          const SizedBox(height: 12),
                          _buildNpkField('Nitrogen – N (mg/kg)', Icons.grass, _nitrogenController,
                              hint: '50'),
                          const SizedBox(height: 12),
                          _buildNpkField('Phosphorus – P (mg/kg)', Icons.eco, _phosphorusController,
                              hint: '30'),
                          const SizedBox(height: 12),
                          _buildNpkField('Potassium – K (mg/kg)', Icons.agriculture, _potassiumController,
                              hint: '50'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isAnalyzing ? null : _analyzeSoil,
                              icon: _isAnalyzing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.analytics, size: 20),
                              label: Text(
                                _isAnalyzing ? 'Analyzing...' : 'Analyze Soil',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Results ───────────────────────────
                    if (_analyzed) ...[
                      const SizedBox(height: 14),

                      // Health Score
                      _buildCard(
                        title: 'Soil Health Score',
                        icon: Icons.favorite,
                        iconColor: const Color(0xFF6A1B9A),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6A1B9A), width: 4,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _soilHealthScore,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A1B9A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    int.parse(_soilHealthScore.replaceAll('%', '')) >= 80
                                        ? 'Excellent Soil Health!'
                                        : int.parse(_soilHealthScore.replaceAll('%', '')) >= 60
                                            ? 'Good — Needs Minor Improvement'
                                            : 'Needs Significant Improvement',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recommended crop: $_cropRecommendation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // NPK Status
                      _buildCard(
                        title: 'Nutrient Status (NPK)',
                        icon: Icons.science,
                        iconColor: const Color(0xFF6A1B9A),
                        child: Column(
                          children: [
                            _buildNutrientRow('Nitrogen (N)', _nitrogenStatus, _nitrogenController.text.isEmpty ? '50' : _nitrogenController.text),
                            const SizedBox(height: 10),
                            _buildNutrientRow('Phosphorus (P)', _phosphorusStatus, _phosphorusController.text.isEmpty ? '30' : _phosphorusController.text),
                            const SizedBox(height: 10),
                            _buildNutrientRow('Potassium (K)', _potassiumStatus, _potassiumController.text.isEmpty ? '50' : _potassiumController.text),
                            const SizedBox(height: 10),
                            _buildNutrientRow('Soil pH', _phStatus, _phController.text.isEmpty ? '6.5' : _phController.text),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Fertilizer Recommendation
                      _buildCard(
                        title: 'Fertilizer Recommendation',
                        icon: Icons.local_florist,
                        iconColor: const Color(0xFF2E7D32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fertilizerRecommendation,
                              style: const TextStyle(
                                fontSize: 14, height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_circle_outlined,
                                      color: Color(0xFF2E7D32), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Soil Improvement: $_soilImprovementPractice',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1B5E20), height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Weather Integration
                      _buildCard(
                        title: 'Localized Weather Context',
                        icon: Icons.cloud_queue,
                        iconColor: Colors.blueGrey,
                        child: const Text(
                          'Recent partly cloudy conditions with moderate humidity in Bogo City are optimal for applying soil amendments without risk of nutrient run-off. Adjust irrigation based on the 7-day forecast.',
                          style: TextStyle(
                            fontSize: 13, height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // AI Insights
                      _buildCard(
                        title: 'AI Insights',
                        icon: Icons.smart_toy,
                        iconColor: const Color(0xFF0277BD),
                        child: Text(
                          _aiInsights,
                          style: const TextStyle(
                            fontSize: 13, height: 1.6,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildNpkField(String label, IconData icon, TextEditingController controller, {String hint = ''}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildNutrientRow(String name, String status, String value) {
    final color = _statusColor(status);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$value mg/kg',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
