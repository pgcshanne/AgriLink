import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';

class MarketPricePage extends StatefulWidget {
  const MarketPricePage({super.key});

  @override
  State<MarketPricePage> createState() => _MarketPricePageState();
}

class _MarketPricePageState extends State<MarketPricePage> {
  final _yieldController = TextEditingController();
  String? _selectedCropCalculator;

  // Analysis / Costing results
  bool _costingCalculated = false;
  double _estGrossRevenue = 0.0;
  double _estInputCost = 0.0;
  double _estNetProfit = 0.0;

  // Localized Bogo City market prices, forecasts, and vegetable photos
  final List<Map<String, dynamic>> _cropPrices = [
    {
      'crop': 'Corn (Mais)',
      'current': 18.00,
      'forecast': 19.50,
      'trend': 'up',
      'unit': 'kg',
      'demand': 'High',
      'imageUrl': 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?q=80&w=400',
    },
    {
      'crop': 'Tomato (Kamatis)',
      'current': 45.00,
      'forecast': 42.00,
      'trend': 'down',
      'unit': 'kg',
      'demand': 'High',
      'imageUrl': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?q=80&w=400',
    },
    {
      'crop': 'Banana (Saging)',
      'current': 30.00,
      'forecast': 32.50,
      'trend': 'up',
      'unit': 'kg',
      'demand': 'High',
      'imageUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?q=80&w=400',
    },
    {
      'crop': 'Coconut (Lubi)',
      'current': 12.00,
      'forecast': 12.00,
      'trend': 'stable',
      'unit': 'piece',
      'demand': 'Medium',
      'imageUrl': 'https://images.unsplash.com/photo-1544376798-89aa6b82c6cd?q=80&w=400',
    },
    {
      'crop': 'Camote (Sweet Potato)',
      'current': 35.00,
      'forecast': 38.00,
      'trend': 'up',
      'unit': 'kg',
      'demand': 'High',
      'imageUrl': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=400',
    },
    {
      'crop': 'Cassava',
      'current': 20.00,
      'forecast': 21.00,
      'trend': 'up',
      'unit': 'kg',
      'demand': 'Medium',
      'imageUrl': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=400',
    },
    {
      'crop': 'Eggplant (Talong)',
      'current': 40.00,
      'forecast': 44.00,
      'trend': 'up',
      'unit': 'kg',
      'demand': 'High',
      'imageUrl': 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?q=80&w=400',
    },
    {
      'crop': 'Squash (Kalabasa)',
      'current': 28.00,
      'forecast': 28.00,
      'trend': 'stable',
      'unit': 'kg',
      'demand': 'Medium',
      'imageUrl': 'https://images.unsplash.com/photo-1570586437263-ab629fccc818?q=80&w=400',
    },
    {
      'crop': 'Cabbage (Repolyo)',
      'current': 50.00,
      'forecast': 48.00,
      'trend': 'down',
      'unit': 'kg',
      'demand': 'Medium',
      'imageUrl': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?q=80&w=400',
    },
  ];

  @override
  void dispose() {
    _yieldController.dispose();
    super.dispose();
  }

  void _calculateCosting() {
    final yieldText = _yieldController.text.trim();
    if (yieldText.isEmpty || _selectedCropCalculator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a crop and enter estimated yield'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? qty = double.tryParse(yieldText);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Find the crop price info
    final cropData = _cropPrices.firstWhere(
      (c) => c['crop'] == _selectedCropCalculator,
      orElse: () => _cropPrices[0],
    );

    final double price = cropData['current'] as double;
    final double revenue = qty * price;

    // Simulate input costs (e.g. fertilizer, seed, water: ~35% of revenue for standard crops)
    final double cost = revenue * 0.35;
    final double profit = revenue - cost;

    setState(() {
      _costingCalculated = true;
      _estGrossRevenue = revenue;
      _estInputCost = cost;
      _estNetProfit = profit;
    });
  }

  Widget _buildTrendBadge(String trend) {
    Color color;
    IconData icon;
    String text;

    if (trend == 'up') {
      color = const Color(0xFF2E7D32);
      icon = Icons.trending_up;
      text = 'Increasing';
    } else if (trend == 'down') {
      color = Colors.red[700]!;
      icon = Icons.trending_down;
      text = 'Decreasing';
    } else {
      color = Colors.grey[700]!;
      icon = Icons.trending_flat;
      text = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              ),
          ),
        ],
      ),
    );
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
                        const Text(
                          'Market Price Index',
                          style: TextStyle(
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
                        'Monitor agricultural market rates & run predictive profitability costing',
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
                    // ── Local Price list ──────────────────
                    const Text(
                      'Bogo City Local Market Price (Today)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._cropPrices.map((cp) {
                      final String imageUrl = cp['imageUrl'] as String;
                      final String cropName = cp['crop'] as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Vegetable Crop Photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: kLightGreen,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: kPrimaryGreen.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  width: 62,
                                  height: 62,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: kPrimaryGreen,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.agriculture,
                                    color: kPrimaryGreen,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cropName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Demand: ${cp['demand']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Forecast: ₱${cp['forecast']}/${cp['unit']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${(cp['current'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  'per ${cp['unit']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildTrendBadge(cp['trend'] as String),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // ── Costing & Profit Calculator ───────
                    const Text(
                      'Predictive Profit Costing Calculator',
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
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCropCalculator,
                            decoration: InputDecoration(
                              labelText: 'Choose Crop',
                              prefixIcon: const Icon(Icons.grass, color: kPrimaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _cropPrices.map((c) {
                              final cropName = c['crop'] as String;
                              final imgUrl = c['imageUrl'] as String;
                              return DropdownMenuItem<String>(
                                value: cropName,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        color: kLightGreen,
                                        child: Image.network(
                                          imgUrl,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => const Icon(
                                            Icons.agriculture,
                                            size: 16,
                                            color: kPrimaryGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(cropName),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCropCalculator = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _yieldController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Estimated Yield (kg/ton)',
                              prefixIcon: const Icon(Icons.scale, color: kPrimaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _calculateCosting,
                              icon: const Icon(Icons.calculate, size: 20),
                              label: const Text('Calculate Costing'),
                            ),
                          ),

                          // Calculation Output
                          if (_costingCalculated) ...[
                            const Divider(height: 32),
                            const Text(
                              'Financial Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFinRow('Estimated Gross Revenue', _estGrossRevenue, Colors.grey[800]!),
                            const SizedBox(height: 8),
                            _buildFinRow('Estimated Input Costs (~35%)', _estInputCost, Colors.red[700]!),
                            const Divider(height: 16),
                            _buildFinRow('Projected Net Profit', _estNetProfit, const Color(0xFF2E7D32), isBold: true),
                          ],
                        ],
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

  Widget _buildFinRow(String label, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF1A1A1A) : Colors.grey[700],
          ),
        ),
        Text(
          '₱${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
