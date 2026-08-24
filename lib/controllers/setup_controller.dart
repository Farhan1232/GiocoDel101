import 'package:get/get.dart';

import '../models/game_rules_config.dart';
import '../models/match_state.dart';
import '../models/player_type.dart';
import '../storage/local_storage.dart';
import '../storage/storage_keys.dart';

/// §26 — the choices made on the setup screen, remembered between sessions.
class SetupController extends GetxController {
  SetupController(this._storage, {required BotDifficulty defaultDifficulty})
      : difficulty = defaultDifficulty.obs;

  final LocalStorage _storage;

  final Rx<GameMode> mode = GameMode.vsComputer.obs;
  final RxInt playerCount = 2.obs;
  final Rx<BotDifficulty> difficulty;
  final RxBool advancedOpen = false.obs;

  // Advanced rules — every one of these maps to a field of GameRulesConfig.
  final RxInt startingHand = 5.obs;
  final RxBool stackTwos = true.obs;
  final RxBool wildNine = true.obs;
  final RxBool voluntaryDraw = true.obs;
  final RxBool eliminate = true.obs;
  final RxBool exactReset = true.obs;

  /// Names for the extra people in Pass & Play (index 0 is the owner).
  final RxList<String> passAndPlayNames =
      <String>['Giocatore 2', 'Giocatore 3', 'Giocatore 4'].obs;

  @override
  void onInit() {
    super.onInit();
    final json = _storage.readJson(StorageKeys.setupPreferences);
    if (json == null) return;
    mode.value = GameMode.fromKey(json['mode'] as String? ?? 'vsComputer');
    playerCount.value = (json['playerCount'] as num?)?.toInt().clamp(2, 4) ?? 2;
    difficulty.value =
        BotDifficulty.fromKey(json['difficulty'] as String? ?? 'normal');
    startingHand.value =
        (json['startingHand'] as num?)?.toInt().clamp(3, 10) ?? 5;
    stackTwos.value = json['stackTwos'] as bool? ?? true;
    wildNine.value = json['wildNine'] as bool? ?? true;
    voluntaryDraw.value = json['voluntaryDraw'] as bool? ?? true;
    eliminate.value = json['eliminate'] as bool? ?? true;
    exactReset.value = json['exactReset'] as bool? ?? true;
    final names = (json['names'] as List?)?.whereType<String>().toList();
    if (names != null && names.length == 3) passAndPlayNames.value = names;
  }

  Future<void> persist() => _storage.writeJson(StorageKeys.setupPreferences, {
        'mode': mode.value.key,
        'playerCount': playerCount.value,
        'difficulty': difficulty.value.key,
        'startingHand': startingHand.value,
        'stackTwos': stackTwos.value,
        'wildNine': wildNine.value,
        'voluntaryDraw': voluntaryDraw.value,
        'eliminate': eliminate.value,
        'exactReset': exactReset.value,
        'names': passAndPlayNames.toList(),
      });

  /// Builds the rule set from the advanced panel. Defaults come from
  /// [GameRulesConfig] itself, never from literals scattered here (§71).
  GameRulesConfig buildRules() => const GameRulesConfig().copyWith(
        startingHandSize: startingHand.value,
        stackDrawTwos: stackTwos.value,
        wildNineCanAlwaysPlay: wildNine.value,
        allowVoluntaryDraw: voluntaryDraw.value,
        eliminateAbove101: eliminate.value,
        exact101ResetsToZero: exactReset.value,
      );

  bool get isDefaultRules {
    const d = GameRulesConfig();
    return startingHand.value == d.startingHandSize &&
        stackTwos.value == d.stackDrawTwos &&
        wildNine.value == d.wildNineCanAlwaysPlay &&
        voluntaryDraw.value == d.allowVoluntaryDraw &&
        eliminate.value == d.eliminateAbove101 &&
        exactReset.value == d.exact101ResetsToZero;
  }

  void resetRules() {
    const d = GameRulesConfig();
    startingHand.value = d.startingHandSize;
    stackTwos.value = d.stackDrawTwos;
    wildNine.value = d.wildNineCanAlwaysPlay;
    voluntaryDraw.value = d.allowVoluntaryDraw;
    eliminate.value = d.eliminateAbove101;
    exactReset.value = d.exact101ResetsToZero;
  }
}
