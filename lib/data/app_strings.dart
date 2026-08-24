/// §38/§55 — every piece of user-facing copy in the game.
///
/// Italian is the base language. Adding English later means subclassing this
/// and overriding the getters that change; no widget needs to be touched:
///
/// ```dart
/// class AppStringsEn extends AppStrings {
///   @override String get play => 'PLAY';
/// }
/// Strings.use(AppStringsEn());
/// ```
class AppStrings {
  const AppStrings();

  String get languageCode => 'it';

  // Identity
  String get appName => 'Gioco del 101';
  String get appTagline => 'Il classico napoletano, rivisitato';

  // Home
  String get play => 'GIOCA';
  String get resumeMatch => 'Riprendi Partita';
  String get resumeMatchHint => 'Continua da dove eri rimasto';
  String get dailyChallenge => 'Sfida del Giorno';
  String get dailyChallengeDone => 'Sfida completata';
  String get howToPlay => 'Come si Gioca';
  String get howToPlayHint => 'Regole in un minuto';
  String get settings => 'Impostazioni';
  String get statistics => 'Statistiche';
  String get profile => 'Profilo';

  // Setup
  String get newGame => 'Nuova Partita';
  String get mode => 'Modalità';
  String get modeVsComputer => 'Vs Computer';
  String get modePassAndPlay => 'Passa & Gioca';
  String get playersCount => 'Giocatori';
  String get difficulty => 'Difficoltà';
  String get difficultyEasy => 'Facile';
  String get difficultyNormal => 'Normale';
  String get difficultyHard => 'Difficile';
  String get playerName => 'Il tuo nome';
  String get tableTheme => 'Tavolo';
  String get advancedRules => 'Regole avanzate';
  String get startMatch => 'INIZIA PARTITA';
  String get startingHand => 'Carte iniziali';
  String get ruleStackTwos => 'Somma dei 2';
  String get ruleStackTwosHint => 'I 2 si possono incatenare';
  String get ruleWildNine => 'Cavallo sempre giocabile';
  String get ruleWildNineHint => 'Il 9 cambia seme in ogni momento';
  String get ruleVoluntaryDraw => 'Pesca volontaria';
  String get ruleVoluntaryDrawHint => 'Puoi pescare anche se hai una carta';
  String get ruleEliminate => 'Eliminazione oltre 101';
  String get ruleEliminateHint => 'Chi supera 101 esce dalla partita';
  String get ruleExactReset => 'Ritorno a zero a 101';
  String get ruleExactResetHint => 'Esattamente 101 azzera il punteggio';

  // Table
  String get yourTurn => 'TOCCA A TE';
  String get turnSkipped => 'TURNO SALTATO';
  String get drawPile => 'Mazzo';
  String get discardPile => 'Scarti';
  String get activeSuit => 'Seme attivo';
  String get drawCard => 'Pesca';
  String get passTurn => 'Passa';
  String get playDrawn => 'Gioca la carta pescata';
  String get takePenalty => 'Prendi';
  String get chooseSuit => 'Scegli il seme';
  String get reactions => 'Reazioni';
  String get round => 'Round';
  String get cardsLeft => 'carte';
  String get lastCard => 'ULTIMA CARTA';

  // Suits
  String get suitDenari => 'Denari';
  String get suitCoppe => 'Coppe';
  String get suitSpade => 'Spade';
  String get suitBastoni => 'Bastoni';

  // Ranks
  String get rankAce => 'Asso';
  String get rankFante => 'Fante';
  String get rankCavallo => 'Cavallo';
  String get rankRe => 'Re';

  // Round result
  String get roundComplete => 'ROUND COMPLETATO';
  String get roundWinner => 'Vince il round';
  String get nextRound => 'Prossimo Round';
  String get exitToMenu => 'Esci al Menu';
  String get replayLastHand => 'Rivedi ultima mano';
  String get eliminated => 'ELIMINATO';
  String get savedFrom101 => 'SALVO!';
  String get backToZero => 'RITORNO A ZERO';
  String get penalty => 'Penalità';

  // Match result
  String get matchWinner => 'VINCITORE';
  String get rematch => 'Rivincita';
  String get newMatch => 'Nuova Partita';
  String get home => 'Home';
  String get finalPoints => 'Punti finali';
  String get roundsPlayed => 'Round giocati';
  String get cardsPlayed => 'Carte giocate';
  String get longestChain => 'Catena più lunga';
  String get bestComeback => 'Miglior rimonta';

  // Pass & play
  String passPhoneTo(String name) => 'PASSA IL TELEFONO A $name';
  String get imReady => 'SONO PRONTO';
  String get passPhoneHint => 'Le carte restano coperte fino al tuo tocco';

  // Exit
  String get exitTitle => 'Vuoi uscire?';
  String get exitBody => 'La partita verrà salvata automaticamente.';
  String get continueGame => 'Continua';
  String get exit => 'Esci';

