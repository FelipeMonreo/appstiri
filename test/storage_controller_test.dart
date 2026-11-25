import 'dart:convert';

import 'package:appstiri/controllers/news_controller.dart';
import 'package:appstiri/models/article.dart';
import 'package:appstiri/services/app_exception.dart';
import 'package:appstiri/services/news_api.dart';
import 'package:appstiri/services/news_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers.dart';

class FailingStorage extends NewsStorage {
  @override
  Future<void> write(String key, Iterable<Article> articles) async {
    throw const AppException('Storage unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  test('Favorites survive recreation and removal is persisted', () async {
    final first = createController();
    await first.initialize();
    await first.toggleFavorite(first.articles.single);
    first.dispose();
    final second = createController();
    await second.initialize();
    expect(second.favorites.single.id, '42');
    await second.toggleFavorite(second.favorites.single);
    second.dispose();
    final third = createController();
    addTearDown(third.dispose);
    await third.initialize();
    expect(third.favorites, isEmpty);
  });
  test('Corrupt saved items do not hide valid favorites', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          NewsStorage.favoritesKey: [
            'invalid',
            jsonEncode(articleJson()),
            '{"id":"bad"}',
          ],
        });
    final result = await NewsStorage().read(NewsStorage.favoritesKey);
    expect(result.articles.single.id, '42');
    expect(result.hasInvalidItems, isTrue);
  });
  test('Offline startup keeps cached news and favorites available', () async {
    final storage = NewsStorage();
    await storage.write(NewsStorage.cacheKey, [sampleArticle()]);
    await storage.write(NewsStorage.favoritesKey, [sampleArticle()]);
    final controller = NewsController(
      api: NewsApi(
        client: MockClient((_) async => throw http.ClientException('Offline')),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.articles.single.id, '42');
    expect(controller.favorites.single.id, '42');
    expect(controller.error, isNotNull);
  });
  test('Failed writes do not falsely mark a story as saved', () async {
    final controller = NewsController(
      storage: FailingStorage(),
      api: NewsApi(
        client: MockClient(
          (_) async => utf8Response(
            jsonEncode({
              'hits': [articleJson()],
            }),
            200,
          ),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await expectLater(
      controller.toggleFavorite(sampleArticle()),
      throwsA(isA<AppException>()),
    );
    expect(controller.favorites, isEmpty);
    expect(controller.savingFavorite, isFalse);
  });
  test(
    'Rapid favorite presses do not create duplicates or race writes',
    () async {
      final controller = createController();
      addTearDown(controller.dispose);
      await controller.initialize();
      await Future.wait([
        controller.toggleFavorite(sampleArticle()),
        controller.toggleFavorite(sampleArticle()),
      ]);
      expect(controller.favorites.length, 1);
    },
  );
}
