import '../local/api_cache_db.dart';
import '../network/api_exception.dart';

/// Repository 层统一的返回结果：区分这份数据是刚从后端拿到的，还是网络不通时读的本地缓存。
/// 页面据此显示一个小角标，比如"离线缓存 · 14:32"，而不是悄悄地把过期数据当最新数据展示。
class CachedResult<T> {
  final T data;
  final bool fromCache;
  final DateTime? cachedAt;

  CachedResult(this.data, {this.fromCache = false, this.cachedAt});
}

/// 所有"GET 接口 + 本地缓存兜底"的 Repository 方法都走这一个函数，逻辑只写一遍：
///   1. 请求后端，成功就把原始 JSON 写入本地缓存，返回"最新"结果；
///   2. 请求失败且是网络层面的问题（断网/超时/5xx），退回读本地缓存；
///   3. 后端明确返回的业务错误（如参数错误）不吞掉，直接抛出去，因为缓存掩盖不了这种错误。
Future<CachedResult<T>> fetchWithCache<T>({
  required String cacheKey,
  required Future<Map<String, dynamic>> Function() fetchRawJson,
  required T Function(Map<String, dynamic> json) parse,
}) async {
  try {
    final raw = await fetchRawJson();
    await ApiCacheDb.instance.put(cacheKey, raw);
    return CachedResult<T>(parse(raw), fromCache: false);
  } on ApiException catch (e) {
    if (!e.isNetworkError) {
      rethrow;
    }
    final cached = await ApiCacheDb.instance.get(cacheKey);
    if (cached != null) {
      return CachedResult<T>(parse(cached.$1), fromCache: true, cachedAt: cached.$2);
    }
    rethrow;
  }
}
