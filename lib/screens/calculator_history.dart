import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalculationHistory extends StatefulWidget {
  const CalculationHistory({super.key});

  @override
  State<CalculationHistory> createState() => _CalculationHistoryState();

  // Dùng hàm này để thêm phép tính mới
  static Future<void> addCalculation(String expression, String result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('calc_history') ?? [];
    Map<String, String> item = {'expression': expression, 'result': result};
    history.insert(0, jsonEncode(item));
    await prefs.setStringList('calc_history', history);
  }

  // Xoá toàn bộ lịch sử
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calc_history');
  }
}

class _CalculationHistoryState extends State<CalculationHistory> {
  List<Map<String, String>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyRaw = prefs.getStringList('calc_history') ?? [];
    setState(() {
      history = historyRaw
          .map((item) => Map<String, String>.from(jsonDecode(item)))
          .toList();
    });
  }

  Future<void> clear() async {
    await CalculationHistory.clearHistory();
    setState(() {
      history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử tính toán"),
      ),
      body: Column(
        children: [
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("Không có lịch sử"))
                : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context, {
                        "expression": item['expression'],
                        "result": item['result'],
                      });
                    },
                    child: Column( // Column nằm bên trong InkWell
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['expression'] ?? "",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['result'] ?? "",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(), // thêm dòng phân cách nếu bạn thích
                      ],
                    ),
                  ),
                );

              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: clear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
              ),
              child: const Text("Xoá lịch sử"),
            ),
          )
        ],
      ),
    );
  }
}
