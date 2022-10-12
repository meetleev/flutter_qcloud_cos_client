class CosServiceError extends Error {
  final String method;
  final int? statusCode;
  final Map<String, dynamic> message;

  CosServiceError(
      {required this.method, this.statusCode, required this.message});

  String get code => message['Code'] ?? 'unknown';

  String get errorMsg => message['Message'] ?? 'unknown';

  String get resource => message['Resource'] ?? 'unknown';

  String get requestId => message['RequestId'] ?? 'unknown';

  String get traceId => message['TraceId'] ?? 'unknown';

  @override
  String toString() =>
      '{ statusCode:$statusCode, method:$method, code:$code, errorMsg:$errorMsg, resource:$resource, requestId:$requestId, traceId:$traceId }';
}
