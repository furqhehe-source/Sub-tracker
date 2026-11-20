import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.instance.init();
  runApp(const SubTrackerApp());
}

class SubTrackerApp extends StatelessWidget {
  const SubTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HiveService.isDarkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'SubTracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
