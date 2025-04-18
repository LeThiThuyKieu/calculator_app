class ExchangeRate {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;

  ExchangeRate({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
  });

  double convert(double amount, String fromCurrency, String toCurrency) {
    // Chuyển đổi về base currency trước
    double inBaseCurrency = fromCurrency == baseCurrency
        ? amount
        : amount / (rates[fromCurrency] ?? 1);
    
    // Chuyển từ base currency sang tiền tệ đích
    return inBaseCurrency * (rates[toCurrency] ?? 1);
  }
} 