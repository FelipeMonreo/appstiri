import 'package:material_ui/material_ui.dart';

/// Flutter's ticker follows display frames; accessibility can remove motion.
bool reduceReaderMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.reduceMotionOf(context);

Duration motionDuration(BuildContext context, [int milliseconds = 200]) =>
    reduceReaderMotion(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

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
                    message,
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
                label: const Text('Reîncearcă'),
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
                ? 'Nu ai încă știri favorite.'
                : 'Nu sunt știri de afișat.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            favorites
                ? 'Păstrează ideile la care vrei să revii.\nLe vei găsi pe toate aici.'
                : 'Încearcă o actualizare când ai conexiune la internet.',
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
              label: const Text('Mergi la toate știrile'),
            ),
          ],
        ],
      ),
    );
  }
}
