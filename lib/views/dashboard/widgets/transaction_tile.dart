import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/transaction_provider.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final String symbol;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.symbol = 'TL',
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final amountPrefix = isIncome ? '+' : '-';
    
    final categoryColor = AppColors.getCategoryColor(transaction.category);
    final categoryIcon = AppColors.getCategoryIcon(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.expense.withOpacity(0.1),
              AppColors.expense,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('İşlemi Sil'),
            content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Colored Bar Indicator (Income vs Expense)
                Container(
                  width: 5,
                  color: amountColor,
                ),
                Expanded(
                  child: ListTile(
                    onTap: () => _showEditBottomSheet(context, ref),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      transaction.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          transaction.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Formatters.formatDate(transaction.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withOpacity(0.7),
                              ),
                            ),
                            if (transaction.isRecurring) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sync_rounded, size: 10, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      transaction.recurringInterval == 'weekly'
                                          ? 'Haftalık'
                                          : transaction.recurringInterval == 'yearly'
                                              ? 'Yıllık'
                                              : 'Aylık',
                                      style: const TextStyle(
                                        fontSize: 9, 
                                        color: AppColors.primary, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      '$amountPrefix${Formatters.formatMoney(transaction.amount, symbol: symbol)}',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Form controllers
    final amountController = TextEditingController(text: transaction.amount.toStringAsFixed(0));
    final descriptionController = TextEditingController(text: transaction.description);
    String selectedCategory = transaction.category;
    String selectedType = transaction.type;
    bool isRecurring = transaction.isRecurring;
    String recurringInterval = transaction.recurringInterval ?? 'monthly';
    DateTime selectedDate = transaction.createdAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İşlemi Düzenle',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Income / Expense Type Toggle Choice Chips
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: const Center(child: Text('Gelir')),
                          selected: selectedType == 'income',
                          selectedColor: AppColors.income.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: selectedType == 'income' ? AppColors.income : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => selectedType = 'income');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: const Center(child: Text('Gider')),
                          selected: selectedType == 'expense',
                          selectedColor: AppColors.expense.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: selectedType == 'expense' ? AppColors.expense : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => selectedType = 'expense');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tutar ($symbol)',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(AppColors.getCategoryIcon(selectedCategory)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const ['Market', 'Yemek', 'Fatura', 'Maaş', 'Ulaşım', 'Eğlence', 'Diğer']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(Icons.category_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text(cat),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Input
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Field
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
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
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: Formatters.formatDate(selectedDate),
                        ),
                        decoration: InputDecoration(
                          labelText: 'İşlem Tarihi',
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring switch list tile
                  SwitchListTile(
                    title: const Text(
                      'Tekrarlı İşlem', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Her periyot otomatik tekrarlanır (fatura, maaş vb.)', 
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isRecurring,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => isRecurring = val);
                    },
                  ),

                  if (isRecurring) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: recurringInterval,
                      decoration: InputDecoration(
                        labelText: 'Tekrarlama Sıklığı',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                        DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => recurringInterval = val);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Save Action Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final double? amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) return;

                            await ref.read(transactionControllerProvider).updateTransaction(
                                  id: transaction.id,
                                  amount: amount,
                                  type: selectedType,
                                  category: selectedCategory,
                                  description: descriptionController.text,
                                  date: selectedDate,
                                  isRecurring: isRecurring,
                                  recurringInterval: isRecurring ? recurringInterval : null,
                                );
                            Navigator.pop(context);
                          },
                          child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
