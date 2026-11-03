import '../models/account.dart';
import '../network/api_client.dart';
import 'cache_helper.dart';

class AccountRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<List<AccountBrief>>> list() {
    return fetchWithCache<List<AccountBrief>>(
      cacheKey: 'accounts_list',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/accounts',
        parse: (json) => {'items': json},
      ),
      parse: (json) => (json['items'] as List<dynamic>)
          .map((e) => AccountBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
