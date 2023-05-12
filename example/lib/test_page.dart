import 'dart:io';
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:qcloud_cos_client/qcloud_cos_client.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key, required this.title});

  final String title;

  @override
  State<TestPage> createState() => _TestPageState();
}

enum Action {
  getService,
  listObjects,
  listObjectVersions,
  headBucket,
  putObject,
  getObject,
  headObject,
  deleteObject,
  deleteMultipleObject,
  putObjectTagging,
  deleteObjectTagging,
  getObjectTagging
}

class _TestPageState extends State<TestPage> {
  final String _secretId = 'your cos secretId';
  final String _secretKey = 'your cos secretKey';
  final String _bucket = 'your cos bucket';
  final String _region = 'your cos region';
  static const String _defaultObjectKey = 'test/test.txt';
  CosClient? _client;

  Future<void> _getService() async {
    await _ensureCosClientNonNull();
    var res = await _client?.getService();
    debugPrint('_getService res ==> $res');
  }

  Future<void> _putObject({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var meta = {'mimetype': 'text/plain', 'size': 4};
    var res = await _client!.putObject(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
      contentType: 'text/plain',
      data: 'hello tencent cos',
      headers: {
        CosHeaders.xCosMeta('test'): convert.jsonEncode(meta),
        CosHeaders.xCosTagging: meta.keys
            .map((key) => '${Uri.encodeComponent(key)}=${Uri.encodeComponent(meta[key].toString())}')
            .toList()
            .join('&')
      },
    );
    debugPrint('_putObject res ==> $res');
  }

  Future<void> _getObject({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.getObject(
        region: _region,
        bucket: _bucket,
        objectKey: objectKey,
        onReceiveProgress: (int cur, int total) {
          debugPrint('onReceiveProgress---$cur:$total');
        });
    if (null != res.data) {
      var utf8 = convert.utf8.decode(res.data!.objectData, allowMalformed: true);
      debugPrint('utf8----$utf8');
    }
    debugPrint('_getObject res ==> $res');
  }

  Future<void> _deleteObjectTagging({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.deleteObjectTagging(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
    );
    debugPrint('_deleteObjectTagging res ==> $res');
  }

  Future<void> _putObjectTagging({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.putObjectTagging(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
      tags: [Tag(key: 'keyTest', value: 'valueTest')],
    );
    debugPrint('_putObjectTagging res ==> $res');
  }

  Future<void> _getObjectTagging({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.getObjectTagging(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
    );
    debugPrint('_getObjectTagging res ==> $res');
  }

  Future<void> _deleteObject({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.deleteObject(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
    );
    debugPrint('_deleteObject res ==> $res');
  }

  Future<void> _deleteMultipleObject({List<CosObjectVersionParams>? deletes}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.deleteMultipleObject(
      region: _region,
      bucket: _bucket,
      deletes: deletes ??= [CosObjectVersionParams(key: _defaultObjectKey)],
    );
    debugPrint('_deleteMultipleObject res ==> $res');
  }

  Future<void> _headObject({String objectKey = _defaultObjectKey}) async {
    await _ensureCosClientNonNull();
    var res = await _client!.headObject(
      region: _region,
      bucket: _bucket,
      objectKey: objectKey,
    );
    debugPrint('_headObject res ==> $res');
  }

  Future<void> _listObjects() async {
    await _ensureCosClientNonNull();
    var res = await _client!.listObjects(
      region: _region,
      bucket: _bucket,
    );
    debugPrint('_listObjects res ==> $res');
  }

  Future<void> _listObjectVersions() async {
    await _ensureCosClientNonNull();
    var res = await _client!.listObjectVersions(
      region: _region,
      bucket: _bucket,
    );
    debugPrint('_listObjectVersions res ==> $res');
  }

  Future<void> _headBucket() async {
    await _ensureCosClientNonNull();
    var res = await _client!.headBucket(
      region: _region,
      bucket: _bucket,
    );
    debugPrint('_headBucket res ==> $res');
  }

  Future _ensureCosClientNonNull([bool useTempSecretKey = false]) async {
    if (null == _client) {
      if (!useTempSecretKey) {
        _client = CosClient(CosConfig(
          secretId: _secretId,
          secretKey: _secretKey,
        ));
        return;
      }
      try {
        var sJson = await _requestTempCredential();
        var json = convert.jsonDecode(sJson);
        _client = CosClient(CosConfig(
          secretId: json['credentials']['tmpSecretId'],
          secretKey: json['credentials']['tmpSecretKey'],
          token: json['credentials']['sessionToken'],
        ));
      } catch (e) {
        throw StateError('_requestTempCredential error $e');
      }
    }
  }

  Future<String> _requestTempCredential() async {
    HttpClient client = HttpClient();
    var url = 'http://127.0.0.1:8080/getQCloudCosCredential';
    var req = await client.postUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(convert.utf8.encode(convert.jsonEncode(['cos:DeleteMultipleObjects'])));
    var res = await req.close();
    debugPrint('_requestTempCredential-res---${res.statusCode}---');
    String content = await res.transform(convert.utf8.decoder).join("");
    debugPrint('_requestTempCredential-res---$content---');
    return content;
  }

  @override
  Widget build(BuildContext context) {
    List<String> buttons = [];
    for (var action in Action.values) {
      buttons.add(action.name);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: GroupButton(
          buttons: buttons,
          onSelected: _onPressAction,
        ),
      ),
    );
  }

  void _onPressAction(String value, int index, bool isSelected) async {
    var action = Action.values.byName(value);
    switch (action) {
      case Action.getService:
        await _getService();
        break;
      case Action.listObjects:
        await _listObjects();
        break;
      case Action.listObjectVersions:
        await _listObjectVersions();
        break;
      case Action.headBucket:
        await _headBucket();
        break;
      case Action.putObject:
        await _putObject();
        break;
      case Action.getObject:
        await _getObject();
        break;
      case Action.headObject:
        await _headObject();
        break;
      case Action.deleteObject:
        await _deleteObject();
        break;
      case Action.deleteMultipleObject:
        await _deleteMultipleObject();
        break;
      case Action.putObjectTagging:
        await _putObjectTagging();
        break;
      case Action.deleteObjectTagging:
        await _deleteObjectTagging();
        break;
      case Action.getObjectTagging:
        await _getObjectTagging();
        break;
    }
  }
}
