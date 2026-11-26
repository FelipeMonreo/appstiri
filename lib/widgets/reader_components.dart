import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'reader_language.dart';

/// Flutter's ticker follows display frames; accessibility can remove motion.
bool reduceReaderMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.reduceMotionOf(context);

Duration motionDuration(BuildContext context, [int milliseconds = 200]) =>
    reduceReaderMotion(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

ScrollPhysics readerScrollPhysics(BuildContext context) =>
    reduceReaderMotion(context)
    ? const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
    : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

class ReaderRefreshIcon extends StatefulWidget {
  const ReaderRefreshIcon({super.key, required this.refreshing});

  final bool refreshing;

  @override
  State<ReaderRefreshIcon> createState() => _ReaderRefreshIconState();
}

class _ReaderRefreshIconState extends State<ReaderRefreshIcon>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRotation();
  }

  @override
  void didUpdateWidget(ReaderRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing != oldWidget.refreshing) _syncRotation();
  }

  void _syncRotation() {
    if (widget.refreshing && !reduceReaderMotion(context)) {
      if (!_rotation.isAnimating) _rotation.repeat();
    } else {
      _rotation.reset();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _rotation,
    child: const Icon(Icons.refresh_rounded),
  );
}

class ReaderIntroMotion extends InheritedWidget {
  const ReaderIntroMotion({
    super.key,
    required this.progress,
    required super.child,
  });

  final double progress;

  static double progressOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReaderIntroMotion>()
          ?.progress ??
      1;

  @override
  bool updateShouldNotify(ReaderIntroMotion oldWidget) =>
      progress != oldWidget.progress;
}

class ReaderHeaderTitle extends StatelessWidget {
  const ReaderHeaderTitle({
    super.key,
    required this.title,
    required this.style,
  });

  final String title;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    const titleKey = ValueKey('reader-app-title');
    final progress = ReaderIntroMotion.progressOf(context);
    if (progress >= 1) {
      return Text(
        title,
        key: titleKey,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final shown = (title.length * progress).floor();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title.substring(0, shown)),
          TextSpan(
            text: title.substring(shown),
            style: const TextStyle(color: Colors.transparent),
          ),
        ],
      ),
      key: titleKey,
      semanticsLabel: title,
      style: style,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class ReaderIntroCard extends StatelessWidget {
  const ReaderIntroCard({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = index.clamp(0, 5) * .085;
    final progress = Interval(
      start,
      start + .42,
      curve: Curves.easeOutCubic,
    ).transform(ReaderIntroMotion.progressOf(context));
    return FractionalTranslation(
      translation: Offset(-.90 * (1 - progress), 0),
      child: Opacity(opacity: progress, child: child),
    );
  }
}

/// The route supplies the modal barrier and focus scope. This only paints frost.
class ReaderPanelBackdrop extends StatelessWidget {
  const ReaderPanelBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (!MediaQuery.highContrastOf(context))
        Positioned.fill(
          child: IgnorePointer(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      child,
    ],
  );
}

/// Frost only the controls that actually sit above scrolling content.
class ReaderGlassBar extends StatelessWidget {
  const ReaderGlassBar({super.key, required this.child, this.docked = false});

  final Widget child;
  final bool docked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final opaque = MediaQuery.highContrastOf(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = theme.navigationBarTheme.backgroundColor ?? colors.surface;
    final frost = Color.lerp(surface, Colors.white, dark ? .12 : .55)!;
    final radius = docked
        ? BorderRadius.zero
        : const BorderRadius.all(Radius.circular(26));
    final rim = opaque
        ? colors.outline
        : Colors.white.withValues(alpha: dark ? .26 : .90);

    final glass = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .28 : .14),
            blurRadius: 20,
            offset: Offset(0, docked ? -3 : 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          enabled: !opaque,
          filter: ui.ImageFilter.blur(sigmaX: 23, sigmaY: 23),
          child: Container(
            decoration: BoxDecoration(
              color: opaque ? surface : null,
              gradient: opaque
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        frost.withValues(alpha: .85),
                        surface.withValues(alpha: .80),
                        surface.withValues(alpha: .84),
                      ],
                      stops: const [0, .54, 1],
                    ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: docked
                  ? Border(top: BorderSide(color: rim))
                  : Border.all(color: rim),
            ),
            child: docked ? SafeArea(top: false, child: child) : child,
          ),
        ),
      ),
    );
    return docked
        ? glass
        : SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: glass,
            ),
          );
  }
}

class ReaderBottomNavigation extends StatelessWidget {
  const ReaderBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = motionDuration(context, 280);
    return ReaderGlassBar(
      docked: true,
      child: Stack(
        children: [
          NavigationBarTheme(
            data: theme.navigationBarTheme.copyWith(
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: 25,
                  color: states.contains(WidgetState.selected)
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            child: NavigationBar(
              key: const ValueKey('main-navigation'),
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              animationDuration: duration,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: IgnorePointer(
              child: AnimatedAlign(
                alignment: AlignmentDirectional(
                  (selectedIndex + .5) * 2 / destinations.length - 1,
                  0,
                ),
                duration: duration,
                curve: Curves.easeInOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / destinations.length,
                  child: Center(
                    child: Container(
                      key: const ValueKey('navigation-selection-indicator'),
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReaderNotice extends StatelessWidget {
  const ReaderNotice({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.localizedMessage(message),
                    textAlign: TextAlign.start,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Reîncearcă', 'Try again')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReaderEmptyState extends StatelessWidget {
  const ReaderEmptyState({super.key, required this.favorites, this.onBrowse});
  final bool favorites;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              favorites ? Icons.bookmarks_outlined : Icons.newspaper_rounded,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            favorites
                ? context.tr(
                    'Nu ai încă știri favorite.',
                    'You have no favorites yet.',
                  )
                : context.tr(
                    'Nu sunt știri de afișat.',
                    'There is no news to display.',
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            favorites
                ? context.tr(
                    'Păstrează ideile la care vrei să revii.\nLe vei găsi pe toate aici.',
                    'Save articles you want to revisit.\nYou’ll find them here.',
                  )
                : context.tr(
                    'Încearcă o actualizare când ai conexiune la internet.',
                    'Try refreshing when you are online.',
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (favorites && onBrowse != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(
                context.tr('Mergi la toate știrile', 'Go to all news'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
