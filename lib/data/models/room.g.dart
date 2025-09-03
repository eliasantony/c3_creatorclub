// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  neighborhood: json['neighborhood'] as String?,
  capacity: (json['capacity'] as num?)?.toInt(),
  facilities:
      (json['facilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  openHourStart: (json['openHourStart'] as num?)?.toInt(),
  openHourEnd: (json['openHourEnd'] as num?)?.toInt(),
  priceCents: (json['priceCents'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'neighborhood': instance.neighborhood,
  'capacity': instance.capacity,
  'facilities': instance.facilities,
  'photos': instance.photos,
  'openHourStart': instance.openHourStart,
  'openHourEnd': instance.openHourEnd,
  'priceCents': instance.priceCents,
  'rating': instance.rating,
};
