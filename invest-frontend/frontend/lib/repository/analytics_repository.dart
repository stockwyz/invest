import '../models/analytics_summary.dart';
import '../network/api_client.dart';
import 'cache_helper.dart';

class AnalyticsRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<AnalyticsSummary>> getSummary(String range) {
    return fetchWithCache<AnalyticsSummary>(
      cacheKey: 'analytics_summary_$range',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/analytics/summary',
        query: {'range': range},
        parse: (json) => json as Map<String, dynamic>,
      ),
      parse: AnalyticsSummary.fromJson,
    );
  }
}
