import '../localization/app_strings.dart';

/// §gadget — harmless table ornaments. A gadget never touches a rule, a
/// score or a card; it is paint on the felt and nothing more.
class TableGadget {
  const TableGadget({
    required this.id,
    required this.name,
    required this.entitlementId,
  });

  final String id;
  final String name;

  /// Server entitlement that unlocks this gadget; null = free.
  final String? entitlementId;

  String get tagline => switch (id) {
    'sigillo' => Strings.s.gadgetTaglineSigillo,
    _ => '',
  };
}

class TableGadgets {
  const TableGadgets._();

  /// Shop cosmetic — `gioco101_gadget_01` → entitlement `gadget.01`.
  /// "Sigillo del 101": a gold laurel seal struck into the felt below the
  /// discard pile, echoing the 101 medallion every card back carries.
  static const TableGadget sigillo = TableGadget(
    id: 'sigillo',
    name: 'Sigillo del 101',
    entitlementId: 'gadget.01',
  );

  static const List<TableGadget> all = [sigillo];

  static TableGadget? byId(String? id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}
