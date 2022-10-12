# qcloud_cos_client

[![Pub](https://img.shields.io/pub/v/qcloud_cos_client.svg?style=flat-square)](https://pub.dev/packages/qcloud_cos_client)
[![support](https://img.shields.io/badge/platform-android%20|%20ios%20|%20macos%20|%20windows%20|%20linux%20-blue.svg)](https://pub.dev/packages/qcloud_cos_client)

腾讯云对象存储（Cloud Object Storage，COS）, 不依赖原生插件. （[XML API](https://cloud.tencent.com/document/product/436/7751)）

## Features

### support api:
* getService
* listObjects
* listObjectVersions
* headBucket
* putObject
* getObject
* headObject
* deleteObject
* deleteMultipleObject
* putObjectTagging
* deleteObjectTagging
* getObjectTagging

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  qcloud_cos_client: <latest_version>
```

## Usage

[example](./example/lib/test_page.dart)

## Additional information

具体参考:[腾讯云对象存储 COS XML API](https://cloud.tencent.com/document/product/436/7751)
