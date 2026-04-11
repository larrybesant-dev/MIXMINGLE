import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/network_image_url.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';

class FriendTileAction {
  const FriendTileAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class FriendTile extends StatelessWidget {
  const FriendTile({
    required this.user,
    required this.statusLabel,
    required this.statusColor,
    required this.actions,
    this.statusIcon,
    this.onTap,
    super.key,
  });

  final UserModel user;
  final String statusLabel;
  final Color statusColor;
  final IconData? statusIcon;
  final List<FriendTileAction> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = sanitizeNetworkImageUrl(user.avatarUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: VelvetNoir.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VelvetNoir.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: VelvetNoir.surfaceHighest,
                        backgroundImage: avatarUrl == null
                            ? null
                            : CachedNetworkImageProvider(avatarUrl),
                        child: avatarUrl == null
                            ? Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: VelvetNoir.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: VelvetNoir.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VelvetNoir.surface,
                              width: 2,
                            ),
                          ),
                          child: statusIcon == null
                              ? Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Icon(statusIcon, size: 10, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VelvetNoir.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions
                      .map(
                        (action) => OutlinedButton.icon(
                          onPressed: action.onPressed,
                          icon: Icon(action.icon, size: 16),
                          label: Text(action.label),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VelvetNoir.onSurface,
                            side: BorderSide(
                              color: VelvetNoir.outlineVariant.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}