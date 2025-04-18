import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

import 'calculator_history.dart';
import 'expression_preprocessor.dart';

class AdvancedCalculatorPage extends StatefulWidget {
  const AdvancedCalculatorPage({super.key});

  @override
  State<AdvancedCalculatorPage> createState() => _AdvancedCalculatorPageState();
}

class _AdvancedCalculatorPageState extends State<AdvancedCalculatorPage> {
  String currentInput = "";
  String result = "";
  bool isDeg = true;

  void _goBackToPortrait(BuildContext context) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Navigator.pop(context);
  }

  void _onButtonPressed(String label) {
    setState(() {
      switch (label) {
        case 'AC':
          currentInput = '';
          result = '';
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
        case 'mc':
        case 'm+':
        case 'm-':
        case 'mr':
          currentInput='';
          break;
        default:
          currentInput += convertToExpression(label);
      }
    });
  }

  void _calculateResult() {
    try {
      String expression = ExpressionPreprocessor.preprocess(currentInput, isDeg);
      
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

  String convertToExpression(String label) {
    switch (label) {
      case '2ˣ':
        return '2^';
      case 'π':
        return 'π';
      case '10ˣ':
        return '10^';
      case '1/x':
        return '^(-1)';
      case 'x²':
        return '^2';
      case 'x³':
        return '^3';
      case 'yˣ':
        return '^';
      case 'x!':
        return '!';
      case '√':
        return 'sqrt(';
      case 'ˣ√y':
        return '^(1/';
      case 'lg':
        return 'lg(';
      case 'ln':
        return 'ln(';
      case 'Deg':
        setState(() {
          isDeg = false;
          if (currentInput.isNotEmpty) {
            _calculateResult();
          }
        });
        return '';
      case 'Rad':
        setState(() {
          isDeg = true;
          if (currentInput.isNotEmpty) {
            _calculateResult();
          }
        });
        return '';
      case 'sin':
      case 'cos':
      case 'tan':
      case 'sinh':
      case 'cosh':
      case 'tanh':
        return '$label(';
      case 'eˣ':
        return 'e^';
      case 'Rand':
      // Tạo số ngẫu nhiên từ 0 đến 1
        return '${math.Random().nextDouble()}';
      default:
        return label;
    }
  }


  // String _mockEvaluate(String expression) {
  //   // Đây là mock, bạn có thể dùng thư viện hoặc tự viết parser
  //   if (expression == "sin(30)+10") return "10.5";
  //   return "42"; // demo
  // }

  bool _isFunction(String label) {
    const ops = ['+','-','×','÷','=','⌫','+/_','AC','%',',','mc','m+','m-','mr'];
    return !RegExp(r'^\d+$').hasMatch(label) && !ops.contains(label);
  }

  @override
  Widget build(BuildContext context) {
    final List<List<String>> buttons = [
      ['2ˣ', '(', ')', '10ˣ', 'mc', 'm+', 'm-', 'mr'],
      ['1/x', 'x²', 'x³', 'yˣ', 'AC', '⌫', '+/_', '÷'],
      ['x!', '√', 'ˣ√y', 'lg', '7', '8', '9', '×'],
      ['sin', 'cos', 'tan', 'ln', '4', '5', '6', '-'],
      ['sinh', 'cosh', 'tanh', 'eˣ', '1', '2', '3', '+'],
      ['${isDeg ? 'Deg' : 'Rad'}', 'π', 'e', 'Rand', '%', '0', ',', '='],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toán nâng cao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBackToPortrait(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentInput,
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: buttons.map((row) {
                    return Expanded(
                      child: Row(
                        children: row.map((label) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ElevatedButton(
                                onPressed: () => _onButtonPressed(label),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFunction(label)
                                      ? Colors.grey.shade200
                                      : ['AC', '⌫', '+/_', '÷', '×', '-', '+', '='].contains(label)
                                          ? label == '=' 
                                              ? Colors.blue.shade800
                                              : Colors.blue.shade100
                                          : Colors.grey.shade200,
                                  foregroundColor: label == '=' ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
