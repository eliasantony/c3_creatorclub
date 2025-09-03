// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  uid: json['uid'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  profession: json['profession'] as String?,
  niche: json['niche'] as String?,
  photoUrl: json['photoUrl'] as String?,
  membershipTier: json['membershipTier'] as String? ?? 'basic',
  stripeCustomerId: json['stripeCustomerId'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'profession': instance.profession,
      'niche': instance.niche,
      'photoUrl': instance.photoUrl,
      'membershipTier': instance.membershipTier,
      'stripeCustomerId': instance.stripeCustomerId,
    };
