import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../achievements/domain/achievements_catalog.dart';
import '../../auth/application/session_controller.dart';
import '../domain/shop_catalog.dart';

/// What happens when a player taps a cosmetic they do not own.
///
/// Before this existed a locked table or card back was simply inert — the tap
/// fell on the floor and the player was left guessing. Now every locked tile
/// answers:
///
/// * a cosmetic earned by playing says which achievement earns it;
/// * a cosmetic that is **bought** leads to the shop, and to the store's own
///   payment sheet for that exact item;
/// * with nobody signed in it leads to the account screens FIRST, because an
///   entitlement is granted to an account and to nothing else — a purchase
///   made by a signed-out player would have nowhere to land.
class CosmeticGate {
  const CosmeticGate._();

  /// The item a signed-out player was trying to buy when they were sent to
  /// the account screens. Those screens replace the whole stack on success,
  /// so without this the player would land on Home and have to find the
  /// locked tile again; with it, signing in continues the purchase they
  /// started. Cleared as soon as it is used, and on a cancelled sign-in it
  /// simply never fires.
  static String? _pendingProductId;

  /// Handles a tap on a locked cosmetic. [entitlementId] is the paid
  /// entitlement that unlocks it (`table.gold`, `deck.special`, …) or null
  /// when it is earned; [achievementId] is the badge that earns it.
  static Future<void> openLocked({
    String? entitlementId,
    String? achievementId,
  }) async {
    final s = Strings.s;

    if (entitlementId == null) {
      // Earned, not sold: name the achievement instead of selling anything.
      await AppDialog.notice(
        title: s.locked,
        body: achievementId == null
            ? s.locked
            : s.shopUnlockWithAchievement(s.achievementTitle(achievementId)),
        dismissLabel: s.gotIt,
      );
      return;
    }

    final product = ShopCatalog.byEntitlement(entitlementId);
    if (product == null) return;

    if (!Get.find<SessionController>().isSignedIn) {
      final go = await AppDialog.confirm(
        title: s.shopSignInRequiredTitle,
        body: s.shopSignInToBuyBody,
        confirmLabel: s.authSignIn,
        cancelLabel: s.cancel,
      );
      if (!go) return;
      _pendingProductId = product.id;
      await Get.toNamed<void>(AppRoutes.authLanding);
      return;
    }

    await Get.toNamed<void>(AppRoutes.shop, arguments: product.id);
  }

  /// Called by the account screens once someone is signed in. Continues the
  /// purchase that sent them there, if there was one.
  static Future<void> resumeAfterSignIn() async {
    final id = _pendingProductId;
    _pendingProductId = null;
    if (id == null || !Get.find<SessionController>().isSignedIn) return;
    await Get.toNamed<void>(AppRoutes.shop, arguments: id);
  }
}
