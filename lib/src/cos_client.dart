import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:qcloud_cos_client/src/cos_service_error.dart';
import 'package:xml/xml.dart';

import 'cos_auth.dart';
import 'cos_headers.dart';
import 'cos_response.dart';
import 'logger.dart';
import 'types.dart';

class CosConfig {
  /// 秘钥SecretId.
  final String secretId;

  /// 秘钥SecretKey
  final String secretKey;

  /// 临时秘钥使用的token
  final String? token;

  /// 使用自定义的域名来访问cos service
  final String? serviceDomain;

  /// 使用自定义的域名来访问COS
  final String? domain;

  /// 地域信息
  final String? region;

  /// Http|Https
  final String? scheme;

  CosConfig({
    required this.secretId,
    required this.secretKey,
    this.serviceDomain,
    this.domain,
    this.region,
    this.scheme = 'https',
    this.token,
  });

  url({String? bucket, String? path, String? sRegion, String? sDomain}) {
    sDomain ??= domain;
    sRegion ??= region;
    if (null == sDomain) {
      assert(null != sRegion, 'region, null given!');
      if ([
        'cn-south',
        'cn-south-2',
        'cn-north',
        'cn-east',
        'cn-southwest',
        'sg'
      ].contains(sRegion)) {
        sDomain = '$sRegion.myqcloud.com';
      } else {
        sDomain = 'cos.$sRegion.myqcloud.com';
      }
      assert(null != bucket, 'bucket, null given!');
      sDomain = '$bucket.$sDomain';
    }
    var fixPath = null != path && path.isNotEmpty
        ? (!path.startsWith('/') ? '/$path' : path)
        : '';
    String requestUrl = '$scheme://$sDomain$fixPath';
    return requestUrl;
  }
}

class CosClient {
  final CosConfig cosConfig;
  final Dio _dio;

  CosClient(this.cosConfig, {Dio? dio}) : _dio = dio ?? Dio();

  /// [LogLevel] 日志等级
  set logLevel(LogLevel level) => Log.logLevel = level;

  /// list_buckets 获取用户的 bucket 列表 action cos:GetService
  Future<CosResponse<GetServiceResult>> getService(
      {String? region, Map<String, String>? headers}) async {
    final domain = cosConfig.serviceDomain;
    String url;
    final protocol = cosConfig.scheme ?? 'https';
    if (null != domain && domain.isNotEmpty) {
      url = '$protocol://$domain';
    } else {
      if (null != region && region.isNotEmpty) {
        url = '$protocol://cos.$region.myqcloud.com';
      } else {
        url = '$protocol://service.cos.myqcloud.com';
      }
    }
    var res = await _sendRequest(url: url, method: 'GET');
    var resData = res.data;
    Log.d('getService response:$resData');
    var xml = XmlDocument.parse(resData);
    List<Bucket> buckets = [];
    var bucketElement = xml.findAllElements('Bucket');
    for (var e in bucketElement) {
      buckets.add(Bucket(
          name: e.getElement('Name')?.value ?? '',
          region: e.getElement('Location')?.value ?? '',
          creationDate: e.getElement('CreationDate')?.value ?? '',
          bucketType: e.getElement('BucketType')?.value ?? ''));
    }
    var ownerElement = xml.findAllElements('Owner').first;
    Owner owner = Owner(
        id: ownerElement.getElement('ID')?.value ?? '',
        displayName: ownerElement.getElement('DisplayName')?.value ?? '');
    return CosResponse<GetServiceResult>(
      statusCode: res.statusCode,
      headers: headerToMap(res.headers.map),
      requestId: res.headers.value(CosHeaders.xCosRequestId),
      data: GetServiceResult(buckets: buckets, owner: owner),
    );
  }

