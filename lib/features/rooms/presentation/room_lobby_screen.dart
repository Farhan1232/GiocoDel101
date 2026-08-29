import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
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
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/remote_room.dart';
import '../domain/room_models.dart';

/// §K — the waiting room.
///
/// Renders entirely from a [RoomLobbyState]. Given a [RemoteRoom] (created or
/// joined through the backend) it shows the real code and the real seats,
/// refreshed every few seconds with a presence heartbeat, and leaving really
/// leaves. Given only a [RoomConfig] or a code it builds the local pending
/// state with the host seated and says the service is not connected. No
/// seat is ever shown as filled by an invented player, and Start stays
/// disabled: dealing the first hand is the authoritative match function of
/// the next session.
class RoomLobbyScreen extends StatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  late final SettingsController _settings = Get.find<SettingsController>();

  RemoteRoom? _room;
  late RoomLobbyState _state;
  Timer? _refresh;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is RemoteRoom) {
      _room = args;
      _state = _fromRemote(args);
      _refresh = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    } else {
      // Arrived from Create Room with a config, or from Join Room with a code.
      final config = args is RoomConfig ? args : const RoomConfig();
      final code = args is String ? args : '';
      _state = RoomLobbyState.pending(
        config: config,
        hostNickname: _settings.settings.playerName,
        hostAvatarId: _settings.settings.avatarId,
        code: code,
      );
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  bool get _isLive => _room != null;

  RoomLobbyState _fromRemote(RemoteRoom room) {
    final self = Get.find<SessionController>().current?.userId;
    final bySeat = {for (final s in room.seats) s.seat: s};
    return RoomLobbyState(
      code: room.code,
      config: RoomConfig(
        name: room.name,
        playerCount: room.maxPlayers,
        isPrivate: room.isPrivate,
        turnTimer: TurnTimer.values.firstWhere(
          (t) => t.seconds == room.turnTimerSeconds,
          orElse: () => TurnTimer.thirty,
        ),
      ),
      selfIsHost: room.hostId == self,
      seats: [
        for (var i = 0; i < room.maxPlayers; i++)
          if (bySeat[i] case final seat?)
            RoomSeat(
              index: i,
              nickname: seat.nickname,
              avatarId: seat.avatarId,
              isHost: seat.isHost,
              isReady: seat.isReady,
              isSelf: seat.userId == self,
            )
          else
            RoomSeat(index: i),
      ],
    );
  }

  Future<void> _poll() async {
    final room = _room;
    if (room == null || _leaving) return;
    final rooms = Get.find<BackendServices>().rooms;
    unawaited(rooms.heartbeat(room.id));
    try {
      final next = await rooms.load(room.id);
      if (!mounted || _leaving) return;
      if (next == null || !next.isOpen) {
        // Cancelled or started elsewhere: nothing to wait in any more.
        _refresh?.cancel();
        Get.back<void>();
        return;
      }
      setState(() {
        _room = next;
        _state = _fromRemote(next);
      });
    } on RoomException {
      // A failed refresh keeps the last known seats; the next tick retries.
    }
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
    if (!ok) return;
    final room = _room;
    if (room != null) {
      _leaving = true;
      _refresh?.cancel();
      try {
        await Get.find<BackendServices>().rooms.leave(room.id);
      } on RoomException {
        // Leaving is best effort; a stale seat expires server-side.
      }
    }
    Get.back<void>();
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
    Get.snackbar(
      s.lobbyShare,
      s.lobbyCopied,
      snackPosition: SnackPosition.BOTTOM,
    );
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
                emptyLabel: s.lobbyEmptySlot,
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
                // Dealing the first hand is the authoritative match function
                // (Session 4); until it exists the host cannot start.
                onPressed: null,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isLive ? s.lobbyStartPending : s.authBackendPending,
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
