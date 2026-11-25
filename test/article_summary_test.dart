import 'dart:async';
import 'dart:convert';

import 'package:appstiri/models/article.dart';
import 'package:appstiri/services/app_exception.dart';
import 'package:appstiri/services/article_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

const sampleContent = '''
# Flutter article

[Sign in](https://example.com/login)
Cookies and privacy settings are available on this website.

Flutter applications can share one codebase across browsers and Android phones while keeping platform-specific features available. The news application retrieves current stories from a public API and stores favorite articles on the device. A calendar integration lets readers turn their saved stories into scheduled events with the required weekday hours. The same application handles network failures without deleting stories that were saved earlier. Automated tests verify persistence, calendar scheduling and the user interface on narrow screens. Developers can run the browser version locally before testing the calendar on an Android device.
''';

http.Response readerResponse(String content) => utf8Response(
  jsonEncode({
    'code': 200,
    'data': {'content': content},
  }),
  200,
);

void main() {
  // Formats are derived from Reader's FormattedPageDto and text serializers:
  // https://github.com/jina-ai/reader/blob/main/src/services/snapshot-formatter.ts
  final formats = <(String, String, String)>[
    (
      'default Markdown',
      'text/plain; charset=utf-8',
      'Title: Source title\n\nURL Source: https://example.com/articol\n\nMarkdown Content:\n$sampleContent',
    ),
    (
      'frontmatter',
      'text/plain; charset=utf-8',
      '---\ntitle: "Source title"\nurl: "https://example.com/articol"\n---\n\n$sampleContent',
    ),
    ('plain text', 'text/plain', sampleContent),
    (
      'unwrapped page DTO',
      'application/json',
      jsonEncode({
        'title': 'Source title',
        'url': 'https://example.com/articol',
        'content': sampleContent,
      }),
    ),
    (
      'wrapped text',
      'application/json',
      jsonEncode({
        'code': 200,
        'data': {'text': sampleContent},
      }),
    ),
    (
      'wrapped HTML',
      'application/json',
      jsonEncode({
        'code': 200,
        'data': {'html': '<article><p>$sampleContent</p></article>'},
      }),
    ),
    (
      'JSON frontmatter content',
      'application/json',
      jsonEncode({
        'code': 200,
        'data': {
          'content': '---\ntitle: "Source title"\n---\n\n$sampleContent',
        },
      }),
    ),
    (
      'BOM and CRLF',
      'text/plain',
      '\uFEFFTitle: Source title\r\nURL Source: https://example.com/articol\r\nMarkdown Content:\r\n$sampleContent',
    ),
  ];
  for (final (name, contentType, body) in formats) {
    test(
      'Regression: reads documented $name response instead of assuming wrapped JSON',
      () async {
        final service = ArticleSummaryService(
          client: MockClient(
            (_) async => http.Response.bytes(
              utf8.encode(body),
              200,
              headers: {'content-type': contentType},
            ),
          ),
        );
        addTearDown(service.close);
        final summary = await service.summarize(sampleArticle());
        expect(summary.sentences, isNotEmpty);
        expect(summary.sentences.first, startsWith('Flutter applications'));
        expect(summary.sentences.join(' '), isNot(contains('Source title')));
        expect(summary.sentences.join(' '), isNot(contains('URL Source')));
        expect(
          summary.sentences.join(' '),
          isNot(contains('Markdown Content:')),
        );
      },
    );
  }
  test('Reader warning is checked independently of the article title', () {
    final response =
        '---\ntitle: "Research into CAPTCHA and access denied messages"\n---\n\n$sampleContent';
    expect(decodeReaderContent(response), contains(sampleContent.trim()));
    expect(
      () => decodeReaderContent(
        'Title: Source\nWarning: Target URL returned error 403: Forbidden\nMarkdown Content:\n$sampleContent',
      ),
      throwsA(isA<AppException>()),
    );
    expect(
      () => decodeReaderContent(
        '---\nwarning: "Target URL returned error 403"\n---\n\n$sampleContent',
      ),
      throwsA(isA<AppException>()),
    );
  });
  test('HTML service error pages are not summarized as a successful story', () {
    expect(
      () => decodeReaderContent(
        '<html><body>$sampleContent</body></html>',
        contentType: 'text/html',
      ),
      throwsFormatException,
    );
    expect(
      () => decodeReaderContent(
        '{"code":403,"message":"Blocked"}',
        contentType: 'application/json',
      ),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'Reads the original URL and builds a bounded summary from the body',
    () async {
      final service = ArticleSummaryService(
        client: MockClient((request) async {
          expect(request.url.host, 'r.jina.ai');
          expect(
            request.url.toString(),
            'https://r.jina.ai/https://example.com/article?lang=en',
          );
          expect(request.url.queryParameters, {'lang': 'en'});
          expect(request.headers['Accept'], 'text/plain');
          return readerResponse(sampleContent);
        }),
      );
      addTearDown(service.close);
      final article = Article.fromJson({
        ...articleJson(),
        'url': 'https://example.com/article?lang=en#section',
      });
      final summary = await service.summarize(article);
      expect(summary.sentences.length, inInclusiveRange(2, 4));
      expect(summary.sentences.join(' '), contains('Flutter applications'));
      expect(summary.sentences.join(' '), isNot(contains('Cookies')));
      expect(summary.source, article.browserUrl);
      expect(
        summary.sentences.join(' ').split(RegExp(r'\s+')).length,
        lessThanOrEqualTo(140),
      );
      for (final sentence in summary.sentences) {
        expect(sampleContent, contains(sentence));
      }
    },
  );
  test(
    'Concurrent loads and subsequent visits reuse a cached summary',
    () async {
      var requests = 0;
      final service = ArticleSummaryService(
        client: MockClient((_) async {
          requests++;
          return readerResponse(sampleContent);
        }),
      );
      addTearDown(service.close);
      final summaries = await Future.wait([
        service.summarize(sampleArticle()),
        service.summarize(sampleArticle()),
      ]);
      expect(requests, 1);
      expect(summaries[0], same(summaries[1]));
      await service.summarize(sampleArticle());
      expect(requests, 1);
      await service.summarize(sampleArticle(), refresh: true);
      expect(requests, 2);
    },
  );
  test(
    'Self posts use the actual API text and decode HTML without a reader call',
    () async {
      final service = ArticleSummaryService(
        client: MockClient(
          (_) async => throw StateError('Unexpected reader request'),
        ),
      );
      addTearDown(service.close);
      final article = Article.fromJson({
        ...articleJson(),
        'url': null,
        'text': '<p>Aplicația afișează știrile recente &amp; permite salvarea lor în lista de favorite.</p><script>Invented hidden content must never appear in the article summary.</script><p>Știrile salvate pot fi exportate în calendarul telefonului pentru a fi citite mai târziu.</p>',
      });
      final summary = await service.summarize(article);
      expect(summary.sentences.join(' '), contains('recente & permite'));
      expect(summary.sentences.join(' '), isNot(contains('hidden')));
    },
  );
  test(
    'Missing article text is not replaced with a summary of HN comments',
    () async {
      final service = ArticleSummaryService(
        client: MockClient((_) async => throw StateError('Unexpected request')),
      );
      addTearDown(service.close);
      await expectLater(
        service.summarize(Article.fromJson({...articleJson(), 'url': null})),
        throwsA(isA<AppException>()),
      );
    },
  );
  for (final status in [401, 403, 404, 429, 503]) {
    test(
      'Reader HTTP $status leaves a useful error and supports retry',
      () async {
        var calls = 0;
        final service = ArticleSummaryService(
          client: MockClient((_) async {
            calls++;
            return calls == 1
                ? utf8Response('Blocked', status)
                : readerResponse(sampleContent);
          }),
        );
        addTearDown(service.close);
        await expectLater(
          service.summarize(sampleArticle()),
          throwsA(isA<AppException>()),
        );
        expect(
          (await service.summarize(sampleArticle())).sentences,
          isNotEmpty,
        );
        expect(calls, 2);
      },
    );
  }
  for (final body in [
    'not json',
    '{"data": {}}',
    '{"code": 403, "data": {"content": "Blocked"}}',
  ]) {
    test(
      'Malformed or failed reader response is not displayed as a summary: $body',
      () async {
        final service = ArticleSummaryService(
          client: MockClient((_) async => utf8Response(body, 200)),
        );
        addTearDown(service.close);
        await expectLater(
          service.summarize(sampleArticle()),
          throwsA(isA<AppException>()),
        );
      },
    );
  }
  test(
    'Access challenge and empty pages are not presented as article summaries',
    () async {
      for (final content in [
        '',
        'Verify you are human to access this website. Please enable JavaScript and cookies to continue loading this page.',
      ]) {
        final service = ArticleSummaryService(
          client: MockClient((_) async => readerResponse(content)),
        );
        await expectLater(
          service.summarize(sampleArticle()),
          throwsA(isA<AppException>()),
        );
        service.close();
      }
    },
  );
  test(
    'Timeouts do not keep the details screen loading indefinitely',
    () async {
      final completer = Completer<http.Response>();
      final service = ArticleSummaryService(
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) => completer.future),
      );
      addTearDown(service.close);
      await expectLater(
        service.summarize(sampleArticle()),
        throwsA(isA<AppException>()),
      );
      completer.complete(readerResponse(sampleContent));
    },
  );
  test('Markdown formatting is removed and HTML entities are decoded', () {
    expect(
      plainArticleText(
        '## Heading\n\nA **bold** [article](https://example.com) &amp; useful content.\n\n![Image](https://example.com/image.jpg)\n```dart\nsecret code\n```',
      ),
      contains('A bold article & useful content.'),
    );
    expect(plainArticleText('Text\n```code```'), isNot(contains('code')));
  });
}
