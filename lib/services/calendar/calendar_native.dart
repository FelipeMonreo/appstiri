import 'dart:io';

import 'package:device_calendar/device_calendar.dart' as device;
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/article.dart';
import '../app_exception.dart';
import 'calendar_document.dart';
import 'calendar_service.dart';

CalendarService createCalendarService() => DeviceCalendarService();

class DeviceCalendarService implements CalendarService {
  DeviceCalendarService({this.platformSupported});
  final bool? platformSupported;
  device.DeviceCalendarPlugin? _calendarPlugin;
  device.DeviceCalendarPlugin get _plugin =>
      _calendarPlugin ??= device.DeviceCalendarPlugin();
  static const _timeZoneChannel = MethodChannel('appstiri/timezone');
  @override
  bool get isNative =>
      platformSupported ?? (Platform.isAndroid || Platform.isIOS);
  @override
  bool get isAvailable => isNative;
  Future<void> _permissions() async {
    if (!isAvailable) {
      throw const AppException(
        'Calendarul dispozitivului este disponibil pe Android și iOS.',
      );
    }
    var result = await _plugin.hasPermissions();
    if (result.data != true) result = await _plugin.requestPermissions();
    if (!result.isSuccess || result.data != true) {
      throw const AppException(
        'Accesul la calendar nu a fost permis. Activează permisiunea din setările aplicației și reîncearcă.',
      );
    }
  }

  @override
  Future<List<CalendarTarget>> calendars() async {
    await _permissions();
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess) {
      throw const AppException(
        'Calendarele nu au putut fi citite. Încearcă din nou.',
      );
    }
    return (result.data ?? [])
        .where((calendar) => calendar.isReadOnly != true && calendar.id != null)
        .map(
          (calendar) => CalendarTarget(
            calendar.id!,
            '${calendar.name ?? 'Calendar'}${calendar.accountName == null ? '' : ' · ${calendar.accountName}'}',
          ),
        )
        .toList();
  }

  @override
  Future<CalendarTarget> createLocalCalendar() async {
    await _permissions();
    final result = await _plugin.createCalendar(
      'Știri favorite',
      localAccountName: 'Appstiri',
    );
    if (!result.isSuccess || result.data == null) {
      throw const AppException(
        'Calendarul local nu a putut fi creat. Adaugă un calendar în aplicația Calendar și reîncearcă.',
      );
    }
    return CalendarTarget(result.data!, 'Știri favorite · Appstiri (local)');
  }

  Future<tz.Location> _location() async {
    try {
      final name = await _timeZoneChannel.invokeMethod<String>('getTimeZone');
      if (name != null) return tz.getLocation(name);
    } catch (_) {
      /* Fall back to the current device offset. */
    }
    final now = DateTime.now();
    return tz.Location('Local', [], [], [
      tz.TimeZone(
        now.timeZoneOffset.inMilliseconds,
        isDst: false,
        abbreviation: now.timeZoneName,
      ),
    ]);
  }

  @override
  Future<CalendarExportResult> export(
    List<Article> articles,
    DateTime day, {
    String? calendarId,
  }) async {
    await _permissions();
    if (calendarId == null || calendarId.isEmpty) {
      throw const AppException('Alege mai întâi calendarul.');
    }
    final slot = CalendarSlot.forDay(day);
    final location = await _location();
    final start = tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      slot.start.hour,
    );
    final end = tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      slot.end.hour,
    );
    final existing = await _plugin.retrieveEvents(
      calendarId,
      device.RetrieveEventsParams(
        startDate: tz.TZDateTime(location, day.year, day.month, day.day),
        endDate: tz.TZDateTime(location, day.year, day.month, day.day + 1),
      ),
    );
    if (!existing.isSuccess) {
      throw const AppException(
        'Evenimentele existente nu pot fi verificate. Reîncearcă exportul pentru a evita duplicatele.',
      );
    }
    final markers = <String>{};
    for (final event in existing.data ?? <device.Event>[]) {
      if (event.start?.isAtSameMomentAs(start) == true) {
        markers.addAll(
          (event.description ?? '')
              .split('\n')
              .where((line) => line.startsWith('Appstiri-ID: ')),
        );
      }
    }
    var created = 0;
    var skipped = 0;
    var failed = 0;
    for (final article in articles) {
      final marker = articleMarker(article);
      if (markers.contains(marker)) {
        skipped++;
        continue;
      }
      try {
        final result = await _plugin.createOrUpdateEvent(
          device.Event(
            calendarId,
            title: article.title,
            description: calendarDescription(article),
            // device_calendar serializes URL values through Uri.data.contentText.
            url: Uri.dataFromString(article.browserUrl.toString()),
            start: start,
            end: end,
          ),
        );
        if (result?.isSuccess == true) {
          created++;
          markers.add(marker);
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    return CalendarExportResult(
      created: created,
      skipped: skipped,
      failed: failed,
    );
  }
}
