import 'package:material_ui/material_ui.dart';

import '../controllers/news_controller.dart';
import '../models/article.dart';
import '../models/article_summary.dart';
import '../services/app_exception.dart';
import '../widgets/article_card.dart';
import '../widgets/reader_components.dart';
import '../widgets/reader_language.dart';

/// Keeps the source visible behind a modal reader with its own focus scope.
class ArticleRoute extends PageRoute<void> {
  ArticleRoute({
    required this.builder,
    required this.reducedMotion,
    required this.closeLabel,
  }) : super(
         settings: const RouteSettings(name: '/article'),
         allowSnapshotting: false,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final WidgetBuilder builder;
  final bool reducedMotion;
  final String closeLabel;
  // Hero temporarily completes ModalRoute.animation for its offstage measure.
  // Listen to the real controller so that measure cannot start network work.
  Animation<double>? get entranceAnimation => controller?.view;
  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Color get barrierColor => Colors.black54;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => closeLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      return Center(
        child: SizedBox(
          width: wide ? constraints.maxWidth * .70 : constraints.maxWidth - 24,
          height: constraints.maxHeight * .70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    },
  );

  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 460);
  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 280);
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => ReaderPanelBackdrop(
    child: reducedMotion
        ? child
        : FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
            child: ScaleTransition(
              scale: animation
                  .drive(CurveTween(curve: Curves.easeOutCubic))
                  .drive(Tween<double>(begin: .94, end: 1)),
              child: child,
            ),
          ),
  );
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.article,
    required this.controller,
    required this.onOpen,
  });
  final Article article;
  final NewsController controller;
  final Future<void> Function(Article) onOpen;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Article _article = widget.article;
  bool _loading = true;
  String? _error;
  bool _summaryLoading = true;
  String? _summaryError;
  ArticleSummary? _summary;
  bool _loadScheduled = false;
  bool _openingExternal = false;
  Animation<double>? _entrance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    final route = ModalRoute.of(context);
    final entrance = route is ArticleRoute
        ? route.entranceAnimation
        : route?.animation;
    if (entrance == null ||
        entrance.isCompleted ||
        reduceReaderMotion(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    } else {
      _entrance = entrance;
      entrance.addStatusListener(_afterEntrance);
    }
  }

  void _afterEntrance(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entrance?.removeStatusListener(_afterEntrance);
    _entrance = null;
    if (mounted) _load();
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_afterEntrance);
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.article.url?.isNotEmpty == true) {
      await Future.wait([_loadDetails(), _loadSummary(widget.article)]);
    } else {
      await _loadDetails();
      if (mounted) await _loadSummary(_article);
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final article = await widget.controller.details(widget.article);
      if (mounted) setState(() => _article = article);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppException
              ? e.message
              : 'Detaliile nu au putut fi încărcate.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSummary(Article article, {bool refresh = false}) async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final summary = await widget.controller.summary(
        article,
        refresh: refresh,
      );
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) {
        setState(
          () => _summaryError = e is AppException ? e.message : 'Rezumatul nu a putut fi încărcat. Poți deschide articolul original mai jos.',
        );
      }
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  Future<void> _favorite() async {
    try {
      await widget.controller.toggleFavorite(_article);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizedMessage(e.toString()))),
        );
      }
    }
  }

  Future<void> _open() async {
    if (_openingExternal) return;
    setState(() => _openingExternal = true);
    try {
      await widget.onOpen(_article);
    } finally {
      if (mounted) setState(() => _openingExternal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(context.tr('Detaliile știrii', 'Article details')),
        actions: [
          IconButton(
            tooltip: context.tr('Actualizează detaliile', 'Refresh details'),
            onPressed: _loading || _summaryLoading ? null : _load,
            icon: ReaderRefreshIcon(refreshing: _loading || _summaryLoading),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: ReaderGlassBar(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openingExternal ? null : _open,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(
                      _openingExternal
                          ? context.tr(
                              'Se deschide articolul…',
                              'Opening article…',
                            )
                          : context.tr(
                              'Citește articolul complet',
                              'Read full article',
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: ListView(
              key: const PageStorageKey('article-reader'),
              physics: readerScrollPhysics(context),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              children: [
                ArticleHeadline(
                  article: _article,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      articleSource(_article),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${context.tr('Autor', 'Author')}: ${_article.author}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${context.tr('Publicată', 'Published')}: ${publicationLabel(context, _article)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    ArticleActivity(article: _article),
                  ],
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    final saved = widget.controller.isFavorite(_article.id);
                    return OutlinedButton.icon(
                      key: const ValueKey('reader-favorite'),
                      onPressed:
                          widget.controller.savingFavorite ||
                              !widget.controller.storageReady
                          ? null
                          : _favorite,
                      icon: FavoriteIcon(
                        saved: saved,
                        enabled:
                            !widget.controller.savingFavorite &&
                            widget.controller.storageReady,
                      ),
                      label: Text(
                        saved
                            ? context.tr(
                                'Scoate din favorite',
                                'Remove from favorites',
                              )
                            : context.tr(
                                'Adaugă la favorite',
                                'Add to favorites',
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                if (_error != null)
                  ReaderNotice(
                    message:
                        '${context.localizedMessage(_error!)} ${context.tr('Sunt afișate datele salvate.', 'Showing saved details.')}',
                    onRetry: _loading ? null : _load,
                  ),
                Text(
                  context.tr('Rezumatul știrii', 'Article summary'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: motionDuration(context, 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _summaryContent(context),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  context.tr(
                    'Pentru mai multe informații, accesează articolul complet de la sursa originală.',
                    'For more information, read the full article at the original source.',
                  ),
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _article.browserUrl.toString(),
                  style: theme.textTheme.bodySmall,
                ),
                const SafeArea(top: false, child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: ValueKey((_summaryLoading, _summaryError, _summary)),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_summaryLoading) ...[
          if (!reduceReaderMotion(context))
            const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              context.tr(
                'Se citește articolul și se pregătește rezumatul…',
                'Reading the article and preparing the summary…',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_summary != null) ...[
          for (final sentence in _summary!.sentences)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: SelectableText(
                sentence,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontSize: 18,
                  height: 1.75,
                ),
              ),
            ),
          Text(
            context.tr(
              'Rezumat automat, în limba articolului original.',
              'Automatic summary in the original language.',
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_summaryError != null) ...[
          ReaderNotice(message: _summaryError!),
          OutlinedButton.icon(
            onPressed: _summaryLoading
                ? null
                : () => _loadSummary(_article, refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('Reîncearcă rezumatul', 'Retry summary')),
          ),
        ],
      ],
    );
  }
}
