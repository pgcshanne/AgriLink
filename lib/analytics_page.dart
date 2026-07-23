import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/app_translations.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _recentScans = [];
  List<Map<String, dynamic>> _scannedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerAccountData();
  }

  Future<void> _loadFarmerAccountData() async {
    final user = await UserSession.getUser();
    final scans = await UserSession.getRecentScans();
    final tasks = await UserSession.getScannedTasks();

    if (mounted) {
      setState(() {
        _user = user;
        _recentScans = scans;
        _scannedTasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmerName = _user?['fullName'] ?? _user?['name'] ?? 'Farmer Account';
    final barangay = _user?['barangay'] ?? 'Pandan';
    final rsbsaNo = _user?['rsbsaId'] ?? _user?['id'] ?? 'RSBSA-07-22-8941';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTranslations.getText('farm_analytics'),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // ── Account Key Metrics Summary (No Revenue) ──────
                  Text(
                    AppTranslations.getText('account_performance'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildMetricCard(
                        title: 'Crop Health Index',
                        value: '89%',
                        subtitle: 'Monitored Healthy',
                        icon: Icons.monitor_heart_outlined,
                        color: kPrimaryGreen,
                      ),
                      _buildMetricCard(
                        title: 'AI Vision Scans',
                        value: '${_recentScans.length} Scans',
                        subtitle: _recentScans.isNotEmpty
                            ? 'Latest: ${_recentScans.first['crop'] ?? 'Crop'}'
                            : 'No recent scans',
                        icon: Icons.biotech,
                        color: Colors.purple,
                      ),
                      _buildMetricCard(
                        title: 'Farm Tasks',
                        value: '${_scannedTasks.length} Active',
                        subtitle: 'Pending Treatment',
                        icon: Icons.assignment_outlined,
                        color: Colors.orange,
                      ),
                      _buildMetricCard(
                        title: 'Soil Status',
                        value: '6.5 pH',
                        subtitle: 'Optimal Moisture',
                        icon: Icons.eco_outlined,
                        color: Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Yield Forecast Chart ──────────────────────────
                  _buildYieldForecastChart(),

                  const SizedBox(height: 24),

                  // ── Soil Health Breakdown ──────────────────────────
                  _buildSoilHealthTrends(),

                  const SizedBox(height: 24),

                  // ── Farmer Activity Summary Log ───────────────────
                  if (_recentScans.isNotEmpty) ...[
                    const Text(
                      'Recent Account Disease Scans',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentScans.length > 3 ? 3 : _recentScans.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.grey[200], height: 1),
                        itemBuilder: (context, index) {
                          final scan = _recentScans[index];
                          final isHealthy = scan['isHealthy'] == true || (scan['result'] ?? '').toString().toLowerCase() == 'healthy';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                              child: Icon(
                                isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                color: isHealthy ? kPrimaryGreen : Colors.red[700],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              scan['crop'] ?? 'Crop Scan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              scan['result'] ?? 'Scan result',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            trailing: Text(
                              scan['date'] ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }



  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildYieldForecastChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crop Yield Summary (Bogo City Season)',
          style: TextStyle(
            fontSize: 17,
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
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildBarChartRow('Corn (Mais)', 0.75, '1.2 tons'),
              const SizedBox(height: 14),
              _buildBarChartRow('Tomato (Kamatis)', 0.50, '400 kg'),
              const SizedBox(height: 14),
              _buildBarChartRow('Banana (Saging)', 0.90, '2.1 tons'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartRow(String label, double fill, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildSoilHealthTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Field Soil Health Analysis',
          style: TextStyle(
            fontSize: 17,
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
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSoilMetric('Nitrogen Level', 0.85, Colors.blue),
              const SizedBox(height: 12),
              _buildSoilMetric('Phosphorus', 0.45, Colors.orange),
              const SizedBox(height: 12),
              _buildSoilMetric('Potassium', 0.65, Colors.purple),
              const SizedBox(height: 12),
              _buildSoilMetric('Soil Moisture', 0.70, Colors.teal),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoilMetric(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
