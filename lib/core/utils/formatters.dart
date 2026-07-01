import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: 'TL',
    decimalDigits: 0,
  );

  static String formatMoney(double amount, {String symbol = 'TL'}) {
    // If the currency is TL (TRY), use custom Turkish formatting.
    if (symbol == '₺' || symbol == 'TL') {
      return '${_currencyFormatter.format(amount).replaceAll('TL', '').trim()} TL';
    }
    // Else use default double formatting with custom symbol
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Bugün';
    } else if (checkDate == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    }
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
