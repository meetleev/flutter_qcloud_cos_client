import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'cos_client.dart';
import 'logger.dart';

List<String> handleHeaderOrParams(Map<String, String?> params) {
  params = params.map((key, value) => MapEntry(
      Uri.encodeComponent(key.toLowerCase()),
      Uri.encodeComponent(value ?? '')));
  var keys = params.keys.toList()..sort();
  var values = keys.map((e) => '$e=${params[e]}').toList().join('&');
  return [keys.join(';'), values];
}

Map<String, String> filterHeaders(Map<String, dynamic> headers) {
  // 可以签入签名的headers
  final List<String> validHeaders = [
    "cache-control",
    "content-disposition",
    "content-encoding",
    "content-type",
    "content-md5",
    "content-length",
    "expect",
    "expires",
    "host",
    "if-match",
    "if-modified-since",
    "if-none-match",
    "if-unmodified-since",
    "origin",
    "range",
    "response-cache-control",
    "response-content-disposition",
    "response-content-encoding",
    "response-content-language",
    "response-content-type",
    "response-expires",
    "transfer-encoding",
    "versionid",
  ];
  Map<String, String> signHeaders = {};
  for (String key in headers.keys) {
    if ('content-length' == key && '0' == headers[key]) continue;
    if (validHeaders.contains(key) || key.toLowerCase().startsWith('x-cos-')) {
      signHeaders[key] = headers[key];
    }
  }
  Log.d('filterHeaders headers:[$headers]');
  Log.d('filterHeaders signHeaders:[$signHeaders}]');
  return signHeaders;
}

class CosS3Auth {
  static String getAuth(CosConfig cosConfig,
      {required String method,
      required Map<String, String?> headers,
      String? key,
      int expire = 10000,
      Map<String, String?>? params}) {
    var startSignTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String qKeyTime = '${startSignTime - 60};${startSignTime + expire}';
    String secretId = cosConfig.secretId;
    String secretKey = cosConfig.secretKey;
    var signKey = hmacSha1(secretKey, qKeyTime);
    key ??= '';
    var sHttpArr = handleHeaderOrParams(params ?? {});
    var urlParamList = sHttpArr[0];
    var httpParams = sHttpArr[1];
    sHttpArr = handleHeaderOrParams(filterHeaders(headers));
    var headList = sHttpArr[0];
    var httpHeaders = sHttpArr[1];
    String pathName = !key.startsWith('/') ? '/$key' : key;
    String formatString = [
      method.toLowerCase(),
      pathName,
      httpParams,
      httpHeaders,
      ''
    ].join('\n');
    Log.d('Auth formatString---$formatString');
    String signHttpString =
        hex.encode(sha1.convert(formatString.codeUnits).bytes);
    String stringToSign = ['sha1', qKeyTime, signHttpString, ''].join('\n');
    Log.d('Auth stringToSign----$stringToSign');
    String signature = hmacSha1(signKey, stringToSign);
    String authorization =
        'q-sign-algorithm=sha1&q-ak=$secretId&q-sign-time=$qKeyTime'
        '&q-key-time=$qKeyTime&q-header-list=$headList'
        '&q-url-param-list=$urlParamList&q-signature=$signature';
    Log.d('Auth authorization---$authorization');
    return authorization;
  }
}

String hmacSha1(String key, String msg) {
  var hmac = Hmac(sha1, key.codeUnits);
  return hex.encode((hmac.convert(msg.codeUnits).bytes));
}
