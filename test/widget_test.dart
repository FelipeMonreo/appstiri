import 'dart:convert';

import 'package:appstiri/app.dart';
import 'package:appstiri/services/article_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  testWidgets('User can favorite, export, remove and return to news', (
    tester,
  ) async {
    final controller = createController();
    final calendar = FakeCalendar();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      NewsApp(controller: controller, calendar: calendar),
    );
    await tester.pumpAndSettle();
    expect(find.text('O știre de test'), findsOneWidget);
    await tester.ensureVisible(find.text('Adaugă la favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adaugă la favorite'));
    await tester.pumpAndSettle();
    expect(controller.favorites.length, 1);
    await tester.tap(find.text('Favorite (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exportă favoritele în calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportă favoritele în calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Descarcă fișierul .ics'), findsOneWidget);
    await tester.tap(find.text('Descarcă fișierul .ics'));
    await tester.pumpAndSettle();
    expect(calendar.exported!.single.id, '42');
    expect(calendar.day, isNotNull);
    await tester.ensureVisible(find.text('Șterge din favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Șterge din favorite'));
    await tester.pumpAndSettle();
    expect(find.text('Nu ai încă știri favorite.'), findsOneWidget);
    expect(controller.favorites, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Details request is made when the user opens a story', (
    tester,
  ) async {
    var detailsCalls = 0;
    final controller = createController(
      client: MockClient((request) async {
        if (request.url.path.contains('/items/')) {
          detailsCalls++;
          return utf8Response(
            jsonEncode({
              ...articleJson(),
              'id': 42,
              'title': 'Detalii actualizate',
            }),
            200,
          );
        }
        return utf8Response(
          jsonEncode({
            'hits': [articleJson()],
          }),
          200,
        );
      }),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      NewsApp(controller: controller, calendar: FakeCalendar()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Detalii'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detalii'));
    await tester.pumpAndSettle();
    expect(detailsCalls, 1);
    expect(find.text('Detalii actualizate'), findsOneWidget);
    expect(find.text('Rezumatul știrii'), findsOneWidget);
    expect(find.textContaining('Flutter permite dezvoltarea'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Citește articolul complet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Pentru mai multe informații'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'Pentru mai multe informații, accesează articolul complet de la sursa originală.',
      ),
      findsOneWidget,
    );
    expect(find.text('Citește articolul complet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'A summary failure leaves the original article accessible and can be retried',
    (tester) async {
      var calls = 0;
      final summaries = ArticleSummaryService(
        client: MockClient((_) async {
          calls++;
          if (calls == 1) return utf8Response('Blocked', 403);
          return utf8Response(
            jsonEncode({
              'code': 200,
              'data': {
                'content': 'Flutter permite realizarea aplicațiilor pentru browser și telefon din aceeași bază de cod. Aplicația de știri permite salvarea articolelor preferate și exportarea lor în calendar.',
              },
            }),
            200,
          );
        }),
      );
      final controller = createController(summaries: summaries);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        NewsApp(controller: controller, calendar: FakeCalendar()),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Detalii'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detalii'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Reîncearcă rezumatul'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reîncearcă rezumatul'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Citește articolul complet'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Citește articolul complet'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.text('Reîncearcă rezumatul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reîncearcă rezumatul'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Flutter permite realizarea'), findsOneWidget);
      expect(find.text('Reîncearcă rezumatul'), findsNothing);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Phone layout uses full-width buttons without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = createController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      NewsApp(controller: controller, calendar: FakeCalendar()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('favorite-42'))).height,
      greaterThanOrEqualTo(56),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Adaugă la favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adaugă la favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorite (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exportă favoritele în calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportă favoritele în calendar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Network failure offers retry without an unhandled error', (
    tester,
  ) async {
    final controller = createController(
      client: MockClient((_) async => throw http.ClientException('Offline')),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      NewsApp(controller: controller, calendar: FakeCalendar()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Verifică internetul'), findsOneWidget);
    expect(find.text('Reîncearcă'), findsOneWidget);
    await tester.tap(find.text('Favorite (0)'));
    await tester.pumpAndSettle();
    final exportButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Exportă favoritele în calendar'),
    );
    expect(exportButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
