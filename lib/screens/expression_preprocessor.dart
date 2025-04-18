import 'dart:math' as math;

class ExpressionPreprocessor {
  static String preprocess(String expression, bool isDeg) {
    String processed = expression;
    
    // Xử lý các phép tính đơn giản
    processed = processed.replaceAll('×', '*');
    processed = processed.replaceAll('÷', '/');
    processed = processed.replaceAll('%', '/100');
    
    // Xử lý hằng số
    processed = processed.replaceAll('π', '${math.pi}');
    processed = processed.replaceAll('e', '${math.e}');
    
    // Xu ly hàm logarit
    processed = processed.replaceAll('lg(', 'log(10,');
    processed = processed.replaceAll('ln(', 'log(${math.e},');
    
    // Xử lý cho các hàm hyperbolic
    processed = processed.replaceAllMapped(
      RegExp(r'sinh\((.*?)\)'),
      (match) {
        String arg = match.group(1)!;
        // sinh(x) = (e^x - e^(-x))/2
        return '((${math.e}^($arg) - ${math.e}^(-($arg)))/2)';
      },
    );
    
    processed = processed.replaceAllMapped(
      RegExp(r'cosh\((.*?)\)'),
      (match) {
        String arg = match.group(1)!;
        // cosh(x) = (e^x + e^(-x))/2
        return '((${math.e}^($arg) + ${math.e}^(-($arg)))/2)';
      },
    );
    
    processed = processed.replaceAllMapped(
      RegExp(r'tanh\((.*?)\)'),
      (match) {
        String arg = match.group(1)!;
        // tanh(x) = sinh(x)/cosh(x) = (e^x - e^(-x))/(e^x + e^(-x))
        return '((${math.e}^($arg) - ${math.e}^(-($arg)))/(${math.e}^($arg) + ${math.e}^(-($arg))))';
      },
    );
    
    // Xử lý rad, deg
    if (isDeg) {
      processed = processed.replaceAllMapped(
        RegExp(r'(sin|cos|tan)\((.*?)\)'),
        (match) {
          String func = match.group(1)!;
          String arg = match.group(2)!;
          return '$func(($arg) * ${math.pi}/180)';
        },
      );
    } else {
      processed = processed.replaceAllMapped(
        RegExp(r'(sin|cos|tan)\((.*?)\)'),
        (match) {
          String func = match.group(1)!;
          String arg = match.group(2)!;
          return '$func(($arg))';
        },
      );
    }
    
    // Add missing closing parentheses
    processed = _addClosingParentheses(processed);
    
    return processed;
  }

  static String _addClosingParentheses(String expression) {
    int openCount = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') {
        openCount++;
      } else if (expression[i] == ')') {
        openCount--;
      }
    }
    
    return expression + ')' * (openCount > 0 ? openCount : 0);
  }

  static double degToRad(double degrees) {
    return degrees * math.pi / 180;
  }

  static double radToDeg(double radians) {
    return radians * 180 / math.pi;
  }
}
