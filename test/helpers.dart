import 'dart:convert';

import 'package:appstiri/controllers/news_controller.dart';
import 'package:appstiri/models/article.dart';
import 'package:appstiri/services/news_api.dart';
import 'package:appstiri/services/article_summary_service.dart';
import 'package:appstiri/services/calendar/calendar_service.dart';
import 'package:appstiri/services/calendar/calendar_stub.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> articleJson({String id = '42'}) => {
  'objectID': id,
  'title': 'O știre de test',
  'author': 'ana',
  'created_at': '2026-11-20T10:30:00Z',
  'points': 120,
  'num_comments': 15,
  'url': 'https://example.com/articol',
};
Article sampleArticle() => Article.fromJson(articleJson());
NewsController createController({
  http.Client? client,
  ArticleSummaryService? summaries,
}) => NewsController(
  summaries:
      summaries ??
      ArticleSummaryService(
        client: MockClient(
          (_) async => utf8Response(
            jsonEncode({
              'code': 200,
              'data': {
                'content': 'Flutter permite dezvoltarea aplicațiilor pentru mai multe platforme folosind aceeași bază de cod. Aplicația de știri afișează articolele recente și permite salvarea favoritelor în calendarul telefonului. Testele automate verifică salvarea datelor și comportamentul interfeței pe ecrane de dimensiuni diferite.',
              },
            }),
            200,
          ),
        ),
      ),
  api: NewsApi(
    client:
        client ??
        MockClient(
          (request) async => utf8Response(
            jsonEncode({
              'hits': [articleJson()],
            }),
            200,
          ),
        ),
  ),
);

class FakeCalendar extends UnsupportedCalendarService {
  List<Article>? exported;
  DateTime? day;
  @override
  bool get isAvailable => true;
  @override
  Future<CalendarExportResult> export(
    List<Article> articles,
    DateTime date, {
    String? calendarId,
  }) async {
    exported = articles;
    day = date;
    return const CalendarExportResult(downloaded: true);
  }
}

http.Response utf8Response(String body, int statusCode) => http.Response.bytes(
  utf8.encode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
