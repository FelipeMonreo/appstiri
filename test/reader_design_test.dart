import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:appstiri/app.dart';
import 'package:appstiri/screens/details_screen.dart';
import 'package:appstiri/screens/news_screen.dart';
import 'package:appstiri/theme/app_theme.dart';
import 'package:appstiri/widgets/reader_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('The refresh icon rotates only while the request is pending', (
    tester,
  ) async {
    final feed = utf8Response(
      jsonEncode({
        'hits': [articleJson()],
      }),
      200,
    );
    final pending = Completer<http.Response>();
    var calls = 0;
    final controller = createController(
      client: MockClient((_) async => ++calls == 1 ? feed : pending.future),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(NewsApp(controller: controller));
    await tester.pumpAndSettle();
    final rotation = find.descendant(
      of: find.byType(ReaderRefreshIcon),
      matching: find.byType(RotationTransition),
    );
    expect(tester.widget<RotationTransition>(rotation).turns.value, 0);
    await tester.tap(find.byTooltip('Actualizează știrile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<RotationTransition>(rotation).turns.value,
      greaterThan(0),
    );

    pending.complete(feed);
    await tester.pumpAndSettle();
    expect(tester.widget<RotationTransition>(rotation).turns.value, 0);
  });

  testWidgets('The intro waits for the platform to show its first frame', (
    tester,
  ) async {
    final platformReady = Completer<void>();
    final controller = createController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      NewsApp(controller: controller, introReady: platformReady.future),
    );
    final title = find.byKey(const ValueKey('reader-app-title'));
    await tester.pump(const Duration(seconds: 6));
    final hidden = tester.widget<Text>(title).textSpan! as TextSpan;
    expect(hidden.children!.first.toPlainText(), isEmpty);

    platformReady.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, 'Știri UNITBV');
  });

  testWidgets('The intro mark shrinks into the header position', (
    tester,
  ) async {
    final controller = createController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(NewsApp(controller: controller));

    final header = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.semanticLabel == 'Universitatea Transilvania din Brașov',
    );
    final intro = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.semanticLabel == null &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/branding/unitbv.png',
    );

    await tester.pump(const Duration(milliseconds: 3650));
    final initialWidth = tester.getSize(intro).width;
    await tester.pump(const Duration(milliseconds: 380));
    expect(tester.getSize(intro).width, lessThan(initialWidth));
    expect(
      tester.getSize(intro).width,
      greaterThan(tester.getSize(header).width),
    );

    await tester.pump(const Duration(milliseconds: 380));
    expect(tester.getRect(intro), tester.getRect(header));
    await tester.pump(const Duration(milliseconds: 260));
    final title = find.byKey(const ValueKey('reader-app-title'));
    final writing = tester.widget<Text>(title).textSpan! as TextSpan;
    final visible = writing.children!.first.toPlainText();
    expect(visible, isNotEmpty);
    expect(visible.length, lessThan('Știri UNITBV'.length));
    expect(intro, findsOneWidget);
    final card = find.byKey(const ValueKey('details-42'));
    final slidingX = tester.getTopLeft(card).dx;
    await tester.pumpAndSettle();
    expect(intro, findsNothing);
    expect(tester.widget<Text>(title).data, 'Știri UNITBV');
    expect(tester.getTopLeft(card).dx, greaterThan(slidingX));
  });

  test('Reading and action colors have AA contrast in both system themes', () {
    double contrast(Color a, Color b) {
      final high = math.max(a.computeLuminance(), b.computeLuminance());
      final low = math.min(a.computeLuminance(), b.computeLuminance());
      return (high + 0.05) / (low + 0.05);
    }

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.colorScheme;
      for (final pair in [
        (colors.primary, colors.onPrimary),
        (colors.surface, colors.onSurface),
        (colors.surface, colors.onSurfaceVariant),
        (colors.surfaceContainerLowest, colors.onSurfaceVariant),
        (colors.primaryContainer, colors.onPrimaryContainer),
        (colors.errorContainer, colors.onErrorContainer),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets(
    'Changing the phone theme preserves favorites and updates the UI',
    (tester) async {
      final controller = createController();
      addTearDown(controller.dispose);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(
        NewsApp(controller: controller, calendar: FakeCalendar()),
      );
      await tester.pumpAndSettle();
      await controller.toggleFavorite(sampleArticle());
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NewsScreen))).brightness,
        Brightness.light,
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      final theme = Theme.of(tester.element(find.byType(NewsScreen)));
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.charcoal);
      expect(controller.favorites.single.id, '42');
      expect(find.text('Favorite (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Article requests start after the entrance and back preserves the feed',
    (tester) async {
      var calls = 0;
      AnimationStatus? requestAnimationStatus;
      final controller = createController(
        client: MockClient((request) async {
          if (request.url.path.contains('/items/')) {
            calls++;
            requestAnimationStatus = ModalRoute.of(
              tester.element(find.byType(DetailsScreen, skipOffstage: false)),
            )?.animation?.status;
            return utf8Response(jsonEncode({...articleJson(), 'id': 42}), 200);
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
      await tester.ensureVisible(find.byKey(const ValueKey('details-42')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('details-42')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(requestAnimationStatus, AnimationStatus.completed);
      expect(find.byType(DetailsScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NewsScreen), findsOneWidget);
      expect(controller.articles.single.id, '42');
      expect(tester.takeException(), isNull);
    },
  );

  for (final features in [
    const FakeAccessibilityFeatures(disableAnimations: true),
    const FakeAccessibilityFeatures(reduceMotion: true),
  ]) {
    testWidgets(
      'Reduced motion opens the reader without a timed transition: $features',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final controller = createController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          NewsApp(controller: controller, calendar: FakeCalendar()),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('details-42')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('details-42')));
        await tester.pumpAndSettle();
        final route =
            ModalRoute.of(tester.element(find.byType(DetailsScreen)))!
                as ArticleRoute;
        expect(route.transitionDuration, Duration.zero);
        expect(route.reverseTransitionDuration, Duration.zero);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    '320px with 200% text supports long titles, large buttons and calendar export',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller = createController(
        client: MockClient(
          (_) async => utf8Response(
            jsonEncode({
              'hits': [
                {
                  ...articleJson(),
                  'title': 'O perspectivă detaliată asupra aplicațiilor pentru telefon și a felului în care tehnologia schimbă lumea în fiecare zi',
                },
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        NewsApp(controller: controller, calendar: FakeCalendar()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final favorite = find.byKey(const ValueKey('favorite-42'));
      await tester.scrollUntilVisible(
        favorite,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(favorite).height, greaterThanOrEqualTo(56));
      await tester.tap(favorite);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favorite (1)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Exportă favoritele în calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exportă favoritele în calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Descarcă fișierul .ics'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
