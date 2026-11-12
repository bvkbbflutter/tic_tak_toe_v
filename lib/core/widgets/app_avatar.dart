import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool showOnlineBadge;
  final bool isOnline;
  final bool isInGame;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.showOnlineBadge = false,
    this.isOnline = false,
    this.isInGame = false,
  });

  String get _initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _avatarBgColor(String name) {
    final colors = [
      Colors.indigo,
      Colors.deepPurple,
      Colors.teal,
      Colors.blueGrey,
      Colors.orange.shade800,
      Colors.pink.shade700,
      Colors.cyan.shade800,
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    final validUrl = photoUrl != null && photoUrl!.trim().isNotEmpty && photoUrl!.startsWith('http');

    if (validUrl) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: _avatarBgColor(name),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            );
          },
        ),
      );
    } else {
      avatarChild = _buildFallback();
    }

    if (!showOnlineBadge) {
      return avatarChild;
    }

    Color badgeColor = Colors.grey;
    if (isInGame) {
      badgeColor = Colors.amber;
    } else if (isOnline) {
      badgeColor = Colors.green;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarChild,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _avatarBgColor(name),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
