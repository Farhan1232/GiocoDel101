import '../../../app/localization/app_strings.dart';

/// What kind of cosmetic a shop product unlocks.
enum CosmeticKind { tableTheme, cardBack, deckStyle, gadget }

/// One purchasable cosmetic: a store product id, the server entitlement it
/// grants, and the cosmetic it unlocks in the app.
///
/// All five products are **permanent non-consumables** — bought once, owned
/// forever, restorable, no expiry, no gameplay effect. The displayed price is
/// ALWAYS the store's own localized metadata (`ProductDetails.price`); nothing
/// here or anywhere else in the app hard-codes a price, so the client can
/// re-price in Play Console / App Store Connect without a code change.
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.entitlement,
    required this.kind,
    required this.cosmeticId,
  });

  /// The store product id — identical on Google Play and the App Store
  /// (docs/FINAL_IAP_PRODUCT_IDS.md is the canonical table).
  final String id;

  /// The server entitlement key `verify-purchase` grants for this product.
  /// One product, one entitlement: ownership is per item, never one global
  /// premium flag.
  final String entitlement;

  final CosmeticKind kind;

  /// Id of the [TableTheme] / [CardBackDesign] / deck style / gadget this
  /// product unlocks.
  final String cosmeticId;

  /// Display name shown in the shop (Italian primary, localized).
  String get displayName => switch (id) {
    ShopCatalog.tableGoldId => Strings.s.shopItemTableGold,
    ShopCatalog.tableClassicId => Strings.s.shopItemTableClassic,
    ShopCatalog.deckSpecialId => Strings.s.shopItemDeckSpecial,
    ShopCatalog.cardBackGoldId => Strings.s.shopItemCardBackGold,
    _ => Strings.s.shopItemGadget,
  };

  /// One line of description under the name in the shop.
  String get description => switch (id) {
    ShopCatalog.tableGoldId => Strings.s.shopItemTableGoldBody,
    ShopCatalog.tableClassicId => Strings.s.shopItemTableClassicBody,
    ShopCatalog.deckSpecialId => Strings.s.shopItemDeckSpecialBody,
    ShopCatalog.cardBackGoldId => Strings.s.shopItemCardBackGoldBody,
    _ => Strings.s.shopItemGadgetBody,
  };
}

/// The five cosmetic products. These ids are canonical: the client creates
/// exactly these in Google Play Console and App Store Connect
/// (docs/IAP_STORE_SETUP.md), and the server's allow-list carries exactly
/// this set (supabase/functions/verify-purchase/verify.ts).
class ShopCatalog {
  const ShopCatalog._();

  static const String tableGoldId = 'gioco101_table_gold';
  static const String tableClassicId = 'gioco101_table_classic';
  static const String deckSpecialId = 'gioco101_deck_special';
  static const String cardBackGoldId = 'gioco101_cardback_gold';
  static const String gadgetId = 'gioco101_gadget_01';

  static const List<ShopProduct> products = [
    ShopProduct(
      id: tableGoldId,
      entitlement: 'table.gold',
      kind: CosmeticKind.tableTheme,
      cosmeticId: 'tavolo_oro',
    ),
    ShopProduct(
      id: tableClassicId,
      entitlement: 'table.classic',
      kind: CosmeticKind.tableTheme,
      cosmeticId: 'tavolo_classico',
    ),
    ShopProduct(
      id: deckSpecialId,
      entitlement: 'deck.special',
      kind: CosmeticKind.deckStyle,
      cosmeticId: 'inciso_oro',
    ),
    ShopProduct(
      id: cardBackGoldId,
      entitlement: 'cardback.gold',
      kind: CosmeticKind.cardBack,
      cosmeticId: 'oro_reale',
    ),
    ShopProduct(
      id: gadgetId,
      entitlement: 'gadget.01',
      kind: CosmeticKind.gadget,
      cosmeticId: 'sigillo',
    ),
  ];

  /// What a card shows before Google Play has answered with the real price.
  ///
  /// The store's own localized `ProductDetails.price` always wins and is what
  /// the player is actually charged — this is a label so a card can be read
  /// and tapped while the products are still being configured in the console,
  /// nothing more. It is never used to complete a purchase.
  static const String indicativePrice = '€4,99';

  static Set<String> get productIds => {for (final p in products) p.id};

  static ShopProduct? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  static ShopProduct? byEntitlement(String entitlement) {
    for (final p in products) {
      if (p.entitlement == entitlement) return p;
    }
    return null;
  }
}
