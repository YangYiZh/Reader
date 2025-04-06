import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences.dart';

class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final Color backgroundColor;
  final Color textColor;

  ReaderSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.fontFamily,
    required this.backgroundColor,
    required this.textColor,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }
}

final readerSettingsProvider = StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  return ReaderSettingsNotifier();
});

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  static const String _fontSizeKey = 'font_size';
  static const String _lineHeightKey = 'line_height';
  static const String _fontFamilyKey = 'font_family';
  static const String _backgroundColorKey = 'background_color';
  static const String _textColorKey = 'text_color';

  static const List<String> availableFonts = [
    'Noto Sans SC',
    'Noto Serif SC',
    'Source Han Sans CN',
    'Source Han Serif CN',
    'PingFang SC',
    'Microsoft YaHei',
    'SimSun',
  ];

  late SharedPreferences _prefs;

  ReaderSettingsNotifier()
      : super(ReaderSettings(
          fontSize: 16,
          lineHeight: 1.5,
          fontFamily: 'Noto Sans SC',
          backgroundColor: Colors.white,
          textColor: Colors.black,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    state = ReaderSettings(
      fontSize: _prefs.getDouble(_fontSizeKey) ?? 16,
      lineHeight: _prefs.getDouble(_lineHeightKey) ?? 1.5,
      fontFamily: _prefs.getString(_fontFamilyKey) ?? 'Noto Sans SC',
      backgroundColor: Color(_prefs.getInt(_backgroundColorKey) ?? Colors.white.value),
      textColor: Color(_prefs.getInt(_textColorKey) ?? Colors.black.value),
    );
  }

  Future<void> updateSettings(ReaderSettings settings) async {
    state = settings;
    await _prefs.setDouble(_fontSizeKey, settings.fontSize);
    await _prefs.setDouble(_lineHeightKey, settings.lineHeight);
    await _prefs.setString(_fontFamilyKey, settings.fontFamily);
    await _prefs.setInt(_backgroundColorKey, settings.backgroundColor.value);
    await _prefs.setInt(_textColorKey, settings.textColor.value);
  }
} 