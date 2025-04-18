import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String baseUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  
  // Singleton pattern
  static final CurrencyService _instance = CurrencyService._internal();
  
  factory CurrencyService() {
    return _instance;
  }
  
  CurrencyService._internal();

  // Lưu trữ tỉ giá để tránh gọi API nhiều lần
  Map<String, double> _exchangeRates = {};
  DateTime? _lastUpdated;

  // Getter cho tỉ giá
  Map<String, double> get exchangeRates => _exchangeRates;
  DateTime? get lastUpdated => _lastUpdated;

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

  // Fetch tỉ giá từ API
  Future<Map<String, double>> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);
        _lastUpdated = DateTime.now();
        return _exchangeRates;
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      throw Exception('Error fetching exchange rates: $e');
    }
  }

  // Convert tiền tệ
  double convertCurrency(
    String amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (_exchangeRates.isEmpty) return 0;
    
    double amountDouble;
    try {
      amountDouble = double.parse(amount);
    } catch (e) {
      return 0;
    }
    
    // Chuyển đổi về USD trước
    double inUSD = fromCurrency == "USD" 
        ? amountDouble 
        : amountDouble / (_exchangeRates[fromCurrency] ?? 1);
    
    // Chuyển từ USD sang tiền tệ đích
    return inUSD * (_exchangeRates[toCurrency] ?? 1);
  }

  // Kiểm tra xem có cần cập nhật tỉ giá không (ví dụ: mỗi 1 giờ)
  bool shouldUpdate() {
    if (_lastUpdated == null) return true;
    
    final difference = DateTime.now().difference(_lastUpdated!);
    return difference.inHours >= 1;
  }
} 