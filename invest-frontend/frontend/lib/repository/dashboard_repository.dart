import '../models/dashboard_summary.dart';
import '../network/api_client.dart';
import 'cache_helper.dart';

class DashboardRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<DashboardSummary>> getSummary(String period) {
    return fetchWithCache<DashboardSummary>(
      cacheKey: 'dashboard_summary_$period',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/dashboard/summary',
        query: {'period': period},
        parse: (json) => json as Map<String, dynamic>,
      ),
      parse: DashboardSummary.fromJson,
    );
  }
}
