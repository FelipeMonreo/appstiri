class Article {
  const Article({
    required this.id,
    required this.title,
    required this.author,
    required this.publishedAt,
    required this.points,
    required this.comments,
    this.url,
    this.text,
  });
  final String id;
  final String title;
  final String author;
  final DateTime? publishedAt;
  final int points;
  final int comments;
  final String? url;
  final String? text;

  Uri get browserUrl {
    final candidate = Uri.tryParse(url ?? '');
    if (candidate != null &&
        (candidate.scheme == 'https' || candidate.scheme == 'http') &&
        candidate.host.isNotEmpty) {
      return candidate;
    }
    return Uri.https('news.ycombinator.com', '/item', {'id': id});
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    final id = (json['objectID'] ?? json['id'])?.toString();
    if (id == null || !RegExp(r'^\d+$').hasMatch(id)) {
      throw const FormatException('Identificator invalid.');
    }
    final rawDate = json['created_at'];
    DateTime? date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (date == null && json['created_at_i'] is num) {
      date = DateTime.fromMillisecondsSinceEpoch(
        (json['created_at_i'] as num).toInt() * 1000,
        isUtc: true,
      );
    }
    return Article(
      id: id,
      title: _string(json['title'], 'Știre fără titlu'),
      author: _string(json['author'], 'Autor necunoscut'),
      publishedAt: date?.toLocal(),
      points: _number(json['points']),
      comments: json['num_comments'] is num
          ? _number(json['num_comments'])
          : _countComments(json['children']),
      url: json['url'] is String ? json['url'] as String : null,
      text: json['text'] is String ? json['text'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'objectID': id,
    'title': title,
    'author': author,
    'created_at': publishedAt?.toUtc().toIso8601String(),
    'points': points,
    'num_comments': comments,
    'url': url,
    'text': text,
  };
  static String _string(dynamic value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;
  static int _number(dynamic value) =>
      value is num && value >= 0 ? value.toInt() : 0;
  static int _countComments(dynamic children) {
    if (children is! List) return 0;
    var count = 0;
    for (final child in children.whereType<Map>()) {
      if (child['type'] == 'comment') count++;
      count += _countComments(child['children']);
    }
    return count;
  }
}
