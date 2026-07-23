import 'package:flutter/material.dart';
import 'package:agrilink/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agrilink/services/user_session.dart';
import 'package:agrilink/services/app_translations.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Map<String, dynamic>> _dailyTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveTasks();
  }

  Future<void> _fetchLiveTasks() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=11.05&longitude=124.00&current=relative_humidity_2m,weather_code,soil_moisture_0_to_1cm,wind_speed_10m&timezone=Asia/Manila'));
      if (response.statusCode == 200) {
        await _loadFallbackTasks();
      } else {
        await _loadFallbackTasks();
      }
    } catch (e) {
      await _loadFallbackTasks();
    }
  }
  
  Future<void> _loadFallbackTasks() async {
    final scannedTasks = await UserSession.getScannedTasks();

    if (mounted) {
      setState(() {
        _dailyTasks = scannedTasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    final int completedTasks = _dailyTasks.where((t) => t['isCompleted']).length;
    final double progress = _dailyTasks.isEmpty ? 0 : completedTasks / _dailyTasks.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.getText('tasks'),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kPrimaryGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add custom task feature coming soon.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
            ),
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGreen,
                      ),
                    ),
                    Text(
                      '$completedTasks/${_dailyTasks.length} Completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Your Checklist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _dailyTasks.length,
              itemBuilder: (context, index) {
                final task = _dailyTasks[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    activeColor: kPrimaryGreen,
                    checkColor: Colors.white,
                    value: task['isCompleted'],
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _dailyTasks[index]['isCompleted'] = value;
                        });
                      }
                    },
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: task['isCompleted'] ? TextDecoration.lineThrough : null,
                        color: task['isCompleted'] ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                task['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