  /// s3 object interface begin. action cos:PutObject*
  /// [bucket] 存储桶名称.
  /// [data] 上传文件的内容
  /// [objectKey] COS路径，即文件名称
  /// [contentType] RFC 2616 中定义的内容类型（MIME），将作为 Object 元数据保存，非必须
  Future<CosResponse<PutObjectResult>> putObject(
      {required String bucket,
      required String objectKey,
      dynamic data,
      CosStorageClassType storageClassType = CosStorageClassType.standard,
      String? region,
      String? contentType,
      ProgressCallback? onSendProgress,
      Map<String, String?>? headers}) async {
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    headers ??= {};
    headers.addAll({
      HttpHeaders.contentTypeHeader: contentType,
      CosHeaders.xCosStorageClass: storageClassType.headerName,
    });
    var res = await _sendRequest(
        method: 'PUT',
        headers: headers,
        url: url,
        key: objectKey,
        data: data,
        onSendProgress: onSendProgress);
    Log.d('putObject response:$res');
    return CosResponse<PutObjectResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: PutObjectResult(
            eTag: res.headers.value(HttpHeaders.etagHeader),
            versionId: res.headers.value(CosHeaders.xCosVersionId),
            location: (region ?? cosConfig.region)!));
  }

  /// 下载 object
  /// [bucket] 存储桶名称.
  /// [objectKey] COS路径，即文件名称
  Future<CosResponse<GetObjectResult>> getObject({
    required String bucket,
    required String objectKey,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
    ProgressCallback? onReceiveProgress,
  }) async {
    headers ??= {};
    Map<String, String?> finalHeaders = {};
    Map<String, String?> params = {};
    for (var key in headers.keys) {
      if (key.startsWith('response')) {
        params[key] = headers[key];
      } else {
        finalHeaders[key] = headers[key];
      }
    }
    if (finalHeaders.containsKey('versionId')) {
      params['versionId'] = versionId ?? finalHeaders['versionId'];
      finalHeaders.remove('versionId');
    } else {
      if (null != versionId && versionId.isNotEmpty) {
        params['versionId'] = versionId;
      }
    }
    headers = finalHeaders;
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    var res = await _sendRequest(
        method: 'GET',
        headers: headers,
        url: url,
        key: objectKey,
        responseType: ResponseType.bytes,
        onReceiveProgress: onReceiveProgress);
    return CosResponse<GetObjectResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: GetObjectResult(
            eTag: res.headers.value(HttpHeaders.etagHeader),
            versionId: res.headers.value(CosHeaders.xCosVersionId),
            objectData: res.data,
            mimeType: res.headers.value(HttpHeaders.contentTypeHeader)));
  }

  /// 下载 object file 流式下载大文件
  /// [bucket] 存储桶名称.
  /// [objectKey] COS路径，即文件名称
  Future<CosResponse<GetObjectFileResult>> getObjectFile({
    required String bucket,
    required String objectKey,
    required File saveFile,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
    ProgressCallback? onReceiveProgress,
  }) async {
    headers ??= {};
    Map<String, String?> finalHeaders = {};
    Map<String, String?> params = {};
    for (var key in headers.keys) {
      if (key.startsWith('response')) {
        params[key] = headers[key];
      } else {
        finalHeaders[key] = headers[key];
      }
    }
    if (finalHeaders.containsKey('versionId')) {
      params['versionId'] = versionId ?? finalHeaders['versionId'];
      finalHeaders.remove('versionId');
    } else {
      if (null != versionId && versionId.isNotEmpty) {
        params['versionId'] = versionId;
      }
    }
    headers = finalHeaders;
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    var res = await _sendRequest(
        method: 'GET',
        headers: headers,
        url: url,
        key: objectKey,
        responseType: ResponseType.bytes,
        onReceiveProgress: onReceiveProgress,
        savePath: saveFile.path);
    return CosResponse<GetObjectFileResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: GetObjectFileResult(
            eTag: res.headers.value(HttpHeaders.etagHeader),
            versionId: res.headers.value(CosHeaders.xCosVersionId),
            objectFile: saveFile,
            mimeType: res.headers.value(HttpHeaders.contentTypeHeader)));
  }

  /// 删除 object
  Future<CosResponse> deleteObject({
    required String bucket,
    required String objectKey,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    Map<String, String?> params = {};
    if (headers.containsKey('versionId')) {
      params['versionId'] = versionId ?? headers['versionId'];
      headers.remove('versionId');
    } else {
      if (null != versionId && versionId.isNotEmpty) {
        params['versionId'] = versionId;
      }
    }
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    var res = await _sendRequest(
        method: 'DELETE', headers: headers, url: url, key: objectKey);
    Log.d('deleteObject response:$res');
    return CosResponse(
      statusCode: res.statusCode,
      headers: res.headers.map,
      requestId: res.headers.value(CosHeaders.xCosRequestId),
    );
  }

  /// 文件批量删除接口, 单次最多支持1000个object
  Future<CosResponse<DeleteMultipleObjectResult>> deleteMultipleObject({
    required String bucket,
    required List<CosObjectVersionParams> deletes,
    bool quiet = true,
    String? region,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    var url = cosConfig.url(bucket: bucket, sRegion: region);
    var xmlBuilder = _createXmlBuilder();
    xmlBuilder.element('Delete', nest: () {
      xmlBuilder.element('Quiet', nest: quiet);
      for (var deleteCos in deletes) {
        xmlBuilder.element('Object', nest: () {
          xmlBuilder.element('Key', nest: deleteCos.key);
          if (null != deleteCos.versionId && deleteCos.versionId!.isNotEmpty) {
            xmlBuilder.element('VersionId', nest: deleteCos.versionId!);
          }
        });
      }
    });
    final document = xmlBuilder.buildDocument();
    var xmlData = document.toXmlString(pretty: true);
    Log.d('deleteMultipleObject deletes:$deletes');
    Log.d('deleteMultipleObject xmlData:$xmlData');
    Map<String, String?> params = {};
    params['delete'] = '';
    headers[HttpHeaders.contentTypeHeader] = 'application/xml';
    headers[HttpHeaders.contentMD5Header] =
        convert.base64.encode(md5.convert(xmlData.codeUnits).bytes);
    var res = await _sendRequest(
        method: 'POST',
        headers: headers,
        url: url,
        query: params,
        data: xmlData);
    Log.d('deleteMultipleObject response:$res');
    var xml = XmlDocument.parse(res.data);
    var deletedElements = xml.rootElement.findAllElements('Deleted');
    List<MultipleDeletedObject>? deleted;
    if (deletedElements.isNotEmpty) {
      deleted = [];
      for (var ele in deletedElements) {
        deleted.add(MultipleDeletedObject(
            key: ele.getElement('Key')?.value ?? '',
            versionId: ele.getElement('VersionId')?.value,
            deleteMarker: ele.getElement('DeleteMarker')?.value == 'true',
            deleteMarkerVersionId:
                ele.getElement('DeleteMarkerVersionId')?.value));
      }
    }

    List<MultipleDeletedError>? errors;
    var errorElements = xml.rootElement.findAllElements('Error');
    if (errorElements.isNotEmpty) {
      errors = [];
      for (var ele in errorElements) {
        errors.add(MultipleDeletedError(
            key: ele.getElement('Key')?.value ?? '',
            versionId: ele.getElement('VersionId')?.value,
            code: ele.getElement('Code')?.value,
            message: ele.getElement('Message')?.value));
      }
    }
    return CosResponse<DeleteMultipleObjectResult>(
      statusCode: res.statusCode,
      headers: res.headers.map,
      requestId: res.headers.value(CosHeaders.xCosRequestId),
      data: DeleteMultipleObjectResult(deleted: deleted, errors: errors),
    );
  }

  /// 取回对应Object的元数据，Head的权限与Get的权限一致. action cos:HeadObject
  Future<CosResponse<HeadObjectResult>> headObject({
    required String bucket,
    required String objectKey,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    Map<String, String?> params = {};
    if (headers.containsKey('versionId')) {
      params['versionId'] = versionId ?? headers['versionId'];
      headers.remove('versionId');
    } else {
      if (null != versionId && versionId.isNotEmpty) {
        params['versionId'] = versionId;
      }
    }
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    var res = await _sendRequest(
        method: 'HEAD', headers: headers, url: url, key: objectKey);
    Log.d('headObject response:$res');
    return CosResponse<HeadObjectResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: HeadObjectResult(
            eTag: res.headers.value(HttpHeaders.etagHeader),
            versionId: res.headers.value(CosHeaders.xCosVersionId)));
  }

  /// 获取 Object 的标签设置 action => cos:GetObjectTagging
  Future<CosResponse<GetObjectTaggingResult>> getObjectTagging({
    required String bucket,
    required String objectKey,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    var fetchList = _fetchObjVersionIdFromHeader(headers, versionId: versionId);
    headers = fetchList[0];
    Map<String, String?> params = fetchList[1];
    params['tagging'] = '';
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    Log.d('getObjectTagging url:$url headers:$headers');
    var res = await _sendRequest(
        method: 'GET',
        headers: headers,
        url: url,
        key: objectKey,
        query: params);
    Log.d('getObjectTagging response:$res');
    var xml = XmlDocument.parse(res.data);
    var tagElements = xml.findAllElements('Tag');
    List<Tag> tags = [];
    for (var element in tagElements) {
      tags.add(Tag(
          key: element.getElement('Key')?.value ?? '',
          value: element.getElement('Value')?.value ?? ''));
    }
    return CosResponse<GetObjectTaggingResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: GetObjectTaggingResult(tags: tags));
  }

  /// 设置 Object 的标签 action => cos:PutObjectTagging
  Future<CosResponse<PutObjectTaggingResult>> putObjectTagging({
    required String bucket,
    required String objectKey,
    required List<Tag> tags,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    var fetchList = _fetchObjVersionIdFromHeader(headers, versionId: versionId);
    headers = fetchList[0];
    Map<String, String?> params = fetchList[1];
    params['tagging'] = '';
    headers[HttpHeaders.contentTypeHeader] = 'application/xml';
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    Log.d('putObjectTagging url:$url headers:$headers tags:$tags');
    var xmlBuilder = _createXmlBuilder();
    xmlBuilder.element('Tagging', nest: () {
      xmlBuilder.element('TagSet', nest: () {
        for (var tag in tags) {
          xmlBuilder.element('Tag', nest: () {
            xmlBuilder.element('Key', nest: tag.key);
            xmlBuilder.element('Value', nest: tag.value);
          });
        }
      });
    });
    var xmlData = xmlBuilder.buildDocument();
    Log.d('putObjectTagging xmlData:$xmlData');
    var res = await _sendRequest(
        method: 'PUT',
        headers: headers,
        url: url,
        key: objectKey,
        query: params,
        data: xmlData.toString());
    Log.d('putObjectTagging response:$res');
    return CosResponse<PutObjectTaggingResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId));
  }

  /// 删除 Object 的标签设置 => cos:DeleteObjectTagging
  Future<CosResponse<DeleteObjectTaggingResult>> deleteObjectTagging({
    required String bucket,
    required String objectKey,
    String? region,
    String? versionId,
    Map<String, String?>? headers,
  }) async {
    headers ??= {};
    var fetchList = _fetchObjVersionIdFromHeader(headers, versionId: versionId);
    headers = fetchList[0];
    Map<String, String?> params = fetchList[1];
    params['tagging'] = '';
    var url = cosConfig.url(bucket: bucket, path: objectKey, sRegion: region);
    Log.d('deleteObjectTagging url:$url headers:$headers');
    var res = await _sendRequest(
        method: 'DELETE',
        headers: headers,
        url: url,
        key: objectKey,
        query: params);
    Log.d('deleteObjectTagging response:$res');
    return CosResponse<DeleteObjectTaggingResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId));
  }

  /// 获取 Bucket 下的 object 列表 action => cos:GetBucket
  /// [resourceKeyPrefix] 前缀匹配，用来规定返回的文件前缀地址，非必须
  /// [delimiter] 定界符为一个符号，如果有Prefix，则将Prefix到delimiter之间的相同路径归为一类，非必须
  /// [marker] 默认以UTF-8二进制顺序列出条目，所有列出条目从marker开始，非必须
  /// [maxKeys] 单次返回最大的条目数量，默认1000，非必须
  // [encodingType] 规定返回值的编码方式，可选值：url, 非必须
  Future<CosResponse<ListBucketObjectsResult>> listObjects({
    required String bucket,
    String? region,
    String? resourceKeyPrefix,
    String? delimiter,
    String? marker,
    int maxKeys = 1000,
    Map<String, String?>? headers,
  }) async {
    Map<String, String?> params = {
      if (null != resourceKeyPrefix) 'prefix': resourceKeyPrefix,
      if (null != delimiter) 'delimiter': delimiter,
      'encoding-type': 'url',
      if (null != marker) 'marker': marker,
      'max-keys': '$maxKeys',
    };
    var url = cosConfig.url(bucket: bucket, sRegion: region);
    Log.d('listObjects url:$url headers:$headers');
    var res = await _sendRequest(
        method: 'GET', headers: headers, url: url, query: params);
    Log.d('listObjects response:$res');
    var xml = XmlDocument.parse(res.data);
    var name = xml.rootElement.getElement('Name')?.value ?? '';
    var isTruncated =
        xml.rootElement.getElement('IsTruncated')?.value == 'true';
    String? nextMarker = xml.rootElement.getElement('NextMarker')?.value;
    var commonPrefixesIterable =
        xml.rootElement.findAllElements('CommonPrefixes');
    List<CommonPrefixes>? commonPrefixes =
        commonPrefixesIterable.isNotEmpty ? [] : null;
    for (var element in commonPrefixesIterable) {
      commonPrefixes
          ?.add(CommonPrefixes(element.getElement('Prefix')?.value ?? ''));
    }
    var contentsIterable = xml.rootElement.findAllElements('Contents');
    List<CosObject> contents = [];
    for (var element in contentsIterable) {
      var ownerElement = element.getElement('Owner');
      contents.add(CosObject(
          key: element.getElement('Key')?.value ?? '',
          lastModified: element.getElement('LastModified')?.value ?? '',
          eTag: element.getElement('ETag')?.value ?? '',
          size: element.getElement('Size')?.value ?? '0',
          storageClass: cosStorageClassNameToType(
              element.getElement('StorageClass')?.value ?? ''),
          storageTier: element.getElement('StorageTier')?.value,
          owner: Owner(
              id: ownerElement?.getElement('ID')?.value ?? '',
              displayName:
                  ownerElement?.getElement('DisplayName')?.value ?? '')));
    }
    return CosResponse<ListBucketObjectsResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: ListBucketObjectsResult(
            name: name,
            isTruncated: isTruncated,
            contents: contents,
            commonPrefixes: commonPrefixes,
            nextMarker: nextMarker));
  }

  /// 获取 Bucket 下的 object 及其历史版本信息 action => cos:GetBucketObjectVersions
  /// [resourceKeyPrefix] 前缀匹配，用来规定返回的文件前缀地址，非必须
  /// [delimiter] 定界符为一个符号，如果有Prefix，则将Prefix到delimiter之间的相同路径归为一类，非必须
  /// [keyMarker] 默认以UTF-8二进制顺序列出条目，所有列出条目从keyMarker开始，非必须
  /// [maxKeys] 单次返回最大的条目数量，默认1000，非必须
  /// [versionIdMarker] 从versionIdMarker指定的版本开始列出条目
  // [encodingType] 规定返回值的编码方式，可选值：url, 非必须
  Future<CosResponse<ListObjectVersionsResult>> listObjectVersions({
    required String bucket,
    String? region,
    String? resourceKeyPrefix,
    String? delimiter,
    String? keyMarker,
    String? versionIdMarker,
    int maxKeys = 1000,
    Map<String, String?>? headers,
  }) async {
    Map<String, String?> params = {
      'versions': '',
      if (null != resourceKeyPrefix) 'prefix': resourceKeyPrefix,
      if (null != delimiter) 'delimiter': delimiter,
      'encoding-type': 'url',
      if (null != keyMarker) 'key-marker	': keyMarker,
      if (null != versionIdMarker) 'version-id-marker': versionIdMarker,
      'max-keys': '$maxKeys',
    };
    var url = cosConfig.url(bucket: bucket, sRegion: region);
    Log.d('listObjectVersions url:$url headers:$headers');
    var res = await _sendRequest(
        method: 'GET', headers: headers, url: url, query: params);
    Log.d('listObjectVersions response:$res');
    var xml = XmlDocument.parse(res.data);
    var name = xml.rootElement.getElement('Name')?.value ?? '';
    var isTruncated =
        xml.rootElement.getElement('IsTruncated')?.value == 'true';
    String? nextMarker = xml.rootElement.getElement('NextMarker')?.value;
    var commonPrefixesIterable =
        xml.rootElement.findAllElements('CommonPrefixes');
    List<CommonPrefixes>? commonPrefixes =
        commonPrefixesIterable.isNotEmpty ? [] : null;
    for (var element in commonPrefixesIterable) {
      commonPrefixes
          ?.add(CommonPrefixes(element.getElement('Prefix')?.value ?? ''));
    }
    var versionsIterable = xml.rootElement.findAllElements('Contents');
    List<CosObjectVersion> versions = [];
    for (var element in versionsIterable) {
      var ownerElement = element.getElement('Owner');
      versions.add(CosObjectVersion(
          key: element.getElement('Key')?.value ?? '',
          lastModified: element.getElement('LastModified')?.value ?? '',
          isLatest: element.getElement('IsLatest')?.value == 'true',
          eTag: element.getElement('ETag')?.value ?? '',
          size: element.getElement('Size')?.value ?? '0',
          storageClass: cosStorageClassNameToType(
              element.getElement('StorageClass')?.value ?? ''),
          storageTier: element.getElement('StorageTier')?.value,
          versionId: element.getElement('VersionId')?.value,
          owner: Owner(
              id: ownerElement?.getElement('ID')?.value ?? '',
              displayName:
                  ownerElement?.getElement('DisplayName')?.value ?? '')));
    }
    var deleteMarkerIterable = xml.rootElement.findAllElements('DeleteMarker');
    List<DeleteMarker> deleteMarkers = [];
    for (var element in deleteMarkerIterable) {
      var ownerElement = element.getElement('Owner');
      deleteMarkers.add(DeleteMarker(
          key: element.getElement('Key')?.value ?? '',
          lastModified: element.getElement('LastModified')?.value ?? '',
          isLatest: element.getElement('IsLatest')?.value == 'true',
          versionId: element.getElement('VersionId')?.value,
          owner: Owner(
              id: ownerElement?.getElement('ID')?.value ?? '',
              displayName:
                  ownerElement?.getElement('DisplayName')?.value ?? '')));
    }
    return CosResponse<ListObjectVersionsResult>(
        statusCode: res.statusCode,
        headers: res.headers.map,
        requestId: res.headers.value(CosHeaders.xCosRequestId),
        data: ListObjectVersionsResult(
            name: name,
            isTruncated: isTruncated,
            versions: versions,
            commonPrefixes: commonPrefixes,
            nextMarker: nextMarker,
            deleteMarkers: deleteMarkers));
  }

  /// 查看是否存在该Bucket，是否有权限访问 cos:GetBucket
  Future<CosResponse<HeadBucketResult>> headBucket({
    required String bucket,
    String? region,
    Map<String, String?>? headers,
  }) async {
    var url = cosConfig.url(bucket: bucket, sRegion: region);
    Log.d('headBucket url:$url headers:$headers');
    var res = await _sendRequest(method: 'HEAD', headers: headers, url: url);
    return CosResponse<HeadBucketResult>(
      statusCode: res.statusCode,
      headers: res.headers.map,
      requestId: res.headers.value(CosHeaders.xCosRequestId),
    );
  }

  List<Map<String, String?>> _fetchObjVersionIdFromHeader(
      Map<String, String?> headers,
      {Map<String, String?>? params,
      String? versionId}) {
    params ??= {};
    if (headers.containsKey('versionId')) {
      params['versionId'] = versionId ?? headers['versionId'];
      headers.remove('versionId');
    } else {
      if (null != versionId && versionId.isNotEmpty) {
        params['versionId'] = versionId;
      }
    }
    return [headers, params];
  }

  XmlBuilder _createXmlBuilder() {
    var xmlBuilder = XmlBuilder();
    xmlBuilder.processing('xml', 'version="2.0"');
    return xmlBuilder;
  }

  /// http request
  Future<Response> _sendRequest(
      {String? key,
      required String url,
      required String method,
      Map<String, String?>? headers,
      Map<String, String?>? query,
      dynamic data,
      ProgressCallback? onSendProgress,
      ResponseType? responseType = ResponseType.plain,
      ProgressCallback? onReceiveProgress,
      String? savePath}) async {
    query ??= {};
    Log.d('request query---$query');
    String sQuery = query.isNotEmpty
        ? query.keys.map((key) => '$key=${query![key]}').join('&')
        : '';
    Uri uri = Uri.parse('$url${sQuery.isNotEmpty ? '?' : ''}$sQuery');
    headers ??= {};
    headers[HttpHeaders.hostHeader] = uri.host;
    if (null != cosConfig.token && cosConfig.token!.isNotEmpty) {
      headers[CosHeaders.xCosSecurityToken] = cosConfig.token;
    }
    Stream<Uint8List>? stream;
    if (data is Uint8List) {
      stream = Stream.fromIterable([data]);
      headers[HttpHeaders.contentLengthHeader] = data.length.toString();
    }
    var authorization = CosS3Auth.getAuth(cosConfig,
        headers: headers, method: method, key: key, params: query);
    headers['Authorization'] = authorization;

    Log.d('request uri---${uri.toString()}');
    Log.d('request header---$headers');
    Response response;
    try {
      if (savePath == null) {
        response = await _dio.requestUri(uri,
            data: stream ?? data,
            options: Options(
                method: method,
                headers: headers,
                responseType: responseType,
                contentType: headers[HttpHeaders.contentTypeHeader]),
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress);
      } else {
        response = await _dio.downloadUri(uri, savePath,
            data: stream ?? data,
            options: Options(
                method: method,
                headers: headers,
                responseType: responseType,
                contentType: headers[HttpHeaders.contentTypeHeader]),
            onReceiveProgress: onReceiveProgress);
      }
    } on DioException catch (e) {
      var res = e.response;
      Map<String, dynamic> message = {};
      if (null == res) throw StateError(e.toString());
      if (HttpStatus.notFound == res.statusCode && method == 'HEAD') {
        message['code'] = 'NoSuchResource';
        message['message'] = 'The Resource You Head Not Exist';
        message['resource'] = url.toString();
        message['requestid'] = res.headers[CosHeaders.xCosRequestId] ?? '';
        message['traceid'] = res.headers[CosHeaders.xCosTraceId] ?? '';
        Log.w(message);
        throw CosServiceError(
            method: method, statusCode: res.statusCode, message: message);
      }
      var data = res.data;
      if (null != data) {
        Log.d('sendRequest err data $data');
        if (data is String &&
            data.isNotEmpty &&
            data.contains('<') &&
            data.contains('>')) {
          var xml = XmlDocument.parse(data);
          message['Code'] = xml.rootElement.getElement('Code')?.value;
          message['Message'] = xml.rootElement.getElement('Message')?.value;
          message['Resource'] = xml.rootElement.getElement('Resource')?.value;
          message['RequestId'] = xml.rootElement.getElement('RequestId')?.value;
          message['TraceId'] = xml.rootElement.getElement('TraceId')?.value;
        }
      }
      throw CosServiceError(
          method: method, statusCode: res.statusCode, message: message);
    }
    return response;
  }
}

Map<String, String?> headerToMap(Map<String, List<String>> httpHeaders) {
  Map<String, String?> headers = {};
  httpHeaders
      .forEach((name, values) => headers[name] = httpHeaders[name]?.first);
  return headers;
}
