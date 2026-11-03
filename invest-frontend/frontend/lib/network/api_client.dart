import 'package:dio/dio.dart';

import 'api_exception.dart';

/// 全局唯一的 Dio 实例。baseUrl 按运行环境区分：
/// - Android 模拟器访问宿主机后端要用 10.0.2.2，真机/iOS 模拟器改成局域网 IP 或线上域名。
/// - 用 --dart-define=API_BASE_URL=... 在打包时切换，不用改代码。
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.2.29:8080',
  );

  late final Dio _dio;

  /// 统一发请求并解包 {code, message, data} 响应壳。
  /// code != 0 时抛出 ApiException(isNetworkError:false) —— 这是后端明确的业务错误，
  /// 调用方不应该用本地缓存兜底，而是直接把 message 展示给用户。
  /// 网络层面失败（超时/断网/服务器挂了）抛出 ApiException(isNetworkError:true)，
  /// 交给 Repository 决定要不要退回本地缓存。
  Future<T> request<T>(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
    required T Function(dynamic json) parse,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        queryParameters: query,
        data: data,
        options: Options(method: method),
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(50000, '服务器无响应', isNetworkError: true);
      }
      final code = body['code'] as int? ?? -1;
      if (code != 0) {
        throw ApiException(code, body['message'] as String? ?? '请求失败');
      }
      return parse(body['data']);
    } on DioException catch (e) {
      final isTimeoutOrNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response == null;
      throw ApiException(
        e.response?.statusCode ?? -1,
        isTimeoutOrNetwork ? '网络不可用' : '服务器错误',
        isNetworkError: isTimeoutOrNetwork,
      );
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query, required T Function(dynamic) parse}) {
    return request('GET', path, query: query, parse: parse);
  }

  Future<T> post<T>(String path, {Object? data, required T Function(dynamic) parse}) {
    return request('POST', path, data: data, parse: parse);
  }

  Future<T> put<T>(String path, {Object? data, required T Function(dynamic) parse}) {
    return request('PUT', path, data: data, parse: parse);
  }

  Future<T> delete<T>(String path, {required T Function(dynamic) parse}) {
    return request('DELETE', path, parse: parse);
  }
}
