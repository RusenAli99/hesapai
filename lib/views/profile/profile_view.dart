import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/chat_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final String displayName = user?.name ?? 'Kullanıcı';
    final String displayEmail = user?.email ?? 'kullanici@yazgec.com';
    final String activeCurrencyCode = user?.currencyCode ?? 'TRY';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // User Avatar Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Settings Group
              _buildSettingsHeader('Tercihler'),
              Card(
                child: Column(
                  children: [
                    // Currency Setting
                    ListTile(
                      leading: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                      title: const Text('Para Birimi'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeCurrencyCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => _showCurrencyDialog(context, ref, activeCurrencyCode),
                    ),
                    const Divider(height: 1, indent: 56),
                    
                    // Dark Theme Setting
                    ListTile(
                      leading: Icon(
                        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Karanlık Mod'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    
                    // Simulated Notification Settings
                    ListTile(
                      leading: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                      title: const Text('Harcama Bildirimleri'),
                      trailing: Switch(
                        value: true,
                        onChanged: (val) {},
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions Group
              _buildSettingsHeader('Hesap & Veri İşlemleri'),
              Card(
                child: Column(
                  children: [
                    // Clear Data
                    ListTile(
                      leading: const Icon(Icons.layers_clear_outlined, color: AppColors.expense),
                      title: const Text('Harcama Verilerini Temizle'),
                      onTap: () => _showClearDataDialog(context, ref),
                    ),
                    const Divider(height: 1, indent: 56),
                    
                    // Sign out
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.expense),
                      title: const Text('Oturumu Kapat'),
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Info
              Text(
                'YazGeç v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, String activeCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Para Birimi Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.currencies.map((currency) {
            final code = currency['code']!;
            final name = currency['name']!;
            final symbol = currency['symbol']!;
            
            return RadioListTile<String>(
              title: Text('$name ($symbol)'),
              value: code,
              groupValue: activeCode,
              onChanged: (val) {
                if (val != null) {
                  ref.read(authControllerProvider.notifier).updateCurrency(code, symbol);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text('Tüm gelir/gider verileriniz kalıcı olarak silinecektir. Bu işlem geri alınamaz. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () {
              ref.read(transactionControllerProvider).clearAllTransactions();
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tüm veriler başarıyla sıfırlandı.')),
              );
            },
            child: const Text('Verileri Sil'),
          ),
        ],
      ),
    );
  }
}
