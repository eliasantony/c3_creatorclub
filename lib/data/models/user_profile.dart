import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// User Profile as per PRD
/// Fields: name, email, phone, profession/niche, profile picture, membershipTier
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String name,
    required String email,
    String? phone,
    String? profession,
    String? niche,
    String? photoUrl,
    @Default('basic') String membershipTier, // 'basic' | 'premium'
    String? stripeCustomerId,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
