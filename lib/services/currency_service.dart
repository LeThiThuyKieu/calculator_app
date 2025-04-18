import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/currency.dart';
import '../models/exchange_rate.dart';

class CurrencyService {
  static const String url = 'https://v6.exchangerate-api.com/v6/08b7273b010d4b690a799708/latest/USD';
  static final CurrencyService _instance = CurrencyService._internal();
  
  factory CurrencyService() {
    return _instance;
  }
  
  CurrencyService._internal() {
    _initCurrencies();
  }

  // Lưu trữ dữ liệu
  ExchangeRate? _exchangeRate;
  List<Currency> _currencies = [];

  // Getters
  ExchangeRate? get exchangeRate => _exchangeRate;
  List<Currency> get currencies => _currencies;
  DateTime? get lastUpdated => _exchangeRate?.lastUpdated;

  // Hỗ trợ với các hàm cũ
  Map<String, double> get exchangeRates => _exchangeRate?.rates ?? {};

  // Danh sách tiền tệ hỗ trợ
  static final Map<String, String> supportedCurrencies = {
    "USD": "Dollar Mỹ",
    "VND": "Đồng Việt Nam",
    "EUR": "Euro",
    "GBP": "Bảng Anh",
    "JPY": "Yên Nhật",
    "KRW": "Won Hàn Quốc",
    "CNY": "Nhân dân tệ",
  };

  // Khởi tạo danh sách tiền tệ
  void _initCurrencies() {
    _currencies = supportedCurrencies.entries
        .map((entry) => Currency(code: entry.key, name: entry.value))
        .toList();
  }

  // Lấy tỉ giá từ API
  Future<ExchangeRate> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRate = ExchangeRate(
          baseCurrency: "USD",
          rates: (data['conversion_rates'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
          lastUpdated: DateTime.now(),
        );
        return _exchangeRate!;
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      throw Exception('Error fetching exchange rates: $e');
    }
  }

  // Convert tiền tệ
  double convertCurrency(String amount,String fromCurrency,String toCurrency,) {
    if (_exchangeRate == null) return 0;

    double amountDouble;
    try {
      amountDouble = double.parse(amount);
    } catch (e) {
      return 0;
    }
    
    return _exchangeRate!.convert(amountDouble, fromCurrency, toCurrency);
  }

  // Lấy tên của một loại tiền tệ
  String getCurrencyName(String code) {
    final currency = _currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency(code: code, name: code),
    );
    return currency.name;
  }

  // Kiểm tra xem có cần cập nhật tỉ giá không
  bool shouldUpdate() {
    if (_exchangeRate == null) return true;
    
    final difference = DateTime.now().difference(_exchangeRate!.lastUpdated);
    return difference.inHours >= 1;
  }
} 