import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/article_summary.dart';
import 'app_exception.dart';

/// Reads the original public article, then selects its most relevant sentences.
/// No generative model, credentials, or app server are required.
class ArticleSummaryService {
  ArticleSummaryService({
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final _cache = <String, ArticleSummary>{};
  final _pending = <String, Future<ArticleSummary>>{};

  Future<ArticleSummary> summarize(Article article, {bool refresh = false}) {
    final key = '${article.id}|${article.browserUrl}';
    final cached = _cache[key];
    if (!refresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) <
            const Duration(minutes: 30)) {
      return Future.value(cached);
    }
    return _pending.putIfAbsent(key, () async {
      try {
        final summary = await _load(article);
        if (_cache.length >= 50) _cache.remove(_cache.keys.first);
        _cache[key] = summary;
        return summary;
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<ArticleSummary> _load(Article article) async {
    String content;
    final url = Uri.tryParse(article.url ?? '');
    final hasArticleUrl =
        url != null &&
        (url.scheme == 'https' || url.scheme == 'http') &&
        url.host.isNotEmpty;
    if (!hasArticleUrl) {
      if (article.text?.trim().isNotEmpty != true) {
        throw const AppException(
          'Această știre nu are un text disponibil pentru rezumat. Poți deschide pagina originală mai jos.',
        );
      }
      content = plainArticleText(article.text!);
    } else {
      content = await _read(url.removeFragment());
    }
    final sentences = extractSummary(content, title: article.title);
    if (sentences.isEmpty) {
      throw const AppException(
        'Pagina nu conține suficient text accesibil pentru un rezumat. Citește articolul complet folosind butonul de mai jos.',
      );
    }
    return ArticleSummary(
      sentences: List.unmodifiable(sentences),
      source: article.browserUrl,
      createdAt: DateTime.now(),
    );
  }

  Future<String> _read(Uri url) async {
    try {
      // Use the documented URL-prefix endpoint and its default text output.
      // Presets can change the output independently of JSON content negotiation.
      final response = await _client
          .get(
            Uri.parse('https://r.jina.ai/$url'),
            headers: {'Accept': 'text/plain'},
          )
          .timeout(timeout);
      if (response.statusCode == 429) {
        throw const AppException(
          'Serviciul de citire a primit prea multe cereri. Așteaptă puțin și reîncearcă.',
        );
      }
      if (response.statusCode != 200) {
        throw const AppException(
          'Articolul nu poate fi citit automat acum. Site-ul poate necesita autentificare sau poate bloca accesul.',
        );
      }
      if (response.bodyBytes.length > 2000000) {
        throw const AppException(
          'Pagina este prea mare pentru rezumat. Deschide articolul complet.',
        );
      }
      return plainArticleText(
        decodeReaderContent(
          utf8.decode(response.bodyBytes),
          contentType: response.headers['content-type'] ?? '',
        ),
      );
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Citirea articolului durează prea mult. Reîncearcă sau deschide sursa originală.',
      );
    } on FormatException {
      throw const AppException(
        'Serviciul de citire a trimis un răspuns neașteptat. Reîncearcă încărcarea articolului.',
      );
    } catch (_) {
      throw const AppException(
        'Rezumatul nu poate fi încărcat. Verifică internetul și reîncearcă.',
      );
    }
  }

  void close() => _client.close();
}

/// Reader supports default Markdown, frontmatter, wrapped JSON and page DTOs.
String decodeReaderContent(String raw, {String contentType = ''}) {
  var body = raw.replaceFirst(RegExp('^\uFEFF'), '').trim();
  final type = contentType.toLowerCase();
  if (type.contains('application/json') || body.startsWith('{')) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid reader response.');
    }
    if (decoded['code'] is num && decoded['code'] != 200) {
      throw const AppException(
        'Site-ul articolului nu a putut fi accesat de serviciul de citire.',
      );
    }
    final page = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;
    _checkReaderWarning(page['warning']?.toString() ?? '');
    final content = page['content'] ?? page['text'] ?? page['html'];
    if (content is! String) {
      throw const FormatException('Missing article body.');
    }
    body = content.trim();
  } else if (type.contains('text/html') ||
      RegExp(r'^\s*(<!doctype|<html)', caseSensitive: false).hasMatch(body)) {
    // Never summarize an API landing page or a proxy error as the article.
    throw const FormatException('Reader returned an HTML page.');
  }
  body = body.replaceAll('\r\n', '\n');
  if (body.startsWith('---\n')) {
    final end = body.indexOf('\n---', 4);
    if (end < 0) throw const FormatException('Incomplete frontmatter.');
    _checkReaderWarning(_metadataWarnings(body.substring(4, end)));
    body = body.substring(end + 4).trim();
  } else {
    final marker = RegExp(
      r'^Markdown Content:\s*$',
      multiLine: true,
    ).firstMatch(body);
    if (marker != null) {
      _checkReaderWarning(_metadataWarnings(body.substring(0, marker.start)));
      body = body.substring(marker.end).trim();
    }
  }
  return body;
}

String _metadataWarnings(String metadata) => RegExp(
  r'^warning:\s*(.*)$',
  caseSensitive: false,
  multiLine: true,
).allMatches(metadata).map((match) => match[1]!).join('\n');

void _checkReaderWarning(String warning) {
  if (RegExp(
    r'(target url returned error|access denied|captcha|authentication required|sign in required)',
    caseSensitive: false,
  ).hasMatch(warning)) {
    throw const AppException(
      'Site-ul articolului blochează citirea automată sau necesită autentificare.',
    );
  }
}

String plainArticleText(String content) {
  var text = content
      .replaceAll(RegExp(r'```[\s\S]*?```'), '\n')
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^\n]*?\)'), '')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^\n]*?\)'),
        (match) => match[1]!,
      )
      .replaceAll(RegExp(r'^\s*\[[^\]]+\]:.*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[#>]+\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^[ \t]*[-*+]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'[*`_]'), '');
  final document = html.parseFragment(text);
  for (final element in document.querySelectorAll(
    'script,style,nav,footer,noscript',
  )) {
    element.remove();
  }
  for (final element in document.querySelectorAll('p,div,br,li,h1,h2,h3')) {
    element.nodes.add(dom.Text('\n'));
  }
  text = document.text ?? '';
  return text
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'[ \t\u00a0]+'), ' ')
      .trim();
}

final _wordPattern = RegExp(r'[a-zA-ZÀ-ž0-9]+', unicode: true);
final _stopWords =
    ('a an and are as at be been but by can could did do does for from had has have how i if in into is it its may more most not of on or our out over s so some than that the their them there these they this those to too up us was we were what when where which who will with would you your '
            'al ale am ar au ca care ce cel cele cu cum că cât de din după e ei el este eu fi fie fost iar la le li lor lui mai mult ne ni nici noi nu o ori pe pentru peste prin poate prea primul prima să se si sunt și un una unei unui unor v ați vă')
        .split(' ')
        .toSet();

Set<String> _terms(String sentence) => _wordPattern
    .allMatches(sentence.toLowerCase())
    .map((match) => match[0]!)
    .where((word) => word.length > 2 && !_stopWords.contains(word))
    .toSet();

/// An extractive summary: full source sentences, selected and kept in source order.
List<String> extractSummary(String text, {required String title}) {
  final paragraphs = text
      .split(RegExp(r'\n+'))
      .map((line) => line.trim())
      .where((line) {
        if (line.length < 35 || line.toLowerCase() == title.toLowerCase()) {
          return false;
        }
        if (RegExp(
          r'^(cookie(s)?\b|accept all\b|privacy policy\b|all rights reserved\b|subscribe\b|sign in\b|log in\b|skip to\b|share this\b|related (articles|stories)\b|verifică dacă|politica de confidențialitate)',
          caseSensitive: false,
        ).hasMatch(line)) {
          return false;
        }
        if (RegExp(
          r'^(just a moment|access denied|verify you are human|enable javascript and cookies|checking your browser|please enable javascript)',
          caseSensitive: false,
        ).hasMatch(line)) {
          return false;
        }
        return true;
      })
      .toList();
  final candidates = <String>[];
  final seen = <String>{};
  for (final paragraph in paragraphs) {
    for (final sentence in paragraph.split(
      RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ž0-9“"(])', unicode: true),
    )) {
      final normalized = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
      final words = _wordPattern.allMatches(normalized).length;
      if (words < 7 ||
          words > 85 ||
          normalized.length > 700 ||
          !seen.add(normalized.toLowerCase())) {
        continue;
      }
      candidates.add(normalized);
      if (candidates.length >= 400) break;
    }
    if (candidates.length >= 400) break;
  }
  if (candidates.isEmpty || candidates.join(' ').length < 80) return [];
  final terms = candidates.map(_terms).toList();
  final frequency = <String, int>{};
  for (final sentence in terms) {
    for (final word in sentence) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }
  }
  final titleTerms = _terms(title);
  double score(int index) {
    final words = terms[index];
    final relevance = words.fold<double>(
      0,
      (sum, word) => sum + math.log(1 + frequency[word]!),
    );
    final titleOverlap = words.intersection(titleTerms).length * 2.0;
    return (relevance + titleOverlap) / math.sqrt(math.max(1, words.length)) +
        1 / (index + 1);
  }

  final ranked = List.generate(candidates.length, (i) => i)
    ..sort((a, b) => score(b).compareTo(score(a)));
  final selected = <int>[0];
  var words = _wordPattern.allMatches(candidates.first).length;
  for (final index in ranked) {
    if (selected.contains(index)) continue;
    final count = _wordPattern.allMatches(candidates[index]).length;
    if (words + count > 140) continue;
    final nearDuplicate = selected.any((other) {
      final union = terms[other].union(terms[index]).length;
      return union > 0 &&
          terms[other].intersection(terms[index]).length / union > 0.75;
    });
    if (nearDuplicate) continue;
    selected.add(index);
    words += count;
    if (selected.length >= 4) break;
  }
  selected.sort();
  return selected.map((index) => candidates[index]).toList();
}
