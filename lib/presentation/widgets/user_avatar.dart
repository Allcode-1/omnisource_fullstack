import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';

import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.username,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const palette = BoringAvatarPalette([
      Color(0xFF06111F),
      Color(0xFF0A84FF),
      Color(0xFF38BDF8),
      Color(0xFF22C55E),
      Color(0xFFE5F4FF),
    ]);

    final seed = username.trim().isEmpty ? 'user' : username.trim();
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.22),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: ClipOval(
        child: BoringAvatar(
          name: seed,
          type: BoringAvatarType.marble,
          palette: palette,
          shape: const OvalBorder(),
        ),
      ),
    );

    final wrapped = Semantics(
      label: 'Profile',
      button: onTap != null,
      child: avatar,
    );

    if (onTap == null) return wrapped;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: wrapped,
    );
  }
}
