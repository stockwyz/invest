import '../network/api_client.dart';
import 'cache_helper.dart';

class TagRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<List<String>>> list() {
    return fetchWithCache<List<String>>(
      cacheKey: 'tags_list',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/tags',
        parse: (json) => {'items': json},
      ),
      parse: (json) => (json['items'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}
