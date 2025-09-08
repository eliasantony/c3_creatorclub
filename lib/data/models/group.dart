import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'group.freezed.dart';
part 'group.g.dart';

/// Chat Group model (community or private)
@freezed
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    required String type, // 'community' | 'private'
    required String ownerId,
    @TimestampConverter() required DateTime createdAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}

/// Firestore Timestamp <-> DateTime converter
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();
  @override
  DateTime fromJson(Object? json) {
    if (json == null) return DateTime.now();
    try {
      if (json is Timestamp) return json.toDate();
      // Support both Firestore Timestamp-like map and ISO strings
      if (json is Map && json['seconds'] != null) {
        final seconds = (json['seconds'] as num).toInt();
        final nanos = (json['nanoseconds'] as num? ?? 0).toInt();
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanos ~/ 1000000,
        );
      }
      if (json is String) return DateTime.parse(json);
    } catch (_) {}
    return DateTime.now();
  }

  @override
  Object toJson(DateTime object) => object.toIso8601String();
}
