import 'package:material_ui/material_ui.dart';

import '../controllers/news_controller.dart';
import '../models/article.dart';
import '../models/article_summary.dart';
import '../services/app_exception.dart';
import '../widgets/article_card.dart';
import '../widgets/reader_components.dart';

/// Keeps the platform's back gesture and predictive-back transition. There is
/// no timer or assumed 60 Hz; Flutter's animation ticker follows display frames.
class ArticleRoute extends MaterialPageRoute<void> {
  ArticleRoute({required super.builder, required this.reducedMotion})
    : super(settings: const RouteSettings(name: '/article'));
  final bool reducedMotion;
  // Hero temporarily completes ModalRoute.animation for its offstage measure.
  // Listen to the real controller so that measure cannot start network work.
  Animation<double>? get entranceAnimation => controller?.view;
  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 360);
  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? Duration.zero : const Duration(milliseconds: 280);
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => reducedMotion
      ? child
      : super.buildTransitions(context, animation, secondaryAnimation, child);
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
          () => _error =
              '${e is AppException ? e.message : 'Detaliile nu au putut fi încărcate.'} Sunt afișate datele salvate.',
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
      appBar: AppBar(
        title: const Text('Detaliile știrii'),
        actions: [
          IconButton(
            tooltip: 'Actualizează detaliile',
            onPressed: _loading || _summaryLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
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
                          ? 'Se deschide articolul…'
                          : 'Citește articolul complet',
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        articleSource(_article),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ArticleHeadline(
                  article: _article,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Autor: ${_article.author}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Publicată: ${publicationLabel(_article)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${_article.points} puncte',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${_article.comments} comentarii',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                      icon: Icon(
                        saved
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                      ),
                      label: Text(
                        saved ? 'Scoate din favorite' : 'Adaugă la favorite',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 28),
                if (_error != null)
                  ReaderNotice(
                    message: _error!,
                    onRetry: _loading ? null : _load,
                  ),
                Text('Rezumatul știrii', style: theme.textTheme.headlineSmall),
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
                  'Pentru mai multe informații, accesează articolul complet de la sursa originală.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _article.browserUrl.toString(),
                  style: theme.textTheme.bodySmall,
                ),
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
            child: const Text(
              'Se citește articolul și se pregătește rezumatul…',
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
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontSize: 18,
                  height: 1.75,
                ),
              ),
            ),
          Text(
            'Rezumat automat, în limba articolului original.',
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
            label: const Text('Reîncearcă rezumatul'),
          ),
        ],
      ],
    );
  }
}