  // Settings
  String get sectionSettings => 'IMPOSTAZIONI';
  String get sectionStatistics => 'STATISTICHE';
  String get soundEffects => 'Effetti sonori';
  String get music => 'Musica';
  String get haptics => 'Vibrazione';
  String get animationSpeed => 'Velocità animazioni';
  String get animationNormal => 'Normale';
  String get animationFast => 'Veloce';
  String get reduceMotion => 'Riduci movimento';
  String get highContrast => 'Alto contrasto';
  String get largeCards => 'Carte grandi';
  String get cardBack => 'Dorso delle carte';
  String get defaultDifficulty => 'Difficoltà predefinita';
  String get resetStatistics => 'Azzera statistiche';
  String get resetStatisticsBody =>
      'Tutti i progressi locali verranno cancellati. Vuoi continuare?';
  String get cancel => 'Annulla';
  String get confirm => 'Conferma';
  String get locked => 'Da sbloccare';

  // Statistics
  String get statMatches => 'Partite giocate';
  String get statWins => 'Partite vinte';
  String get statWinRate => 'Percentuale vittorie';
  String get statRoundsWon => 'Round vinti';
  String get statCards => 'Carte giocate';
  String get statAces => 'Assi usati';
  String get statTwos => 'Carte +2 giocate';
  String get statChain => 'Catena più lunga';
  String get statResets => 'Ritorni da 101';
  String get statComeback => 'Rimonta più grande';
  String get statFavouriteSuit => 'Seme preferito';
  String get statStreak => 'Serie attuale';
  String get statBestStreak => 'Serie migliore';
  String get achievements => 'Obiettivi';
  String get noStatsYet => 'Gioca una partita per iniziare a raccogliere dati.';

  // How to play
  String get tutorialGoal => 'Obiettivo';
  String get tutorialGoalBody =>
      'Libera la mano prima degli altri. Le carte che restano agli avversari '
      'diventano punti di penalità: chi supera 101 esce, chi arriva a 101 '
      'esatti torna a zero.';
  String get tutorialMatch => 'Seme o valore';
  String get tutorialMatchBody =>
      'Puoi giocare una carta dello stesso seme attivo oppure dello stesso '
      'valore della carta in cima agli scarti.';
  String get tutorialDraw => 'Pescare';
  String get tutorialDrawBody =>
      'Senza carte giocabili peschi dal mazzo. Se la carta pescata è valida '
      'puoi giocarla subito, altrimenti il turno passa.';
  String get tutorialAce => 'Asso — salta il turno';
  String get tutorialAceBody =>
      'L’Asso fa saltare il turno al giocatore successivo. In due, il '
      'turno torna subito a te.';
  String get tutorialTwo => 'Due — pesca due';
  String get tutorialTwoBody =>
      'Il 2 obbliga il prossimo a pescare due carte. Se ha un altro 2 può '
      'rilanciare: +4, +6, +8. Chi si ferma pesca tutto e perde il turno.';
  String get tutorialCavallo => 'Cavallo — cambia seme';
  String get tutorialCavalloBody =>
      'Il Cavallo (9) si gioca in qualsiasi momento e ti lascia scegliere il '
      'nuovo seme attivo con il Rituale dei Semi.';
  String get tutorialScoring => 'Punteggio';
  String get tutorialScoringBody =>
      'A fine round ogni carta rimasta vale il suo numero: Asso 1, Fante 8, '
      'Cavallo 9, Re 10. I punti si sommano al totale.';
  String get tutorial101 => '101 esatti';
  String get tutorial101Body =>
      'Arrivare esattamente a 101 azzera il punteggio. È il colpo di scena '
      'che può ribaltare una partita.';
  String get tutorialOver101 => 'Oltre 101';
  String get tutorialOver101Body =>
      'Superare 101 significa uscire dalla partita. Resta in gioco chi '
      'gestisce meglio le carte alte.';
  String get tutorialWin => 'Vincere la partita';
  String get tutorialWinBody =>
      'La partita finisce quando resta un solo giocatore in gioco. È lui il '
      'vincitore del Gioco del 101.';

  // Coach marks (§65)
  String get coachMatch => 'Gioca una carta dello stesso seme o valore.';
  String get coachDraw => 'Nessuna carta valida? Tocca il mazzo per pescare.';
  String get coachSpecials =>
      'Asso salta il turno, 2 fa pescare, Cavallo cambia seme.';
  String get coachFateRing =>
      'L’anello mostra quanto manca a 101. A 101 esatti torni a zero.';
  String get gotIt => 'Ho capito';

  // Reactions (§23) — exactly eight.
  List<String> get reactions8 => const [
        'Bella mossa!',
        'Vai!',
        'Che fortuna!',
        'Nooo!',
        'Tocca a te!',
        'Pesca!',
        'Bravo!',
        'Rivincita!',
      ];

  // Daily challenge
  String get dailyTitle => 'Sfida del Giorno';
  String dailyOfDate(String date) => 'Sfida del $date';
  String get dailyStartHint => 'Una configurazione diversa ogni giorno.';
  String get dailyCompleted => 'Completata oggi';
  String get dailyReward => 'Ricompensa';
  String get startChallenge => 'ACCETTA LA SFIDA';
}

/// Global access point. Swap the instance to change language.
class Strings {
  const Strings._();

  static AppStrings _current = const AppStrings();
  static AppStrings get s => _current;
  static void use(AppStrings strings) => _current = strings;
}
