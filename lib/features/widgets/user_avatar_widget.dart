import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserAvatarWidget extends StatefulWidget {
  final String? avatarBase64;
  final double radius;
  final IconData fallbackIcon;
  final Color fallbackBackgroundColor;
  final Color fallbackIconColor;
  final double borderWidth;
  final Color borderColor;

  const UserAvatarWidget({
    super.key,
    required this.avatarBase64,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.fallbackBackgroundColor = Colors.blue,
    this.fallbackIconColor = Colors.white,
    this.borderWidth = 0,
    this.borderColor = Colors.white,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  Uint8List? _cachedBytes;
  String? _lastBase64;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarBase64 != widget.avatarBase64) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    final raw = widget.avatarBase64;
    if (raw == null || raw.isEmpty) {
      _cachedBytes = null;
      _lastBase64 = null;
      return;
    }
    if (raw == _lastBase64 && _cachedBytes != null) return;

    try {
      _cachedBytes = base64Decode(raw);
      _lastBase64 = raw;
    } catch (e) {
      debugPrint('Ошибка декодирования Base64 аватарки: $e');
      _cachedBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.fallbackBackgroundColor,
      backgroundImage: _cachedBytes != null ? MemoryImage(_cachedBytes!) : null,
      child: _cachedBytes == null
          ? Icon(
              widget.fallbackIcon,
              size: widget.radius * 1.1,
              color: widget.fallbackIconColor,
            )
          : null,
    );

    if (widget.borderWidth > 0) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}