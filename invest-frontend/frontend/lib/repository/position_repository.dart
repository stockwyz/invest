import '../models/position.dart';
import '../models/trade.dart';
import '../network/api_client.dart';
import 'cache_helper.dart';

class PositionRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<PositionSummary>> summary({InstrumentType? type}) {
    final typeKey = type == null ? 'ALL' : instrumentTypeToApi(type);
    return fetchWithCache<PositionSummary>(
      cacheKey: 'positions_$typeKey',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/positions',
        query: {if (type != null) 'type': instrumentTypeToApi(type)},
        parse: (json) => json as Map<String, dynamic>,
      ),
      parse: PositionSummary.fromJson,
    );
  }
}
