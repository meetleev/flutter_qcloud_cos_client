import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:qcloud_cos_client/src/types.dart';

typedef Headers = Map<String, dynamic>;

class Owner {
  /// 存储桶持有者的完整 ID，格式为 qcs::cam::uin/[OwnerUin]:uin/[OwnerUin]，如 qcs::cam::uin/100000000001:uin/100000000001
  final String id;

  /// 存储桶持有者的名字
  final String displayName;

  Owner({required this.id, required this.displayName});

  @override
  String toString() => '{ id:$id, displayName:$displayName }';
}

class CosResponse<T> {
  /// 请求返回的 HTTP 状态码
  final int? statusCode;

  /// 请求返回的 header 字段
  final Headers? headers;

  /// 请求的唯一标识
  final String? requestId;

  final T? data;

  CosResponse({this.statusCode, this.headers, this.requestId, this.data});

  @override
  String toString() =>
      '{ statusCode:$statusCode, headers:$headers, requestId:$requestId }, data:$data}';
}

class Bucket {
  /// 存储桶的名称，格式为<bucketname-appid>，例如examplebucket-1250000000
  final String name;

  /// 存储桶所在地域
  final String region;

  /// 存储桶创建时间
  final String creationDate;

  final String? bucketType;

  Bucket(
      {required this.name,
      required this.region,
      required this.creationDate,
      this.bucketType});

  @override
  String toString() =>
      '{ name:$name, region:$region, creationDate:$creationDate }';
}

class GetServiceResult {
  final List<Bucket> buckets;

  /// 所有者的信息
  final Owner owner;

  GetServiceResult({required this.buckets, required this.owner});

  @override
  String toString() => '{ buckets:$buckets, owner:$owner }';
}

class PutObjectResult {
  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String? eTag;

  /// 创建的存储桶访问地址，不带 https:// 前缀，例如 examplebucket-1250000000.cos.ap-guangzhou.myqcloud.com/images/1.jpg
  final String location;

  /// 对象的版本 ID, 当未启用版本控制时，该节点的值为空字符串；当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null；当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
  final String? versionId;

  PutObjectResult({required this.location, this.eTag, this.versionId});

  @override
  String toString() =>
      '{ eTag:$eTag, location:$location, versionId:$versionId }';
}

class GetObjectResult {
  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String? eTag;

  /// 对象的版本 ID, 当未启用版本控制时，该节点的值为空字符串；当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null；当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
  final String? versionId;

  /// object Data
  final Uint8List objectData;

  final String? mimeType;

  GetObjectResult(
      {this.eTag, this.versionId, required this.objectData, this.mimeType});

  @override
  String toString() =>
      '{ objectData:[Uint8List ${objectData.length}], versionId:$versionId, mimeType:$mimeType }';
}

class GetObjectFileResult {
  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String? eTag;

  /// 对象的版本 ID, 当未启用版本控制时，该节点的值为空字符串；当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null；当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
  final String? versionId;

  /// object File
  final File objectFile;

  final String? mimeType;

  GetObjectFileResult(
      {this.eTag, this.versionId, required this.objectFile, this.mimeType});

  @override
  String toString() =>
      '{ objectFile:${objectFile.path}, versionId:$versionId, mimeType:$mimeType }';
}

class DeleteObjectResult {
  @override
  String toString() => '{}';
}

class HeadObjectResult {
  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String? eTag;

  /// 对象的版本 ID, 当未启用版本控制时，该节点的值为空字符串；当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null；当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
  final String? versionId;

  HeadObjectResult({required this.eTag, this.versionId});

  @override
  String toString() => '{ eTag:$eTag, versionId:$versionId}';
}

class MultipleDeletedObject {
  /// 删除失败的对象的对象键
  final String key;

  /// 删除失败的版本 ID，仅当请求中指定了要删除对象的版本 ID 时才返回该元素
  final String? versionId;

  /// 仅当对该对象的删除创建了一个删除标记，或删除的是该对象的一个删除标记时才返回该元素，布尔值，固定为 true
  final bool? deleteMarker;

  /// 仅当对该对象的删除创建了一个删除标记，或删除的是该对象的一个删除标记时才返回该元素，值为创建或删除的删除标记的版本 ID
  final String? deleteMarkerVersionId;

  MultipleDeletedObject(
      {required this.key,
      this.versionId,
      this.deleteMarker,
      this.deleteMarkerVersionId});

