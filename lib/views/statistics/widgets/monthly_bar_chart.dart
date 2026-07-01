import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const MonthlyBarChart({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Identify the last 5 months
    final List<DateTime> months = [];
    final now = DateTime.now();
    for (int i = 4; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    // 2. Sum up Income and Expense for each month
    final List<BarChartGroupData> barGroups = [];
    double maxVal = 1000.0; // Dynamic scale baseline

    for (int i = 0; i < months.length; i++) {
      final monthDate = months[i];
      double monthlyIncome = 0.0;
      double monthlyExpense = 0.0;

      for (final t in transactions) {
        if (t.createdAt.month == monthDate.month && t.createdAt.year == monthDate.year) {
          if (t.type == 'income') {
            monthlyIncome += t.amount;
          } else {
            monthlyExpense += t.amount;
          }
        }
      }

      if (monthlyIncome > maxVal) maxVal = monthlyIncome;
      if (monthlyExpense > maxVal) maxVal = monthlyExpense;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Income Rod
            BarChartRodData(
              toY: monthlyIncome,
              color: AppColors.income,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            // Expense Rod
            BarChartRodData(
              toY: monthlyExpense,
              color: AppColors.expense,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Aylık Karşılaştırma',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // The Bar Chart itself
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.15,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark ? AppColors.cardDark : Colors.white,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final String category = rodIndex == 0 ? 'Gelir' : 'Gider';
                        return BarTooltipItem(
                          '$category\n${rod.toY.toStringAsFixed(0)} TL',
                          TextStyle(
                            color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            final monthName = DateFormat('MMM', 'tr_TR').format(months[idx]);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthName,
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide Y values for clean look
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.income, 'Gelir'),
                const SizedBox(width: 24),
                _buildLegendItem(AppColors.expense, 'Gider'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
