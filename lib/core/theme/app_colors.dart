import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Violet Accent
  
  // Financial State Colors
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFEF4444); // Coral Red
  static const Color savings = Color(0xFF3B82F6); // Blue
  
  // Dark Theme Palette
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark = Color(0xFF334155); // Slate 700
  
  // Light Theme Palette
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Category Icons & Colors
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      // Income
      case 'maaş':
        return const Color(0xFF059669);
      case 'freelance':
        return const Color(0xFF0284C7);
      case 'yatırım':
        return const Color(0xFF7C3AED);
      case 'diğer gelir':
        return const Color(0xFF0F766E);
      
      // Expense
      case 'market':
        return const Color(0xFFEA580C);
      case 'yemek':
        return const Color(0xFFD97706);
      case 'ulaşım':
        return const Color(0xFF2563EB);
      case 'yakıt':
        return const Color(0xFF4F46E5);
      case 'fatura':
        return const Color(0xFF0891B2);
      case 'eğlence':
        return const Color(0xFFDB2777);
      case 'sağlık':
        return const Color(0xFFE11D48);
      case 'eğitim':
        return const Color(0xFF9333EA);
      case 'alışveriş':
        return const Color(0xFF475569);
      case 'diğer':
      default:
        return const Color(0xFF64748B);
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      // Income
      case 'maaş':
        return Icons.account_balance_wallet_rounded;
      case 'freelance':
        return Icons.computer_rounded;
      case 'yatırım':
        return Icons.trending_up_rounded;
      case 'diğer gelir':
        return Icons.add_card_rounded;
      
      // Expense
      case 'market':
        return Icons.shopping_basket_rounded;
      case 'yemek':
        return Icons.restaurant_rounded;
      case 'ulaşım':
        return Icons.directions_bus_rounded;
      case 'yakıt':
        return Icons.local_gas_station_rounded;
      case 'fatura':
        return Icons.receipt_long_rounded;
      case 'eğlence':
        return Icons.celebration_rounded;
      case 'sağlık':
        return Icons.medical_services_rounded;
      case 'eğitim':
        return Icons.school_rounded;
      case 'alışveriş':
        return Icons.shopping_bag_rounded;
      case 'diğer':
      default:
        return Icons.category_rounded;
    }
  }
}
