class AppConstants {
  static const String appName = 'YazGeç';

  // Income Categories
  static const List<String> incomeCategories = [
    'Maaş',
    'Freelance',
    'Yatırım',
    'Diğer Gelir',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Market',
    'Yemek',
    'Ulaşım',
    'Yakıt',
    'Fatura',
    'Eğlence',
    'Sağlık',
    'Eğitim',
    'Alışveriş',
    'Diğer',
  ];

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'TRY', 'symbol': 'TL', 'name': 'Türk Lirası'},
    {'code': 'USD', 'symbol': r'$', 'name': 'ABD Doları'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'İngiliz Sterlini'},
  ];

  static const String defaultCurrencyCode = 'TRY';
  static const String defaultCurrencySymbol = 'TL';
}
