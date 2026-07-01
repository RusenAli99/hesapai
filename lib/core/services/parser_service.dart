import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ParserResult {
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String description;
  final DateTime date;
  final bool isRecurring;
  final String? recurringInterval;

  ParserResult({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.isRecurring = false,
    this.recurringInterval,
  });

  @override
  String toString() {
    return 'ParserResult(amount: $amount, type: $type, category: $category, description: $description, date: $date, isRecurring: $isRecurring, recurringInterval: $recurringInterval)';
  }
}

class ParserService {
  // Regex to extract numbers (e.g., 450, 1.200, 35000, 45,50, 35,000)
  static final RegExp _amountRegExp = RegExp(
    r'\b\d+(?:[\.,\s]\d{3})*(?:[.,]\d+)?\b',
    caseSensitive: false,
  );

  /// Preprocesses text to handle slang, abbreviations and number suffixes
  static String _preprocessText(String text) {
    String processed = text.toLowerCase().trim();

    // 1. Match numbers followed by thousand suffixes (e.g. 20 bin, 20bin, 20k, 20bn, 20b)
    processed = processed.replaceAllMapped(
      RegExp(r'\b(\d+(?:[.,]\d+)?)\s*(?:bin|bn|k|b)\b', caseSensitive: false),
      (match) {
        final numStr = match.group(1)!;
        final numVal = _parseTurkishDouble(numStr);
        if (numVal != null) {
          final val = numVal * 1000;
          return val % 1 == 0 ? val.toInt().toString() : val.toString();
        }
        return match.group(0)!;
      },
    );

    // 2. Match numbers followed by million suffixes (e.g. 2 milyon, 2m)
    processed = processed.replaceAllMapped(
      RegExp(r'\b(\d+(?:[.,]\d+)?)\s*(?:milyon|m)\b', caseSensitive: false),
      (match) {
        final numStr = match.group(1)!;
        final numVal = _parseTurkishDouble(numStr);
        if (numVal != null) {
          final val = numVal * 1000000;
          return val % 1 == 0 ? val.toInt().toString() : val.toString();
        }
        return match.group(0)!;
      },
    );

    return processed;
  }

  /// Main parse function (runs Gemini API with local Regex fallback)
  static Future<ParserResult?> parse(String text) async {
    if (text.trim().isEmpty) return null;

    // 1. Try Gemini API via secure Proxy Server
    try {
      // Determine host: Android Emulator needs 10.0.2.2, others can use localhost
      String host = 'localhost';
      if (!kIsWeb && Platform.isAndroid) {
        host = '10.0.2.2';
      }

      final url = Uri.parse('http://$host:3000/api/parse');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ParserResult(
          amount: (data['amount'] as num).toDouble(),
          type: data['type'] ?? 'expense',
          category: data['category'] ?? 'Diğer',
          description: data['description'] ?? '',
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          isRecurring: data['isRecurring'] ?? false,
          recurringInterval: data['recurringInterval'],
        );
      } else {
        print("Gemini Proxy server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Gemini API proxy connection failed, falling back to local parsing: $e");
    }

    // 2. Fallback: Parse locally using Regex/rules
    return _parseLocally(text);
  }

  /// Internal local parsing fallback using Regex/rules
  static ParserResult? _parseLocally(String text) {
    if (text.trim().isEmpty) return null;

    final cleanedText = text.trim();
    final preprocessedText = _preprocessText(cleanedText);

    // 1. Extract Amount
    final double? amount = _extractAmount(preprocessedText);
    if (amount == null || amount <= 0) return null;

    // 2. Determine Type (Income/Expense)
    final String type = _determineType(preprocessedText);

    // 3. Determine Category
    final String category = _determineCategory(preprocessedText, type);

    // 4. Determine Date (default to today, look for keywords like "dün", "geçen hafta")
    final DateTime date = _determineDate(preprocessedText);

    // 5. Determine Recurrence (routine keywords)
    bool isRecurring = false;
    String? recurringInterval;

    if (preprocessedText.contains('her ay') || preprocessedText.contains('aylık') || preprocessedText.contains('aylik')) {
      isRecurring = true;
      recurringInterval = 'monthly';
    } else if (preprocessedText.contains('her hafta') || preprocessedText.contains('haftalık') || preprocessedText.contains('haftalik')) {
      isRecurring = true;
      recurringInterval = 'weekly';
    } else if (preprocessedText.contains('her yıl') || preprocessedText.contains('her yil') || preprocessedText.contains('yıllık') || preprocessedText.contains('yillik')) {
      isRecurring = true;
      recurringInterval = 'yearly';
    }

    // 6. Clean description (capitalize first letter, keep length reasonable)
    String description = cleanedText;
    if (description.length > 100) {
      description = '${description.substring(0, 97)}...';
    }

    return ParserResult(
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
    );
  }

