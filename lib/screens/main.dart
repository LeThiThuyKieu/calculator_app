import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';
import 'expression_preprocessor.dart';

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
  String currentInput = "";
  String result = "0";

  void _onButtonPressed(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          currentInput = '';
          result = '0';
          break;
        case '⌫':
          if (currentInput.isNotEmpty) {
            currentInput = currentInput.substring(0, currentInput.length - 1);
          }
          break;
        case '=':
          _calculateResult();
          CalculationHistory.addCalculation(currentInput, result);
          break;
        case '+/_':
          if (currentInput.isEmpty || currentInput == '-') {
            return;
          }

          RegExp numberRegex = RegExp(r'-?\d+\.?\d*$');
          Match? match = numberRegex.firstMatch(currentInput);
          
          if (match != null) {
            String number = match.group(0)!;
            int startIndex = match.start;
            
            bool hasOperatorBefore = startIndex > 0 && 
                ['+', '-', '×', '÷', '^'].contains(currentInput[startIndex - 1]);

            if (number.startsWith('-')) {
              currentInput = currentInput.substring(0, startIndex) + number.substring(1);
            } else {
              if (hasOperatorBefore) {
                currentInput = currentInput.substring(0, startIndex) + '(-' + number + ')';
              } else {
                currentInput = currentInput.substring(0, startIndex) + '-' + number;
              }
            }
          } else {
            if (currentInput.startsWith('-')) {
              currentInput = currentInput.substring(1);
            } else {
              currentInput = '-' + currentInput;
            }
          }
          break;
        case '%':
          // Thêm dấu % vào biểu thức, sẽ được xử lý trong ExpressionPreprocessor
          currentInput += '%';
          break;
        case ',':
          // Thêm dấu . (thập phân) vào biểu thức
          currentInput += '.';
          break;
        default:
          if (['+', '-', '×', '÷'].contains(value)) {
            // Thêm toán tử
            currentInput += value;
          } else {
            // Thêm số
            currentInput += value;
          }
      }
    });
  }

  void _calculateResult() {
    try {
      String expression = ExpressionPreprocessor.preprocess(currentInput, true);
      
      // Create parser and context
      Parser p = Parser();
      ContextModel cm = ContextModel();
      
      // Add custom functions to context
      cm.bindVariable(Variable('e'), Number(math.e));
      cm.bindVariable(Variable('pi'), Number(math.pi));
      
      // Parse and evaluate
      Expression exp = p.parse(expression);
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      // Format result
      if (eval.isInfinite) {
        result = "∞";
      } else if (eval.isNaN) {
        result = "Lỗi";
      } else {
        // Format to remove trailing zeros and handle very small/large numbers
        if (eval.abs() < 1e-10) {
          result = "0";
        } else if (eval.abs() > 1e10) {
          result = eval.toStringAsExponential(6);
        } else {
          String formatted = eval.toStringAsFixed(10);
          // Loại bỏ các số 0 thừa sau dấu thập phân
          formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
          result = formatted;
        }
      }
    } catch (e) {
      result = "Lỗi";
    }
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
                          formatNumber(currentInput),
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formatNumber(result),
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
                          currentInput =
                          selectedCalculation["expression"];
                          result = selectedCalculation["result"];
                          // Optionally: cập nhật lại biến để xử lý tiếp
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
                      onPressed: () => _onButtonPressed(e),
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