import 'dart:convert';

import 'package:appstiri/models/article.dart';
import 'package:appstiri/services/calendar/calendar_document.dart';
import 'package:appstiri/services/calendar/calendar_native.dart';
import 'package:appstiri/services/app_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const calendarChannel = MethodChannel(
    'plugins.builttoroam.com/device_calendar',
  );
  const zoneChannel = MethodChannel('appstiri/timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    messenger.setMockMethodCallHandler(calendarChannel, null);
    messenger.setMockMethodCallHandler(zoneChannel, null);
  });
  final expected = [
    (14, 20),
    (12, 18),
    (14, 20),
    (12, 18),
    (14, 20),
    (8, 12),
    (8, 12),
  ];
  for (var i = 0; i < 7; i++) {
    test('Required event hours for weekday ${i + 1}', () {
      final day = DateTime(2026, 11, 23 + i);
      final slot = CalendarSlot.forDay(day);
      expect((slot.start.hour, slot.end.hour), expected[i]);
      expect(slot.start.day, day.day);
    });
  }
  test(
    'ICS includes metadata, stable IDs, escaping and folded UTF-8 lines',
    () {
      final article = Article.fromJson({
        ...articleJson(),
        'title': '${List.filled(70, 'știre').join()} ,;\\\nEND:VEVENT',
      });
      final document = buildCalendarDocument(
        [article, article],
        DateTime(2026, 11, 24),
        generatedAt: DateTime.utc(2026),
      );
      final unfolded = document.replaceAll('\r\n ', '');
      expect(RegExp('BEGIN:VEVENT').allMatches(document).length, 1);
      expect(unfolded, contains('UID:news-42-20261124@appstiri.local'));
      expect(unfolded, contains('DTSTART:20261124T120000'));
      expect(unfolded, contains('DTEND:20261124T180000'));
      expect(unfolded, contains('Autor: ana'));
      expect(unfolded, contains('Data publicării:'));
      expect(unfolded, contains('URL:https://example.com/articol'));
      expect(unfolded, contains(r'\nEND:VEVENT'));
      for (final line in document.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
    },
  );
  test(
    'Native export honors the timezone and does not duplicate saved events',
    () async {
      final events = <Map<String, dynamic>>[];
      messenger.setMockMethodCallHandler(
        zoneChannel,
        (_) async => 'Europe/Bucharest',
      );
      messenger.setMockMethodCallHandler(calendarChannel, (call) async {
        if (call.method == 'hasPermissions') return true;
        if (call.method == 'retrieveEvents') return jsonEncode(events);
        if (call.method == 'createOrUpdateEvent') {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          events.add({...args, 'eventId': 'event-${events.length}'});
          return 'event-${events.length}';
        }
        return null;
      });
      final service = DeviceCalendarService(platformSupported: true);
      final day = DateTime(2026, 11, 24);
      final result = await service.export(
        [sampleArticle()],
        day,
        calendarId: 'calendar',
      );
      expect(result.created, 1);
      final event = events.single;
      final eventStart = event['eventStartDate'] as int;
      final eventEnd = event['eventEndDate'] as int;
      expect(event['eventURL'], 'https://example.com/articol');
      expect(event['eventTitle'], 'O știre de test');
      expect(
        event['eventDescription'],
        allOf(
          contains('Autor: ana'),
          contains('Link: https://example.com/articol'),
          contains('Data publicării:'),
        ),
      );
      expect(
        tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.getLocation('Europe/Bucharest'),
          eventStart,
        ).hour,
        12,
      );
      expect(
        tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.getLocation('Europe/Bucharest'),
          eventEnd,
        ).hour,
        18,
      );
      final repeated = await service.export(
        [sampleArticle()],
        day,
        calendarId: 'calendar',
      );
      expect(repeated.skipped, 1);
      expect(events.length, 1);
    },
  );
  test('Denied calendar permission results in a useful error', () async {
    final requests = <String>[];
    messenger.setMockMethodCallHandler(calendarChannel, (call) async {
      requests.add(call.method);
      return false;
    });
    final service = DeviceCalendarService(platformSupported: true);
    await expectLater(service.calendars(), throwsA(isA<AppException>()));
    expect(requests, ['hasPermissions', 'requestPermissions']);
  });
  test('Read-only calendars are excluded', () async {
    messenger.setMockMethodCallHandler(
      calendarChannel,
      (call) async => call.method == 'hasPermissions'
          ? true
          : jsonEncode([
              {'id': '1', 'name': 'Writable', 'isReadOnly': false},
              {'id': '2', 'isReadOnly': true},
            ]),
    );
    final service = DeviceCalendarService(platformSupported: true);
    expect((await service.calendars()).single.id, '1');
  });
}