  /// Extracts the numerical amount from Turkish text
  static double? _extractAmount(String text) {
    // Find all numbers in text
    final Iterable<RegExpMatch> matches = _amountRegExp.allMatches(text);
    if (matches.isEmpty) return null;

    double? bestAmount;
    
    for (final match in matches) {
      String matchText = match.group(0)!;
      double? parsed = _parseTurkishDouble(matchText);
      if (parsed != null && parsed > 0) {
        // In personal finance, we usually want the largest number or the first number.
        final index = match.start;
        final remainingText = text.substring(index + matchText.length).trim();
        
        bool isCurrencyFollowed = remainingText.startsWith('tl') ||
            remainingText.startsWith('lira') ||
            remainingText.startsWith('₺') ||
            remainingText.startsWith('dolar') ||
            remainingText.startsWith('euro') ||
            remainingText.startsWith(r'$') ||
            remainingText.startsWith('€');
            
        if (isCurrencyFollowed) {
          return parsed; // Direct match!
        }
        
        // If the new one is larger, it might be the price (e.g. 3 items for 150 TL)
        if (bestAmount == null) {
          bestAmount = parsed;
        } else {
          if (parsed > bestAmount && bestAmount < 10) {
            bestAmount = parsed;
          }
        }
      }
    }

    return bestAmount;
  }

