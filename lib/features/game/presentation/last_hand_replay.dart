import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/motion.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/history_entry.dart';
import '../domain/game_card.dart';
import '../domain/game_state.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/cards/playing_card.dart';
import '../../../core/widgets/cards/card_names.dart';
import '../../../core/widgets/premium_button.dart';

/// §36 "Rivedi ultima mano" — replays the closing moves.
///
/// It reads the action history the engine already keeps, so nothing extra is
/// recorded during play and there is no separate replay screen: this is an
/// overlay over the round results.
class LastHandReplay extends StatefulWidget {
  const LastHandReplay({
    super.key,
    required this.match,
    required this.onClose,
    this.accent,
  });

  final GameState match;
  final VoidCallback onClose;
  final Color? accent;

  /// How many closing actions to show.
  static const int window = 6;

  static bool isAvailable(GameState match) =>
      match.history.any((a) => a.type == HistoryEntryType.play);

  @override
  State<LastHandReplay> createState() => _LastHandReplayState();
}

class _LastHandReplayState extends State<LastHandReplay> {
  late final List<HistoryEntry> _steps;
  int _index = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final relevant = widget.match.history
        .where(
          (a) =>
              a.type == HistoryEntryType.play ||
              a.type == HistoryEntryType.draw ||
              a.type == HistoryEntryType.penaltyDraw ||
              a.type == HistoryEntryType.skip,
        )
        .toList();
    _steps = relevant.length <= LastHandReplay.window
        ? relevant
        : relevant.sublist(relevant.length - LastHandReplay.window);
    _advance();
  }

  void _advance() {
    _timer?.cancel();
    if (_index + 1 >= _steps.length) {
      setState(() => _index = _steps.length - 1);
      return;
    }
    setState(() => _index++);
    _timer = Timer(Motion.scale(const Duration(milliseconds: 700)), _advance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _nameOf(String id) => widget.match.playerById(id)?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.antiqueGold;
    final shown = _index < 0
        ? <HistoryEntry>[]
        : _steps.take(_index + 1).toList();
    final current = shown.isEmpty ? null : shown.last;

    return GestureDetector(
      onTap: widget.onClose,
      child: ColoredBox(
        color: AppColors.inkDeep.withValues(alpha: 0.92),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Strings.s.replayLastHand.toUpperCase(),
                  style: AppText.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        _step(shown[i], i, shown.length),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 44,
                  child: current == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Text(
                              _nameOf(current.playerId),
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                            Text(_describe(current), style: AppText.caption),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PremiumButton(
                      label: Strings.s.replayAgain,
                      size: ButtonSize.small,
                      variant: ButtonVariant.secondary,
                      expand: false,
                      onPressed: () {
                        setState(() => _index = -1);
                        _advance();
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    PremiumButton(
                      label: Strings.s.commonClose,
                      size: ButtonSize.small,
                      variant: ButtonVariant.ghost,
                      expand: false,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(HistoryEntry action, int i, int total) {
    final isLatest = i == total - 1;
    final offset = (i - (total - 1)) * 16.0;
    final card = action.card;

    return TweenAnimationBuilder<double>(
      key: ValueKey('$i-${action.card?.id}-${action.type}'),
      tween: Tween(begin: 0, end: 1),
      duration: Motion.scale(AppDurations.cardPlay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(offset * t, (1 - t) * -50),
        child: Opacity(
          opacity: (0.35 + t * 0.65) * (isLatest ? 1 : 0.55),
          child: child,
        ),
      ),
      child: Transform.rotate(
        angle: (i - (total - 1)) * 0.06,
        child: card != null
            ? PlayingCard(
                width: 96,
                card: card,
                elevation: isLatest ? 1.4 : 0.4,
              )
            : _tokenCard(action),
      ),
    );
  }

  Widget _tokenCard(HistoryEntry action) {
    final label = switch (action.type) {
      HistoryEntryType.draw => '+1',
      HistoryEntryType.penaltyDraw => '+${action.count ?? 0}',
      HistoryEntryType.skip => '×',
      _ => '',
    };
    return Container(
      width: 96,
      height: 96 * CardMetrics.aspect,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(96 * 0.075),
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.hairline),
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppText.scoreLarge),
    );
  }

  String _describe(HistoryEntry action) {
    final s = Strings.s;
    return switch (action.type) {
      HistoryEntryType.play => _cardName(action.card),
      HistoryEntryType.draw => s.drawCard,
      HistoryEntryType.penaltyDraw => '${s.takePenalty} +${action.count ?? 0}',
      HistoryEntryType.skip => s.turnSkipped,
      _ => '',
    };
  }

  static String _cardName(GameCard? card) =>
      card == null ? '' : cardDisplayName(card);
}
