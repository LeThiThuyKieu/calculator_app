import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: SafeArea(child: CalculatorApp()),
    debugShowCheckedModeBanner: false,
  ));
}

class CalculatorApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CalculatorState();
  }
}

class CalculatorState extends State<CalculatorApp> {
  final List<String> buttons = [
    "AC", "+/-", "%", "⌫",
    "7", "8", "9", "÷",
    "4", "5", "6", "×",
    "1", "2", "3", "-",
    "0", ".", "=", "+"
  ];

  final List<Color> buttonColors = [
    Colors.lightBlue, Colors.lightBlue, Colors.lightBlue, Colors.blue,
    Colors.grey, Colors.grey, Colors.grey, Colors.blue,
    Colors.grey, Colors.grey, Colors.grey, Colors.blue,
    Colors.grey, Colors.grey, Colors.grey, Colors.blue,
    Colors.grey, Colors.grey, Colors.blue, Colors.blue
  ];

  String displayText = "0";
  String currentNumber = "";
  List<String> expression = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.all(20),
              child: Text(
                displayText,
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: buttons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return createButtonWidget(buttons[index], buttonColors[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget createButtonWidget(String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          switch (text) {
            case "AC":
              displayText = "0";
              expression.clear();
              currentNumber = "";
              break;
            case "⌫":
              if (currentNumber.isNotEmpty) {
                currentNumber = currentNumber.substring(0, currentNumber.length - 1);
              } else if (expression.isNotEmpty) {
                expression.removeLast();
              }
              _updateDisplay();
              break;
            case "=":
              if (currentNumber.isNotEmpty) {
                expression.add(currentNumber);
              }
              double result = _evaluateExpression(expression);
              displayText = result.toString();
              expression = [result.toString()];
              currentNumber = "";
              break;
            case "+/-":
              if (currentNumber.isNotEmpty) {
                if (currentNumber.startsWith("-")) {
                  currentNumber = currentNumber.substring(1);
                } else {
                  currentNumber = "-$currentNumber";
                }
                _updateDisplay();
              }
              break;
            case "%":
              if (currentNumber.isNotEmpty) {
                double num = double.parse(currentNumber) / 100;
                currentNumber = num.toString();
                _updateDisplay();
              }
              break;
            case "+": case "-": case "×": case "÷":
            if (currentNumber.isNotEmpty) {
              expression.add(currentNumber);
              currentNumber = "";
            }
            if (expression.isNotEmpty &&
                !_isOperator(expression.last)) {
              expression.add(text);
            } else if (expression.isNotEmpty) {
              expression[expression.length - 1] = text;
            }
            _updateDisplay();
            break;
            default:
              if (text == "." && currentNumber.contains(".")) return;
              currentNumber += text;
              _updateDisplay();
          }
        });
      },
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: text == "0" ? EdgeInsets.symmetric(horizontal: 40) : EdgeInsets.all(15),
        backgroundColor: color,
        minimumSize: Size(60, 60),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _updateDisplay() {
    displayText = expression.join(" ") + (currentNumber.isNotEmpty ? " $currentNumber" : "");
    displayText = displayText.trim();
    if (displayText.isEmpty) displayText = "0";
  }

  bool _isOperator(String s) {
    return s == "+" || s == "-" || s == "×" || s == "÷";
  }

  double _evaluateExpression(List<String> expr) {
    List<String> temp = List.from(expr);

    for (int i = 0; i < temp.length; i++) {
      if (temp[i] == "×" || temp[i] == "÷") {
        double num1 = double.parse(temp[i - 1]);
        double num2 = double.parse(temp[i + 1]);
        double result = temp[i] == "×" ? num1 * num2 : num1 / num2;
        temp.replaceRange(i - 1, i + 2, [result.toString()]);
        i -= 1;
      }
    }

    double result = double.parse(temp[0]);
    for (int i = 1; i < temp.length; i += 2) {
      String op = temp[i];
      double num = double.parse(temp[i + 1]);
      if (op == "+") result += num;
      if (op == "-") result -= num;
    }
    return result;
  }
}