  /// Helper to parse Turkish formatted doubles (e.g. 1.200, 35.000, 45,5)
  static double? _parseTurkishDouble(String text) {
    // Remove all spaces
    String cleaned = text.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.contains('.') && cleaned.contains(',')) {
      // 1.250,50 -> 1250.50
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      // 450,50 -> 450.50 or 35,000 (if English formatting used)
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 3 && ((int.tryParse(parts[0]) ?? 0) > 100)) {
        // e.g. 35,000 -> 35000
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // e.g. 45,5 -> 45.5
        cleaned = cleaned.replaceAll(',', '.');
      }
    } else if (cleaned.contains('.')) {
      // 35.000 or 45.50
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(cleaned);
  }

  /// Determines the type (income/expense) using scores with robust weights
  static String _determineType(String text) {
    int incomeScore = 0;
    int expenseScore = 0;

    // Strong Income Indicators (+3)
    final strongIncome = [
      'maaş', 'maas', 'maaşım', 'maasim', 'maaşımı', 'maasimi', 'mas',
      'burs', 'bursum', 'bursumu',
      'freelance', 'kazandım', 'kazandim', 'gelir', 'gelirim',
      'yattı', 'yatti', 'yatmış', 'yatmis', 'yatan',
      'sattım', 'sattim', 'satış', 'satis'
    ];

    // Medium Income Indicators (+1)
    final mediumIncome = [
      'aylık', 'aylik', 'aldım', 'aldim', 'alıyorum', 'aliyom', 'aliyomyom',
      'geldi', 'giriş', 'giris', 'yükledim', 'yukledim'
    ];

    // Strong Expense Indicators (+3)
    final strongExpense = [
      'harcadım', 'harcadim', 'harcadık', 'harcadik', 'harcama', 'harcaması',
      'ödedim', 'odedim', 'ödeme', 'odeme',
      'verdim', 'verdik', 'gitti', 'giden',
      'masraf', 'gider', 'fatura', 'faturası', 'faturasi'
    ];

    // Medium Expense Indicators (+1)
    final mediumExpense = [
      'aldım', 'aldim', 'aldık', 'aldik',
      'çekti', 'cekti', 'çekildi', 'cekildi',
      'yedim', 'içtim', 'ictim', 'yemek',
      'market', 'bakkal', 'manav', 'kasap',
      'satın', 'satin'
    ];

    // Calculate scores
    for (final word in strongIncome) {
      if (text.contains(word)) {
        incomeScore += 3;
      }
    }
    for (final word in mediumIncome) {
      if (text.contains(word)) {
        incomeScore += 1;
      }
    }

    for (final word in strongExpense) {
      if (text.contains(word)) {
        expenseScore += 3;
      }
    }
    for (final word in mediumExpense) {
      if (text.contains(word)) {
        expenseScore += 1;
      }
    }

    // Special context checks:
    // If it contains "maaş" or similar and also "aldım" or "alıyorum", it's definitely income
    if ((text.contains('maaş') || text.contains('maas') || text.contains('mas') || text.contains('aylık') || text.contains('aylik')) &&
        (text.contains('aldım') || text.contains('aldim') || text.contains('alıyorum') || text.contains('aliyom') || text.contains('aliyomyom'))) {
      incomeScore += 5;
    }

    // If it contains an expense category keyword and a neutral verb like "aldım", it's definitely an expense
    final expenseCategoriesKeywords = [
      'market', 'yemek', 'fatura', 'ulaşım', 'ulasim', 'benzin', 'yakıt', 'yakit', 'kira',
      'sinema', 'tiyatro', 'bilet', 'restoran', 'cafe', 'kafe', 'kıyafet', 'kiyafet'
    ];
    for (final keyword in expenseCategoriesKeywords) {
      if (text.contains(keyword)) {
        expenseScore += 2;
        if (text.contains('aldım') || text.contains('aldim')) {
          expenseScore += 3;
        }
      }
    }

    return incomeScore > expenseScore ? 'income' : 'expense';
  }

  /// Maps the text to a category depending on the transaction type
  static String _determineCategory(String text, String type) {
    if (type == 'income') {
      if (text.contains('maaş') || text.contains('maas') || text.contains('aylık') || text.contains('aylik') || text.contains('mas')) {
        return 'Maaş';
      }
      if (text.contains('freelance') || text.contains('ek iş') || text.contains('proje') || text.contains('kodlama') || text.contains('tasarım')) {
        return 'Freelance';
      }
      if (text.contains('yatırım') || text.contains('borsa') || text.contains('hisse') || text.contains('kripto') || text.contains('faiz') || text.contains('temettü') || text.contains('altın')) {
        return 'Yatırım';
      }
      return 'Diğer Gelir';
    } else {
      // Expense Categories mapping
      final categoryMap = {
        'Market': ['market', 'bakkal', 'manav', 'kasap', 'migros', 'bim', 'a101', 'şok', 'sok', 'carrefour', 'tekel', 'şarküteri', 'sarkuteri', 'deterjan', 'sabun'],
        'Yemek': ['yemek', 'restoran', 'lokanta', 'cafe', 'kafe', 'starbucks', 'döner', 'doner', 'kebap', 'pizza', 'hamburger', 'çorba', 'corba', 'kahve', 'çay', 'cay', 'tatlı', 'tatli', 'restorant', 'yemeksepeti', 'getiryemek', 'trendyolyemek', 'öğle', 'ogle', 'akşam', 'aksam', 'kahvaltı', 'kahvalti'],
        'Ulaşım': ['ulaşım', 'ulasim', 'otobüs', 'otobus', 'metro', 'akbil', 'taksi', 'dolmuş', 'dolmus', 'marmaray', 'bilet', 'uçak', 'ucak', 'tren', 'vapur', 'kartkart'],
        'Yakıt': ['benzin', 'yakıt', 'yakit', 'mazot', 'dizel', 'lpg', 'shell', 'opet', 'petrol', 'depo', 'akaryakıt', 'akaryakit'],
        'Fatura': ['fatura', 'faturası', 'faturasi', 'elektrik', 'su', 'doğalgaz', 'dogalgaz', 'gaz', 'internet', 'kira', 'kirası', 'kirasi', 'aidat', 'telefon', 'netflix', 'spotify', 'youtube', 'abonelik', 'gsm', 'turkcell', 'vodafone', 'türk telekom'],
        'Eğlence': ['eğlence', 'eglence', 'sinema', 'tiyatro', 'konser', 'pub', 'bar', 'kulüp', 'kulup', 'parti', 'bira', 'alkol', 'playstation', 'steam', 'oyun', 'müzik', 'muzik', 'gezi', 'tatil'],
        'Sağlık': ['sağlık', 'saglik', 'eczane', 'ilaç', 'ilac', 'doktor', 'hastane', 'klinik', 'diş', 'dis', 'muayene', 'tahlil', 'ameliyat', 'optik', 'gözlük', 'gozluk'],
        'Eğitim': ['eğitim', 'egitim', 'okul', 'kurs', 'kitap', 'kırtasiye', 'kirtasiye', 'harç', 'harc', 'üni', 'uni', 'üniversite', 'universite', 'ders', 'kalem', 'defter', 'kütüphane', 'kutupane'],
        'Alışveriş': ['alışveriş', 'alisveris', 'kıyafet', 'kiyafet', 'elbise', 'ayakkabı', 'ayakkabi', 'trendyol', 'hepsiburada', 'amazon', 'zara', 'mango', 'tişört', 'tisort', 'pantolon', 'mont', 'ceket', 'saat', 'çanta', 'canta', 'teknoloji', 'telefon', 'bilgisayar', 'kulaklık', 'mobilya', 'dekorasyon'],
      };

      for (final entry in categoryMap.entries) {
        for (final keyword in entry.value) {
          if (text.contains(keyword)) {
            return entry.key;
          }
        }
      }

      return 'Diğer';
    }
  }

  /// Determines the transaction date based on keywords (defaults to today)
  static DateTime _determineDate(String text) {
    final now = DateTime.now();
    if (text.contains('dün') || text.contains('dun')) {
      return now.subtract(const Duration(days: 1));
    }
    if (text.contains('evvelsi gün') || text.contains('önceki gün') || text.contains('onceki gun')) {
      return now.subtract(const Duration(days: 2));
    }
    return now;
  }
}
