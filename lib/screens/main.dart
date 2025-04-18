import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'calculator_history.dart';
import 'advanced_calculator.dart';
import 'currency_converter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Khởi tạo theme mặc định

  void _toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calculator',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode, // Sử dụng biến _themeMode
      home: CalculatorPage(toggleTheme: _toggleTheme), // Truyền hàm toggleTheme
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.toggleTheme});

  final VoidCallback toggleTheme; // Nhận hàm toggleTheme từ MyApp

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String expressionDisplayText = "";
  String displayText = "0";
  List<String> expression = [];
  String currentNumber = "";
  bool justCalculated = false;

  void _updateDisplay() {
    expressionDisplayText =
        expression.join(" ") +
            (currentNumber.isNotEmpty ? " $currentNumber" : "");
    expressionDisplayText = expressionDisplayText.trim();
    if (expressionDisplayText.isEmpty) expressionDisplayText = "";
  }

  void _onPressed(String value) {
    setState(() {
      if (value == "AC") {
        expression.clear();
        currentNumber = "";
        displayText = "0";
        expressionDisplayText = "";
      } else if (value == "=") {
        if (currentNumber.isNotEmpty) {
          expression.add(currentNumber);
        }

        // Ghi lại biểu thức trước khi tính toán
        expressionDisplayText = expression.join(" ");

        double result = _evaluateExpression(expression);

        displayText = formatNumber(formatSmart(result));
        expression = [formatSmart(result)];
        currentNumber = "";
        justCalculated = true;

        CalculationHistory.addCalculation(expressionDisplayText, displayText);
      } else if (_isOperator(value)) {
        if (currentNumber.isNotEmpty) {
          expression.add(currentNumber);
          currentNumber = '';
        }

        if (expression.isNotEmpty && _isOperator(expression.last)) {
          expression.removeLast();
        }
        expression.add(value);
        justCalculated = false;
      } else if (value == "+/_") {
        if (currentNumber.isNotEmpty) {
          if (currentNumber.startsWith("-")) {
            currentNumber = currentNumber.substring(1);
          } else {
            currentNumber = "-$currentNumber";
          }
        }
      } else if (value == ",") {
        if (!currentNumber.contains(".")) {
          currentNumber += ".";
        }
      } else if (value == "%") {
        if (currentNumber.isNotEmpty) {
          double num = double.tryParse(currentNumber) ?? 0;
          currentNumber = (num / 100).toString();
        }
      } else if (value == "⌫") {
        if (currentNumber.isNotEmpty) {
          currentNumber = currentNumber.substring(0, currentNumber.length - 1);
        } else if (expression.isNotEmpty) {
          expression.removeLast();
        }
      } else {
        // Nếu vừa mới tính xong và nhấn số => reset biểu thức
        if (justCalculated && _isNumber(value)) {
          expression.clear();
          displayText = "0";
          currentNumber = value;
          justCalculated = false;
        } else {
          currentNumber += value;
        }
      }

      _updateDisplay();
    });
  }

  bool _isOperator(String value) {
    return ['+', '-', '×', '÷'].contains(value);
  }

  bool _isNumber(String value) {
    return ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(value);
  }

  double _evaluateExpression(List<String> tokens) {
    List<String> postfix = _toPostfix(tokens);
    return _evaluatePostfix(postfix);
  }

  List<String> _toPostfix(List<String> tokens) {
    final precedence = {'+': 1, '-': 1, '×': 2, '÷': 2};
    List<String> output = [];
    List<String> stack = [];

    for (var token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if (["+", "-", "×", "÷"].contains(token)) {
        while (stack.isNotEmpty &&
            precedence[stack.last] != null &&
            precedence[stack.last]! >= precedence[token]!) {
          output.add(stack.removeLast());
        }
        stack.add(token);
      }
    }

    while (stack.isNotEmpty) {
      output.add(stack.removeLast());
    }

    return output;
  }

  double _evaluatePostfix(List<String> tokens) {
    List<double> stack = [];

    for (var token in tokens) {
      if (double.tryParse(token) != null) {
        stack.add(double.parse(token));
      } else {
        double b = stack.removeLast();
        double a = stack.removeLast();
        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '×':
            stack.add(a * b);
            break;
          case '÷':
            stack.add(a / b);
            break;
        }
      }
    }

    return stack.first;
  }

  String formatNumber(String numberStr) {
    try {
      double number = double.parse(numberStr);

      final formatter = NumberFormat("#,##0.#######", "vi_VN");
      return formatter.format(number);
    } catch (e) {
      return numberStr;
    }
  }

  String formatSmart(double number) {
    if (number == number.roundToDouble()) {
      //số nguyên
      return number.toInt().toString();
    } else {
      return number.toString();
    }
  }

  //xây dựng giao diện main
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                alignment: Alignment.topRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: widget.toggleTheme, // Gọi hàm toggleTheme được truyền vào
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatNumber(expressionDisplayText),
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formatNumber(displayText),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3 icon hàng dưới
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () async {
                      final selectedCalculation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalculationHistory(),
                        ),
                      );

                      // Nếu người dùng đã chọn một dòng từ lịch sử
                      if (selectedCalculation != null) {
                        setState(() {
                          expressionDisplayText =
                          selectedCalculation["expression"];
                          displayText = selectedCalculation["result"];
                          // Optionally: cập nhật lại biến để xử lý tiếp
                          currentNumber = "";
                          expression = selectedCalculation["expression"]
                              .split(" ");
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.functions),
                    onPressed: () async {
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                      ]);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedCalculatorPage(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.currency_exchange),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CurrencyConverterPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Nút số
            Expanded(
              flex: 5,
              child: GridView.count(
                padding: const EdgeInsets.all(10),
                crossAxisCount: 4,
                children:
                [
                  "AC",
                  "⌫",
                  "+/_",
                  "÷",
                  "7",
                  "8",
                  "9",
                  "×",
                  "4",
                  "5",
                  "6",
                  "-",
                  "1",
                  "2",
                  "3",
                  "+",
                  "%",
                  "0",
                  ",",
                  "=",
                ].map((e) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => _onPressed(e),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(16),
                        backgroundColor:
                        e == "="
                            ? Colors.blue.shade800
                            : [
                          "AC",
                          "⌫",
                          "+/_",
                          "÷",
                          "×",
                          "-",
                          "+",
                        ].contains(e)
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        foregroundColor:
                        e == "="
                            ? Colors.white
                            : [
                          "AC",
                          "⌫",
                          "+/_",
                          "÷",
                          "×",
                          "-",
                          "+",
                        ].contains(e)
                            ? const Color(0xFF5F6CB2)
                            : Colors.black,
                      ),
                      child:
                      e == "⌫"
                          ? const Icon(Icons.backspace, size: 28)
                          : Text(
                        e,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}