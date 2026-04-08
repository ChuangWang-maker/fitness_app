// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_type, return_of_invalid_type

part of 'exercise_action.dart';

class ExerciseActionAdapter extends TypeAdapter<ExerciseAction> {
  @override
  final int typeId = 4;

  @override
  ExerciseAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseAction(
      id: fields[0] as String,
      name: fields[1] as String,
      isBuiltIn: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseAction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isBuiltIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
