import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/budget_provider.dart';

class CategoryProgressBars extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String symbol;

  const CategoryProgressBars({
    super.key,
    required this.transactions,
    required this.symbol,
  });

  void _editBudget(BuildContext context, WidgetRef ref, String category, double? currentLimit) {
    final controller = TextEditingController(
      text: currentLimit != null && currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$category Bütçe Limiti',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu kategori için aylık maksimum harcama limiti belirleyin:',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                labelText: 'Aylık Limit',
                labelStyle: GoogleFonts.outfit(),
                hintText: 'Bütçe belirtmek için bir sayı yazın',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: '$symbol ',
                suffixText: ' TL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final double limit = double.tryParse(controller.text) ?? 0.0;
              ref.read(budgetNotifierProvider.notifier).setBudget(category, limit);
              Navigator.pop(context);
            },
            child: Text('Kaydet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenses = transactions.where((t) => t.type == 'expense').toList();

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Watch budgets
    final budgets = ref.watch(budgetNotifierProvider);

    // Group expenses by category
    final Map<String, double> categorySums = {};
    for (final e in expenses) {
      categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
    }

    // Sort categories by expenditure (largest first)
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find the maximum category sum to scale fallback progress bars
    final maxCategorySum = sortedCategories.isEmpty ? 1.0 : sortedCategories.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.align_horizontal_left_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Harcama Yoğunluğu & Bütçeler',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final categoryName = entry.key;
                final amount = entry.value;
                
                final double? budgetLimit = budgets[categoryName];
                final bool hasBudget = budgetLimit != null && budgetLimit > 0;
                final bool isOverBudget = hasBudget && amount > budgetLimit;
                
                final color = isOverBudget ? AppColors.expense : AppColors.getCategoryColor(categoryName);
                final icon = AppColors.getCategoryIcon(categoryName);
                
                // Ratio of this category relative to its budget limit, or relative to max category sum as fallback
                final double progressRatio = hasBudget 
                    ? (amount / budgetLimit) 
                    : (maxCategorySum > 0 ? (amount / maxCategorySum) : 0.0);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: isOverBudget ? AppColors.expense : color),
                        const SizedBox(width: 8),
                        Text(
                          categoryName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _editBudget(context, ref, categoryName, budgetLimit),
                          child: Icon(
                            hasBudget ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                            size: 14,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  Formatters.formatMoney(amount, symbol: symbol),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isOverBudget ? AppColors.expense : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (hasBudget) ...[
                                  Text(
                                    ' / ${Formatters.formatMoney(budgetLimit, symbol: symbol)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (hasBudget) ...[
                              Text(
                                isOverBudget
                                    ? 'Limit aşıldı: -${Formatters.formatMoney(amount - budgetLimit, symbol: symbol)} 🚨'
                                    : 'Kalan: ${Formatters.formatMoney(budgetLimit - amount, symbol: symbol)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isOverBudget ? AppColors.expense : Colors.green,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Bütçe tanımlanmamış',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        // Background track
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill bar
                        FractionallySizedBox(
                          widthFactor: progressRatio.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
