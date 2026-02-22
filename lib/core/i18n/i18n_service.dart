/// Internationalization (i18n) Service
///
/// Handles language detection, locale management, dynamic translation loading,
/// and localized content formatting for global users.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';

/// Supported locale configuration
class SupportedLocale {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final bool isRTL;
  final double translationCompleteness;

  const SupportedLocale({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    this.isRTL = false,
    this.translationCompleteness = 1.0,
  });

  Locale get locale => Locale(code.split('_').first,
      code.contains('_') ? code.split('_').last : null);
}

/// Translation entry with metadata
class TranslationEntry {
  final String key;
  final String value;
  final String? context;
  final Map<String, String>? plurals;
  final int? maxLength;

  const TranslationEntry({
    required this.key,
    required this.value,
    this.context,
    this.plurals,
    this.maxLength,
  });

  factory TranslationEntry.fromJson(String key, dynamic json) {
    if (json is String) {
      return TranslationEntry(key: key, value: json);
    }
    final map = json as Map<String, dynamic>;
    return TranslationEntry(
      key: key,
      value: map['value'] as String? ?? '',
      context: map['context'] as String?,
      plurals: map['plurals'] != null
          ? Map<String, String>.from(map['plurals'] as Map)
          : null,
      maxLength: map['maxLength'] as int?,
    );
  }
}

/// Locale change event
class LocaleChangeEvent {
  final String previousLocale;
  final String newLocale;
  final DateTime timestamp;

  const LocaleChangeEvent({
    required this.previousLocale,
    required this.newLocale,
    required this.timestamp,
  });
}

/// i18n Service
class I18nService extends ChangeNotifier {
  static I18nService? _instance;
  static I18nService get instance => _instance ??= I18nService._();

  I18nService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Supported locales
  static const List<SupportedLocale> supportedLocales = [
    SupportedLocale(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: 'ðŸ‡ºðŸ‡¸',
    ),
    SupportedLocale(
      code: 'es',
      name: 'Spanish',
      nativeName: 'EspaÃ±ol',
      flagEmoji: 'ðŸ‡ªðŸ‡¸',
    ),
    SupportedLocale(
      code: 'fr',
      name: 'French',
      nativeName: 'FranÃ§ais',
      flagEmoji: 'ðŸ‡«ðŸ‡·',
    ),
    SupportedLocale(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flagEmoji: 'ðŸ‡©ðŸ‡ª',
    ),
    SupportedLocale(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'PortuguÃªs',
      flagEmoji: 'ðŸ‡§ðŸ‡·',
    ),
    SupportedLocale(
      code: 'ja',
      name: 'Japanese',
      nativeName: 'æ—¥æœ¬èªž',
      flagEmoji: 'ðŸ‡¯ðŸ‡µ',
    ),
    SupportedLocale(
      code: 'ko',
      name: 'Korean',
      nativeName: 'í•œêµ­ì–´',
      flagEmoji: 'ðŸ‡°ðŸ‡·',
    ),
    SupportedLocale(
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: 'ç®€ä½“ä¸­æ–‡',
      flagEmoji: 'ðŸ‡¨ðŸ‡³',
    ),
    SupportedLocale(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©',
      flagEmoji: 'ðŸ‡¸ðŸ‡¦',
      isRTL: true,
    ),
    SupportedLocale(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'à¤¹à¤¿à¤¨à¥à¤¦à¥€',
      flagEmoji: 'ðŸ‡®ðŸ‡³',
    ),
  ];

  // Current state
  String _currentLocale = 'en';
  Map<String, Map<String, dynamic>> _translations = {};
  bool _isInitialized = false;

  // Streams
  final _localeChangeController = StreamController<LocaleChangeEvent>.broadcast();

  /// Get current locale code
  String get currentLocale => _currentLocale;

  /// Get current Locale object
  Locale get locale => Locale(_currentLocale.split('_').first,
      _currentLocale.contains('_') ? _currentLocale.split('_').last : null);

  /// Check if current locale is RTL
  bool get isRTL => supportedLocales
      .firstWhere((l) => l.code == _currentLocale,
          orElse: () => supportedLocales.first)
      .isRTL;

  /// Stream of locale changes
  Stream<LocaleChangeEvent> get localeChanges => _localeChangeController.stream;

