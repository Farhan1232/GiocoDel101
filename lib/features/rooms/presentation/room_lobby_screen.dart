import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/network_banner.dart';
import '../../../core/widgets/player_slot.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/room_models.dart';

/// §K — the waiting room.
///
/// Renders entirely from a [RoomLobbyState]. Session 3 will feed it a live
/// state from the backend; today it builds one locally with only the host
/// seated, and no seat is ever shown as filled by an invented player.
class RoomLobbyScreen extends StatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  late final SettingsController _settings = Get.find<SettingsController>();
  late final RoomLobbyState _state = _initialState();

  RoomLobbyState _initialState() {
    final args = Get.arguments;
    // Arrived from Create Room with a config, or from Join Room with a code.
    final config = args is RoomConfig ? args : const RoomConfig();
    final code = args is String ? args : '';
    return RoomLobbyState.pending(
      config: config,
      hostNickname: _settings.settings.playerName,
      hostAvatarId: _settings.settings.avatarId,
      code: code,
    );
  }

  Future<void> _leave() async {
    final s = Strings.s;
    final ok = await AppDialog.confirm(
      title: s.lobbyLeave,
      body: s.exitBody,
      confirmLabel: s.exit,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (ok) Get.back<void>();
  }

  Future<void> _share() async {
    final s = Strings.s;
    if (_state.code.isEmpty) {
      await AppDialog.notice(
        title: s.lobbyShare,
        body: s.authBackendPending,
        dismissLabel: s.gotIt,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: _state.code));
    Get.snackbar(s.lobbyShare, s.lobbyCopied,
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    return ScreenScaffold(
      title: s.lobbyTitle,
      onBack: _leave,
      banner: OnlineStatus.isConfigured
          ? null
          : NetworkStatusBanner(
              status: NetworkStatus.offline,
              connectingLabel: s.networkReconnecting,
              offlineLabel: s.commonComingSoon,
            ),
      child: Obx(() {
        final accent = _settings.theme.accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            _codePanel(s, accent),
            const SizedBox(height: AppSpacing.xl),
            SectionHeading(
              s.playersCount.toUpperCase(),
              trailing: Text(
                '${_state.filledSeats}/${_state.seats.length}',
                style: AppText.label,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final seat in _state.seats) ...[
              PlayerSlotTile(
                emptyLabel: _state.code.isEmpty
                    ? s.commonComingSoon
                    : s.lobbyEmptySlot,
                nickname: seat.nickname,
                avatarId: seat.avatarId,
                isHost: seat.isHost,
                isReady: seat.isReady,
                isSelf: seat.isSelf,
                hostLabel: s.lobbyHost,
                readyLabel: s.lobbyReady,
                waitingLabel: s.lobbyNotReady,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (_state.selfIsHost)
              PremiumButton(
                label: s.lobbyStart,
                accent: accent,
                // The host cannot start a match that has no other players and
                // no service to run it.
                onPressed: null,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.authBackendPending,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: s.lobbyLeave,
              variant: ButtonVariant.ghost,
              size: ButtonSize.medium,
              onPressed: _leave,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }

  Widget _codePanel(AppLocalizations s, Color accent) {
    final hasCode = _state.code.isNotEmpty;
    return AppPanel(
      accent: accent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(s.lobbyRoomCode, style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hasCode ? _state.code : '••••••',
              style: AppText.heroTitle.copyWith(
                fontSize: 34,
                letterSpacing: 10,
                color: hasCode ? AppColors.goldLight : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumButton(
            label: s.lobbyShare,
            icon: AppIcon.reactions,
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
            expand: false,
            onPressed: _share,
          ),
        ],
      ),
    );
  }
}
