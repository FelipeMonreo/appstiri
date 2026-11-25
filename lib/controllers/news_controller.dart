import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/article_summary.dart';
import '../services/article_summary_service.dart';
import '../services/app_exception.dart';
import '../services/news_api.dart';
import '../services/news_storage.dart';

class NewsController extends ChangeNotifier {
  NewsController({
    NewsApi? api,
    NewsStorage? storage,
    ArticleSummaryService? summaries,
  }) : _api = api ?? NewsApi(),
       _storage = storage ?? NewsStorage(),
       _summaries = summaries ?? ArticleSummaryService();
  final NewsApi _api;
  final NewsStorage _storage;
  final ArticleSummaryService _summaries;
  List<Article> _articles = [];
  Map<String, Article> _favorites = {};
  bool initializing = true;
  bool loading = false;
  bool storageReady = false;
  bool savingFavorite = false;
  bool _disposed = false;
  String? error;
  String? storageWarning;
  String? cacheWarning;
  List<Article> get articles => List.unmodifiable(_articles);
  List<Article> get favorites => List.unmodifiable(_favorites.values);
  bool isFavorite(String id) => _favorites.containsKey(id);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    initializing = true;
    storageWarning = null;
    _notify();
    try {
      final stored = await _storage.read(NewsStorage.favoritesKey);
      _favorites = {for (final article in stored.articles) article.id: article};
      storageReady = true;
      if (stored.hasInvalidItems) {
        storageWarning =
            'Unele favorite salvate sunt deteriorate și nu pot fi afișate.';
      }
    } catch (_) {
      storageReady = false;
      storageWarning =
          'Favoritele nu pot fi citite. Reîncearcă accesul la salvarea locală.';
    }
    try {
      _articles = (await _storage.read(NewsStorage.cacheKey)).articles;
    } catch (_) {
      /* Feed loading can continue without a cache. */
    }
    initializing = false;
    _notify();
    await refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      _articles = await _api.frontPage();
      cacheWarning = null;
      try {
        await _storage.write(NewsStorage.cacheKey, _articles);
      } catch (_) {
        cacheWarning = 'Știrile sunt încărcate, dar copia pentru acces offline nu a putut fi salvată.';
      }
    } on AppException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Știrile nu au putut fi încărcate. Încearcă din nou.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> toggleFavorite(Article article) async {
    if (!storageReady) {
      throw const AppException(
        'Salvarea locală nu este disponibilă. Reîncearcă mai întâi.',
      );
    }
    if (savingFavorite) return;
    savingFavorite = true;
    _notify();
    final next = Map<String, Article>.of(_favorites);
    if (next.containsKey(article.id)) {
      next.remove(article.id);
    } else {
      next[article.id] = article;
    }
    try {
      // Change visible state only after persistence succeeds.
      await _storage.write(NewsStorage.favoritesKey, next.values);
      _favorites = next;
    } finally {
      savingFavorite = false;
      _notify();
    }
  }

  Future<Article> details(Article article) => _api.details(article.id);
  Future<ArticleSummary> summary(Article article, {bool refresh = false}) =>
      _summaries.summarize(article, refresh: refresh);
  @override
  void dispose() {
    _disposed = true;
    _api.close();
    _summaries.close();
    super.dispose();
  }
}
