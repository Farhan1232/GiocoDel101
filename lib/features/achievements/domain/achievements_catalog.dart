import 'achievement.dart';

/// §41 — five earned badges plus the daily-challenge badge. Each one that
/// unlocks something says so, and everything it unlocks is cosmetic.
class AchievementsCatalog {
  const AchievementsCatalog._();

  static const String catena = 'catena';
  static const String rinascita = 'rinascita';
  static const String maestroSemi = 'maestro_semi';
  static const String manoPerfetta = 'mano_perfetta';
  static const String veterano = 'veterano';
  static const String sfidaGiorno = 'sfida_giorno';

  static const List<Achievement> all = [
    Achievement(
      id: catena,
      title: 'Catena!',
      description: 'Porta una catena di 2 fino a +6',
      icon: 'chain',
      unlocksThemeId: 'vesuvio',
      unlocksCardBackId: 'brace',
    ),
    Achievement(
      id: rinascita,
      title: 'Rinascita',
      description: 'Arriva a 101 esatti e torna a zero',
      icon: 'ring',
      unlocksCardBackId: null,
    ),
    Achievement(
      id: maestroSemi,
      title: 'Maestro dei Semi',
      description: 'Vinci dopo aver scelto tutti e quattro i semi col Cavallo',
      icon: 'suits',
      unlocksThemeId: 'maiolica',
      unlocksCardBackId: 'cobalto',
    ),
    Achievement(
      id: manoPerfetta,
      title: 'Mano Perfetta',
      description: 'Vinci un round senza pescare nemmeno una carta',
      icon: 'hand',
    ),
    Achievement(
      id: veterano,
      title: 'Veterano',
      description: 'Completa 25 partite',
      icon: 'trophy',
    ),
    Achievement(
      id: sfidaGiorno,
      title: 'Sfidante',
      description: 'Completa una Sfida del Giorno',
      icon: 'calendar',
      unlocksCardBackId: 'notturno',
    ),
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
