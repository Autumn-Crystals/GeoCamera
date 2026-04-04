import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DynamicCalendarWidget extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const DynamicCalendarWidget({
    super.key,
    this.size = 42,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateFormat('dd').format(now);
    final month = DateFormat('MMM').format(now).toUpperCase();
    final weekday = DateFormat('EEE').format(now).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Month header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.danger,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Day number
          Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: textColor ?? AppTheme.textPrimary,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
          
          // Weekday
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              weekday,
              style: TextStyle(
                color: (textColor ?? AppTheme.textPrimary).withOpacity(0.6),
                fontSize: 6,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative minimal version - just shows day and month
class MinimalCalendarWidget extends StatelessWidget {
  final double size;

  const MinimalCalendarWidget({
    super.key,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateFormat('dd').format(now);
    final month = DateFormat('MMM').format(now).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.danger,
            AppTheme.danger.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
