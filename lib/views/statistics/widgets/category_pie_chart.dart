import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class CategoryPieChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String symbol;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    this.symbol = 'TL',
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expenses = widget.transactions.where((t) => t.type == 'expense').toList();
    
    if (expenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Gider işlemi bulunmadığından grafik çizilemiyor.'),
        ),
      );
    }

    // 1. Group expenses by category
    final Map<String, double> categorySums = {};
    double totalExpenseSum = 0.0;
    
    for (final e in expenses) {
      categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
      totalExpenseSum += e.amount;
    }

    // 2. Map sums to PieChart sections
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final percentage = (entry.value / totalExpenseSum) * 100;

      sections.add(
        PieChartSectionData(
          color: AppColors.getCategoryColor(entry.key),
          value: entry.value,
          title: '%${percentage.toStringAsFixed(0)}',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Legends List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          itemBuilder: (context, idx) {
            final entry = sortedCategories[idx];
            final color = AppColors.getCategoryColor(entry.key);
            final percent = (entry.value / totalExpenseSum) * 100;
            final isTouched = idx == touchedIndex;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isTouched ? color.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.formatMoney(entry.value, symbol: widget.symbol),
                    style: TextStyle(
                      fontWeight: isTouched ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%${percent.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
