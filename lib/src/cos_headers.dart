class CosHeaders {
  // common header begin
  /// 对象的 CRC64 值，详情请参见 CRC64 校验文档。	integer
  static const String xCosHashCrc64ecma = 'x-cos-hash-crc64ecma';

  /// 每次请求发送时，服务端将会自动为请求生成一个 ID。	string
  static const String xCosRequestId = 'x-cos-request-id';

  /// 每次请求出错时，服务端将会自动为这个错误生成一个 ID。仅当请求出错时才会在响应中包含此头部。	string
  static const String xCosTraceId = 'x-cos-trace-id';

  /// 使用临时安全凭证时需要传入的安全令牌字段，当使用临时密钥并通过 Authorization 携带鉴权信息时，此头部为必选项。
  static const String xCosSecurityToken = 'x-cos-security-token';

  // common header end
  /// 对象的版本 ID
  static const String xCosVersionId = 'x-cos-version-id';

  /// 对象存储类型
  static const String xCosStorageClass = 'x-cos-storage-class';

  /// 对象的标签集合，最多可设置10个标签（例如，Key1=Value1&Key2=Value2）。 标签集合中的 Key 和 Value 必须先进行 URL 编码。
  static const String xCosTagging = 'x-cos-tagging';

  /// 包括用户自定义元数据头部后缀和用户自定义元数据信息，将作为对象元数据保存，大小限制为2KB. 注意：用户自定义元数据信息支持下划线（_），但用户自定义元数据头部后缀不支持下划线，仅支持减号（-）
  static String xCosMeta(value) => 'x-cos-meta-$value';

  /// 针对本次上传进行流量控制的限速值，必须为数字，单位默认为 bit/s。限速值设置范围为819200 - 838860800，即100KB/s - 100MB/s，如果超出该范围将返回400错误
  static const String xCosTrafficLimit = 'x-cos-traffic-limit';

  /// 存储桶所在地域
  static const String xCosBucketRegion = 'x-cos-bucket-region';

  /// 存储桶 AZ 类型，当存储桶为多 AZ 存储桶时返回此头部，值固定为 MAZ。
  static const String xCosBucketAzType = 'x-cos-bucket-az-type';
}
