import 'package:flutter_test/flutter_test.dart';
import 'package:yazgec/core/services/parser_service.dart';

void main() {
  group('YazGeç Parser Service Tests', () {
    test('Should parse simple market expense correctly', () async {
      final result = await ParserService.parse('Bugün markette 450 TL harcadım');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(450.0));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Market'));
      expect(result.description, contains('market'));
    });

    test('Should parse income with thousands separator correctly', () async {
      final result = await ParserService.parse('Maaşım yattı 35.000 TL');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(35000.0));
      expect(result.type, equals('income'));
      expect(result.category, equals('Maaş'));
    });

    test('Should parse fuel expense correctly', () async {
      final result = await ParserService.parse('Benzine 1200 TL verdim');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(1200.0));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Yakıt'));
    });

    test('Should parse freelance income correctly', () async {
      final result = await ParserService.parse('Freelance işten 5000 TL kazandım');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(5000.0));
      expect(result.type, equals('income'));
      expect(result.category, equals('Freelance'));
    });

    test('Should parse double with comma decimals correctly', () async {
      final result = await ParserService.parse('Faturaya 120,50 TL ödedim');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(120.50));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Fatura'));
    });

    test('Should detect yesterday (dün) date correctly', () async {
      final result = await ParserService.parse('Dün akşam yemeğine 350 TL harcadım');
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(result, isNotNull);
      expect(result!.amount, equals(350.0));
      expect(result.type, equals('expense'));
      expect(result.category, equals('Yemek'));
      expect(result.date.day, equals(yesterday.day));
      expect(result.date.month, equals(yesterday.month));
    });

    test('Should parse Turkish slang and suffix (20 BN MAS ALIYOMYOM) correctly', () async {
      final result = await ParserService.parse('AYLIK 20 BN MAS ALIYOMYOM KNK BEN');
      
      expect(result, isNotNull);
      expect(result!.amount, equals(20000.0));
      expect(result.type, equals('income'));
      expect(result.category, equals('Maaş'));
    });

    test('Should parse k suffix correctly (5k, 25 k, 25 K)', () async {
      final r1 = await ParserService.parse('Freelance projem için 5k aldım');
      expect(r1, isNotNull);
      expect(r1!.amount, equals(5000.0));
      
      final r2 = await ParserService.parse('maaşım 25 k');
      expect(r2, isNotNull);
      expect(r2!.amount, equals(25000.0));
      expect(r2.type, equals('income'));
      expect(r2.category, equals('Maaş'));

      final r3 = await ParserService.parse('faturaya 1.5 K verdim');
      expect(r3, isNotNull);
      expect(r3!.amount, equals(1500.0));
      expect(r3.type, equals('expense'));
      expect(r3.category, equals('Fatura'));
    });

    test('Should return null for messages without amount', () async {
      final result = await ParserService.parse('Merhaba nasılsın bugün hava güzel');
      expect(result, isNull);
    });
  });
}
