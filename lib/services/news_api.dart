import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import 'app_exception.dart';

class NewsApi {
  NewsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 404) {
        throw const AppException('Știrea nu mai este disponibilă.');
      }
      if (response.statusCode != 200) {
        throw const AppException(
          'Serverul de știri nu răspunde. Încearcă din nou.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      return data;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Conexiunea durează prea mult. Încearcă din nou.',
      );
    } on FormatException {
      throw const AppException(
        'Serverul a trimis date invalide. Încearcă din nou.',
      );
    } catch (_) {
      throw const AppException(
        'Nu se poate contacta serverul. Verifică internetul.',
      );
    }
  }

  Future<List<Article>> frontPage() async {
    final data = await _get(
      Uri.https('hn.algolia.com', '/api/v1/search', {'tags': 'front_page'}),
    );
    if (data['hits'] is! List) {
      throw const AppException('Lista de știri primită este invalidă.');
    }
    final articles = <String, Article>{};
    for (final hit in data['hits'] as List) {
      if (hit is! Map<String, dynamic>) continue;
      try {
        final article = Article.fromJson(hit);
        articles[article.id] = article;
      } on FormatException {
        /* A bad item must not hide the rest of the feed. */
      }
    }
    if (articles.isEmpty && (data['hits'] as List).isNotEmpty) {
      throw const AppException(
        'Știrile primite nu pot fi citite. Încearcă din nou.',
      );
    }
    return articles.values.toList();
  }

  Future<Article> details(String id) async {
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      throw const AppException('Identificator invalid.');
    }
    final data = await _get(Uri.https('hn.algolia.com', '/api/v1/items/$id'));
    if (data['id'] == null || data['deleted'] == true) {
      throw const AppException('Știrea nu mai este disponibilă.');
    }
    try {
      return Article.fromJson(data);
    } on FormatException {
      throw const AppException('Detaliile știrii sunt invalide.');
    }
  }

  void close() => _client.close();
}
