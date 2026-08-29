import 'package:get/get.dart';

import '../../game/domain/game_rules.dart';
import '../domain/room_models.dart';

/// Holds the room the player is configuring.
///
/// Pure local state: building a [RoomConfig] needs no network, and this
/// controller deliberately has no way to publish one. The Create button hands
/// the finished config to the lobby screen, which says plainly that the room
/// cannot be opened until the service is connected.
class CreateRoomController extends GetxController {
  final Rx<RoomConfig> config = const RoomConfig().obs;

  void setPlayerCount(int value) {
    if (value < 2 || value > 4) return;
    config.value = config.value.copyWith(playerCount: value);
  }

  void setName(String value) =>
      config.value = config.value.copyWith(name: value.trim());

  void setPrivate(bool value) =>
      config.value = config.value.copyWith(isPrivate: value);

  void setTurnTimer(TurnTimer value) =>
      config.value = config.value.copyWith(turnTimer: value);

  void setRules(GameRules value) =>
      config.value = config.value.copyWith(rules: value);

  void toggleStackTwos(bool value) =>
      setRules(config.value.rules.copyWith(stackDrawTwos: value));

  void toggleWildNine(bool value) =>
      setRules(config.value.rules.copyWith(wildNineCanAlwaysPlay: value));

  void toggleExactReset(bool value) =>
      setRules(config.value.rules.copyWith(exact101ResetsToZero: value));

  void toggleEliminate(bool value) =>
      setRules(config.value.rules.copyWith(eliminateAbove101: value));
}
