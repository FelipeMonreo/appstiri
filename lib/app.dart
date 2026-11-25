import 'package:material_ui/material_ui.dart';

import 'controllers/news_controller.dart';
import 'screens/news_screen.dart';
import 'services/calendar/calendar_service.dart';
import 'theme/app_theme.dart';

class NewsApp extends StatelessWidget {
  const NewsApp({super.key, this.controller, this.calendar});
  final NewsController? controller;
  final CalendarService? calendar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Știri și favorite',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ro'),
      supportedLocales: const [Locale('ro'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeAnimationDuration:
          (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
              (MediaQuery.maybeOf(context)?.reduceMotion ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      home: NewsScreen(controller: controller, calendar: calendar),
    );
  }
}
