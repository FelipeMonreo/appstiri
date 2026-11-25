class ArticleSummary {
  const ArticleSummary({
    required this.sentences,
    required this.source,
    required this.createdAt,
  });

  final List<String> sentences;
  final Uri source;
  final DateTime createdAt;
}
