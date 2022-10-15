/// 储
enum CosStorageClassType {
  /// 标准存储
  standard,

  /// 标准存储(多AZ)
  maxStandard,

  /// 低频存储
  standardIA,

  /// 低频存储(多AZ)
  maxStandardIA,

  /// 智能分层存储
  intelligentTiering,

  /// 智能分层存储(多AZ)
  mazIntelligentTiering,

  /// 归档存储
  archive,

  /// 深度归档存储
  deepArchive,
}

extension CosStorageClassTypeExtension on CosStorageClassType {
  String get headerName {
    CosStorageClassType type = CosStorageClassType.values[index];
    switch (type) {
      case CosStorageClassType.standard:
        return 'STANDARD';
      case CosStorageClassType.maxStandard:
        return 'MAZ_STANDARD';
      case CosStorageClassType.standardIA:
        return 'STANDARD_IA';
      case CosStorageClassType.maxStandardIA:
        return 'MAZ_STANDARD_IA';
      case CosStorageClassType.intelligentTiering:
        return 'INTELLIGENT_TIERING';
      case CosStorageClassType.mazIntelligentTiering:
        return 'MAZ_INTELLIGENT_TIERING';
      case CosStorageClassType.archive:
        return 'ARCHIVE';
      case CosStorageClassType.deepArchive:
        return 'DEEP_ARCHIVE';
    }
  }
}

CosStorageClassType cosStorageClassNameToType(String name) {
  return <String, CosStorageClassType>{
        'STANDARD': CosStorageClassType.standard,
        'MAZ_STANDARD': CosStorageClassType.maxStandard,
        'STANDARD_IA': CosStorageClassType.standardIA,
        'MAZ_STANDARD_IA': CosStorageClassType.maxStandardIA,
        'INTELLIGENT_TIERING': CosStorageClassType.intelligentTiering,
        'MAZ_INTELLIGENT_TIERING': CosStorageClassType.mazIntelligentTiering,
        'ARCHIVE': CosStorageClassType.archive,
        'DEEP_ARCHIVE': CosStorageClassType.deepArchive
      }[name] ??
      CosStorageClassType.standard;
}

/*/// 描述待检索对象的压缩格式： 如果对象未被压缩过，则该项为 NONE。
/// 如果对象被压缩过，COS Select 目前支持的两种压缩格式为 GZIP 和 BZIP2，可选项为 NONE、GZIP、BZIP2，默认值为 NONE
enum CompressionType { none, gzip, bzip2 }
/// 待检索对象中是否存在列表头。该参数为存在 NONE、USE、IGNORE 三个选项。
/// NONE 代表对象中没有列表头，USE 代表对象中存在列表头并且您可以使用表头进行检索（例如 SELECT "name" FROM COSObject），
/// IGNORE 代表对象中存在列表头且您不打算使用表头进行检索（但您仍然可以通过列索引进行检索，如 SELECT s._1 FROM COSObject s）
enum FileHeaderInfoType{none,use,ignore}*/
