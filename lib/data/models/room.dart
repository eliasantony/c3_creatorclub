import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

/// Workspace/Room model as per PRD
@freezed
abstract class Room with _$Room {
  const factory Room({
    required String id,
    required String name,
    String? description,
    String? neighborhood, // e.g., Neubau, Wieden
    int? capacity,
    @Default(<String>[])
    List<String> facilities, // e.g., ['podcast','lighting','wifi']
    @Default(<String>[]) List<String> photos,
    int? openHourStart, // 6
    int? openHourEnd, // 23
    int? priceCents, // optional display price
    double? rating, // optional
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}
