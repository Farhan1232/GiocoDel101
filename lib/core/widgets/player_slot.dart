import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_icons.dart';
import 'app_panel.dart';
import 'avatar_medallion.dart';

/// One seat in a room, filled or waiting.
///
/// Presentational only: it is told whether the seat is taken, ready and
/// hosting, and never asks a network layer.
class PlayerSlotTile extends StatelessWidget {
  const PlayerSlotTile({
    super.key,
    required this.emptyLabel,
    this.nickname,
    this.avatarId,
    this.isHost = false,
    this.isReady = false,
    this.isSelf = false,
    this.hostLabel,
    this.readyLabel,
    this.waitingLabel,
    this.accent,
    this.onTap,
  });

  /// Shown when [nickname] is null.
  final String emptyLabel;

  final String? nickname;
  final String? avatarId;
  final bool isHost;
  final bool isReady;
  final bool isSelf;

  final String? hostLabel;
  final String? readyLabel;
  final String? waitingLabel;

  final Color? accent;
  final VoidCallback? onTap;

  bool get _empty => nickname == null;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.antiqueGold;
    final status = _empty ? null : (isReady ? readyLabel : waitingLabel);

    return AppPanel(
      onTap: onTap,
      accent: isSelf ? tint : null,
      tintStrength: _empty ? 0.25 : 0.6,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (_empty)
            _emptyMedallion()
          else
            AvatarMedallion(avatarId: avatarId ?? 'lucia', size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nickname ?? emptyLabel,
                  style: _empty
                      ? AppText.bodySmall.copyWith(color: AppColors.textMuted)
                      : AppText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    status,
                    style: AppText.caption.copyWith(
                      color: isReady
                          ? AppColors.mediterraneanTeal
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isHost && hostLabel != null) _tag(hostLabel!, tint),
        ],
      ),
    );
  }

  Widget _emptyMedallion() => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surfaceSunken,
      border: Border.all(color: AppColors.hairline),
    ),
    child: const Center(
      child: AppIconView(AppIcon.players, size: 18, color: AppColors.textMuted),
    ),
  );

  Widget _tag(String label, Color tint) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(color: tint.withValues(alpha: 0.5)),
    ),
    child: Text(label, style: AppText.caption.copyWith(color: tint)),
  );
}
