import 'package:easy_localization/easy_localization.dart' show NumberFormat;
import 'package:flutter/material.dart';

/// Arabic plural rules (simplified for UI)
String _arPlural(int n, String one, String two, String few, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}

extension DateTimeX on DateTime {
  /// Returns a human-readable "time ago" string
  String timeAgo({String locale = 'ar', DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    var diff = currentTime.difference(this);
    final isFuture = diff.isNegative;
    if (isFuture) diff = diff.abs();

    if (diff.inSeconds < 45) {
      return locale.startsWith('ar') ? 'الآن' : 'just now';
    }

    String arPhrase(int n, String one, String two, String few, String many) {
      final core = _arPlural(n, one, two, few, many);
      return isFuture ? 'بعد $core' : 'قبل $core';
    }

    if (diff.inMinutes < 1) {
      final s = diff.inSeconds;
      return locale.startsWith('ar')
          ? arPhrase(s, 'ثانية', 'ثانيتين', 'ثوانٍ', 'ثانية')
          : isFuture ? 'in ${s}s' : '${s}s ago';
    }

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return locale.startsWith('ar')
          ? arPhrase(m, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة')
          : isFuture ? 'in ${m}m' : '${m}m ago';
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      return locale.startsWith('ar')
          ? arPhrase(h, 'ساعة', 'ساعتين', 'ساعات', 'ساعة')
          : isFuture ? 'in ${h}h' : '${h}h ago';
    }

    if (diff.inDays < 7) {
      final d = diff.inDays;
      return locale.startsWith('ar')
          ? arPhrase(d, 'يوم', 'يومين', 'أيام', 'يوم')
          : isFuture ? 'in ${d}d' : '${d}d ago';
    }

    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return locale.startsWith('ar')
          ? arPhrase(w, 'أسبوع', 'أسبوعين', 'أسابيع', 'أسبوع')
          : isFuture ? 'in ${w}w' : '${w}w ago';
    }

    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return locale.startsWith('ar')
          ? arPhrase(mo, 'شهر', 'شهرين', 'أشهر', 'شهر')
          : isFuture ? 'in ${mo}mo' : '${mo}mo ago';
    }

    final y = (diff.inDays / 365).floor();
    return locale.startsWith('ar')
        ? arPhrase(y, 'سنة', 'سنتين', 'سنوات', 'سنة')
        : isFuture ? 'in ${y}y' : '${y}y ago';
  }

  /// Get time ago using context locale
  String timeAgoCtx(BuildContext context, {DateTime? now}) {
    final locale = Localizations.localeOf(context).languageCode;
    return timeAgo(locale: locale, now: now);
  }

  /// Format as YYYY-MM-DD
  String yMd([String sep = '-']) =>
      '${year.toString().padLeft(4, '0')}$sep${month.toString().padLeft(2, '0')}$sep${day.toString().padLeft(2, '0')}';

  /// Format as DD/MM/YYYY
  String dMy([String sep = '/']) =>
      '${day.toString().padLeft(2, '0')}$sep${month.toString().padLeft(2, '0')}$sep${year.toString().padLeft(4, '0')}';

  /// Format as HH:MM
  String hhmm() => '${_two(hour)}:${_two(minute)}';

  /// Start of day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// End of day (23:59:59.999)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Check if same day as other
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Check if today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if yesterday
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// Check if tomorrow
  bool get isTomorrow =>
      isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// Days since given date
  int daysSince([DateTime? from]) =>
      (from ?? DateTime.now()).difference(this).inDays;

  /// Days until given date
  int daysUntil([DateTime? to]) => difference(to ?? DateTime.now()).inDays;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Extension to get day names from DateTime
extension DateTimeDayExtension on DateTime {
  /// Convert DateTime to English day name (lowercase)
  String get dayName {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  /// Convert DateTime to Arabic day name
  String get arabicDayName {
    const arabicDays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return arabicDays[weekday - 1];
  }
}

extension NumberFormatting on num {
  /// Format number with commas (e.g., 100,000)
  /// [decimalDigits] Controls how many numbers after the dot. Default is 0.
  String toFormattedString([int decimalDigits = 0]) {
    final formatter = NumberFormat.decimalPattern('en_US');
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(this);
  }

  /// Format money with currency symbol (e.g., 100,000 ج.م)
  String toMoney(String currency, [int decimalDigits = 0]) {
    return '${toFormattedString(decimalDigits)} $currency';
  }

  /// Format money with currency symbol first (e.g., ج.م 100,000)
  String toPrefixMoney(String currency, [int decimalDigits = 0]) {
    return '$currency ${toFormattedString(decimalDigits)}';
  }
}