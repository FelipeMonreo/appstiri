import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/news_controller.dart';
import '../models/article.dart';
import '../services/app_exception.dart';
import '../services/calendar/calendar_service.dart';
import '../widgets/article_card.dart';
import '../widgets/reader_components.dart';
import 'details_screen.dart';
import 'export_dialog.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.controller, this.calendar});
  final NewsController? controller;
  final CalendarService? calendar;
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsController _controller = widget.controller ?? NewsController();
  late final CalendarService _calendar = widget.calendar ?? CalendarService();
  int _page = 0;
  bool _exporting = false;
  bool _openingArticle = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          showCloseIcon: true,
        ),
      );
  }

  Future<void> _favorite(Article article) async {
    final wasFavorite = _controller.isFavorite(article.id);
    try {
      await _controller.toggleFavorite(article);
      _message(
        wasFavorite
            ? 'Știrea a fost ștearsă din favorite.'
            : 'Știrea a fost salvată la favorite.',
      );
    } catch (e) {
      _message(e.toString());
    }
  }

  Future<void> _open(Article article) async {
    try {
      if (!await launchUrl(
        article.browserUrl,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      )) {
        throw const AppException('Articolul nu a putut fi deschis.');
      }
    } catch (_) {
      _message(
        'Browserul nu a putut deschide articolul. Verifică setările sau folosește linkul din detalii.',
      );
    }
  }

  Future<void> _details(Article article) async {
    if (_openingArticle) return;
    _openingArticle = true;
    try {
      await Navigator.of(context).push(
        ArticleRoute(
          reducedMotion: reduceReaderMotion(context),
          builder: (_) => DetailsScreen(
            article: article,
            controller: _controller,
            onOpen: _open,
          ),
        ),
      );
    } finally {
      _openingArticle = false;
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final result = await showDialog<CalendarExportResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            ExportDialog(articles: _controller.favorites, calendar: _calendar),
      );
      if (result != null) _message(result.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final theme = Theme.of(context);
      final favoritesPage = _page == 1;
      final articles = favoritesPage
          ? _controller.favorites
          : _controller.articles;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                    size: 27,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: 'Știri și favorite',
                      excludeSemantics: true,
                      child: Text(
                        'Știri.',
                        style: theme.textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 460 &&
                      MediaQuery.textScalerOf(context).scale(13) < 19)
                    Text(
                      DateFormat('d MMMM', 'ro').format(DateTime.now()),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          key: const ValueKey('main-navigation'),
          selectedIndex: _page,
          onDestinationSelected: (page) => setState(() => _page = page),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper_rounded),
              label: 'Toate știrile',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmarks_outlined),
              selectedIcon: const Icon(Icons.bookmarks_rounded),
              label: 'Favorite (${_controller.favorites.length})',
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1064),
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                child: CustomScrollView(
                  key: PageStorageKey(
                    favoritesPage ? 'saved-stories' : 'front-page',
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: _ReaderHeader(
                          favorites: favoritesPage,
                          loading: _controller.loading,
                          exporting: _exporting,
                          canExport:
                              articles.isNotEmpty && _calendar.isAvailable,
                          onRefresh: _controller.refresh,
                          onExport: _export,
                        ),
                      ),
                    ),
                    if (_controller.initializing)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_controller.storageWarning != null)
                                ReaderNotice(
                                  message: _controller.storageWarning!,
                                  onRetry: _controller.storageReady
                                      ? null
                                      : _controller.initialize,
                                ),
                              if (!favoritesPage &&
                                  _controller.cacheWarning != null)
                                ReaderNotice(
                                  message: _controller.cacheWarning!,
                                ),
                              if (!favoritesPage && _controller.error != null)
                                ReaderNotice(
                                  message:
                                      '${_controller.error!}${articles.isNotEmpty ? ' Sunt afișate ultimele știri salvate.' : ''}',
                                  onRetry: _controller.loading
                                      ? null
                                      : _controller.refresh,
                                ),
                              if (_controller.loading) ...[
                                const LinearProgressIndicator(minHeight: 3),
                                const SizedBox(height: 16),
                              ],
                              if (favoritesPage && !_calendar.isAvailable)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Exportul este disponibil în browser și în aplicația Android/iOS.',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (articles.isEmpty && !_controller.loading)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: ReaderEmptyState(
                              favorites: favoritesPage,
                              onBrowse: () => setState(() => _page = 0),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return ArticleCard(
                              key: ValueKey(article.id),
                              article: article,
                              featured: index == 0 && !favoritesPage,
                              favorite: _controller.isFavorite(article.id),
                              showRemove: favoritesPage,
                              onFavorite:
                                  _controller.savingFavorite ||
                                      !_controller.storageReady
                                  ? null
                                  : () => _favorite(article),
                              onDetails: () => _details(article),
                              onOpen: () => _open(article),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.favorites,
    required this.loading,
    required this.exporting,
    required this.canExport,
    required this.onRefresh,
    required this.onExport,
  });
  final bool favorites;
  final bool loading;
  final bool exporting;
  final bool canExport;
  final VoidCallback onRefresh;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              favorites ? 'Biblioteca ta.' : 'Lumea tech,\npe îndelete.',
              style: theme.textTheme.displaySmall!.copyWith(
                fontSize: wide ? 52 : 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              favorites
                  ? 'Favoritele rămân salvate după închiderea aplicației.'
                  : 'Știri Hacker News, favorite și idei de păstrat.',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        final action = favorites
            ? FilledButton.icon(
                onPressed: !canExport || exporting ? null : onExport,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  exporting
                      ? 'Se pregătește exportul…'
                      : 'Exportă favoritele în calendar',
                ),
              )
            : OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  loading ? 'Se încarcă știrile…' : 'Actualizează știrile',
                ),
              );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 330),
                child: action,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [copy, const SizedBox(height: 22), action],
        );
      },
    );
  }
}
