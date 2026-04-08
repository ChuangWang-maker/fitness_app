// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_type, return_of_invalid_type

part of 'exercise.dart';

class ExerciseStatusAdapter extends TypeAdapter<ExerciseStatus> {
  @override
  final int typeId = 2;

  @override
  ExerciseStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseStatus.planned;
      case 1:
        return ExerciseStatus.inProgress;
      case 2:
        return ExerciseStatus.completed;
      default:
        return ExerciseStatus.planned;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseStatus obj) {
    switch (obj) {
      case ExerciseStatus.planned:
        writer.writeByte(0);
        break;
      case ExerciseStatus.inProgress:
        writer.writeByte(1);
        break;
      case ExerciseStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 3;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      typeId: fields[1] as String,
      typeName: fields[2] as String,
      date: fields[3] as DateTime,
      durationSeconds: fields[4] as int,
      distance: fields[5] as double?,
      sets: fields[6] as int?,
      reps: fields[7] as int?,
      restSeconds: fields[8] as int?,
      completedSets: fields[9] as int,
      status: fields[10] as ExerciseStatus,
      isStrength: fields[11] as bool,
      actionId: fields[12] as String?,
      actionName: fields[13] as String?,
      scheduledTime: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.typeId)
      ..writeByte(2)
      ..write(obj.typeName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.distance)
      ..writeByte(6)
      ..write(obj.sets)
      ..writeByte(7)
      ..write(obj.reps)
      ..writeByte(8)
      ..write(obj.restSeconds)
      ..writeByte(9)
      ..write(obj.completedSets)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.isStrength)
      ..writeByte(12)
      ..write(obj.actionId)
      ..writeByte(13)
      ..write(obj.actionName)
      ..writeByte(14)
      ..write(obj.scheduledTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
