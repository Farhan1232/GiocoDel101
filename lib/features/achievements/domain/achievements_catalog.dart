import '../../../app/localization/app_strings.dart';
import '../../../core/widgets/app_icons.dart';
import 'achievement.dart';

/// §41 — every badge in the game.
///
/// The six the UI brief names (Prima Vittoria, Centouno!, Vendetta, Maestro
/// del Nove, Imbattibile, Veterano) are all here. Three older badges that
/// already unlock table dressings — Catena, Mano Perfetta and Sfidante — were
/// kept so no player loses a cosmetic they had earned; their ids are unchanged
/// for exactly that reason.
class AchievementsCatalog {
  const AchievementsCatalog._();

  static const String primaVittoria = 'prima_vittoria';

  /// Historic id. Displayed as "Centouno!".
  static const String centouno = 'rinascita';

  static const String vendetta = 'vendetta';

  /// Historic id. Displayed as "Maestro del Nove".
  static const String maestroNove = 'maestro_semi';

  static const String imbattibile = 'imbattibile';
  static const String veterano = 'veterano';

  static const String catena = 'catena';
  static const String manoPerfetta = 'mano_perfetta';
  static const String sfidante = 'sfida_giorno';

  /// Kept as aliases so older call sites still read naturally.
  static const String rinascita = centouno;
  static const String maestroSemi = maestroNove;
  static const String sfidaGiorno = sfidante;

  static const List<Achievement> all = [
    Achievement(id: primaVittoria, icon: AppIcon.trophy),
    Achievement(
      id: centouno,
      icon: AppIcon.ring,
      unlocksCardBackId: 'notturno',
    ),
    Achievement(id: vendetta, icon: AppIcon.restart),
    Achievement(
      id: maestroNove,
      icon: AppIcon.suits,
      unlocksThemeId: 'maiolica',
      unlocksCardBackId: 'cobalto',
    ),
    Achievement(id: imbattibile, icon: AppIcon.stats),
    Achievement(id: veterano, icon: AppIcon.players),
    Achievement(
      id: catena,
      icon: AppIcon.chain,
      unlocksThemeId: 'vesuvio',
      unlocksCardBackId: 'brace',
    ),
    Achievement(id: manoPerfetta, icon: AppIcon.hand),
    Achievement(id: sfidante, icon: AppIcon.calendar),
  ];

  /// The six the UI brief lists, in the order it lists them.
  static const List<String> featured = [
    primaVittoria,
    centouno,
    vendetta,
    maestroNove,
    imbattibile,
    veterano,
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}

/// Resolves a badge id to localized copy.
extension AchievementCopy on AppLocalizations {
  String achievementTitle(String id) => switch (id) {
    AchievementsCatalog.primaVittoria => achPrimaVittoriaTitle,
    AchievementsCatalog.centouno => achCentounoTitle,
    AchievementsCatalog.vendetta => achVendettaTitle,
    AchievementsCatalog.maestroNove => achMaestroNoveTitle,
    AchievementsCatalog.imbattibile => achImbattibileTitle,
    AchievementsCatalog.veterano => achVeteranoTitle,
    AchievementsCatalog.catena => achCatenaTitle,
    AchievementsCatalog.manoPerfetta => achManoPerfettaTitle,
    AchievementsCatalog.sfidante => achSfidanteTitle,
    _ => achievements,
  };

  String achievementDescription(String id) => switch (id) {
    AchievementsCatalog.primaVittoria => achPrimaVittoriaBody,
    AchievementsCatalog.centouno => achCentounoBody,
    AchievementsCatalog.vendetta => achVendettaBody,
    AchievementsCatalog.maestroNove => achMaestroNoveBody,
    AchievementsCatalog.imbattibile => achImbattibileBody,
    AchievementsCatalog.veterano => achVeteranoBody,
    AchievementsCatalog.catena => achCatenaBody,
    AchievementsCatalog.manoPerfetta => achManoPerfettaBody,
    AchievementsCatalog.sfidante => achSfidanteBody,
    _ => '',
  };
}
