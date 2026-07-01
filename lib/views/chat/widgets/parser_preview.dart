import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../core/services/parser_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/chat_provider.dart';

class ParserPreview extends ConsumerStatefulWidget {
  final ChatMessageModel message;

  const ParserPreview({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<ParserPreview> createState() => _ParserPreviewState();
}

class _ParserPreviewState extends ConsumerState<ParserPreview> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  late String _selectedCategory;
  bool _isEditing = false;
  late bool _isRecurring;
  late String _recurringInterval;

  @override
  void initState() {
    super.initState();
    final result = widget.message.parserResult;
    _amountController = TextEditingController(text: result?.amount.toStringAsFixed(0) ?? '0');
    _descriptionController = TextEditingController(text: result?.description ?? '');
    _selectedType = result?.type ?? 'expense';
    _selectedCategory = result?.category ?? 'Diğer';
    _isRecurring = result?.isRecurring ?? false;
    _recurringInterval = result?.recurringInterval ?? 'monthly';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.message.parserResult;
    if (result == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApproved = widget.message.isApproved;
    final isRejected = widget.message.isRejected;
    final isIncome = _selectedType == 'income';
    final accentColor = isIncome ? AppColors.income : AppColors.expense;

    // Header Color & Label
    final typeLabel = isIncome ? 'GELİR TESPİT EDİLDİ' : 'GİDER TESPİT EDİLDİ';

    if (isApproved) {
      return _buildFinalizedCard(
        context,
        title: 'İşlem Kaydedildi',
        statusColor: AppColors.income,
        statusIcon: Icons.check_circle_rounded,
        isDark: isDark,
      );
    }

    if (isRejected) {
      return _buildFinalizedCard(
        context,
        title: 'İşlem İptal Edildi',
        statusColor: AppColors.textSecondaryLight,
        statusIcon: Icons.cancel_rounded,
        isDark: isDark,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility_rounded : Icons.edit_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  tooltip: _isEditing ? 'Göster' : 'Düzenle',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Main body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditing) ...[
                  // Read Only Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedCategory,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (_isRecurring) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                        _recurringInterval == 'weekly'
                                            ? 'Haftalık'
                                            : _recurringInterval == 'yearly'
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
                          const SizedBox(height: 4),
                          Text(
                            _descriptionController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_amountController.text} TL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Inline Editing Fields
                  Row(
                    children: [
                      // Amount Field
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tutar (TL)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Type Switch (Income/Expense)
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'İşlem Tipi',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'expense', child: Text('Gider')),
                            DropdownMenuItem(value: 'income', child: Text('Gelir')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                                // Reset category based on type fallback
                                _selectedCategory = val == 'income' 
                                    ? AppConstants.incomeCategories.first 
                                    : AppConstants.expenseCategories.first;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Category & Description fields
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: (_selectedType == 'income'
                                  ? AppConstants.incomeCategories
                                  : AppConstants.expenseCategories)
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'Tekrarlı İşlem',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Otomatik tekrarlanır (fatura, maaş vb.)',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _isRecurring,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _isRecurring = val);
                    },
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _recurringInterval,
                      decoration: const InputDecoration(
                        labelText: 'Tekrarlama Sıklığı',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                        DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _recurringInterval = val);
                      },
                    ),
                  ],
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        ref.read(chatProvider.notifier).rejectTransaction(widget.message.id);
                      },
                      child: const Text('Vazgeç'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        // Apply changes if edited
                        final finalAmount = double.tryParse(_amountController.text) ?? result.amount;
                        
                        final updatedResult = ParserResult(
                          amount: finalAmount,
                          type: _selectedType,
                          category: _selectedCategory,
                          description: _descriptionController.text,
                          date: result.date,
                          isRecurring: _isRecurring,
                          recurringInterval: _isRecurring ? _recurringInterval : null,
                        );

                        // Save updated data
                        ref.read(chatProvider.notifier).updatePreviewResult(
                          widget.message.id,
                          updatedResult,
                        );

                        // Approve and commit
                        ref.read(chatProvider.notifier).approveTransaction(widget.message.id);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizedCard(
    BuildContext context, {
    required String title,
    required Color statusColor,
    required IconData statusIcon,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: isDark ? AppColors.cardDark.withOpacity(0.5) : Colors.white.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Spacer(),
            Text(
              '${_amountController.text} TL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
                decoration: widget.message.isRejected ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