  @override
  String toString() =>
      '{ key:$key, versionId:$versionId, deleteMarker:$deleteMarker, deleteMarkerVersionId:$deleteMarkerVersionId }';
}

class MultipleDeletedError {
  /// 删除失败的对象的对象键
  final String key;

  /// 删除失败的版本 ID，仅当请求中指定了要删除对象的版本 ID 时才返回该元素
  final String? versionId;

  /// 删除失败的错误码，用来定位唯一的错误条件和确定错误场景
  final String? code;

  /// 删除失败的具体错误信息
  final String? message;

  MultipleDeletedError(
      {required this.key, this.versionId, this.code, this.message});

  @override
  String toString() =>
      '{ key:$key, versionId:$versionId, code:$code, message:$message }';
}

/// 带版本信息的对象
class CosObjectVersion {
  /// 对象键
  final String key;

  /// 对象的版本 Id
  final String? versionId;

  /// 当前版本是否为该对象的最新版本
  final bool isLatest;

  /// 当前版本的最后修改时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
  final String lastModified;

  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如"8e0b617ca298a564c3331da28dcb50df"。此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String eTag;

  /// 对象大小，单位为 Byte
  final String size;

  /// 对象持有者信息
  final Owner owner;

  /// [CosStorageClassType] 对象存储类型
  final CosStorageClassType storageClass;

  /// 当对象存储类型为智能分层存储时，指示对象当前所处的存储层，枚举值：FREQUENT（标准层），INFREQUENT（低频层）。仅当 StorageClass 为 INTELLIGENT_TIERING（智能分层）时才会返回该节点
  final String? storageTier;

  CosObjectVersion({
    required this.key,
    this.versionId,
    required this.isLatest,
    required this.lastModified,
    required this.eTag,
    required this.size,
    required this.owner,
    required this.storageClass,
    this.storageTier,
  });

  @override
  String toString() =>
      '{ key:$key, versionId:$versionId, isLatest:$isLatest, lastModified:$lastModified, eTag:$eTag, size:$size,'
      ' storageClass:$storageClass, storageTier:$storageTier, owner:$owner }';
}

class CosObjectVersionParams {
  /// 对象键
  final String key;

  /// 对象的版本 Id
  final String? versionId;

  CosObjectVersionParams({
    required this.key,
    this.versionId,
  });

  @override
  String toString() => '{ key:$key, versionId:$versionId}';
}

/// deleteMultipleObject 接口返回值
class DeleteMultipleObjectResult {
  final List<MultipleDeletedObject>? deleted;
  final List<MultipleDeletedError>? errors;

  DeleteMultipleObjectResult({required this.deleted, this.errors});

  @override
  String toString() => '{ deleted:$deleted, errors:$errors }';
}

/// 存储桶/对象标签信息
class Tag {
  /// 标签的 Key，长度不超过128字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
  final String key;

  /// 标签的 Value，长度不超过256字节, 支持英文字母、数字、空格、加号、减号、下划线、等号、点号、冒号、斜线
  final String value;

  Tag({required this.key, required this.value});

  @override
  String toString() => '{ key:$key, value:$value }';
}

class GetObjectTaggingResult {
  /// 标签集合，最多支持10个标签
  final List<Tag> tags;

  GetObjectTaggingResult({required this.tags});

  @override
  String toString() => '{ tags:$tags }';
}

/// putObjectTagging 接口返回值
class PutObjectTaggingResult {
  @override
  String toString() => '{}';
}

/// deleteObjectTagging 接口返回值
class DeleteObjectTaggingResult {
  @override
  String toString() => '{}';
}

class CommonPrefixes {
  /// 前缀匹配，用来规定返回的文件前缀地址
  final String prefix;

  CommonPrefixes(this.prefix);

  @override
  String toString() => '{ prefix:$prefix }';
}

class CosObject {
  /// 对象键
  final String key;

  /// 当前版本的最后修改时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
  final String lastModified;

  /// 对象的实体标签（Entity Tag），是对象被创建时标识对象内容的信息标签，可用于检查对象的内容是否发生变化，例如“8e0b617ca298a564c3331da28dcb50df”，此头部并不一定返回对象的 MD5 值，而是根据对象上传和加密方式而有所不同
  final String eTag;

  /// 对象大小，单位为 Byte
  final String size;

  /// [CosStorageClassType] 对象存储类型
  final CosStorageClassType storageClass;

