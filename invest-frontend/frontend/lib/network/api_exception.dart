/// 统一的接口异常：区分"网络/服务器不可达"（该走本地缓存兜底）和
/// "后端明确返回的业务错误"（不该用缓存掩盖，要把错误信息展示给用户）。
class ApiException implements Exception {
  final int code;
  final String message;
  final bool isNetworkError;

  ApiException(this.code, this.message, {this.isNetworkError = false});

  @override
  String toString() => 'ApiException($code, $message)';
}
