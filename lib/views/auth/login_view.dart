import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authControllerProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.bgDark,
                  Color(0xFF1E1B4B), // Deep indigo
                  Color(0xFF0F172A),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Animated Logo Section
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'YazGeç',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Konuşur gibi finans takibi',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Glassmorphism login panel
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hesabınızı Oluşturun',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Name Surname Field
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.outfit(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Adınız Soyadınız',
                                hintStyle: GoogleFonts.outfit(color: Colors.white54),
                                prefixIcon: const Icon(Icons.person_rounded, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.expense),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.expense, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Lütfen adınızı soyadınızı girin';
                                }
                                if (value.trim().length < 2) {
                                  return 'Adınız en az 2 karakter olmalıdır';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Giriş Yap Button
                            if (authState.isLoading)
                              const CircularProgressIndicator(color: AppColors.primary)
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      ref
                                          .read(authControllerProvider.notifier)
                                          .signInAnonymously(_nameController.text.trim());
                                    }
                                  },
                                  child: Text(
                                    'Giriş Yap',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Error display if failed
                            if (authState.hasError) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Giriş yapılırken hata oluştu. Lütfen tekrar deneyin.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer
                    Text(
                      'Kullanmaya başlayarak Kullanıcı Sözleşmesini kabul etmiş olursunuz.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppColors.textSecondaryDark.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
