import '../models/trade.dart';
import '../models/trade_save_request.dart';
import '../network/api_client.dart';
import 'cache_helper.dart';

class TradeRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<TradePage>> list({InstrumentType? type, int page = 0, int size = 20}) {
    final typeKey = type == null ? 'ALL' : instrumentTypeToApi(type);
    return fetchWithCache<TradePage>(
      cacheKey: 'trades_${typeKey}_p${page}_s$size',
      fetchRawJson: () => _api.get<Map<String, dynamic>>(
        '/api/trades',
        query: {
          if (type != null) 'type': instrumentTypeToApi(type),
          'page': page,
          'size': size,
        },
        parse: (json) => json as Map<String, dynamic>,
      ),
      parse: TradePage.fromJson,
    );
  }

  /// 新增/编辑/删除是写操作，不做本地缓存兜底——离线时应该明确提示用户"当前无法保存"，
  /// 而不是假装保存成功。真要支持离线记账，需要额外做一个本地待同步队列，这里先不做。
  Future<Trade> create(TradeSaveRequest req) {
    return _api.post<Trade>(
      '/api/trades',
      data: req.toJson(),
      parse: (json) => Trade.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Trade> update(int id, TradeSaveRequest req) {
    return _api.put<Trade>(
      '/api/trades/$id',
      data: req.toJson(),
      parse: (json) => Trade.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) {
    return _api.delete<void>('/api/trades/$id', parse: (_) {});
  }
}
