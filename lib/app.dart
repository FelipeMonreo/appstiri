import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'controllers/news_controller.dart';
import 'screens/news_screen.dart';
import 'services/calendar/calendar_service.dart';
import 'theme/app_theme.dart';
import 'widgets/reader_components.dart';
import 'widgets/reader_language.dart';

class NewsApp extends StatefulWidget {
  const NewsApp({super.key, this.controller, this.calendar, this.introReady});
  final NewsController? controller;
  final CalendarService? calendar;
  final Future<void>? introReady;

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  Locale _locale = const Locale('ro');
  final _headerLogo = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.tr('Știri UNITBV', 'UNITBV News'),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      supportedLocales: const [Locale('ro'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) => _LaunchIntro(
        headerLogo: _headerLogo,
        ready: widget.introReady,
        child: child!,
      ),
      themeAnimationDuration:
          (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
              (MediaQuery.maybeOf(context)?.reduceMotion ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      home: NewsScreen(
        logoKey: _headerLogo,
        controller: widget.controller,
        calendar: widget.calendar,
        onToggleLanguage: () => setState(() {
          _locale = Locale(_locale.languageCode == 'ro' ? 'en' : 'ro');
        }),
      ),
    );
  }
}

class _LaunchIntro extends StatefulWidget {
  const _LaunchIntro({
    required this.headerLogo,
    required this.ready,
    required this.child,
  });

  final GlobalKey headerLogo;
  final Future<void>? ready;
  final Widget child;

