import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:sub_tracker/main.dart';
import 'package:sub_tracker/models/subscription.dart';
import 'package:sub_tracker/services/hive_service.dart';

void main() {
  late Directory tempDir;
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async {
          if (call.method == 'initialize' ||
              call.method == 'requestNotificationsPermission') {
            return true;
          }
          return null;
        });
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDir = Directory.systemTemp.createTempSync('sub_tracker_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubscriptionAdapter());
    }
    await Hive.openBox<Subscription>(
      HiveService.boxName,
      bytes: Uint8List(0),
    );
    await Hive.openBox<dynamic>(
      HiveService.settingsBoxName,
      bytes: Uint8List(0),
    );
  });

  setUp(() async {
    await Hive.box<Subscription>(HiveService.boxName).clear();
    await Hive.box<dynamic>(HiveService.settingsBoxName).clear();
    HiveService.maxBudgetNotifier.value = HiveService.defaultMaxBudget;
    HiveService.isDarkModeNotifier.value = true;
    HiveService.currencyCodeNotifier.value = HiveService.defaultCurrencyCode;
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Monochromatic SubTracker end-to-end CRUD and pause test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SubTrackerApp());
    expect(find.text('SUBTRACKER'), findsOneWidget);
    expect(find.text('Total / mo'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('ADD SUBSCRIPTION'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost'),
      '15.99',
    );
    await tester.ensureVisible(find.text('Free Trial'));
    await tester.tap(find.text('Free Trial'));
    await tester.pump();

    await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
    await tester.tap(find.text('SAVE SUBSCRIPTION'));
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Trial'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('\$15.99'), findsOneWidget);

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    expect(find.text('DETAILS'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('detail_free_trial_switch')),
    );
    await tester.tap(find.byKey(const Key('detail_free_trial_switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('\$15.99'), findsNWidgets(2));

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    expect(find.text('DETAILS'), findsOneWidget);
    await tester.ensureVisible(find.text('Pause Subscription'));
    await tester.tap(find.text('Pause Subscription'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('\$0.00'), findsOneWidget);

    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacityWidget.opacity, 0.5);

    final priceText = tester.widget<Text>(find.text('\$15.99'));
    expect(priceText.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    expect(find.text('No subscriptions'), findsOneWidget);
  });

  testWidgets(
    'Hard Budget Ceiling progress bar fills and shows OVER BUDGET when exceeded',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SubTrackerApp());

      expect(find.byKey(const Key('budget_progress_bar')), findsOneWidget);
      expect(find.text('Budget: \$50.00 / mo'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsNothing);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('budget_input')),
        '30',
      );
      await tester.ensureVisible(find.text('SAVE BUDGET'));
      await tester.tap(find.text('SAVE BUDGET'));
      await tester.pumpAndSettle();

      expect(find.text('Budget: \$30.00 / mo'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '15',
      );
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsNothing);
      final halfBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('budget_progress_bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(halfBar.widthFactor, closeTo(0.5, 0.001));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '20',
      );
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('over_budget_banner')), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsOneWidget);
      expect(find.text('\$35.00 / \$30.00'), findsOneWidget);
      final fullBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('budget_progress_bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fullBar.widthFactor, 1.0);
    },
  );

  testWidgets('Toggles between Dark Mode and Light Mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SubTrackerApp());

    MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black,
    );

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );

    await tester.ensureVisible(find.text('DARK'));
    await tester.tap(find.text('DARK'));
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black,
    );
  });

  testWidgets(
    'Tapping dashboard budget bar lets user change budget limit directly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SubTrackerApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '40',
      );
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      expect(find.text('Budget: \$50.00 / mo'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard_budget_tap')));
      await tester.pumpAndSettle();

      expect(find.text('SET BUDGET LIMIT'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('dialog_budget_input')),
        '25',
      );
      await tester.tap(find.byKey(const Key('dialog_budget_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('over_budget_banner')), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsOneWidget);
      expect(find.text('\$40.00 / \$25.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard_budget_tap')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('dialog_budget_input')),
        '100',
      );
      await tester.tap(find.byKey(const Key('dialog_budget_save')));
      await tester.pumpAndSettle();

      expect(find.text('OVER BUDGET'), findsNothing);
      expect(find.text('Budget: \$100.00 / mo'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    },
  );

  testWidgets(
    'Supports multi-currency switching (PKR, EUR, SAR) across screens',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SubTrackerApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '25',
      );
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('currency_chip_PKR')));
      await tester.tap(find.byKey(const Key('currency_chip_PKR')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Rs 25.00'), findsNWidgets(2));
      expect(find.text('Budget: Rs 50.00 / mo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard_currency_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Euro (€)'));
      await tester.pumpAndSettle();

      expect(find.text('€25.00'), findsNWidgets(2));
      expect(find.text('Budget: €50.00 / mo'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('currency_chip_SAR')));
      await tester.tap(find.byKey(const Key('currency_chip_SAR')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('SAR 25.00'), findsNWidgets(2));
      expect(find.text('Budget: SAR 50.00 / mo'), findsOneWidget);
    },
  );

  testWidgets(
    'Free trial subscription is excluded from budget bar until trial ends',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SubTrackerApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '60',
      );
      await tester.ensureVisible(find.text('Free Trial'));
      await tester.tap(find.text('Free Trial'));
      await tester.pump();
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      expect(find.text('Trial'), findsOneWidget);
      expect(find.text('\$0.00'), findsOneWidget);
      expect(find.text('Budget: \$50.00 / mo'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsNothing);
      final zeroBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('budget_progress_bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(zeroBar.widthFactor, 0.0);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Prime',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cost'),
        '20',
      );
      await tester.ensureVisible(find.text('SAVE SUBSCRIPTION'));
      await tester.tap(find.text('SAVE SUBSCRIPTION'));
      await tester.pumpAndSettle();

      expect(find.text('40%'), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsNothing);
      final fortyBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('budget_progress_bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fortyBar.widthFactor, closeTo(0.4, 0.001));

      final service = HiveService();
      final trialSub = service.getAll().firstWhere((s) => s.isFreeTrial);
      await service.update(
        trialSub.copyWith(
          billingDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trial Ended'), findsOneWidget);
      expect(find.byKey(const Key('over_budget_banner')), findsOneWidget);
      expect(find.text('OVER BUDGET'), findsOneWidget);
      expect(find.text('\$80.00 / \$50.00'), findsOneWidget);
      final fullBar = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(const Key('budget_progress_bar')),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fullBar.widthFactor, 1.0);
    },
  );

  test(
    'HiveService calculateActiveMonthly excludes paused and active free trials',
    () async {
      final service = HiveService();
      final referenceNow = DateTime(2026, 11, 19);
      await service.add(
        Subscription(
          id: '1',
          name: 'Claude',
          cost: 20.0,
          billingDate: DateTime(2026, 12, 1),
          cycle: 'Monthly',
          brandKey: 'Claude',
        ),
      );
      await service.add(
        Subscription(
          id: '2',
          name: 'Canva',
          cost: 120.0,
          billingDate: DateTime(2026, 12, 1),
          cycle: 'Yearly',
          brandKey: 'Canva',
        ),
      );
      await service.add(
        Subscription(
          id: '3',
          name: 'ChatGPT',
          cost: 20.0,
          billingDate: DateTime(2026, 12, 1),
          cycle: 'Monthly',
          isPaused: true,
          brandKey: 'ChatGPT',
        ),
      );
      await service.add(
        Subscription(
          id: '4',
          name: 'Netflix Trial',
          cost: 15.0,
          billingDate: DateTime(2026, 11, 26),
          cycle: 'Monthly',
          isFreeTrial: true,
          brandKey: 'Netflix',
        ),
      );
      await service.add(
        Subscription(
          id: '5',
          name: 'Ended Trial',
          cost: 10.0,
          billingDate: DateTime(2026, 11, 18),
          cycle: 'Monthly',
          isFreeTrial: true,
        ),
      );

      expect(
        service.calculateActiveMonthly(now: referenceNow),
        closeTo(40.0, 0.001),
      );
    },
  );
}
