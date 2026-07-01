import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_colors.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final String monthName = DateFormat('MMMM yyyy', 'tr_TR').format(selectedMonth);

    // Capitalize the first letter of monthName (e.g. temmuz 2026 -> Temmuz 2026)
    final String capitalizedMonthName = monthName.isNotEmpty
        ? '${monthName[0].toUpperCase()}${monthName.substring(1)}'
        : monthName;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
            },
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                helpText: 'GÖRÜNTÜLENECEK TARİHİ SEÇİN',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: isDark ? const Color(0xFF1E1B4B) : Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state = DateTime(
                  picked.year,
                  picked.month,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Text(
                    capitalizedMonthName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}