  @override
  State<_LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<_LaunchIntro> {
  final _viewport = GlobalKey();
  late bool _ready = widget.ready == null;

  @override
  void initState() {
    super.initState();
    final ready = widget.ready;
    if (ready != null) {
      unawaited(
        ready.then((_) {
          if (mounted) setState(() => _ready = true);
        }),
      );
    }
  }

  Rect? _headerBounds() {
    final logo = widget.headerLogo.currentContext?.findRenderObject();
    final viewport = _viewport.currentContext?.findRenderObject();
    if (logo is! RenderBox || !logo.hasSize || viewport is! RenderBox) {
      return null;
    }
    return logo.localToGlobal(Offset.zero, ancestor: viewport) & logo.size;
  }

  @override
  Widget build(BuildContext context) {
    const moveStart = 3650;
    const moveDuration = 760;
    const newsDelay = 80;
    const newsReveal = 420;
    const titleTyping = 1050;
    const newsStart = moveStart + moveDuration + newsDelay;
    const introDuration = newsStart + titleTyping;
    final reduced = reduceReaderMotion(context);
    final theme = Theme.of(context);
    final background = theme.brightness == Brightness.dark
        ? theme.scaffoldBackgroundColor
        : AppTheme.brand;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: _ready || reduced ? 1 : 0),
      duration: motionDuration(context, introDuration),
      child: widget.child,
      builder: (context, value, child) {
        final elapsed = value * introDuration;
        final feed = reduced
            ? 1.0
            : Curves.easeOutCubic.transform(
                ((elapsed - newsStart) / newsReveal).clamp(0.0, 1.0),
              );
        final typing = reduced
            ? 1.0
            : ((elapsed - newsStart) / titleTyping).clamp(0.0, 1.0);
        return Stack(
          key: _viewport,
          fit: StackFit.expand,
          children: [
            ReaderIntroMotion(progress: typing, child: child!),
            if (feed < 1)
              AbsorbPointer(
                child: ExcludeSemantics(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 1 - feed,
                        child: ColoredBox(color: background),
                      ),
                      if (elapsed < moveStart)
                        Center(child: _IntroMark(elapsedMilliseconds: elapsed))
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final start = Rect.fromCenter(
                              center: constraints.biggest.center(Offset.zero),
                              width: _IntroMark._size,
                              height: _IntroMark._size,
                            );
                            final progress = Curves.easeInOutCubic.transform(
                              ((elapsed - moveStart) / moveDuration).clamp(
                                0.0,
                                1.0,
                              ),
                            );
                            return Stack(
                              children: [
                                Positioned.fromRect(
                                  rect: Rect.lerp(
                                    start,
                                    _headerBounds() ?? start,
                                    progress,
                                  )!,
                                  child: Image.asset(
                                    'assets/branding/unitbv.png',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IntroMark extends StatelessWidget {
  const _IntroMark({required this.elapsedMilliseconds});

  final double elapsedMilliseconds;

  static const _size = 144.0;
  static const _assemblyStart = 650;
  static const _travelDuration = 720;
  static const _drawDuration = 380;

  // Crop each piece from the original 203×202 PNG and set its entry edge.
  static const _pieces = [
    (Rect.fromLTRB(0, 0, 203, 33), Offset(-1, -1)),
    (Rect.fromLTRB(0, 33, 203, 68), Offset(1, 0)),
    (Rect.fromLTRB(0, 68, 34, 202), Offset(-1, 1)),
    (Rect.fromLTRB(34, 68, 68, 202), Offset(-1, 1)),
    (Rect.fromLTRB(68, 68, 138, 202), Offset(0, 1)),
    (Rect.fromLTRB(138, 68, 172, 202), Offset(1, 1)),
    (Rect.fromLTRB(172, 68, 203, 202), Offset(1, 1)),
  ];

  static int _entryTime(int index) => _assemblyStart + index * 85;

  static Rect _trace(Rect piece, int index, double progress) => switch (index) {
    0 => Rect.fromLTRB(
      piece.left,
      piece.top,
      piece.left + piece.width * progress,
      piece.bottom,
    ),
    1 => Rect.fromLTRB(
      piece.right - piece.width * progress,
      piece.top,
      piece.right,
      piece.bottom,
    ),
    _ => Rect.fromLTRB(
      piece.left,
      piece.bottom - piece.height * progress,
      piece.right,
      piece.bottom,
    ),
  };

  @override
  Widget build(BuildContext context) {
    const lightStart = 2280;
    const lightStep = 115;
    const lightDuration = 340;
    final mark = Image.asset(
      'assets/branding/unitbv.png',
      width: _size,
      height: _size,
    );
    if (elapsedMilliseconds >=
        lightStart + (_pieces.length - 1) * lightStep + lightDuration) {
      return mark;
    }
    final screen = MediaQuery.sizeOf(context);
    final square = 1 - _phase(1930, 330, Curves.easeInOut);
    return SizedBox.fromSize(
      size: screen,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (elapsedMilliseconds >= _assemblyStart)
            Positioned.fill(
              child: CustomPaint(
                painter: _IntroSnakeTrails(elapsedMilliseconds),
              ),
            ),
          for (final (index, (piece, _)) in _pieces.indexed)
            if (elapsedMilliseconds > _entryTime(index) + _travelDuration)
              ClipRect(
                clipper: _MarkPieceClipper(
                  _trace(
                    piece,
                    index,
                    _phase(
                      _entryTime(index) + _travelDuration,
                      _drawDuration,
                      Curves.easeOut,
                    ),
                  ),
                ),
                child: Opacity(
                  opacity:
                      .62 +
                      .38 *
                          _phase(
                            lightStart + index * lightStep,
                            lightDuration,
                            Curves.easeInOut,
                          ),
                  child: mark,
                ),
              ),
          if (square > 0)
            Opacity(
              opacity: square,
              child: const ColoredBox(
                color: Colors.white,
                child: SizedBox.square(dimension: 15),
              ),
            ),
        ],
      ),
    );
  }

  double _phase(int start, int duration, Curve curve) => curve.transform(
    ((elapsedMilliseconds - start) / duration).clamp(0.0, 1.0),
  );
}

class _IntroSnakeTrails extends CustomPainter {
  const _IntroSnakeTrails(this.elapsedMilliseconds);

  final double elapsedMilliseconds;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _IntroMark._size / 203;
    final origin = size.center(Offset.zero) - const Offset(72, 72);
    final paint = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final (index, (piece, direction)) in _IntroMark._pieces.indexed) {
      final time = elapsedMilliseconds - _IntroMark._entryTime(index);
      if (time <= 0 || time >= _IntroMark._travelDuration + 180) continue;

      final endpoint =
          origin +
          Offset(
            (index == 0
                    ? piece.left + 6
                    : index == 1
                    ? piece.right - 4
                    : piece.center.dx) *
                scale,
            (index < 2 ? piece.center.dy : piece.bottom - 5) * scale,
          );
      final start = Offset(
        direction.dx < 0
            ? 0
            : direction.dx > 0
            ? size.width
            : endpoint.dx,
        switch ((direction.dx == 0, direction.dy)) {
          (_, 0) => endpoint.dy,
          (true, _) => size.height,
          (_, -1) => size.height * .18,
          _ => size.height * (.70 + index * .035),
        },
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(endpoint.dx, start.dy)
        ..lineTo(endpoint.dx, endpoint.dy);
      final metric = path.computeMetrics().first;
      final head =
          metric.length *
          Curves.easeInOutCubic.transform(
            (time / _IntroMark._travelDuration).clamp(0.0, 1.0),
          );
      final tail =
          (head -
                  54 +
                  54 *
                      ((time - _IntroMark._travelDuration) / 180).clamp(
                        0.0,
                        1.0,
                      ))
              .clamp(0.0, head);
      paint.strokeWidth = index < 2 ? 12 : 14;
      canvas.drawPath(metric.extractPath(tail, head), paint);
    }
  }

  @override
  bool shouldRepaint(_IntroSnakeTrails oldDelegate) =>
      elapsedMilliseconds != oldDelegate.elapsedMilliseconds;
}

class _MarkPieceClipper extends CustomClipper<Rect> {
  const _MarkPieceClipper(this.piece);

  final Rect piece;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    piece.left * size.width / 203,
    piece.top * size.height / 202,
    piece.right * size.width / 203,
    piece.bottom * size.height / 202,
  );

  @override
  bool shouldReclip(_MarkPieceClipper oldClipper) => piece != oldClipper.piece;
}
