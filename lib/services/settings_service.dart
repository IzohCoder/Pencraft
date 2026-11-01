import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Settings keys
// ---------------------------------------------------------------------------
abstract final class SettingsKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode'; // 'system'|'light'|'dark'
  static const String isPro = 'is_pro_mock'; // mock Pro status for testing
  static const String docsThisMonth = 'docs_this_month';
  static const String docsMonthKey = 'docs_month_key'; // 'YYYY-MM'
}

// ---------------------------------------------------------------------------
// Settings notifier
// ---------------------------------------------------------------------------
class SettingsState {
  const SettingsState({
    this.onboardingComplete = false,
    this.themeMode = 'system',
    this.isProMock = false,
    this.docsThisMonth = 0,
  });

  final bool onboardingComplete;
  final String themeMode;
  final bool isProMock;
  final int docsThisMonth;

  SettingsState copyWith({
    bool? onboardingComplete,
    String? themeMode,
    bool? isProMock,
    int? docsThisMonth,
  }) =>
      SettingsState(
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        themeMode: themeMode ?? this.themeMode,
        isProMock: isProMock ?? this.isProMock,
        docsThisMonth: docsThisMonth ?? this.docsThisMonth,
      );
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late SharedPreferences _prefs;

  @override
  Future<SettingsState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  SettingsState _load() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final storedMonth = _prefs.getString(SettingsKeys.docsMonthKey) ?? '';
    final docsCount =
        storedMonth == monthKey ? (_prefs.getInt(SettingsKeys.docsThisMonth) ?? 0) : 0;

    return SettingsState(
      onboardingComplete: _prefs.getBool(SettingsKeys.onboardingComplete) ?? false,
      themeMode: _prefs.getString(SettingsKeys.themeMode) ?? 'system',
      isProMock: _prefs.getBool(SettingsKeys.isPro) ?? false,
      docsThisMonth: docsCount,
    );
  }

  Future<void> setOnboardingComplete(bool v) async {
    await _prefs.setBool(SettingsKeys.onboardingComplete, v);
    state = AsyncData(state.value!.copyWith(onboardingComplete: v));
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(SettingsKeys.themeMode, mode);
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }

  Future<void> setProMock(bool v) async {
    await _prefs.setBool(SettingsKeys.isPro, v);
    state = AsyncData(state.value!.copyWith(isProMock: v));
  }

  Future<void> incrementDocsThisMonth() async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _prefs.setString(SettingsKeys.docsMonthKey, monthKey);
    final current = state.value!.docsThisMonth;
    await _prefs.setInt(SettingsKeys.docsThisMonth, current + 1);
    state = AsyncData(state.value!.copyWith(docsThisMonth: current + 1));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
