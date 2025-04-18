import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/currency_service.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final CurrencyService _currencyService = CurrencyService();
  String currentInput = "0";
  String result = "0,00";
  String selectedFromCurrency = "USD";
  String selectedToCurrency = "VND";
  String lastUpdated = "";

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      await _currencyService.fetchExchangeRates();
      setState(() {
        lastUpdated = DateFormat('dd thg M, yyyy HH:mm:ss')
            .format(_currencyService.lastUpdated!);
        _updateResult();
      });
    } catch (e) {
      if(kDebugMode){
        print('Error loading exchange rates: $e');
      }
    }
  }

  void _updateResult() {
    try {
      if (currentInput == "0" || currentInput.isEmpty) {
        setState(() {
          result = "0,00";
        });
        return;
      }

      double converted = _currencyService.convertCurrency(
        currentInput,
        selectedFromCurrency,
        selectedToCurrency
      );
      setState(() {
        result = NumberFormat("#,##0.00", "vi_VN").format(converted);
      });
    } catch (e) {
      setState(() {
        result = "Lỗi";
      });
    }
  }

  void _onButtonPressed(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          currentInput = '0';
          result = '0,00';
          break;
        case '⌫':
          if (currentInput.length > 1) {
            currentInput = currentInput.substring(0, currentInput.length - 1);
          } else {
            currentInput = '0';
          }
          _updateResult();
          break;
        case '=':
          _updateResult();
          break;
        case ',':
          if (!currentInput.contains('.')) {
            currentInput += '.';
          }
          break;
        case '×':
        case '÷':
        case '+':
        case '-':
          // Bỏ qua các phép toán này trong chuyển đổi tiền tệ
          break;
        default:
          // Xử lý nhập số
          if (RegExp(r'[0-9]').hasMatch(value)) {
            if (currentInput == "0") {
              currentInput = value;
            } else {
              currentInput += value;
            }
            _updateResult();
          }
      }
    });
  }

  void _showCurrencyPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn loại tiền tệ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: CurrencyService.supportedCurrencies.length,
                  itemBuilder: (context, index) {
                    String code = CurrencyService.supportedCurrencies.keys.elementAt(index);
                    String name = CurrencyService.supportedCurrencies[code]!;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(code),
                      onTap: () {
                        setState(() {
                          if (isFrom) {
                            selectedFromCurrency = code;
                          } else {
                            selectedToCurrency = code;
                          }
                          _updateResult();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencySelector(bool isFrom) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyService.supportedCurrencies[
                    isFrom ? selectedFromCurrency : selectedToCurrency
                  ]!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFrom ? selectedFromCurrency : selectedToCurrency,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tỷ giá hối đoái'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Currency selectors
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _showCurrencyPicker(true),
                  child: _buildCurrencySelector(true),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showCurrencyPicker(false),
                  child: _buildCurrencySelector(false),
                ),
              ],
            ),
          ),

          // Exchange rate info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Dữ liệu từ xCurrency, $lastUpdated',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),

          const Spacer(),

          // Calculator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentInput,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                        ),
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

                // Buttons
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  childAspectRatio: 1.5,
                  children: [
                    'AC', '⌫', '×', '÷',
                    '7', '8', '9', '-',
                    '4', '5', '6', '+',
                    '1', '2', '3', '=',
                    '00', '0', ',', '',
                  ].map((key) {
                    return Container(
                      padding: const EdgeInsets.all(4),
                      child: key.isEmpty ? Container() : TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: ['+', '-', '×', '÷'].contains(key)
                              ? Colors.blue[100]
                              : key == '='
                                  ? Colors.blue[800]
                                  : Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => _onButtonPressed(key),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 24,
                            color: key == '=' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 