import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.photoUrl, this.size = 40, this.onTap});
  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Icon(Icons.person, color: theme.colorScheme.onSurface)
          : null,
    );
    if (onTap == null) return avatar;
    return InkWell(
      borderRadius: BorderRadius.circular(size),
      onTap: onTap,
      child: avatar,
    );
  }
}
