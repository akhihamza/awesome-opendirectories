// GENERATED CODE - DO NOT MODIFY BY HAND
// Manual Hive TypeAdapter for PortfolioData

part of 'portfolio.dart';

class PortfolioDataAdapter extends TypeAdapter<PortfolioData> {
  @override
  final int typeId = 0;

  @override
  PortfolioData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return PortfolioData(
      fundName: fields[0] as String,
      navFilePath: fields[1] as String,
      pdfFilePath: fields[2] as String?,
      transactionsJson:
          (fields[3] as List).cast<Map<String, dynamic>>().toList(),
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fundName)
      ..writeByte(1)
      ..write(obj.navFilePath)
      ..writeByte(2)
      ..write(obj.pdfFilePath)
      ..writeByte(3)
      ..write(obj.transactionsJson)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
