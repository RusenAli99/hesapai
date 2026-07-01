import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/summary_card.dart';
import 'widgets/transaction_tile.dart';
import '../shared/month_selector.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String displayName = user?.name ?? 'Kullanıcı';
    final String symbol = user?.currencySymbol ?? '₺';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          () {
                            final hour = DateTime.now().hour;
                            if (hour >= 6 && hour < 12) return 'Günaydın ☀️';
                            if (hour >= 12 && hour < 18) return 'Tünaydın 🌤️';
                            if (hour >= 18 && hour < 23) return 'İyi Akşamlar 🌙';
                            return 'İyi Geceler 🌌';
                          }(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const MonthSelector(),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: isDark ? AppColors.bgDark : Colors.white,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              transactionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Veri yüklenirken hata oluştu: $err'),
                  ),
                ),
                data: (transactions) {
                  // Calculate monthly summary based on selected month
                  final selectedMonth = ref.watch(selectedMonthProvider);
                  final currentMonthTransactions = transactions.where((t) {
                    return t.createdAt.month == selectedMonth.month && t.createdAt.year == selectedMonth.year;
                  }).toList();

                  // Sort by date descending
                  currentMonthTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  double monthlyIncome = 0.0;
                  double monthlyExpense = 0.0;

                  for (final t in currentMonthTransactions) {
                    if (t.type == 'income') {
                      monthlyIncome += t.amount;
                    } else {
                      monthlyExpense += t.amount;
                    }
                  }

                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        SummaryCard(
                          totalIncome: monthlyIncome,
                          totalExpense: monthlyExpense,
                          symbol: symbol,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Recent Transactions label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Son İşlemler',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (currentMonthTransactions.isNotEmpty)
                              Text(
                                '${currentMonthTransactions.length} İşlem',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Transaction List
                        Expanded(
                          child: currentMonthTransactions.isEmpty
                              ? _buildEmptyState(context, isDark)
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: currentMonthTransactions.length,
                                  itemBuilder: (context, index) {
                                    final item = currentMonthTransactions[index];
                                    return TransactionTile(
                                      transaction: item,
                                      symbol: symbol,
                                      onDelete: () {
                                        ref.read(transactionControllerProvider).deleteTransaction(item.id);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz İşlem Eklenmemiş',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sohbet sekmesine gidip konuşur gibi yazarak ilk işlem kaydınızı hemen yapın!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
