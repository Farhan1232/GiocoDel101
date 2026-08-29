import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_durations.dart';
import '../constants/app_spacing.dart';

/// What the connection is doing, as far as the interface is concerned.
///
/// Session 1 ships the shell only: nothing sets anything but [online],
/// because there is no network layer yet. Session 3 supplies the real values.
enum NetworkStatus { online, connecting, offline }

/// The strip that appears under the title bar when the connection is not
/// healthy. Collapses to nothing when [status] is [NetworkStatus.online].
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({
    super.key,
    required this.status,
    required this.connectingLabel,
    required this.offlineLabel,
  });

  final NetworkStatus status;
  final String connectingLabel;
  final String offlineLabel;

  @override
  Widget build(BuildContext context) {
    final visible = status != NetworkStatus.online;
    final offline = status == NetworkStatus.offline;
    final tint =
        offline ? AppColors.terracottaCoral : AppColors.mediterraneanTeal;

    return AnimatedSize(
      duration: AppDurations.quick,
      curve: Curves.easeOutCubic,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: tint.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        offline ? offlineLabel : connectingLabel,
                        style: AppText.caption.copyWith(color: tint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
