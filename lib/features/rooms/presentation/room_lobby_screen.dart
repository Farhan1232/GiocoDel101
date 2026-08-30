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
import '../../online/application/online_match_launcher.dart';
import '../../online/domain/online_match_models.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../application/rooms_repository.dart';
import '../domain/remote_room.dart';
import '../domain/room_models.dart';

/// §K — the waiting room.
///
/// Renders entirely from a [RoomLobbyState]. Given a [RemoteRoom] it shows
/// the real code and the real seats, kept fresh by Realtime (with a slow
/// poll underneath and a presence heartbeat), lets guests toggle Ready, lets
/// the host start once every seat is filled and ready, and takes everyone
/// to the table the moment the server has dealt. Given only a [RoomConfig]
/// or a code it builds the local pending state and says the service is not
/// connected. No seat is ever shown as filled by an invented player.
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
  Timer? _heartbeat;
  RoomWatch? _watch;
  bool _leaving = false;
  bool _starting = false;
  bool _launched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is RemoteRoom) {
      _room = args;
      _state = _fromRemote(args);
      final rooms = Get.find<BackendServices>().rooms;
      _watch = rooms.watch(args.id, () => unawaited(_poll()));
      // Realtime first; the poll is the safety net for a missed event.
      _refresh = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
      _heartbeat = Timer.periodic(
        const Duration(seconds: 8),
        (_) => rooms.heartbeat(args.id),
      );
      unawaited(rooms.heartbeat(args.id));
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
    _heartbeat?.cancel();
    unawaited(_watch?.call());
    super.dispose();
  }

  bool get _isLive => _room != null;
  String? get _self => Get.find<SessionController>().current?.userId;

  RoomLobbyState _fromRemote(RemoteRoom room) {
    final self = _self;
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

  bool _polling = false;
  bool _pollAgain = false;

  /// Coalesced: a Realtime hint or a tick that lands during a load asks for
  /// one more load afterwards, never a pile-up, and never a stale reply
  /// painted over a newer one.
  Future<void> _poll() async {
    if (_polling) {
      _pollAgain = true;
      return;
    }
    _polling = true;
    try {
      do {
        _pollAgain = false;
        await _pollOnce();
      } while (_pollAgain && mounted && !_leaving && !_launched);
    } finally {
      _polling = false;
    }
  }

  Future<void> _pollOnce() async {
    final room = _room;
    if (room == null || _leaving || _launched) return;
    final rooms = Get.find<BackendServices>().rooms;
    try {
      final next = await rooms.load(room.id);
      if (!mounted || _leaving || _launched) return;
      if (next == null || next.status == 'cancelled') {
        _refresh?.cancel();
        Get.back<void>();
        return;
      }
      setState(() {
        _room = next;
        _state = _fromRemote(next);
      });
      if (next.hasStarted) {
        await _enterMatch(next.matchId!);
        return;
      }
      // A quick-match room starts itself: the first seat deals as soon as
      // everyone is in; any other seat may press Start if it does not.
      if (next.isQuick &&
          next.isOpen &&
          next.isFull &&
          next.hostId == _self &&
          !_starting) {
        unawaited(_start());
      }
    } on RoomException {
      // A failed refresh keeps the last known seats; the next tick retries.
    }
  }

  Future<void> _enterMatch(String matchId) async {
    if (_launched) return;
    _launched = true;
    _refresh?.cancel();
    _heartbeat?.cancel();
    try {
      await OnlineMatchLauncher.launch(matchId, replace: true);
    } on OnlineException catch (e) {
      _launched = false;
      if (mounted) setState(() => _error = _enterFailure(e));
    }
  }

  Future<void> _start() async {
    final room = _room;
    if (room == null || _starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final matchId = await Get.find<BackendServices>().matches.startRoom(
        room.id,
      );
      await _enterMatch(matchId);
    } on OnlineException catch (e) {
      if (!mounted) return;
      setState(() => _error = Strings.s.lobbyStartFailed(_reason(e)));
      unawaited(_poll());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Every server code the start op can answer with, in the player's
  /// language. Anything unexpected gets the generic line — never the raw
  /// code or an exception string.
  String _reason(OnlineException e) => switch (e.detail) {
    'room_not_full' => Strings.s.lobbyWaitingForPlayers,
    'not_everyone_ready' => Strings.s.lobbyNotReady,
    'not_the_host' => Strings.s.lobbyWaitingForHost,
    'room_not_startable' ||
    'room_changed' ||
    'already_in_match' => Strings.s.roomAlreadyStarted,
    _ => switch (e.error) {
      OnlineError.network ||
      OnlineError.unavailable => Strings.s.onlineUnavailableRetry,
      OnlineError.notSignedIn => Strings.s.onlineSignInRequired,
      _ => Strings.s.commonErrorBody,
    },
  };

  String _enterFailure(OnlineException e) => switch (e.error) {
    OnlineError.network ||
    OnlineError.unavailable => Strings.s.onlineUnavailableRetry,
    OnlineError.notSignedIn => Strings.s.onlineSignInRequired,
    OnlineError.notParticipant => Strings.s.onlineMatchAbandoned,
    _ => Strings.s.commonErrorBody,
  };

  Future<void> _toggleReady() async {
    final room = _room;
    if (room == null) return;
    final me = room.seats.where((s) => s.userId == _self).firstOrNull;
    if (me == null) return;
    try {
      await Get.find<BackendServices>().rooms.setReady(room.id, !me.isReady);
      await _poll();
    } on RoomException {
      // The next poll shows the truth either way.
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
      _heartbeat?.cancel();
      try {
        await Get.find<BackendServices>().rooms.leave(room.id);
      } on RoomException {
        // Leaving is best effort; a stale seat expires server-side.
      }
      if (room.isQuick) {
        unawaited(Get.find<BackendServices>().matchmaking.cancel());
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
      backgroundColor: AppColors.surfaceRaised,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.hairline,
      borderWidth: 1,
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final room = _room;
    final now = DateTime.now().toUtc();
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
        final me = room?.seats.where((x) => x.userId == _self).firstOrNull;
        final canStart =
            room != null &&
            room.isOpen &&
            room.isFull &&
            room.everyoneReady &&
            (_state.selfIsHost || room.isQuick) &&
            !_starting;
        final String hint;
        if (!_isLive || room == null) {
          hint = s.authBackendPending;
        } else if (_starting || room.hasStarted) {
          hint = s.lobbyStarting;
        } else if (!room.isFull) {
          hint = s.lobbyWaitingForPlayers;
        } else if (!room.everyoneReady) {
          hint = s.lobbyNotReady;
        } else if (!_state.selfIsHost && !room.isQuick) {
          hint = s.lobbyWaitingForHost;
        } else {
          hint = '';
        }
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
                readyLabel: _connected(room, seat, now)
                    ? s.lobbyReady
                    : s.lobbyAway,
                waitingLabel: s.lobbyNotReady,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (_isLive && me != null && !me.isHost)
              PremiumButton(
                label: me.isReady ? s.lobbyNotReadyToggle : s.lobbyReadyToggle,
                variant: me.isReady
                    ? ButtonVariant.secondary
                    : ButtonVariant.primary,
                accent: accent,
                icon: AppIcon.check,
                onPressed: room!.isOpen ? _toggleReady : null,
              ),
            if (!_isLive || _state.selfIsHost || room!.isQuick)
              PremiumButton(
                label: s.lobbyStart,
                accent: accent,
                onPressed: canStart ? _start : null,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? hint,
              style: AppText.caption.copyWith(
                color: _error != null
                    ? AppColors.terracottaCoral
                    : AppColors.textMuted,
              ),
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

  bool _connected(RemoteRoom? room, RoomSeat seat, DateTime now) {
    if (room == null || seat.isEmpty) return true;
    final remote = room.seats.where((x) => x.seat == seat.index).firstOrNull;
    return remote == null || remote.isConnectedAt(now);
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
