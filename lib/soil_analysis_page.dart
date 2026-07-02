import 'package:flutter/material.dart';
import 'package:agrilink/drawer_menu.dart';

class SoilAnalysisPage extends StatefulWidget {
  const SoilAnalysisPage({super.key});

  @override
  State<SoilAnalysisPage> createState() => _SoilAnalysisPageState();
}

class _SoilAnalysisPageState extends State<SoilAnalysisPage> {
  final TextEditingController phController = TextEditingController();
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();

  bool analyzed = false;

  String soilHealth = "85%";
  String cropRecommendation = "Rice";
  String fertilizerRecommendation =
      "Apply Urea fertilizer and Organic Compost.";
  String aiRecommendation =
      "Your soil is suitable for rice production. Phosphorus levels are slightly low. Applying phosphate fertilizer may improve yield.";

  String nitrogenStatus = "Normal";
  String phosphorusStatus = "Low";
  String potassiumStatus = "High";
  String phStatus = "Optimal";

  void analyzeSoil() {
    double ph = double.tryParse(phController.text) ?? 6.5;
    int n = int.tryParse(nitrogenController.text) ?? 50;
    int p = int.tryParse(phosphorusController.text) ?? 30;
    int k = int.tryParse(potassiumController.text) ?? 50;

    setState(() {
      analyzed = true;

      nitrogenStatus = n < 40 ? "Low" : "Normal";
      phosphorusStatus = p < 40 ? "Low" : "Normal";
      potassiumStatus = k < 40 ? "Low" : "Normal";

      if (ph >= 5.5 && ph <= 7.0) {
        cropRecommendation = "Rice";
        phStatus = "Optimal";
      } else if (ph > 7.0) {
        cropRecommendation = "Corn";
        phStatus = "Alkaline";
      } else {
        cropRecommendation = "Vegetables";
        phStatus = "Acidic";
      }

      fertilizerRecommendation =
          "Apply Organic Compost and balanced NPK fertilizer.";

      aiRecommendation =
          "Based on the soil nutrient values entered, the soil appears suitable for $cropRecommendation cultivation. Regular monitoring of nutrient levels is recommended.";

      soilHealth = "85%";
    });
  }

  Widget buildInputField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildStatusTile(String title, String value) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.green),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget buildCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: Colors.green),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(currentPage: 'Soil Analysis'),
      appBar: AppBar(
        title: const Text('Soil Analysis'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard(
              title: "Soil Input Parameters",
              icon: Icons.science,
              child: Column(
                children: [
                  buildInputField("Soil pH", Icons.water_drop, phController),
                  buildInputField(
                    "Nitrogen (N)",
                    Icons.grass,
                    nitrogenController,
                  ),
                  buildInputField(
                    "Phosphorus (P)",
                    Icons.eco,
                    phosphorusController,
                  ),
                  buildInputField(
                    "Potassium (K)",
                    Icons.agriculture,
                    potassiumController,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: analyzeSoil,
                      icon: const Icon(Icons.analytics),
                      label: const Text("Analyze Soil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (analyzed) ...[
              buildCard(
                title: "Soil Health Score",
                icon: Icons.favorite,
                child: Center(
                  child: Text(
                    soilHealth,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

              buildCard(
                title: "Nutrient Status",
                icon: Icons.bar_chart,
                child: Column(
                  children: [
                    buildStatusTile("Nitrogen", nitrogenStatus),
                    buildStatusTile("Phosphorus", phosphorusStatus),
                    buildStatusTile("Potassium", potassiumStatus),
                    buildStatusTile("Soil pH", phStatus),
                  ],
                ),
              ),

              buildCard(
                title: "Recommended Crop",
                icon: Icons.grass,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropRecommendation,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Suitability Score: 92%"),
                  ],
                ),
              ),

              buildCard(
                title: "Fertilizer Recommendation",
                icon: Icons.local_florist,
                child: Text(
                  fertilizerRecommendation,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              buildCard(
                title: "AI Insights",
                icon: Icons.smart_toy,
                child: Text(
                  aiRecommendation,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
