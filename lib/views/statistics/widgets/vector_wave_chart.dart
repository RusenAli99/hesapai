import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class VectorWaveChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String symbol;

  const VectorWaveChart({
    super.key,
    required this.transactions,
    required this.symbol,
  });

  @override
  State<VectorWaveChart> createState() => _VectorWaveChartState();
}

class _VectorWaveChartState extends State<VectorWaveChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous animation loop for flowing vector waves and particles
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Take the last 5 transactions and sort them by amount descending
    final displayTransactions = List<TransactionModel>.from(
      widget.transactions.length > 5
          ? widget.transactions.sublist(widget.transactions.length - 5)
          : widget.transactions
    );
    displayTransactions.sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Legend Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.waves_rounded,
                      size: 20,
                      color: isDark ? AppColors.primary : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'İşlem Dalgaları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Legend
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFF00F2FE), 'Gelir'),
                    const SizedBox(width: 14),
                    _buildLegendItem(const Color(0xFFFF0844), 'Gider'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Wave drawing canvas inside AnimatedBuilder
            SizedBox(
              height: 240,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      transactions: displayTransactions,
                      symbol: widget.symbol,
                      isDark: isDark,
                      animationValue: _controller.value,
                    ),
                  );
                },
              ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final List<TransactionModel> transactions;
  final String symbol;
  final bool isDark;
  final double animationValue;

  WavePainter({
    required this.transactions,
    required this.symbol,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    
    // Space on the right for text labels
    final double waveWidth = width - 100;
    
    // Find max amount to scale the deflection (optimized loop)
    double maxAmount = 1.0;
    for (final t in transactions) {
      if (t.amount > maxAmount) {
        maxAmount = t.amount;
      }
    }

    final int count = transactions.length;
    final double spacing = height / (count + 1);

    // Reuse Paint objects by declaring them once outside the loop
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final glowPaint = Paint()..style = PaintingStyle.fill;
    final solidPaint = Paint()..style = PaintingStyle.fill;
    final whiteCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final particleGlow = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final particleCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final particleBack = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final pillPaint = Paint()..style = PaintingStyle.fill;
    final pillBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < count; i++) {
      final t = transactions[i];
      final isIncome = t.type == 'income';
      
      // Holographic Neon colors
      final Color colorStart = isIncome ? const Color(0xFF00F2FE) : const Color(0xFFFF0844);
      final Color colorEnd = isIncome ? const Color(0xFF4FACFE) : const Color(0xFFFFB199);
      
      final double yBase = spacing * (i + 1);
      
      // Baseline wave deflection to keep even low values nicely wavy
      final double minDeflection = 12.0;
      final double maxDeflection = 35.0;
      final double deflection = minDeflection + (t.amount / maxAmount) * (maxDeflection - minDeflection);

      // Phase calculation for continuous smooth flowing motion
      final double phase = i * 1.5 - animationValue * 2 * pi;

      // 1. Draw secondary thin wave (hologram ribbon effect - optimized step=8)
      secondaryPaint.color = colorStart.withOpacity(0.2);
      final secondaryPath = Path();
      secondaryPath.moveTo(0, yBase);
      for (double x = 0; x <= waveWidth; x += 8) {
        final double phaseOffset = phase + pi / 2.5; // Offset phase
        final double y = yBase + (deflection * 0.7) * sin((x / waveWidth) * 2 * pi + phaseOffset) * sin((x / waveWidth) * pi);
        secondaryPath.lineTo(x, y);
      }
      final double yEndSecondary = yBase + (deflection * 0.7) * sin(2 * pi + phase + pi / 2.5) * sin(pi);
      secondaryPath.lineTo(waveWidth, yEndSecondary);
      canvas.drawPath(secondaryPath, secondaryPaint);

      // 2. Draw primary main wave (optimized step=6)
      final primaryPath = Path();
      primaryPath.moveTo(0, yBase);
      for (double x = 0; x <= waveWidth; x += 6) {
        final double y = yBase + deflection * sin((x / waveWidth) * 2 * pi + phase) * sin((x / waveWidth) * pi);
        primaryPath.lineTo(x, y);
      }
      primaryPath.lineTo(waveWidth, yBase);

      // Gradient shader for the primary stroke
      final Rect lineRect = Rect.fromLTWH(0, yBase - deflection, waveWidth, deflection * 2);
      final strokeGradient = LinearGradient(
        colors: [colorStart.withOpacity(0.3), colorStart, colorEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
      final shader = strokeGradient.createShader(lineRect);
      paint.shader = shader;
      shadowPaint.shader = shader;

      // Draw shadow and primary path
      canvas.drawPath(primaryPath, shadowPaint);
      canvas.drawPath(primaryPath, paint);

      // 3. Draw glowing radar end dot
      glowPaint.color = colorEnd.withOpacity(0.35);
      canvas.drawCircle(Offset(waveWidth, yBase), 7.5, glowPaint);
      
      solidPaint.color = colorEnd;
      canvas.drawCircle(Offset(waveWidth, yBase), 4.5, solidPaint);
      canvas.drawCircle(Offset(waveWidth, yBase), 1.8, whiteCenterPaint);
      
      // 4. Draw animated traveling glowing particle
      final double particleProgress = (animationValue + i * 0.25) % 1.0;
      final double particleX = waveWidth * particleProgress;
      final double particleY = yBase + deflection * sin((particleX / waveWidth) * 2 * pi + phase) * sin((particleX / waveWidth) * pi);
      
      particleBack.color = colorStart.withOpacity(0.5);
      canvas.drawCircle(Offset(particleX, particleY), 6.0, particleBack);
      canvas.drawCircle(Offset(particleX, particleY), 3.0, particleGlow);
      canvas.drawCircle(Offset(particleX, particleY), 1.5, particleCore);

      // 5. Draw Category label above the start of the wave
      final String categoryText = '${t.category} (${t.description.length > 15 ? '${t.description.substring(0, 12)}...' : t.description})';
      final categorySpan = TextSpan(
        text: categoryText,
        style: TextStyle(
          color: (isDark ? Colors.white60 : Colors.black54).withOpacity(0.7),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      );
      final categoryPainter = TextPainter(
        text: categorySpan,
        textDirection: TextDirection.ltr,
      );
      categoryPainter.layout();
      categoryPainter.paint(canvas, Offset(4, yBase - 15));

      // 6. Draw a rounded background pill for the price label
      final String labelText = Formatters.formatMoney(t.amount, symbol: symbol);
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final double rectW = textPainter.width + 12;
      final double rectH = textPainter.height + 6;
      final RRect pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(waveWidth + 10, yBase - rectH / 2, rectW, rectH),
        const Radius.circular(8),
      );
      
      pillPaint.color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
      pillBorderPaint.color = colorEnd.withOpacity(0.35);
        
      canvas.drawRRect(pillRect, pillPaint);
      canvas.drawRRect(pillRect, pillBorderPaint);
      
      textPainter.paint(canvas, Offset(waveWidth + 16, yBase - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.transactions != transactions ||
        oldDelegate.isDark != isDark ||
        oldDelegate.symbol != symbol;
  }
}
