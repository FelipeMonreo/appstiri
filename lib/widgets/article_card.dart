import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/article.dart';
import 'reader_components.dart';
import 'reader_language.dart';

String publicationLabel(BuildContext context, Article article) =>
    article.publishedAt == null
    ? context.tr('Data publicării necunoscută', 'Publication date unknown')
    : DateFormat(
        'dd.MM.yyyy · HH:mm',
        Localizations.localeOf(context).languageCode,
      ).format(article.publishedAt!.toLocal());

String articleSource(Article article) =>
    article.browserUrl.host.replaceFirst(RegExp(r'^www\.'), '');

/// Only the headline flies between routes. API work starts after that flight.
class ArticleHeadline extends StatelessWidget {
  const ArticleHeadline({super.key, required this.article, this.style});
  final Article article;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !reduceReaderMotion(context),
    child: Hero(
      tag: 'headline-${article.id}',
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          header: true,
          child: Text(
            article.title,
            textAlign: TextAlign.start,
            style: style ?? Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    ),
  );
}

/// A compact card shared by the feed and saved articles.
class ArticleCard extends StatelessWidget {
  const ArticleCard({
    super.key,
    required this.article,
    required this.favorite,
    required this.onFavorite,
    required this.onDetails,
    required this.onOpen,
    this.showRemove = false,
  });

  final Article article;
  final bool favorite;
  final bool showRemove;
  final VoidCallback? onFavorite;
  final VoidCallback? onDetails;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final metadataStyle = theme.textTheme.bodySmall;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: favorite ? colors.outline : colors.outlineVariant,
      ),
    );
    final favoriteLabel = showRemove
        ? context.tr('Șterge din favorite', 'Remove from favorites')
        : favorite
        ? context.tr('Scoate din favorite', 'Remove from favorites')
        : context.tr('Adaugă la favorite', 'Add to favorites');

    final headline = Semantics(
      button: true,
      child: InkWell(
        key: ValueKey('details-${article.id}'),
        onTap: onDetails,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ArticleHeadline(
                article: article,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(articleSource(article), style: metadataStyle),
                  Text(
                    '${context.tr('Autor', 'Author')}: ${article.author}',
                    style: metadataStyle,
                  ),
                  Text(
                    publicationLabel(context, article),
                    style: metadataStyle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('favorite-${article.id}'),
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
          tooltip: favoriteLabel,
          onPressed: onFavorite,
          icon: FavoriteIcon(
            saved: favorite,
            removing: showRemove,
            enabled: onFavorite != null,
          ),
        ),
        IconButton(
          tooltip: context.tr('Articolul original', 'Original article'),
          onPressed: onOpen,
          alignment: AlignmentDirectional.centerEnd,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 680 &&
                  MediaQuery.textScalerOf(context).scale(13) <= 16;
              final activity = ArticleActivity(article: article);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    Row(
                      children: [
                        Expanded(child: headline),
                        const SizedBox(width: 20),
                        SizedBox(width: 212, child: activity),
                        actions,
                      ],
                    )
                  else ...[
                    headline,
                    Row(
                      children: [
                        Expanded(child: activity),
                        const SizedBox(width: 4),
                        actions,
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({
    super.key,
    required this.saved,
    this.removing = false,
    this.enabled = true,
  });

  final bool saved;
  final bool removing;
  final bool enabled;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: motionDuration(context, 240),
    transitionBuilder: (child, animation) {
      final scale = child.key == const ValueKey(true) && !removing
          ? TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween<double>(
                  begin: .86,
                  end: 1.13,
                ).chain(CurveTween(curve: Curves.easeOut)),
                weight: 55,
              ),
              TweenSequenceItem(
                tween: Tween<double>(
                  begin: 1.13,
                  end: 1,
                ).chain(CurveTween(curve: Curves.easeInOut)),
                weight: 45,
              ),
            ])
          : Tween<double>(begin: .92, end: 1);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: scale.animate(animation), child: child),
      );
    },
    child: Icon(
      removing
          ? Icons.bookmark_remove_outlined
          : saved
          ? Icons.bookmark_added_rounded
          : Icons.bookmark_add_outlined,
      key: ValueKey(saved),
      color: saved && enabled ? Theme.of(context).colorScheme.primary : null,
      size: 20,
    ),
  );
}

class ArticleActivity extends StatelessWidget {
  const ArticleActivity({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          '${article.points} ${context.tr('puncte', 'points')}',
          style: style,
        ),
        Text(
          '${article.comments} ${context.tr('comentarii', 'comments')}',
          style: style,
        ),
      ],
    );
  }
}
