import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/category_progress_bars.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/vector_wave_chart.dart';
import '../shared/month_selector.dart';
import '../shared/fade_in_slide.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction_model.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final String symbol = user?.currencySymbol ?? '₺';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Raporu Paylaş',
            onPressed: () {
              final allTransactions = ref.read(transactionsProvider).value ?? [];
              final selectedMonth = ref.read(selectedMonthProvider);
              final transactions = allTransactions.where((t) {
                return t.createdAt.year == selectedMonth.year &&
                       t.createdAt.month == selectedMonth.month;
              }).toList();
              
              if (transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bu aya ait aktarılacak işlem bulunamadı.')),
                );
                return;
              }
              
              final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(selectedMonth);
              final capitalizedMonthName = monthName.isNotEmpty
                  ? '${monthName[0].toUpperCase()}${monthName.substring(1)}'
                  : monthName;

              _exportToCsv(context, transactions, capitalizedMonthName);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: MonthSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text('Veriler yüklenirken hata oluştu: $err'),
          ),
          data: (allTransactions) {
            // Filter transactions by selected month
            final selectedMonth = ref.watch(selectedMonthProvider);
            final transactions = allTransactions.where((t) {
              return t.createdAt.year == selectedMonth.year &&
                     t.createdAt.month == selectedMonth.month;
            }).toList();

            if (transactions.isEmpty) {
              return _buildEmptyState(context, isDark);
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Yapay Zeka Harcama Analiz Raporu Card
                  FadeInSlide(
                    delay: Duration.zero,
                    child: GestureDetector(
                      onTap: () => _showAiInsights(context, ref, transactions),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4FACFE),
                              Color(0xFF00F2FE),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F2FE).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yapay Zeka Harcama Analizi',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gemini ile bütçenizi yorumlayın ve tasarruf tavsiyeleri alın.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Pie Chart Card (Category Distribution)
                  FadeInSlide(
                    delay: const Duration(milliseconds: 150),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.pie_chart_rounded, size: 20, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Kategori Bazlı Dağılım',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            CategoryPieChart(
                              transactions: transactions,
                              symbol: symbol,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category Progress Bars (Expense Intensity)
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: CategoryProgressBars(
                      transactions: transactions,
                      symbol: symbol,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Vector Wave Chart
                  FadeInSlide(
                    delay: const Duration(milliseconds: 450),
                    child: VectorWaveChart(
                      transactions: transactions,
                      symbol: symbol,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bar Chart (Monthly Trend of all transactions)
                  FadeInSlide(
                    delay: const Duration(milliseconds: 600),
                    child: MonthlyBarChart(transactions: allTransactions),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, List<TransactionModel> transactions, String monthName) async {
    try {
      final buffer = StringBuffer('\uFEFF');
      buffer.writeln('Tarih,Tip,Kategori,Tutar,Açıklama');

      for (final t in transactions) {
        final dateStr = DateFormat('dd.MM.yyyy').format(t.createdAt);
        final typeStr = t.type == 'income' ? 'Gelir' : 'Gider';
        final amountStr = t.amount.toStringAsFixed(2);
        final descEscaped = t.description.replaceAll('"', '""');
        
        buffer.writeln('$dateStr,$typeStr,${t.category},$amountStr,"$descEscaped"');
      }

      final directory = await getTemporaryDirectory();
      final String path = '${directory.path}/YazGec_Rapor_${monthName.replaceAll(' ', '_')}.csv';
      
      final file = File(path);
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'YazGeç Harcama Raporu - $monthName',
        text: 'YazGeç harcama asistanı tarafından oluşturulan $monthName raporu.',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapor dışa aktarılırken hata oluştu: $e')),
      );
    }
  }

  void _showAiInsights(BuildContext context, WidgetRef ref, List<TransactionModel> transactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top drag bar indicator
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'AI Harcama Analiz Raporu',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: FutureBuilder<String>(
                  future: _fetchInsights(ref, transactions),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 20),
                            Text(
                              'Gemini bütçenizi analiz ediyor...',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.expense),
                              const SizedBox(height: 16),
                              Text(
                                'Rapor oluşturulamadı.',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Proxy sunucusunun açık ve internet bağlantınızın olduğundan emin olun.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24.0),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Akıllı Tasarruf Özetiniz',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  snapshot.data ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '* Bu analiz sadece seçili aya ait harcamalarınızı ve koyduğunuz bütçe limitlerini temel almaktadır.',
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _fetchInsights(WidgetRef ref, List<TransactionModel> transactions) async {
    final budgets = ref.read(budgetNotifierProvider);

    final txData = transactions.map((t) => {
      'amount': t.amount,
      'type': t.type,
      'category': t.category,
      'description': t.description,
      'date': t.createdAt.toIso8601String().split('T')[0]
    }).toList();

    String host = 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      host = '10.0.2.2';
    }

    final response = await http.post(
      Uri.parse('http://$host:3000/api/insights'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transactions': txData,
        'budgets': budgets,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['insights'] ?? 'Analiz verisi bulunamadı.';
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Grafik Verisi Yok',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İstatistiklerin oluşturulabilmesi için öncelikle işlem verisi eklemelisiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
