// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentProgressAdapter extends TypeAdapter<StudentProgress> {
  @override
  final int typeId = 2;

  @override
  StudentProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentProgress(
      id: fields[0] as String,
      studentId: fields[1] as String,
      questionId: fields[2] as String,
      subject: fields[3] as String,
      topic: fields[4] as String,
      gradeLevel: fields[5] as int,
      difficulty: fields[6] as DifficultyTag,
      attemptedAt: fields[7] as DateTime,
      studentAnswer: fields[8] as String,
      correctAnswer: fields[9] as String,
      isCorrect: fields[10] as bool,
      responseTimeSeconds: fields[11] as int,
      attemptNumber: fields[12] as int,
      confidenceLevel: fields[13] as double,
      hintsUsed: (fields[14] as List).cast<String>(),
      metadata: (fields[15] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudentProgress obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.questionId)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.topic)
      ..writeByte(5)
      ..write(obj.gradeLevel)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.attemptedAt)
      ..writeByte(8)
      ..write(obj.studentAnswer)
      ..writeByte(9)
      ..write(obj.correctAnswer)
      ..writeByte(10)
      ..write(obj.isCorrect)
      ..writeByte(11)
      ..write(obj.responseTimeSeconds)
      ..writeByte(12)
      ..write(obj.attemptNumber)
      ..writeByte(13)
      ..write(obj.confidenceLevel)
      ..writeByte(14)
      ..write(obj.hintsUsed)
      ..writeByte(15)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PerformanceLevelAdapter extends TypeAdapter<PerformanceLevel> {
  @override
  final int typeId = 3;

  @override
  PerformanceLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PerformanceLevel.excellent;
      case 1:
        return PerformanceLevel.good;
      case 2:
        return PerformanceLevel.average;
      case 3:
        return PerformanceLevel.needsImprovement;
      default:
        return PerformanceLevel.excellent;
    }
  }

  @override
  void write(BinaryWriter writer, PerformanceLevel obj) {
    switch (obj) {
      case PerformanceLevel.excellent:
        writer.writeByte(0);
        break;
      case PerformanceLevel.good:
        writer.writeByte(1);
        break;
      case PerformanceLevel.average:
        writer.writeByte(2);
        break;
      case PerformanceLevel.needsImprovement:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
