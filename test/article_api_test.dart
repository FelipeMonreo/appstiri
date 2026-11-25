import 'dart:convert';

import 'package:appstiri/models/article.dart';
import 'package:appstiri/services/app_exception.dart';
import 'package:appstiri/services/news_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

void main() {
  test('Models preserve fields through storage and normalize dates', () {
    final article = sampleArticle();
    expect(Article.fromJson(article.toJson()).toJson(), article.toJson());
    expect(article.publishedAt!.toUtc(), DateTime.utc(2026, 11, 20, 10, 30));
  });
  test('Missing and unsafe URLs fall back to Hacker News', () {
    for (final url in [null, 'javascript:alert(1)', '/relative', 'https://']) {
      final article = Article.fromJson({...articleJson(), 'url': url});
      expect(
        article.browserUrl.toString(),
        'https://news.ycombinator.com/item?id=42',
      );
    }
  });
  test('Missing metadata is safe and invalid ids are rejected', () {
    final article = Article.fromJson({
      'id': 1,
      'created_at': 'invalid',
      'points': -1,
    });
    expect(article.publishedAt, isNull);
    expect(article.points, 0);
    expect(article.author, 'Autor necunoscut');
    expect(() => Article.fromJson({'id': '../bad'}), throwsFormatException);
  });
  test('Nested API comments are counted for details', () {
    final article = Article.fromJson({
      'id': 42,
      'children': [
        {
          'type': 'comment',
          'children': [
            {'type': 'comment'},
          ],
        },
        {'type': 'comment'},
      ],
    });
    expect(article.comments, 3);
  });
  test(
    'Front page uses required endpoint and handles duplicates and bad items',
    () async {
      final api = NewsApi(
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://hn.algolia.com/api/v1/search?tags=front_page',
          );
          return utf8Response(
            jsonEncode({
              'hits': [
                articleJson(),
                {'bad': true},
                articleJson(),
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      expect((await api.frontPage()).single.title, 'O știre de test');
    },
  );
  test('Details use secure item endpoint and handle deleted stories', () async {
    final api = NewsApi(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://hn.algolia.com/api/v1/items/42',
        );
        return utf8Response(jsonEncode({'id': 42, 'deleted': true}), 200);
      }),
    );
    addTearDown(api.close);
    await expectLater(api.details('42'), throwsA(isA<AppException>()));
  });
  for (final body in ['not json', '[]', '{"hits": null}']) {
    test('Invalid API response is reported: $body', () async {
      final api = NewsApi(
        client: MockClient((_) async => utf8Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(api.frontPage(), throwsA(isA<AppException>()));
    });
  }
  test('Network failures and server errors are reported', () async {
    for (final client in [
      MockClient((_) async => throw http.ClientException('Offline')),
      MockClient((_) async => utf8Response('Unavailable', 503)),
    ]) {
      final api = NewsApi(client: client);
      await expectLater(api.frontPage(), throwsA(isA<AppException>()));
      api.close();
    }
  });
}