  /// Get text direction
  TextDirection get textDirection => isRTL ? TextDirection.RTL : TextDirection.LTR;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load saved locale preference
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_locale');

    if (savedLocale != null && _isValidLocale(savedLocale)) {
      _currentLocale = savedLocale;
    } else {
      // Detect system locale
      _currentLocale = _detectSystemLocale();
    }

    // Load translations for current locale
    await _loadTranslations(_currentLocale);

    // Load fallback (English) if not English
    if (_currentLocale != 'en') {
      await _loadTranslations('en');
    }

    _isInitialized = true;

    AnalyticsService.instance.logEvent(
      name: 'i18n_initialized',
      parameters: {
        'locale': _currentLocale,
      },
    );
  }

  /// Set locale
  Future<void> setLocale(String localeCode) async {
    if (!_isValidLocale(localeCode)) return;
    if (localeCode == _currentLocale) return;

    final previousLocale = _currentLocale;
    _currentLocale = localeCode;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', localeCode);

    // Load translations
    await _loadTranslations(localeCode);

    // Notify listeners
    notifyListeners();

    // Emit event
    _localeChangeController.add(LocaleChangeEvent(
      previousLocale: previousLocale,
      newLocale: localeCode,
      timestamp: DateTime.now(),
    ));

    AnalyticsService.instance.logEvent(
      name: 'locale_changed',
      parameters: {
        'from': previousLocale,
        'to': localeCode,
      },
    );
  }

  /// Translate a key
  String translate(String key, {Map<String, dynamic>? params}) {
    // Try current locale first
    String? value = _getTranslation(key, _currentLocale);

    // Fall back to English
    if (value == null && _currentLocale != 'en') {
      value = _getTranslation(key, 'en');
    }

    // Return key if not found
    if (value == null) return key;

    // Apply parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value!.replaceAll('{$paramKey}', paramValue.toString());
      });
    }

    return value!;
  }

  /// Short alias for translate
  String tr(String key, {Map<String, dynamic>? params}) =>
      translate(key, params: params);

  /// Translate with plural support
  String translatePlural(String key, int count, {Map<String, dynamic>? params}) {
    final translations = _translations[_currentLocale];
    if (translations == null) return key;

    final entry = translations[key];
    if (entry == null) return key;

    String? value;
    if (entry is Map) {
      final plurals = entry['plurals'] as Map<String, dynamic>?;
      if (plurals != null) {
        if (count == 0 && plurals.containsKey('zero')) {
          value = plurals['zero'] as String;
        } else if (count == 1 && plurals.containsKey('one')) {
          value = plurals['one'] as String;
        } else if (plurals.containsKey('other')) {
          value = plurals['other'] as String;
        }
      }
      value ??= entry['value'] as String?;
    } else if (entry is String) {
      value = entry;
    }

    value ??= key;

    // Apply count parameter
    value = value.replaceAll('{count}', count.toString());

    // Apply other parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value!.replaceAll('{$paramKey}', paramValue.toString());
      });
    }

    return value ?? key;
  }

  /// Format date according to locale
  String formatDate(DateTime date, {String? pattern}) {
    final format = pattern != null
        ? DateFormat(pattern, _currentLocale)
        : DateFormat.yMMMd(_currentLocale);
    return format.format(date);
  }

  /// Format time according to locale
  String formatTime(DateTime time, {bool include24Hour = false}) {
    final format = include24Hour
        ? DateFormat.Hm(_currentLocale)
        : DateFormat.jm(_currentLocale);
    return format.format(time);
  }

  /// Format number according to locale
  String formatNumber(num number, {int? decimalDigits}) {
    final format = NumberFormat.decimalPattern(_currentLocale);
    if (decimalDigits != null) {
      format.minimumFractionDigits = decimalDigits;
      format.maximumFractionDigits = decimalDigits;
    }
    return format.format(number);
  }

  /// Format currency according to locale
  String formatCurrency(num amount, {String? currencyCode}) {
    final code = currencyCode ?? _getCurrencyForLocale();
    final format = NumberFormat.currency(locale: _currentLocale, symbol: code);
    return format.format(amount);
  }

  /// Format relative time (e.g., "5 minutes ago")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return translatePlural('time.years_ago', years, params: {'count': years});
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return translatePlural('time.months_ago', months, params: {'count': months});
    } else if (difference.inDays > 0) {
      return translatePlural('time.days_ago', difference.inDays,
          params: {'count': difference.inDays});
    } else if (difference.inHours > 0) {
      return translatePlural('time.hours_ago', difference.inHours,
          params: {'count': difference.inHours});
    } else if (difference.inMinutes > 0) {
      return translatePlural('time.minutes_ago', difference.inMinutes,
          params: {'count': difference.inMinutes});
    } else {
      return translate('time.just_now');
    }
  }

  /// Get supported locale info
  SupportedLocale? getLocaleInfo(String code) {
    try {
      return supportedLocales.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Check if a locale is supported
  bool isLocaleSupported(String code) {
    return supportedLocales.any((l) => l.code == code);
  }

  /// Get translation completeness for a locale
  Future<double> getTranslationCompleteness(String localeCode) async {
    if (localeCode == 'en') return 1.0;

    final englishTranslations = _translations['en'];
    final targetTranslations = _translations[localeCode];

    if (englishTranslations == null || targetTranslations == null) {
      return 0.0;
    }

    return targetTranslations.length / englishTranslations.length;
  }

  /// Load remote translation updates
  Future<void> loadRemoteTranslations() async {
    try {
      final doc = await _firestore
          .collection('translations')
          .doc(_currentLocale)
          .get();

      if (doc.exists) {
        final remoteTranslations = doc.data() ?? {};

        // Merge with local translations (remote takes precedence)
        _translations[_currentLocale] = {
          ...?_translations[_currentLocale],
          ...remoteTranslations,
        };

        notifyListeners();
      }
    } catch (e) {
      // Fall back to local translations
      debugPrint('Failed to load remote translations: $e');
    }
  }

  // Private methods

  bool _isValidLocale(String code) {
    return supportedLocales.any((l) => l.code == code);
  }

  String _detectSystemLocale() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final code = systemLocale.languageCode;

    // Check if system locale is supported
    if (_isValidLocale(code)) {
      return code;
    }

    // Check with country code
    final fullCode = '${code}_${systemLocale.countryCode}';
    if (_isValidLocale(fullCode)) {
      return fullCode;
    }

    // Default to English
    return 'en';
  }

  Future<void> _loadTranslations(String localeCode) async {
    if (_translations.containsKey(localeCode)) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/i18n/$localeCode.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _translations[localeCode] = jsonMap;
    } catch (e) {
      debugPrint('Failed to load translations for $localeCode: $e');
      _translations[localeCode] = {};
    }
  }

  String? _getTranslation(String key, String locale) {
    final translations = _translations[locale];
    if (translations == null) return null;

    // Support nested keys (e.g., "auth.login.title")
    final parts = key.split('.');
    dynamic current = translations;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    if (current is String) return current;
    if (current is Map && current.containsKey('value')) {
      return current['value'] as String?;
    }
    return null;
  }

  String _getCurrencyForLocale() {
    const localeToCurrency = {
      'en': 'USD',
      'es': 'EUR',
      'fr': 'EUR',
      'de': 'EUR',
      'pt': 'BRL',
      'ja': 'JPY',
      'ko': 'KRW',
      'zh': 'CNY',
      'ar': 'SAR',
      'hi': 'INR',
    };
    return localeToCurrency[_currentLocale.split('_').first] ?? 'USD';
  }

  /// Dispose resources
  @override
  void dispose() {
    _localeChangeController.close();
    super.dispose();
  }
}

/// Extension for easy translation access
extension TranslationExtension on String {
  String get tr => I18nService.instance.translate(this);

  String trParams(Map<String, dynamic> params) =>
      I18nService.instance.translate(this, params: params);

  String trPlural(int count, {Map<String, dynamic>? params}) =>
      I18nService.instance.translatePlural(this, count, params: params);
}

/// Localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<I18nService> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return I18nService.supportedLocales.any(
      (l) => l.code == locale.languageCode,
    );
  }

  @override
  Future<I18nService> load(Locale locale) async {
    await I18nService.instance.setLocale(locale.languageCode);
    return I18nService.instance;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