  /// 当对象存储类型为智能分层存储时，指示对象当前所处的存储层，枚举值：FREQUENT（标准层），INFREQUENT（低频层）。仅当 StorageClass 为 INTELLIGENT_TIERING（智能分层）时才会返回该节点
  final String? storageTier;

  /// 对象持有者信息
  final Owner owner;

  CosObject(
      {required this.key,
      required this.lastModified,
      required this.eTag,
      required this.size,
      required this.storageClass,
      this.storageTier,
      required this.owner});

  @override
  String toString() =>
      '{ key:$key, lastModified:$lastModified, eTag:$eTag, size:$size,'
      ' storageClass:$storageClass, storageTier:$storageTier, owner:$owner }';
}

/// getBucket/listObjects 接口返回值
class ListBucketObjectsResult {
  /// 存储桶的名称，格式为<BucketName-APPID>
  final String name;

  /// 对象条目
  final List<CosObject> contents;

  /// 从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点
  final List<CommonPrefixes>? commonPrefixes;

  /// 响应条目是否被截断，布尔值，例如 true 或 false，可用于判断是否还需要继续列出文件
  final bool isTruncated;

  /// 仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，该节点的值为当前响应条目中的最后一个对象键，当需要继续请求后续条目时，将该节点的值作为下一次请求的 marker 参数传入
  final String? nextMarker;

  ListBucketObjectsResult(
      {required this.name,
      required this.contents,
      required this.isTruncated,
      this.commonPrefixes,
      this.nextMarker});

  @override
  String toString() =>
      '{ name:$name, contents:$contents, isTruncated:$isTruncated, commonPrefixes:$commonPrefixes, nextMarker:$nextMarker }';
}

/// 对象删除标记条目
class DeleteMarker {
  /// 对象键
  final String key;

  /// 对象的版本 ID；当未启用版本控制时，该节点的值为空字符串；当启用版本控制时，启用版本控制之前的对象，其版本 ID 为 null；当暂停版本控制时，新上传的对象其版本 ID 为 null，且同一个对象最多只存在一个版本 ID 为 null 的对象版本
  final String? versionId;

  /// 当前版本是否为该对象的最新版本
  final bool isLatest;

  /// 当前版本的最后修改时间，为 ISO8601 格式，例如2019-05-24T10:56:40Z
  final String lastModified;

  /// 对象持有者信息
  final Owner owner;

  DeleteMarker(
      {required this.key,
      this.versionId,
      required this.isLatest,
      required this.lastModified,
      required this.owner});

  @override
  String toString() =>
      '{ key:$key, versionId:$versionId, isLatest:$isLatest, lastModified:$lastModified, owner:$owner }';
}

/// listObjectVersions 接口返回值
class ListObjectVersionsResult {
  /// 存储桶的名称，格式为<BucketName-APPID>
  final String name;

  /// 对象版本条目
  final List<CosObjectVersion> versions;

  /// 对象删除标记条目
  final List<DeleteMarker> deleteMarkers;

  /// 从 prefix 或从头（如未指定 prefix）到首个 delimiter 之间相同的部分，定义为 Common Prefix。仅当请求中指定了 delimiter 参数才有可能返回该节点
  final List<CommonPrefixes>? commonPrefixes;

  /// 响应条目是否被截断，布尔值，例如 true 或 false，可用于判断是否还需要继续列出文件
  final bool isTruncated;

  /// 仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，该节点的值为当前响应条目中的最后一个对象键，当需要继续请求后续条目时，将该节点的值作为下一次请求的 marker 参数传入
  final String? nextMarker;

  /// 仅当响应条目有截断（IsTruncated 为 true）才会返回该节点，该节点的值为当前响应条目中的最后一个对象的版本 ID，当需要继续请求后续条目时，将该节点的值作为下一次请求的 version-id-marker 参数传入。该节点的值可能为空，此时下一次请求的 version-id-marker 参数也需要指定为空。
  final String? nextVersionIdMarker;

  ListObjectVersionsResult({
    required this.name,
    required this.versions,
    required this.deleteMarkers,
    required this.isTruncated,
    this.commonPrefixes,
    this.nextMarker,
    this.nextVersionIdMarker,
  });

  @override
  String toString() =>
      '{ name:$name, versions:$versions, deleteMarkers:$deleteMarkers, isTruncated:$isTruncated,'
      ' commonPrefixes:$commonPrefixes, nextMarker:$nextMarker, nextVersionIdMarker:$nextVersionIdMarker }';
}

/// headBucket 接口返回值
class HeadBucketResult {}
