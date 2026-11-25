import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';
import 'app_exception.dart';

class StoredNews {
  const StoredNews(this.articles, {this.hasInvalidItems = false});
  final List<Article> articles;
  final bool hasInvalidItems;
}

class NewsStorage {
  NewsStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const favoritesKey = 'appstiri.favorites.v1';
  static const cacheKey = 'appstiri.frontpage.v1';
  Future<StoredNews> read(String key) async {
    final raw = await _preferences.getStringList(key) ?? [];
    var invalid = false;
    final articles = <String, Article>{};
    for (final item in raw) {
      try {
        final data = jsonDecode(item);
        if (data is! Map<String, dynamic>) throw const FormatException();
        final article = Article.fromJson(data);
        articles[article.id] = article;
      } on FormatException {
        invalid = true;
      }
    }
    return StoredNews(articles.values.toList(), hasInvalidItems: invalid);
  }

  Future<void> write(String key, Iterable<Article> articles) async {
    try {
      await _preferences.setStringList(
        key,
        articles.map((article) => jsonEncode(article.toJson())).toList(),
      );
    } catch (_) {
      throw const AppException(
        'Salvarea locală a eșuat. Verifică spațiul disponibil și setările browserului.',
      );
    }
  }
}
