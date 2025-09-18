import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AnimatedBalanceCard extends StatelessWidget {
  final double balance;
  final String title;
  final IconData icon;
  final Color? backgroundColor;
  final bool isLoading;

  const AnimatedBalanceCard({
    super.key,
    required this.balance,
    required this.title,
    required this.icon,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundColor != null
                ? [backgroundColor!, backgroundColor!.withOpacity(0.8)]
                : [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.8),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                )
                    .animate()
                    .scale(delay: 100.ms, duration: 300.ms)
                    .fadeIn(delay: 100.ms, duration: 300.ms),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 1000.ms),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideX(begin: 0.2, end: 0, delay: 200.ms, duration: 300.ms),
            const SizedBox(height: AppTheme.spacingXs),
            if (!isLoading)
              Text(
                numberFormat.format(balance.abs()),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideX(begin: 0.3, end: 0, delay: 400.ms, duration: 500.ms)
                  .shimmer(
                    delay: 1000.ms,
                    duration: 1500.ms,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.3),
                  ),
          ],
        ),
      ),
    )
        .animate()
        .scale(begin: 0.8, duration: 400.ms)
        .fadeIn(duration: 400.ms);
  }
}