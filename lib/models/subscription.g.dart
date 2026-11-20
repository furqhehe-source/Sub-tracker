part of 'subscription.dart';

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 0;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      name: fields[1] as String,
      cost: (fields[2] as num).toDouble(),
      billingDate: fields[3] as DateTime,
      cycle: fields[4] as String,
      isFreeTrial: fields[5] is bool ? fields[5] as bool : false,
      isPaused: fields[6] is bool ? fields[6] as bool : false,
      brandKey: fields[7] is String ? fields[7] as String : null,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.cost)
      ..writeByte(3)
      ..write(obj.billingDate)
      ..writeByte(4)
      ..write(obj.cycle)
      ..writeByte(5)
      ..write(obj.isFreeTrial)
      ..writeByte(6)
      ..write(obj.isPaused)
      ..writeByte(7)
      ..write(obj.brandKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
