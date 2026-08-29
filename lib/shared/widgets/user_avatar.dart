import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:presenza/config/theme/app_colors.dart';

/// A robust, crash-proof avatar widget that safely renders:
/// - Base64 Data URIs (with complete try-catch decoding safety)
/// - HTTP/HTTPS network URLs
/// - Fallback initials
/// - Optional edit badge
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.radius = 36,
    this.fontSize,
    this.onTap,
    this.showEditBadge = false,
  });

  Uint8List? _tryDecodeBase64(String uri) {
    try {
      final parts = uri.split(',');
      if (parts.length > 1) {
        return base64Decode(parts[1].trim());
      }
      return base64Decode(uri.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFontSize = fontSize ?? (radius * 0.65);

    ImageProvider? imageProvider;
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      final trimmed = avatarUrl!.trim();
      if (trimmed.startsWith('data:')) {
        final bytes = _tryDecodeBase64(trimmed);
        if (bytes != null && bytes.isNotEmpty) {
          imageProvider = MemoryImage(bytes);
        }
      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        imageProvider = NetworkImage(trimmed);
      }
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null
          ? (exception, stackTrace) {
              debugPrint('UserAvatar load error: $exception');
            }
          : null,
      child: imageProvider == null
          ? Text(
              initials.isNotEmpty ? initials : '?',
              style: TextStyle(
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
              ),
            )
          : null,
    );

    if (!showEditBadge && onTap == null) {
      return avatar;
    }

    final content = showEditBadge
        ? Stack(
            children: [
              avatar,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(radius * 0.12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: radius * 0.35,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
