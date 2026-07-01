import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, Map<String, double>>((ref) {
  return BudgetNotifier();
});

class BudgetNotifier extends StateNotifier<Map<String, double>> {
  static const String _key = 'category_budgets';

  BudgetNotifier() : super({}) {
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(data);
        final Map<String, double> budgets = {};
        json.forEach((key, value) {
          budgets[key] = (value as num).toDouble();
        });
        state = budgets;
      } catch (e) {
        print("Error loading budgets: $e");
      }
    }
  }

  Future<void> setBudget(String category, double limit) async {
    final budgets = Map<String, double>.from(state);
    if (limit <= 0) {
      budgets.remove(category);
    } else {
      budgets[category] = limit;
    }
    state = budgets;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(budgets));
  }

  Future<void> clearAllBudgets() async {
    state = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
