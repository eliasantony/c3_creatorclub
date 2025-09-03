// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Room {

 String get id; String get name; String? get description; String? get neighborhood;// e.g., Neubau, Wieden
 int? get capacity; List<String> get facilities;// e.g., ['podcast','lighting','wifi']
 List<String> get photos; int? get openHourStart;// 6
 int? get openHourEnd;// 23
 int? get priceCents;// optional display price
 double? get rating;
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomCopyWith<Room> get copyWith => _$RoomCopyWithImpl<Room>(this as Room, _$identity);

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other.facilities, facilities)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.openHourStart, openHourStart) || other.openHourStart == openHourStart)&&(identical(other.openHourEnd, openHourEnd) || other.openHourEnd == openHourEnd)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.rating, rating) || other.rating == rating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,neighborhood,capacity,const DeepCollectionEquality().hash(facilities),const DeepCollectionEquality().hash(photos),openHourStart,openHourEnd,priceCents,rating);

@override
String toString() {
  return 'Room(id: $id, name: $name, description: $description, neighborhood: $neighborhood, capacity: $capacity, facilities: $facilities, photos: $photos, openHourStart: $openHourStart, openHourEnd: $openHourEnd, priceCents: $priceCents, rating: $rating)';
}


}

/// @nodoc
abstract mixin class $RoomCopyWith<$Res>  {
  factory $RoomCopyWith(Room value, $Res Function(Room) _then) = _$RoomCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? neighborhood, int? capacity, List<String> facilities, List<String> photos, int? openHourStart, int? openHourEnd, int? priceCents, double? rating
});




}
/// @nodoc
class _$RoomCopyWithImpl<$Res>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._self, this._then);

  final Room _self;
  final $Res Function(Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? neighborhood = freezed,Object? capacity = freezed,Object? facilities = null,Object? photos = null,Object? openHourStart = freezed,Object? openHourEnd = freezed,Object? priceCents = freezed,Object? rating = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,facilities: null == facilities ? _self.facilities : facilities // ignore: cast_nullable_to_non_nullable
as List<String>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,openHourStart: freezed == openHourStart ? _self.openHourStart : openHourStart // ignore: cast_nullable_to_non_nullable
as int?,openHourEnd: freezed == openHourEnd ? _self.openHourEnd : openHourEnd // ignore: cast_nullable_to_non_nullable
as int?,priceCents: freezed == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Room].
extension RoomPatterns on Room {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Room value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Room value)  $default,){
final _that = this;
switch (_that) {
case _Room():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Room value)?  $default,){
final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? neighborhood,  int? capacity,  List<String> facilities,  List<String> photos,  int? openHourStart,  int? openHourEnd,  int? priceCents,  double? rating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.neighborhood,_that.capacity,_that.facilities,_that.photos,_that.openHourStart,_that.openHourEnd,_that.priceCents,_that.rating);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? neighborhood,  int? capacity,  List<String> facilities,  List<String> photos,  int? openHourStart,  int? openHourEnd,  int? priceCents,  double? rating)  $default,) {final _that = this;
switch (_that) {
case _Room():
return $default(_that.id,_that.name,_that.description,_that.neighborhood,_that.capacity,_that.facilities,_that.photos,_that.openHourStart,_that.openHourEnd,_that.priceCents,_that.rating);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? neighborhood,  int? capacity,  List<String> facilities,  List<String> photos,  int? openHourStart,  int? openHourEnd,  int? priceCents,  double? rating)?  $default,) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.neighborhood,_that.capacity,_that.facilities,_that.photos,_that.openHourStart,_that.openHourEnd,_that.priceCents,_that.rating);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Room implements Room {
  const _Room({required this.id, required this.name, this.description, this.neighborhood, this.capacity, final  List<String> facilities = const <String>[], final  List<String> photos = const <String>[], this.openHourStart, this.openHourEnd, this.priceCents, this.rating}): _facilities = facilities,_photos = photos;
  factory _Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String? neighborhood;
// e.g., Neubau, Wieden
@override final  int? capacity;
 final  List<String> _facilities;
@override@JsonKey() List<String> get facilities {
  if (_facilities is EqualUnmodifiableListView) return _facilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facilities);
}

// e.g., ['podcast','lighting','wifi']
 final  List<String> _photos;
// e.g., ['podcast','lighting','wifi']
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  int? openHourStart;
// 6
@override final  int? openHourEnd;
// 23
@override final  int? priceCents;
// optional display price
@override final  double? rating;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomCopyWith<_Room> get copyWith => __$RoomCopyWithImpl<_Room>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other._facilities, _facilities)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.openHourStart, openHourStart) || other.openHourStart == openHourStart)&&(identical(other.openHourEnd, openHourEnd) || other.openHourEnd == openHourEnd)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.rating, rating) || other.rating == rating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,neighborhood,capacity,const DeepCollectionEquality().hash(_facilities),const DeepCollectionEquality().hash(_photos),openHourStart,openHourEnd,priceCents,rating);

@override
String toString() {
  return 'Room(id: $id, name: $name, description: $description, neighborhood: $neighborhood, capacity: $capacity, facilities: $facilities, photos: $photos, openHourStart: $openHourStart, openHourEnd: $openHourEnd, priceCents: $priceCents, rating: $rating)';
}


}

/// @nodoc
abstract mixin class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) _then) = __$RoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? neighborhood, int? capacity, List<String> facilities, List<String> photos, int? openHourStart, int? openHourEnd, int? priceCents, double? rating
});




}
/// @nodoc
class __$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(this._self, this._then);

  final _Room _self;
  final $Res Function(_Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? neighborhood = freezed,Object? capacity = freezed,Object? facilities = null,Object? photos = null,Object? openHourStart = freezed,Object? openHourEnd = freezed,Object? priceCents = freezed,Object? rating = freezed,}) {
  return _then(_Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,facilities: null == facilities ? _self._facilities : facilities // ignore: cast_nullable_to_non_nullable
as List<String>,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,openHourStart: freezed == openHourStart ? _self.openHourStart : openHourStart // ignore: cast_nullable_to_non_nullable
as int?,openHourEnd: freezed == openHourEnd ? _self.openHourEnd : openHourEnd // ignore: cast_nullable_to_non_nullable
as int?,priceCents: freezed == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
