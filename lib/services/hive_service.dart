import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription.dart';
import '../utils/currencies.dart';

class HiveService {
  static const String boxName = 'subscriptions';
  static const String settingsBoxName = 'settings';
  static const String maxBudgetKey = 'max_budget';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String currencyCodeKey = 'currency_code';
  static const double defaultMaxBudget = 50.0;
  static const String defaultCurrencyCode = AppCurrencies.defaultCode;

  static final ValueNotifier<double> maxBudgetNotifier =
      ValueNotifier<double>(defaultMaxBudget);
  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<String> currencyCodeNotifier =
      ValueNotifier<String>(defaultCurrencyCode);

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubscriptionAdapter());
    }
    await Hive.openBox<Subscription>(boxName);
    final settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    final storedBudget = settingsBox.get(maxBudgetKey);
    maxBudgetNotifier.value = storedBudget is num && storedBudget > 0
        ? storedBudget.toDouble()
        : defaultMaxBudget;
    final storedTheme = settingsBox.get(isDarkModeKey);
    isDarkModeNotifier.value = storedTheme is bool ? storedTheme : true;
    final storedCurrency = settingsBox.get(currencyCodeKey);
    currencyCodeNotifier.value = storedCurrency is String
        ? AppCurrencies.byCode(storedCurrency).code
        : defaultCurrencyCode;
  }

  Box<Subscription> get box => Hive.box<Subscription>(boxName);

  List<Subscription> getAll() => box.values.toList();

  Subscription? getById(String id) => box.get(id);

  Future<void> add(Subscription subscription) async {
    await box.put(subscription.id, subscription);
  }

  Future<void> update(Subscription subscription) async {
    await box.put(subscription.id, subscription);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }

  Future<void> togglePause(String id, bool isPaused) async {
    final existing = box.get(id);
    if (existing != null) {
      await box.put(id, existing.copyWith(isPaused: isPaused));
    }
  }

  Future<void> toggleFreeTrial(String id, bool isFreeTrial) async {
    final existing = box.get(id);
    if (existing != null) {
      await box.put(id, existing.copyWith(isFreeTrial: isFreeTrial));
    }
  }

  double calculateActiveMonthly({DateTime? now}) {
    double total = 0.0;
    for (final sub in box.values) {
      if (!sub.isPaused && !sub.isTrialActive(now)) {
        total += sub.monthlyCost;
      }
    }
    return total;
  }

  double getMaxBudget() => maxBudgetNotifier.value;

  Future<void> setMaxBudget(double budget) async {
    maxBudgetNotifier.value = budget;
    if (Hive.isBoxOpen(settingsBoxName)) {
      await Hive.box<dynamic>(settingsBoxName).put(maxBudgetKey, budget);
    }
  }

  bool getIsDarkMode() => isDarkModeNotifier.value;

  Future<void> setIsDarkMode(bool isDark) async {
    isDarkModeNotifier.value = isDark;
    if (Hive.isBoxOpen(settingsBoxName)) {
      await Hive.box<dynamic>(settingsBoxName).put(isDarkModeKey, isDark);
    }
  }

  Future<void> toggleTheme() => setIsDarkMode(!getIsDarkMode());

  String getCurrencyCode() => currencyCodeNotifier.value;

  Future<void> setCurrencyCode(String code) async {
    final normalized = AppCurrencies.byCode(code).code;
    currencyCodeNotifier.value = normalized;
    if (Hive.isBoxOpen(settingsBoxName)) {
      await Hive.box<dynamic>(settingsBoxName).put(currencyCodeKey, normalized);
    }
  }
}
