import 'dart:convert';

import 'package:intl/intl.dart';

import '../../models/article.dart';

class CalendarSlot {
  const CalendarSlot(this.start, this.end);
  final DateTime start;
  final DateTime end;
  factory CalendarSlot.forDay(DateTime day) {
    final (startHour, endHour) = switch (day.weekday) {
      DateTime.saturday || DateTime.sunday => (8, 12),
      DateTime.tuesday || DateTime.thursday => (12, 18),
      _ => (14, 20),
    };
    return CalendarSlot(
      DateTime(day.year, day.month, day.day, startHour),
      DateTime(day.year, day.month, day.day, endHour),
    );
  }
  String get label =>
      '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}';
}

String articleMarker(Article article) => 'Appstiri-ID: ${article.id}';
String calendarDescription(Article article) => [
  'Autor: ${article.author}',
  'Link: ${article.browserUrl}',
  'Data publicării: ${article.publishedAt == null ? 'Necunoscută' : DateFormat('dd.MM.yyyy HH:mm').format(article.publishedAt!.toLocal())}',
  articleMarker(article),
].join('\n');

String buildCalendarDocument(
  Iterable<Article> articles,
  DateTime day, {
  DateTime? generatedAt,
}) {
  final slot = CalendarSlot.forDay(day);
  // Floating local times preserve the specified hours in the importing calendar.
  final stamp = DateFormat("yyyyMMdd'T'HHmmss'Z'")
      .format((generatedAt ?? DateTime.now()).toUtc());
  final eventFormat = DateFormat("yyyyMMdd'T'HHmmss");
  final dateId = DateFormat('yyyyMMdd').format(slot.start);
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Appstiri//Favorite news//RO',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  final seen = <String>{};
  for (final article in articles) {
    if (!seen.add(article.id)) continue;
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:news-${article.id}-$dateId@appstiri.local',
      'DTSTAMP:$stamp',
      'DTSTART:${eventFormat.format(slot.start)}',
      'DTEND:${eventFormat.format(slot.end)}',
      'SUMMARY:${_escape(article.title)}',
      'DESCRIPTION:${_escape(calendarDescription(article))}',
      'URL:${article.browserUrl}',
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

String _escape(String text) => text
    .replaceAll('\\', '\\\\')
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll('\n', r'\n')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,');
String _fold(String line) {
  final result = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final character = String.fromCharCode(rune);
    final size = utf8.encode(character).length;
    if (bytes + size > 75) {
      result.write('\r\n ');
      bytes = 1;
    }
    result.write(character);
    bytes += size;
  }
  return result.toString();
}
