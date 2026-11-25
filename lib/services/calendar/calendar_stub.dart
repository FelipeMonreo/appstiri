import '../../models/article.dart';
import '../app_exception.dart';
import 'calendar_service.dart';

CalendarService createCalendarService() => UnsupportedCalendarService();

class UnsupportedCalendarService implements CalendarService {
  @override
  bool get isNative => false;
  @override
  bool get isAvailable => false;
  @override
  Future<List<CalendarTarget>> calendars() async => [];
  @override
  Future<CalendarTarget> createLocalCalendar() async =>
      throw const AppException('Calendarul este disponibil pe Android și iOS.');
  @override
  Future<CalendarExportResult> export(
    List<Article> articles,
    DateTime day, {
    String? calendarId,
  }) async => throw const AppException(
    'Rulează aplicația în browser, pe Android sau pe iOS pentru export.',
  );
}
