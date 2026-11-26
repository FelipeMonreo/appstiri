import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/news_controller.dart';
import '../models/article.dart';
import '../services/app_exception.dart';
import '../services/calendar/calendar_service.dart';
import '../widgets/article_card.dart';
import '../widgets/reader_components.dart';
import '../widgets/reader_language.dart';
import 'details_screen.dart';
import 'export_dialog.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({
    super.key,
    this.controller,
    this.calendar,
    this.onToggleLanguage,
    this.logoKey,
  });
  final NewsController? controller;
  final CalendarService? calendar;
  final VoidCallback? onToggleLanguage;
  final Key? logoKey;
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
      if (!mounted) return;
      _message(
        wasFavorite
            ? context.tr(
                'Știrea a fost ștearsă din favorite.',
                'Article removed from favorites.',
              )
            : context.tr(
                'Știrea a fost salvată la favorite.',
                'Article added to favorites.',
              ),
      );
    } catch (e) {
      if (mounted) _message(context.localizedMessage(e.toString()));
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
      if (!mounted) return;
      _message(
        context.tr(
          'Browserul nu a putut deschide articolul. Verifică setările sau folosește linkul din detalii.',
          'The browser could not open the article. Check its settings or use the link in the article details.',
        ),
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
          closeLabel: context.tr('Închide detaliile', 'Close article details'),
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
        builder: (_) => ReaderPanelBackdrop(
          child: ExportDialog(
            articles: _controller.favorites,
            calendar: _calendar,
          ),
        ),
      );
      if (mounted && result != null) _message(context.calendarResult(result));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final dark = theme.brightness == Brightness.dark;
      final headerText = dark ? colors.onSurface : Colors.white;
      final wide =
          MediaQuery.sizeOf(context).width >= 840 &&
          MediaQuery.textScalerOf(context).scale(13) <= 18;
      final favoritesLabel =
          '${context.tr('Favorite', 'Favorites')} (${_controller.favorites.length})';
      final favoritesPage = _page == 1;
      final articles = favoritesPage
          ? _controller.favorites
          : _controller.articles;
      return Scaffold(
        extendBody: !wide,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: dark
              ? theme.scaffoldBackgroundColor
              : colors.primary,
          foregroundColor: headerText,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          toolbarHeight:
              72 +
              (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                0.0,
                24.0,
              ),
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: Row(
                children: [
                  Image.asset(
                    'assets/branding/unitbv.png',
                    key: widget.logoKey,
                    width: 36,
                    height: 36,
                    semanticLabel: 'Universitatea Transilvania din Brașov',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReaderHeaderTitle(
                      title: context.tr('Știri UNITBV', 'UNITBV News'),
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: headerText,
                      ),
                    ),
                  ),
                  if (widget.onToggleLanguage != null)
                    Tooltip(
                      message: context.tr(
                        'Schimbă limba în engleză',
                        'Switch language to Romanian',
                      ),
                      child: TextButton(
                        onPressed: widget.onToggleLanguage,
                        style: TextButton.styleFrom(
                          foregroundColor: headerText,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(context.tr('RO', 'EN')),
                      ),
                    ),
                  if (!favoritesPage)
                    IconButton(
                      tooltip: context.tr(
                        'Actualizează știrile',
                        'Refresh news',
                      ),
                      color: headerText,
                      disabledColor: headerText.withValues(alpha: .78),
                      onPressed: _controller.loading
                          ? null
                          : _controller.refresh,
                      icon: ReaderRefreshIcon(refreshing: _controller.loading),
                    ),
                  if (wide)
                    SegmentedButton<int>(
                      key: const ValueKey('main-navigation'),
                      style: SegmentedButton.styleFrom(
                        foregroundColor: headerText,
                        selectedBackgroundColor: dark
                            ? colors.primary
                            : Colors.white,
                        selectedForegroundColor: dark
                            ? colors.onPrimary
                            : colors.primary,
                        side: BorderSide(color: headerText),
                      ),
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.newspaper_outlined),
                          label: Text(context.tr('Toate știrile', 'All news')),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: const Icon(Icons.bookmarks_outlined),
                          label: Text(favoritesLabel),
                        ),
                      ],
                      selected: {_page},
                      onSelectionChanged: (pages) =>
                          setState(() => _page = pages.single),
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : ReaderBottomNavigation(
                selectedIndex: _page,
                onDestinationSelected: (page) => setState(() => _page = page),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.newspaper_outlined),
                    selectedIcon: const Icon(Icons.newspaper_rounded),
                    label: context.tr('Toate știrile', 'All news'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.bookmarks_outlined),
                    selectedIcon: const Icon(Icons.bookmarks_rounded),
                    label: favoritesLabel,
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
                  physics: readerScrollPhysics(context),
                  slivers: [
                    if (favoritesPage)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: _FavoritesHeader(
                            exporting: _exporting,
                            canExport:
                                articles.isNotEmpty && _calendar.isAvailable,
                            onExport: _export,
                          ),
                        ),
                      ),
                    if (!favoritesPage)
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
                                      '${context.localizedMessage(_controller.error!)}${articles.isNotEmpty ? context.tr(' Sunt afișate ultimele știri salvate.', ' Showing the most recently cached news.') : ''}',
                                  onRetry: _controller.loading
                                      ? null
                                      : _controller.refresh,
                                ),
                              if (_controller.loading) ...[
                                const LinearProgressIndicator(minHeight: 3),
                                const SizedBox(height: 16),
                              ],
                              if (favoritesPage && !_calendar.isAvailable)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    context.tr(
                                      'Exportul este disponibil în browser și în aplicația Android/iOS.',
                                      'Export is available in the browser and in the Android/iOS app.',
                                    ),
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
                            final card = ArticleCard(
                              article: article,
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
                            return ReaderIntroCard(
                              key: ValueKey(article.id),
                              index: index,
                              child: card,
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SafeArea(
                          top: false,
                          child: SizedBox(height: 28),
                        ),
                      ),
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

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.exporting,
    required this.canExport,
    required this.onExport,
  });
  final bool exporting;
  final bool canExport;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      context.tr('Favorite', 'Favorites'),
      style: Theme.of(context).textTheme.headlineSmall,
    );
    final action = FilledButton.icon(
      onPressed: !canExport || exporting ? null : onExport,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text(
        exporting
            ? context.tr('Se pregătește exportul…', 'Preparing export…')
            : context.tr(
                'Exportă favoritele în calendar',
                'Export favorites to calendar',
              ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560 ||
            MediaQuery.textScalerOf(context).scale(15) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 8), action],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 8),
            action,
          ],
        );
      },
    );
  }
}
