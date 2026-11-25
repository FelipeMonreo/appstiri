import 'dart:js_interop';

import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;

import '../../models/article.dart';
import 'calendar_document.dart';
import 'calendar_service.dart';
import 'calendar_stub.dart';

CalendarService createCalendarService() => WebCalendarService();

class WebCalendarService extends UnsupportedCalendarService {
  @override
  bool get isAvailable => true;
  @override
  Future<CalendarExportResult> export(
    List<Article> articles,
    DateTime day, {
    String? calendarId,
  }) async {
    final document = buildCalendarDocument(articles, day);
    final blob = web.Blob(
      [document.toJS].toJS,
      web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'stiri-favorite-${DateFormat('yyyy-MM-dd').format(day)}.ics';
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
    Future<void>.delayed(
      const Duration(seconds: 30),
      () => web.URL.revokeObjectURL(url),
    );
    return const CalendarExportResult(downloaded: true);
  }
}
