import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/article.dart';
import 'reader_components.dart';

String publicationLabel(Article article) => article.publishedAt == null
    ? 'Data publicării necunoscută'
    : DateFormat('dd.MM.yyyy · HH:mm').format(article.publishedAt!.toLocal());

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
            style: style ?? Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    ),
  );
}

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    super.key,
    required this.article,
    required this.favorite,
    required this.onFavorite,
    required this.onDetails,
    required this.onOpen,
    this.showRemove = false,
    this.featured = false,
  });
  final Article article;
  final bool favorite;
  final bool showRemove;
  final bool featured;
  final VoidCallback? onFavorite;
  final VoidCallback? onDetails;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final background = featured
        ? (dark ? colors.surfaceContainerHigh : colors.primary)
        : colors.surface;
    final foreground = featured && !dark ? colors.onPrimary : colors.onSurface;
    final muted = featured && !dark
        ? const Color(0xFFE0EAFF)
        : colors.onSurfaceVariant;
    final primaryStyle = featured && !dark
        ? FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: colors.primary,
          )
        : null;
    final secondaryStyle = featured && !dark
        ? OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFB6CEFF)),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(featured ? 26 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.language_rounded, size: 17, color: muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      articleSource(article),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (favorite) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.bookmark_added_rounded,
                      size: 21,
                      color: foreground,
                      semanticLabel: 'Salvată la favorite',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              ArticleHeadline(
                article: article,
                style:
                    (featured
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.headlineSmall)!
                        .copyWith(color: foreground),
              ),
              const SizedBox(height: 18),
              Text(
                'Autor: ${article.author}',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Publicată: ${publicationLabel(article)}',
                style: theme.textTheme.bodySmall!.copyWith(color: muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 22,
                runSpacing: 10,
                children: [
                  _Metadata(
                    icon: Icons.trending_up_rounded,
                    text: '${article.points} puncte',
                    color: foreground,
                  ),
                  _Metadata(
                    icon: Icons.chat_bubble_outline_rounded,
                    text: '${article.comments} comentarii',
                    color: foreground,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttons = <Widget>[
                    if (onDetails != null)
                      FilledButton.icon(
                        key: ValueKey('details-${article.id}'),
                        onPressed: onDetails,
                        style: primaryStyle,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Detalii'),
                      ),
                    OutlinedButton.icon(
                      key: ValueKey('favorite-${article.id}'),
                      onPressed: onFavorite,
                      style: secondaryStyle,
                      icon: AnimatedSwitcher(
                        duration: motionDuration(context, 160),
                        switchInCurve: Curves.easeOutCubic,
                        child: Icon(
                          favorite
                              ? (showRemove
                                    ? Icons.bookmark_remove_rounded
                                    : Icons.bookmark_added_rounded)
                              : Icons.bookmark_add_outlined,
                          key: ValueKey(favorite),
                        ),
                      ),
                      label: Text(
                        favorite
                            ? (showRemove
                                  ? 'Șterge din favorite'
                                  : 'Scoate din favorite')
                            : 'Adaugă la favorite',
                      ),
                    ),
                    if (onOpen != null)
                      TextButton.icon(
                        onPressed: onOpen,
                        style: TextButton.styleFrom(foregroundColor: muted),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Articolul original'),
                      ),
                  ];
                  if (constraints.maxWidth < 580) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < buttons.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 10),
                          buttons[index],
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: buttons,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
