import '../../models/article.dart';
import 'calendar_stub.dart'
    if (dart.library.io) 'calendar_native.dart'
    if (dart.library.js_interop) 'calendar_web.dart'
    as platform;

class CalendarTarget {
  const CalendarTarget(this.id, this.name);
  final String id;
  final String name;
}

class CalendarExportResult {
  const CalendarExportResult({
    this.created = 0,
    this.skipped = 0,
    this.failed = 0,
    this.downloaded = false,
  });
  final int created;
  final int skipped;
  final int failed;
  final bool downloaded;
  String get message => downloaded
      ? 'Fișierul .ics a fost generat pentru descărcare. Importă-l în calendar pentru a salva evenimentele.'
      : '$created evenimente salvate, $skipped deja existente, $failed nereușite.';
}

abstract interface class CalendarService {
  factory CalendarService() => platform.createCalendarService();
  bool get isNative;
  bool get isAvailable;
  Future<List<CalendarTarget>> calendars();
  Future<CalendarTarget> createLocalCalendar();
  Future<CalendarExportResult> export(
    List<Article> articles,
    DateTime day, {
    String? calendarId,
  });
}
