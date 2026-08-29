// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get accountGuestLabel => 'Ospite';

  @override
  String get accountGuestUpgradeHint =>
      'Crea un account per conservare i progressi su tutti i dispositivi.';

  @override
  String accountSignedInAs(String name) {
    return 'Accesso come $name';
  }

  @override
  String get accountSignedOut => 'Non hai effettuato l’accesso';

  @override
  String get achCatenaBody => 'Porta una catena di 2 fino a +6';

  @override
  String get achCatenaTitle => 'Catena!';

  @override
  String get achCentounoBody => 'Arriva a 101 esatti e torna a zero';

  @override
  String get achCentounoTitle => 'Centouno!';

  @override
  String get achImbattibileBody => 'Vinci cinque partite di fila';

  @override
  String get achImbattibileTitle => 'Imbattibile';

  @override
  String get achLocked => 'Da sbloccare';

  @override
  String get achMaestroNoveBody =>
      'Vinci dopo aver scelto tutti e quattro i semi col Cavallo';

  @override
  String get achMaestroNoveTitle => 'Maestro del Nove';

  @override
  String get achManoPerfettaBody =>
      'Vinci un round senza pescare nemmeno una carta';

  @override
  String get achManoPerfettaTitle => 'Mano Perfetta';

  @override
  String get achPrimaVittoriaBody => 'Vinci la tua prima partita';

  @override
  String get achPrimaVittoriaTitle => 'Prima Vittoria';

  @override
  String get achSfidanteBody => 'Completa una Sfida del Giorno';

  @override
  String get achSfidanteTitle => 'Sfidante';

  @override
  String get achUnlocked => 'Sbloccato';

  @override
  String get achVendettaBody => 'Vinci subito dopo una sconfitta';

  @override
  String get achVendettaTitle => 'Vendetta';

  @override
  String get achVeteranoBody => 'Completa 25 partite';

  @override
  String get achVeteranoTitle => 'Veterano';

  @override
  String get achievementUnlockedToast => 'Obiettivo sbloccato';

  @override
  String get achievements => 'Obiettivi';

  @override
  String get activeSuit => 'Seme attivo';

  @override
  String get advancedRules => 'Regole avanzate';

  @override
  String get animationFast => 'Veloce';

  @override
  String get animationNormal => 'Normale';

  @override
  String get animationSpeed => 'Velocità animazioni';

  @override
  String get appName => 'Gioco del 101';

  @override
  String get appTagline => 'Il classico napoletano, rivisitato';

  @override
  String get authBackendPending =>
      'L’accesso sarà attivo quando il servizio online sarà collegato.';

  @override
  String authConfirmEmailBody(String email) {
    return 'Abbiamo inviato un link di conferma a $email. Aprilo, poi accedi.';
  }

  @override
  String get authConfirmEmailTitle => 'Controlla la tua email';

  @override
  String get authContinueWithApple => 'Continua con Apple';

  @override
  String get authContinueWithGoogle => 'Continua con Google';

  @override
  String get authErrorEmailTaken => 'Esiste già un account con questa email.';

  @override
  String get authErrorGuestDisabled =>
      'L’accesso ospite non è attivo su questo server.';

  @override
  String get authErrorInvalidCredentials => 'Email o password non corretti.';

  @override
  String get authErrorNetwork =>
      'Nessuna connessione. Controlla la rete e riprova.';

  @override
  String get authErrorRateLimited =>
      'Troppi tentativi. Attendi un momento e riprova.';

  @override
  String get authErrorUnknown => 'Qualcosa è andato storto durante l’accesso.';

  @override
  String get authErrorWeakPassword => 'Scegli una password più sicura.';

  @override
  String get authGuestFailed => 'Impossibile avviare la sessione ospite.';

  @override
  String get authGuestHint => 'Puoi creare un account in qualsiasi momento.';

  @override
  String get authPlayAsGuest => 'GIOCA COME OSPITE';

  @override
  String get authRegister => 'Registrati';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authSocialUnavailable => 'L’accesso social non è ancora attivo.';

  @override
  String get authSubtitle =>
      'Accedi per giocare online e conservare i tuoi progressi.';

  @override
  String get authTitle => 'Benvenuto';

  @override
  String get backToZero => 'RITORNO A ZERO';

  @override
  String get bestComeback => 'Miglior rimonta';

  @override
  String get cancel => 'Annulla';

  @override
  String get cardBack => 'Dorso delle carte';

  @override
  String get cardsLeft => 'carte';

  @override
  String get cardsPlayed => 'Carte giocate';

  @override
  String get chooseSuit => 'Scegli il seme';

  @override
  String get coachDraw => 'Nessuna carta valida? Tocca il mazzo per pescare.';

  @override
  String get coachFateRing =>
      'L’anello mostra quanto manca a 101. A 101 esatti torni a zero.';

  @override
  String get coachMatch => 'Gioca una carta dello stesso seme o valore.';

  @override
  String get coachSpecials =>
      'Asso salta il turno, 2 fa pescare, Cavallo cambia seme.';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonComingSoon => 'Disponibile a breve';

  @override
  String get commonEmptyBody => 'Quando ci saranno dati, li vedrai qui.';

  @override
  String get commonEmptyTitle => 'Non c’è ancora nulla';

  @override
  String get commonErrorBody =>
      'Non siamo riusciti a completare l’operazione. Riprova.';

  @override
  String get commonErrorTitle => 'Qualcosa è andato storto';

  @override
  String get commonLoading => 'Caricamento…';

  @override
  String get commonNext => 'Avanti';

  @override
  String get commonOptional => 'facoltativo';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonSkip => 'Salta';

  @override
  String get commonStart => 'Inizia';

  @override
  String get confirm => 'Conferma';

  @override
  String get continueGame => 'Continua';

  @override
  String get createRoomCta => 'CREA LA STANZA';

  @override
  String get createRoomHouseRules => 'Regole della casa';

  @override
  String get createRoomName => 'Nome della stanza';

  @override
  String get createRoomNameHint => 'Es. Tavolo di Marco';

  @override
  String get createRoomPrivate => 'Stanza privata';

  @override
  String get createRoomPrivateHint => 'Si entra solo con il codice';

  @override
  String get createRoomTimer => 'Timer del turno';

  @override
  String get createRoomTimerOff => 'Nessuno';

  @override
  String createRoomTimerSeconds(int seconds) {
    return '$seconds secondi';
  }

  @override
  String get createRoomTitle => 'Crea una stanza';

  @override
  String get dailyChallenge => 'Sfida del Giorno';

  @override
  String get dailyChallengeDone => 'Sfida completata';

  @override
  String get dailyCompleted => 'Completata oggi';

  @override
  String get dailyReward => 'Ricompensa';

  @override
  String dailyRewardBalance(int coins) {
    return '$coins monete';
  }

  @override
  String get dailyRewardBody =>
      'Torna ogni giorno: la ricompensa cresce fino al settimo.';

  @override
  String get dailyRewardClaim => 'RITIRA';

  @override
  String get dailyRewardClaimFailed =>
      'Impossibile riscuotere il premio. Riprova.';

  @override
  String get dailyRewardClaimed => 'Ritirata';

  @override
  String get dailyRewardClaimedToday => 'Riscosso oggi. Torna domani!';

  @override
  String dailyRewardDay(int day) {
    return 'Giorno $day';
  }

  @override
  String get dailyRewardGuestHint =>
      'Crea un account per riscuotere i premi giornalieri.';

  @override
  String get dailyRewardTitle => 'Ricompensa giornaliera';

  @override
  String get dailyRewardTomorrow => 'Torna domani';

  @override
  String get dailyStartHint => 'Una configurazione diversa ogni giorno.';

  @override
  String get dailyTitle => 'Sfida del Giorno';

  @override
  String get defaultDifficulty => 'Difficoltà predefinita';

  @override
  String get difficulty => 'Difficoltà';

  @override
  String get difficultyEasy => 'Facile';

  @override
  String get difficultyHard => 'Difficile';

  @override
  String get difficultyNormal => 'Normale';

  @override
  String get discardPile => 'Scarti';

  @override
  String get drawCard => 'Pesca';

  @override
  String get drawPile => 'Mazzo';

  @override
  String get editProfileAvatar => 'Scegli un avatar';

  @override
  String get editProfileTitle => 'Modifica profilo';

  @override
  String get eliminated => 'ELIMINATO';

  @override
  String get exit => 'Esci';

  @override
  String get exitBody => 'La partita verrà salvata automaticamente.';

  @override
  String get exitTitle => 'Vuoi uscire?';

  @override
  String get exitToMenu => 'Esci al Menu';

  @override
  String get fieldConfirmPassword => 'Conferma password';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String get fieldPassword => 'Password';

  @override
  String get finalPoints => 'Punti finali';

  @override
  String get forgotBackToLogin => 'Torna all’accesso';

  @override
  String get forgotBody =>
      'Inserisci la tua email: ti invieremo un link per reimpostare la password.';

  @override
  String get forgotCta => 'INVIA IL LINK';

  @override
  String forgotSentBody(String email) {
    return 'Se esiste un account per $email, il link per reimpostare la password è in arrivo.';
  }

  @override
  String get forgotSentTitle => 'Email inviata';

  @override
  String get forgotTitle => 'Recupera la password';

  @override
  String get gotIt => 'Ho capito';

  @override
  String get haptics => 'Vibrazione';

  @override
  String get hidePassword => 'Nascondi la password';

  @override
  String get highContrast => 'Alto contrasto';

  @override
  String get home => 'Home';

  @override
  String get homeCreateRoom => 'CREA STANZA';

  @override
  String get homeJoinRoom => 'ENTRA IN UNA STANZA';

  @override
  String get homeLeaderboard => 'Classifica';

  @override
  String get homeMissions => 'Missioni';

  @override
  String get homeMissionsHint => 'Obiettivi di oggi';

  @override
  String get homePlayOffline => 'GIOCA OFFLINE';

  @override
  String get homePlayOnline => 'GIOCA ONLINE';

  @override
  String get homeQuickMatch => 'PARTITA RAPIDA';

  @override
  String get howToPlay => 'Come si Gioca';

  @override
  String get howToPlayHint => 'Regole in un minuto';

  @override
  String get imReady => 'SONO PRONTO';

  @override
  String get joinRoomBody =>
      'Inserisci il codice a sei caratteri che ti ha dato l’host.';

  @override
  String get joinRoomCta => 'ENTRA';

  @override
  String get joinRoomInvalid => 'Il codice deve avere sei caratteri';

  @override
  String get joinRoomPaste => 'Incolla';

  @override
  String get joinRoomTitle => 'Entra in una stanza';

  @override
  String get largeCards => 'Carte grandi';

  @override
  String get lastCard => 'ULTIMA CARTA';

  @override
  String get leaderboardAllTime => 'Di sempre';

  @override
  String get leaderboardEmpty =>
      'La classifica sarà disponibile con il gioco online.';

  @override
  String get leaderboardLoadFailed => 'Impossibile caricare la classifica.';

  @override
  String get leaderboardNoScoresYet =>
      'Ancora nessun punteggio: gioca partite online per comparire qui.';

  @override
  String get leaderboardPoints => 'Punti';

  @override
  String get leaderboardRank => 'Pos.';

  @override
  String get leaderboardTitle => 'Classifica';

  @override
  String get leaderboardWeekly => 'Settimanale';

  @override
  String get lobbyCopied => 'Codice copiato';

  @override
  String get lobbyEmptySlot => 'In attesa di un giocatore';

  @override
  String get lobbyHost => 'Host';

  @override
  String get lobbyLeave => 'Esci dalla stanza';

  @override
  String get lobbyNotReady => 'In attesa';

  @override
  String lobbyPlayerSlot(int index) {
    return 'Posto $index';
  }

  @override
  String get lobbyReady => 'Pronto';

  @override
  String get lobbyRoomCode => 'Codice stanza';

  @override
  String get lobbyShare => 'Condividi il codice';

  @override
  String get lobbyStart => 'INIZIA LA PARTITA';

  @override
  String get lobbyStartPending =>
      'L’avvio delle partite online arriva con il prossimo aggiornamento.';

  @override
  String get lobbyTitle => 'Sala d’attesa';

  @override
  String get locked => 'Da sbloccare';

  @override
  String get loginCta => 'ACCEDI';

  @override
  String get loginForgot => 'Password dimenticata?';

  @override
  String get loginNoAccount => 'Non hai un account?';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get longestChain => 'Catena più lunga';

  @override
  String get matchWinner => 'VINCITORE';

  @override
  String get matchmakingBody => 'Stiamo cercando altri giocatori…';

  @override
  String get matchmakingCancel => 'Annulla la ricerca';

  @override
  String matchmakingElapsed(int seconds) {
    return 'Tempo di attesa ${seconds}s';
  }

  @override
  String matchmakingFound(int found, int total) {
    return '$found di $total giocatori';
  }

  @override
  String get matchmakingPending =>
      'Le code per la partita rapida non sono ancora aperte.';

  @override
  String get matchmakingTitle => 'Ricerca in corso';

  @override
  String get mode => 'Modalità';

  @override
  String get modePassAndPlay => 'Passa & Gioca';

  @override
  String get modeVsComputer => 'Vs Computer';

  @override
  String get music => 'Musica';

  @override
  String get networkOffline => 'Nessuna connessione';

  @override
  String get networkOnline => 'Di nuovo online';

  @override
  String get networkReconnecting => 'Riconnessione…';

  @override
  String get newGame => 'Nuova Partita';

  @override
  String get newMatch => 'Nuova Partita';

  @override
  String get nextRound => 'Prossimo Round';

  @override
  String get noStatsYet => 'Gioca una partita per iniziare a raccogliere dati.';

  @override
  String get onboard1Body =>
      'Un mazzo tradizionale da 40 carte — Denari, Coppe, Spade e Bastoni — disegnato a mano per lo schermo.';

  @override
  String get onboard1Title => 'Carte napoletane';

  @override
  String get onboard2Body =>
      'L’Asso salta il turno, il 2 fa pescare, il Cavallo cambia seme. Arrivare a 101 esatti azzera il punteggio.';

  @override
  String get onboard2Title => 'Le regole del 101';

  @override
  String get onboard3Body =>
      'Crea una stanza, condividi il codice e sfida da due a quattro giocatori online.';

  @override
  String get onboard3Title => 'Gioca con gli amici';

  @override
  String get onlineCreateRoomHint => 'Invita gli amici con un codice';

  @override
  String get onlineJoinRoomHint => 'Hai un codice? Entra subito';

  @override
  String get onlineQuickMatchHint => 'Ti troviamo un tavolo libero';

  @override
  String get onlineSignInRequired =>
      'Accedi o gioca come ospite per usare le funzioni online.';

  @override
  String get onlineTitle => 'Gioca online';

  @override
  String get passPhoneHint => 'Le carte restano coperte fino al tuo tocco';

  @override
  String passPhoneTo(String name) {
    return 'PASSA IL TELEFONO A $name';
  }

  @override
  String get passTurn => 'Passa';

  @override
  String get penalty => 'Penalità';

  @override
  String get play => 'GIOCA';

  @override
  String get playDrawn => 'Gioca la carta pescata';

  @override
  String get playerName => 'Il tuo nome';

  @override
  String get playersCount => 'Giocatori';

  @override
  String get profile => 'Profilo';

  @override
  String get profileBestStreak => 'Serie migliore';

  @override
  String get profileEdit => 'Modifica profilo';

  @override
  String get profileLevel => 'Livello';

  @override
  String profileLevelValue(int level) {
    return 'Livello $level';
  }

  @override
  String get profileLosses => 'Sconfitte';

  @override
  String get profileMatches => 'Partite';

  @override
  String get profileNicknameTaken => 'Questo nickname è già in uso.';

  @override
  String get profileRating => 'Punteggio';

  @override
  String get profileSaveFailed => 'Impossibile salvare il profilo. Riprova.';

  @override
  String get profileWinRate => 'Vittorie %';

  @override
  String get profileWins => 'Vittorie';

  @override
  String get profileXp => 'Esperienza';

  @override
  String profileXpProgress(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get rankAce => 'Asso';

  @override
  String get rankCavallo => 'Cavallo';

  @override
  String get rankFante => 'Fante';

  @override
  String get rankRe => 'Re';

  @override
  String get reaction1 => 'Bella mossa!';

  @override
  String get reaction2 => 'Vai!';

  @override
  String get reaction3 => 'Che fortuna!';

  @override
  String get reaction4 => 'Nooo!';

  @override
  String get reaction5 => 'Tocca a te!';

  @override
  String get reaction6 => 'Pesca!';

  @override
  String get reaction7 => 'Bravo!';

  @override
  String get reaction8 => 'Rivincita!';

  @override
  String get reactions => 'Reazioni';

  @override
  String get reduceMotion => 'Riduci movimento';

  @override
  String get rematch => 'Rivincita';

  @override
  String get replayLastHand => 'Rivedi ultima mano';

  @override
  String get resetStatistics => 'Azzera statistiche';

  @override
  String get resetStatisticsBody =>
      'Tutti i progressi locali verranno cancellati. Vuoi continuare?';

  @override
  String get resumeMatch => 'Riprendi Partita';

  @override
  String get resumeMatchHint => 'Continua da dove eri rimasto';

  @override
  String get roomCreateFailed => 'Impossibile aprire la stanza. Riprova.';

  @override
  String get roomFull => 'La stanza è piena.';

  @override
  String get roomJoinFailed => 'Impossibile entrare nella stanza. Riprova.';

  @override
  String get roomNotFound => 'Nessuna stanza aperta con questo codice.';

  @override
  String get round => 'Round';

  @override
  String get roundComplete => 'ROUND COMPLETATO';

  @override
  String get roundWinner => 'Vince il round';

  @override
  String get roundsPlayed => 'Round giocati';

  @override
  String get ruleEliminate => 'Eliminazione oltre 101';

  @override
  String get ruleEliminateHint => 'Chi supera 101 esce dalla partita';

  @override
  String get ruleExactReset => 'Ritorno a zero a 101';

  @override
  String get ruleExactResetHint => 'Esattamente 101 azzera il punteggio';

  @override
  String get ruleStackTwos => 'Somma dei 2';

  @override
  String get ruleStackTwosHint => 'I 2 si possono incatenare';

  @override
  String get ruleVoluntaryDraw => 'Pesca volontaria';

  @override
  String get ruleVoluntaryDrawHint => 'Puoi pescare anche se hai una carta';

  @override
  String get ruleWildNine => 'Cavallo sempre giocabile';

  @override
  String get ruleWildNineHint => 'Il 9 cambia seme in ogni momento';

  @override
  String get savedFrom101 => 'SALVO!';

  @override
  String get sectionSettings => 'IMPOSTAZIONI';

  @override
  String get sectionStatistics => 'STATISTICHE';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageEnglish => 'Inglese';

  @override
  String get settingsLanguageItalian => 'Italiano';

  @override
  String get settingsLinkPending =>
      'Il link sarà disponibile alla pubblicazione.';

  @override
  String get settingsLogout => 'Esci dall’account';

  @override
  String get settingsLogoutBody =>
      'Uscirai dall’account su questo dispositivo. I progressi salvati sull’account restano.';

  @override
  String get settingsPrivacy => 'Informativa sulla privacy';

  @override
  String get settingsTerms => 'Termini di servizio';

  @override
  String get showPassword => 'Mostra la password';

  @override
  String get signupCta => 'REGISTRATI';

  @override
  String get signupHaveAccount => 'Hai già un account?';

  @override
  String get signupTitle => 'Crea un account';

  @override
  String get soundEffects => 'Effetti sonori';

  @override
  String get startChallenge => 'ACCETTA LA SFIDA';

  @override
  String get startMatch => 'INIZIA PARTITA';

  @override
  String get startingHand => 'Carte iniziali';

  @override
  String get statAces => 'Assi usati';

  @override
  String get statBestStreak => 'Serie migliore';

  @override
  String get statCards => 'Carte giocate';

  @override
  String get statChain => 'Catena più lunga';

  @override
  String get statComeback => 'Rimonta più grande';

  @override
  String get statFavouriteSuit => 'Seme preferito';

  @override
  String get statMatches => 'Partite giocate';

  @override
  String get statResets => 'Ritorni da 101';

  @override
  String get statRoundsWon => 'Round vinti';

  @override
  String get statStreak => 'Serie attuale';

  @override
  String get statTwos => 'Carte +2 giocate';

  @override
  String get statWinRate => 'Percentuale vittorie';

  @override
  String get statWins => 'Partite vinte';

  @override
  String get statistics => 'Statistiche';

  @override
  String get suitBastoni => 'Bastoni';

  @override
  String get suitCoppe => 'Coppe';

  @override
  String get suitDenari => 'Denari';

  @override
  String get suitSpade => 'Spade';

  @override
  String get tableRules => 'Regole';

  @override
  String get tableTheme => 'Tavolo';

  @override
  String get tableTurnTimer => 'Tempo';

  @override
  String get takePenalty => 'Prendi';

  @override
  String get turnSkipped => 'TURNO SALTATO';

  @override
  String get tutorial101 => '101 esatti';

  @override
  String get tutorial101Body =>
      'Arrivare esattamente a 101 azzera il punteggio. È il colpo di scena che può ribaltare una partita.';

  @override
  String get tutorialAce => 'Asso — salta il turno';

  @override
  String get tutorialAceBody =>
      'L’Asso fa saltare il turno al giocatore successivo. In due, il turno torna subito a te.';

  @override
  String get tutorialCavallo => 'Cavallo — cambia seme';

  @override
  String get tutorialCavalloBody =>
      'Il Cavallo (9) si gioca in qualsiasi momento e ti lascia scegliere il nuovo seme attivo con il Rituale dei Semi.';

  @override
  String get tutorialDraw => 'Pescare';

  @override
  String get tutorialDrawBody =>
      'Senza carte giocabili peschi dal mazzo. Se la carta pescata è valida puoi giocarla subito, altrimenti il turno passa.';

  @override
  String get tutorialGoal => 'Obiettivo';

  @override
  String get tutorialGoalBody =>
      'Libera la mano prima degli altri. Le carte che restano agli avversari diventano punti di penalità: chi supera 101 esce, chi arriva a 101 esatti torna a zero.';

  @override
  String get tutorialMatch => 'Seme o valore';

  @override
  String get tutorialMatchBody =>
      'Puoi giocare una carta dello stesso seme attivo oppure dello stesso valore della carta in cima agli scarti.';

  @override
  String get tutorialOver101 => 'Oltre 101';

  @override
  String get tutorialOver101Body =>
      'Superare 101 significa uscire dalla partita. Resta in gioco chi gestisce meglio le carte alte.';

  @override
  String get tutorialScoring => 'Punteggio';

  @override
  String get tutorialScoringBody =>
      'A fine round ogni carta rimasta vale il suo numero: Asso 1, Fante 8, Cavallo 9, Re 10. I punti si sommano al totale.';

  @override
  String get tutorialTwo => 'Due — pesca due';

  @override
  String get tutorialTwoBody =>
      'Il 2 obbliga il prossimo a pescare due carte. Se ha un altro 2 può rilanciare: +4, +6, +8. Chi si ferma pesca tutto e perde il turno.';

  @override
  String get tutorialWin => 'Vincere la partita';

  @override
  String get tutorialWinBody =>
      'La partita finisce quando resta un solo giocatore in gioco. È lui il vincitore del Gioco del 101.';

  @override
  String get valEmailInvalid => 'Inserisci un’email valida';

  @override
  String get valNicknameLong => 'Il nickname può avere al massimo 16 caratteri';

  @override
  String get valNicknameShort => 'Il nickname deve avere almeno 3 caratteri';

  @override
  String get valPasswordMismatch => 'Le password non coincidono';

  @override
  String get valPasswordShort => 'La password deve avere almeno 8 caratteri';

  @override
  String get valRequired => 'Campo obbligatorio';

  @override
  String get yourTurn => 'TOCCA A TE';
}
