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
      'Vinci dopo aver scelto tutti e quattro i pali col Cavallo';

  @override
  String get achMaestroNoveTitle => 'Maestro del Nove';

  @override
  String get achManoPerfettaBody =>
      'Vinci un round senza pescare nemmeno una carta';

  @override
  String get achManoPerfettaTitle => 'Mano Perfetta';

  @override
  String get achOffline => 'Sbloccato offline';

  @override
  String get achOnline => 'Sbloccato online';

  @override
  String get achPrimaVittoriaBody => 'Vinci la tua prima partita';

  @override
  String get achPrimaVittoriaTitle => 'Prima Vittoria';

  @override
  String get achServerHint =>
      'Gli obiettivi online sono convalidati dal server; quelli offline restano su questo dispositivo.';

  @override
  String get achSfidanteBody => 'Completa una Sfida del Giorno';

  @override
  String get achSfidanteTitle => 'Sfidante';

  @override
  String get achVendettaBody => 'Vinci subito dopo una sconfitta';

  @override
  String get achVendettaTitle => 'Vendetta';

  @override
  String get achVeteranoBody => 'Completa 25 partite';

  @override
  String get achVeteranoTitle => 'Veterano';

  @override
  String get achievements => 'Obiettivi';

  @override
  String get activeSuit => 'Palo attivo';

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
  String get bestComeback => 'Miglior rimonta';

  @override
  String get botThinking => 'Sta pensando…';

  @override
  String get cancel => 'Annulla';

  @override
  String get cardBack => 'Dorso delle carte';

  @override
  String cardName(String rank, String suit) {
    return '$rank di $suit';
  }

  @override
  String cardSemanticsNotPlayable(String card) {
    return '$card, non giocabile ora';
  }

  @override
  String cardSemanticsPlayable(String card) {
    return '$card, giocabile';
  }

  @override
  String get cardsLeft => 'carte';

  @override
  String get cardsPlayed => 'Carte giocate';

  @override
  String centounoBody(String name) {
    return '$name torna a zero';
  }

  @override
  String get centounoTitle => 'CENTOUNO!';

  @override
  String get challengeEdgeBody =>
      'Parti da 80 punti contro un avversario difficile. Un round sbagliato e sei fuori.';

  @override
  String get challengeEdgeTitle => 'Sull’orlo';

  @override
  String get challengeFullBody =>
      'Quattro giocatori, avversari difficili, nessuna pesca volontaria.';

  @override
  String get challengeFullTitle => 'Tavolo pieno';

  @override
  String get challengeStormBody =>
      'Mano da 8 carte e catene di 2 scatenate. Sopravvivi alla tempesta.';

  @override
  String get challengeStormTitle => 'Tempesta di due';

  @override
  String get challengeTightBody =>
      'Solo 3 carte a testa. Poche scelte, nessun margine di errore.';

  @override
  String get challengeTightTitle => 'Mano stretta';

  @override
  String get challengeZeroBody =>
      'Parti da 94 punti: trova i 7 punti esatti e torna a zero.';

  @override
  String get challengeZeroTitle => 'Ritorno a zero';

  @override
  String get chooseSuit => 'Scegli il palo';

  @override
  String get coachDraw => 'Nessuna carta valida? Tocca il mazzo per pescare.';

  @override
  String get coachFateRing =>
      'L’anello mostra quanto manca a 101. A 101 esatti torni a zero.';

  @override
  String get coachMatch => 'Gioca una carta dello stesso palo o valore.';

  @override
  String get coachSpecials =>
      'Asso salta il turno, 2 fa pescare, Cavallo cambia palo.';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonComingSoon => 'Disponibile a breve';

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
  String get commonOff => 'Disattivata';

  @override
  String get commonOn => 'Attiva';

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
  String get dealerBadge => 'MAZZIERE';

  @override
  String get deckTaglineIncisoOro => 'L’incisione della casa, rifinita in oro.';

  @override
  String get deckTaglineNapoletane => 'Le autentiche carte napoletane.';

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
  String discardTop(String card) {
    return 'Scarti: $card';
  }

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
  String get gadgetTaglineSigillo => 'Un sigillo dorato impresso nel panno.';

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
  String lastCardAnnounced(String name) {
    return '$name: ULTIMA CARTA!';
  }

  @override
  String get lastCardButton => 'ULTIMA CARTA';

  @override
  String get lastCardDeclared => 'ULTIMA CARTA!';

  @override
  String get lastCardPrompt => 'Dichiara ULTIMA CARTA prima di giocare.';

  @override
  String get lastCardSemantics => 'Dichiara ultima carta';

  @override
  String get leaderboardAllTime => 'Di sempre';

  @override
  String get leaderboardEmpty =>
      'La classifica sarà disponibile con il gioco online.';

  @override
  String get leaderboardLoadFailed => 'Impossibile caricare la classifica.';

  @override
  String get leaderboardLoadMore => 'Carica altri';

  @override
  String get leaderboardNoScoresYet =>
      'Ancora nessun punteggio: gioca partite online per comparire qui.';

  @override
  String get leaderboardNotRanked =>
      'Non sei ancora in classifica: gioca online per entrarci.';

  @override
  String get leaderboardPoints => 'Punti';

  @override
  String get leaderboardRank => 'Pos.';

  @override
  String get leaderboardTitle => 'Classifica';

  @override
  String get leaderboardWeekly => 'Settimanale';

  @override
  String get leaderboardYourRank => 'La tua posizione';

  @override
  String legalLastUpdated(String date) {
    return 'Ultimo aggiornamento: $date';
  }

  @override
  String get lobbyAway => 'Assente';

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
  String get lobbyNotReadyToggle => 'Non sono pronto';

  @override
  String get lobbyReady => 'Pronto';

  @override
  String get lobbyReadyToggle => 'Sono pronto';

  @override
  String get lobbyRoomCode => 'Codice stanza';

  @override
  String get lobbyShare => 'Condividi il codice';

  @override
  String get lobbyStart => 'INIZIA LA PARTITA';

  @override
  String lobbyStartFailed(String reason) {
    return 'Impossibile avviare: $reason';
  }

  @override
  String get lobbyStartPending =>
      'La partita parte quando tutti i posti sono occupati e ogni giocatore è pronto.';

  @override
  String get lobbyStarting => 'La partita sta per iniziare…';

  @override
  String get lobbyTitle => 'Sala d’attesa';

  @override
  String get lobbyWaitingForHost => 'In attesa che l’host avvii la partita…';

  @override
  String get lobbyWaitingForPlayers => 'In attesa di altri giocatori…';

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
  String get matchmakingBusy => 'Hai già una partita in corso.';

  @override
  String get matchmakingCancel => 'Annulla la ricerca';

  @override
  String get matchmakingCpuHint =>
      'Nessun altro giocatore per ora. Puoi giocare subito offline contro il computer: non vale per la classifica.';

  @override
  String get matchmakingCpuOffer => 'Continua contro CPU';

  @override
  String matchmakingElapsed(int seconds) {
    return 'Tempo di attesa ${seconds}s';
  }

  @override
  String matchmakingFound(int found, int total) {
    return '$found di $total giocatori';
  }

  @override
  String get matchmakingMatched => 'Tavolo trovato!';

  @override
  String get matchmakingPlayers => 'Giocatori al tavolo';

  @override
  String get matchmakingSearch => 'Cerca partita';

  @override
  String matchmakingSearching(int count) {
    return 'Cerchiamo altri giocatori veri per un tavolo da $count…';
  }

  @override
  String get matchmakingTitle => 'Ricerca in corso';

  @override
  String missionBlockTwo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Blocca $n +2 con il Cavallo',
      one: 'Blocca un +2 con il Cavallo',
    );
    return '$_temp0';
  }

  @override
  String missionOnlineMatch(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Completa $n partite online',
      one: 'Completa una partita online',
    );
    return '$_temp0';
  }

  @override
  String missionPlayAces(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gioca $n Assi',
      one: 'Gioca un Asso',
    );
    return '$_temp0';
  }

  @override
  String missionPlayMatches(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gioca $n partite',
      one: 'Gioca una partita',
    );
    return '$_temp0';
  }

  @override
  String missionPlayTwos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gioca $n carte 2',
      one: 'Gioca un 2',
    );
    return '$_temp0';
  }

  @override
  String missionUseNine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Usa $n Cavalli (9)',
      one: 'Usa un Cavallo (9)',
    );
    return '$_temp0';
  }

  @override
  String missionWinMatch(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vinci $n partite',
      one: 'Vinci una partita',
    );
    return '$_temp0';
  }

  @override
  String get missionsClaim => 'RISCUOTI';

  @override
  String get missionsClaimFailed => 'Impossibile riscuotere la ricompensa.';

  @override
  String get missionsClaimed => 'Riscossa';

  @override
  String get missionsCycleHint =>
      'Nuove missioni ogni giorno, su un ciclo di sette giorni.';

  @override
  String get missionsEmpty => 'Nessuna missione oggi.';

  @override
  String get missionsLoadFailed => 'Impossibile caricare le missioni online.';

  @override
  String get missionsOffline => 'Offline (questo dispositivo)';

  @override
  String get missionsOnline => 'Missioni online';

  @override
  String get missionsOnlineOnly => 'Solo online';

  @override
  String missionsProgress(int done, int total) {
    return '$done/$total completate';
  }

  @override
  String missionsReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get missionsSignInHint =>
      'Accedi per le missioni online: l’esperienza va sul tuo profilo.';

  @override
  String get missionsTitle => 'Missioni del giorno';

  @override
  String get mode => 'Modalità';

  @override
  String get modePassAndPlay => 'Passa & Gioca';

  @override
  String get modeVsComputer => 'Contro il computer';

  @override
  String get music => 'Musica';

  @override
  String get networkOffline => 'Nessuna connessione';

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
      'L’Asso salta il turno, il 2 fa pescare, il Cavallo cambia palo. Arrivare a 101 esatti azzera il punteggio.';

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
  String get onlineDisconnected =>
      'Connessione persa. Tentativo di riconnessione...';

  @override
  String get onlineForfeit => 'Abbandona';

  @override
  String get onlineForfeitBody =>
      'La partita verrà data persa e non potrai rientrare.';

  @override
  String get onlineForfeitTitle => 'Abbandoni la partita?';

  @override
  String get onlineJoinRoomHint => 'Hai un codice? Entra subito';

  @override
  String get onlineMatchAbandoned => 'La partita è stata abbandonata';

  @override
  String get onlineMoveRefused => 'Mossa non valida.';

  @override
  String get onlineMoveStale => 'Il tavolo era cambiato: riprova';

  @override
  String get onlineNotYourTurn => 'Non è il tuo turno.';

  @override
  String onlineOpponentLeft(String name) {
    return '$name ha abbandonato la partita';
  }

  @override
  String get onlineQuickMatchHint => 'Ti troviamo un tavolo libero';

  @override
  String get onlineRejoinMatch => 'Rientra nella partita';

  @override
  String get onlineRejoinMatchHint => 'Una partita online ti sta aspettando';

  @override
  String onlineRematchWaiting(int votes, int needed) {
    return 'In attesa degli altri ($votes/$needed)';
  }

  @override
  String get onlineSignInRequired =>
      'Accedi o gioca come ospite per usare le funzioni online.';

  @override
  String get onlineTitle => 'Gioca online';

  @override
  String onlineTurnSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get onlineUnavailableRetry =>
      'Servizio online non raggiungibile. Il gioco offline resta disponibile.';

  @override
  String get passPhoneHint => 'Le carte restano coperte fino al tuo tocco';

  @override
  String passPhoneTo(String name) {
    return 'PASSA IL TELEFONO A $name';
  }

  @override
  String get passTurn => 'Passa';

  @override
  String get pauseHint => 'La partita è ferma: gli avversari aspettano.';

  @override
  String get pauseResume => 'Riprendi';

  @override
  String get pauseTitle => 'Pausa';

  @override
  String get penalty => 'Penalità';

  @override
  String get play => 'GIOCA';

  @override
  String get playerName => 'Il tuo nome';

  @override
  String get playersCount => 'Giocatori';

  @override
  String premiumBuyFor(String price) {
    return 'Acquista · $price';
  }

  @override
  String get premiumCancelled => 'Acquisto annullato.';

  @override
  String get premiumFailed => 'L’acquisto non è andato a buon fine. Riprova.';

  @override
  String get premiumNetwork =>
      'Connessione assente. Controlla la rete e riprova.';

  @override
  String get premiumNothingToRestore =>
      'Nessun acquisto da ripristinare su questo account dello store.';

  @override
  String get premiumOwnedElsewhere =>
      'Questo acquisto risulta già associato a un altro profilo di gioco.';

  @override
  String get premiumPending => 'Acquisto in corso…';

  @override
  String get premiumProductMissing =>
      'Il prodotto non è ancora disponibile nello store. Riprova più tardi.';

  @override
  String get premiumRestore => 'Ripristina acquisti';

  @override
  String get premiumRestored => 'Acquisti ripristinati.';

  @override
  String get premiumSignInRequired =>
      'Accedi con un account per completare l’acquisto.';

  @override
  String get premiumStoreUnavailable =>
      'Lo store non è disponibile su questo dispositivo.';

  @override
  String get premiumSuccess => 'Acquisto completato. Grazie!';

  @override
  String get premiumVerificationUnavailable =>
      'La verifica degli acquisti non è ancora attiva. Nessun addebito è andato perso: riprova più tardi.';

  @override
  String get premiumVerifyFailed =>
      'Impossibile verificare l’acquisto in questo momento. L’acquisto non va perso: riprova.';

  @override
  String get premiumVerifying => 'Verifica dell’acquisto…';

  @override
  String get profile => 'Profilo';

  @override
  String get profileBestStreak => 'Serie migliore';

  @override
  String get profileEdit => 'Modifica profilo';

  @override
  String profileLevelValue(int level) {
    return 'Livello $level';
  }

  @override
  String get profileLosses => 'Sconfitte';

  @override
  String get profileMatches => 'Partite';

  @override
  String profileNextLevel(int level) {
    return 'Prossimo livello: $level';
  }

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
  String profileXpProgress(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String profileXpToNext(int xp) {
    return 'Mancano $xp XP';
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
  String get reactionAhahaha => 'Ahahaha! 😂';

  @override
  String get reactionBellaMossa => 'Bella mossa! 😎';

  @override
  String get reactionBravo => 'Bravo! 👏';

  @override
  String get reactionCheFortuna => 'Che fortuna! 🍀';

  @override
  String get reactionCiao => 'Ciao! 👋';

  @override
  String get reactionGg => 'GG! 🤝';

  @override
  String get reactionMammaMia => 'Mamma mia! 😱';

  @override
  String get reactionRateLimited =>
      'Aspetta un attimo prima della prossima reazione';

  @override
  String get reactionRivincita => 'Rivincita? 🔁';

  @override
  String get reactions => 'Reazioni';

  @override
  String get reduceMotion => 'Riduci movimento';

  @override
  String get rematch => 'Rivincita';

  @override
  String get replayAgain => 'Rivedi';

  @override
  String get replayLastHand => 'Rivedi ultima mano';

  @override
  String get resetStatistics => 'Azzera statistiche';

  @override
  String get resetStatisticsBody =>
      'Tutti i progressi locali verranno cancellati. Vuoi continuare?';

  @override
  String get resumeMatch => 'Continua partita';

  @override
  String get resumeMatchHint => 'Continua da dove eri rimasto';

  @override
  String get roomAlreadyInMatch =>
      'Hai già una partita online in corso. Rientra al tavolo o abbandonala prima di aprirne un’altra.';

  @override
  String get roomAlreadyStarted => 'La partita è già iniziata.';

  @override
  String get roomCreateFailed => 'Impossibile aprire la stanza. Riprova.';

  @override
  String get roomFull => 'La stanza è piena.';

  @override
  String get roomJoinFailed => 'Impossibile entrare nella stanza. Riprova.';

  @override
  String get roomNotFound => 'Stanza non trovata.';

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
  String get ruleNineBlock => 'Cavallo contro il 2';

  @override
  String get ruleNineBlockCancel => 'Annulla la catena';

  @override
  String get ruleNineBlockDisabled => 'Non consentito';

  @override
  String get ruleNineBlockPassOn => 'Passa la catena';

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
  String get ruleWildNineHint => 'Il 9 cambia palo in ogni momento';

  @override
  String get rulesActiveTitle => 'Regole di questa partita';

  @override
  String get savedFrom101 => 'SALVO!';

  @override
  String get sectionSettings => 'IMPOSTAZIONI';

  @override
  String get sectionStatistics => 'STATISTICHE';

  @override
  String get sessionExpired => 'Sessione scaduta. Accedi di nuovo.';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get settingsGuestLogoutBody =>
      'Sei un ospite: uscendo perderai questo account e i suoi progressi online per sempre.';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageEnglish => 'Inglese';

  @override
  String get settingsLanguageItalian => 'Italiano';

  @override
  String get settingsLogout => 'Esci dall’account';

  @override
  String get settingsLogoutBody =>
      'Uscirai dall’account su questo dispositivo. I progressi salvati sull’account restano.';

  @override
  String get settingsLogoutGuest => 'Esci (account ospite)';

  @override
  String get settingsPrivacy => 'Informativa sulla privacy';

  @override
  String get settingsTerms => 'Termini di servizio';

  @override
  String get setupOtherPlayers => 'Altri giocatori';

  @override
  String setupPlayerN(int n) {
    return 'Giocatore $n';
  }

  @override
  String get setupResetRules => 'Ripristina regole';

  @override
  String get shopFootnote =>
      'Acquisti una tantum, permanenti e solo estetici. Il gioco completo resta gratuito. I prezzi sono gestiti dallo store del dispositivo.';

  @override
  String get shopInUse => 'In uso';

  @override
  String get shopIntro =>
      'Contenuti estetici opzionali. Nessun vantaggio di gioco: tavoli, mazzo, dorso e ornamenti sono solo bellezza.';

  @override
  String get shopItemCardBackGold => 'Dorso Oro';

  @override
  String get shopItemCardBackGoldBody =>
      'Un dorso in oro zecchino per le tue carte. Le figure restano le autentiche napoletane.';

  @override
  String get shopItemDeckSpecial => 'Mazzo Speciale';

  @override
  String get shopItemDeckSpecialBody =>
      'Il mazzo inciso della casa, rifinito in oro. Il mazzo napoletano classico resta sempre disponibile.';

  @override
  String get shopItemGadget => 'Sigillo del 101';

  @override
  String get shopItemGadgetBody =>
      'Un sigillo d’alloro dorato impresso nel panno del tavolo.';

  @override
  String get shopItemTableClassic => 'Tavolo Classico';

  @override
  String get shopItemTableClassicBody =>
      'Il circolo di una volta: panno verde su noce scuro.';

  @override
  String get shopItemTableGold => 'Tavolo Oro';

  @override
  String get shopItemTableGoldBody =>
      'Un tavolo da gran salone: panno d’oro battuto sotto luce calda.';

  @override
  String get shopItemUnavailable =>
      'Non ancora disponibile nello store. Riprova più tardi.';

  @override
  String get shopOwned => 'Sbloccato';

  @override
  String get shopRemove => 'Rimuovi';

  @override
  String get shopTitle => 'Negozio';

  @override
  String get shopUse => 'Usa';

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
  String get statFavouriteSuit => 'Palo preferito';

  @override
  String get statMatches => 'Partite giocate';

  @override
  String get statOnlineMatches => 'Partite online';

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
  String get statsOfflineHeading => 'OFFLINE — QUESTO DISPOSITIVO';

  @override
  String get statsOfflineHint =>
      'Le partite contro il computer non toccano la classifica online.';

  @override
  String get statsOnlineHeading => 'ONLINE — PROFILO';

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
  String get tableTaglineClassico => 'Panno verde, noce scuro, silenzio.';

  @override
  String get tableTaglineMaiolica => 'Ceramica mediterranea, cobalto e sole';

  @override
  String get tableTaglineNapoli => 'Oro antico sul golfo che dorme';

  @override
  String get tableTaglineOro => 'Oro battuto sotto luce di lampadario.';

  @override
  String get tableTaglineVesuvio => 'Cenere calda e bagliori di terracotta';

  @override
  String get tableTheme => 'Tavolo';

  @override
  String get takePenalty => 'Prendi';

  @override
  String get turnSkipped => 'TURNO SALTATO';

  @override
  String tutAceDone(String name) {
    return '$name ha saltato il turno. In due, l’Asso ti riporta subito al tuo turno.';
  }

  @override
  String get tutAcePrompt =>
      'Gioca l’Asso di Coppe: l’avversario perde il turno.';

  @override
  String get tutAceTitle => 'Asso — salta il turno';

  @override
  String get tutBlockDone =>
      'Il Cavallo è anche la tua difesa contro i 2. Usalo con giudizio: nel mazzo ce ne sono solo quattro.';

  @override
  String get tutBlockPrompt =>
      'Un 2 ti minaccia e non hai 2 da rispondere. Gioca il Cavallo di Bastoni per annullare la catena.';

  @override
  String get tutBlockSuit => 'Catena annullata: nessuno pesca. Scegli il palo.';

  @override
  String get tutBlockTitle => 'Cavallo contro il 2';

  @override
  String tutCavalloDone(String suit) {
    return 'Il palo attivo ora è $suit. Il Cavallo non impone il proprio palo: impone quello che scegli tu.';
  }

  @override
  String get tutCavalloPrompt =>
      'Il Cavallo (il 9) si gioca sempre, su qualsiasi carta. Gioca il Cavallo di Spade.';

  @override
  String get tutCavalloSuit =>
      'Ora scegli il nuovo palo attivo: conviene quello di cui hai più carte.';

  @override
  String get tutCavalloTitle => 'Cavallo — cambia palo';

  @override
  String tutCentounoDone(String name) {
    return '76 + 25 = 101 esatti: $name torna a zero. Chi invece supera 101 viene eliminato. Vince chi resta per ultimo.';
  }

  @override
  String get tutCentounoPrompt =>
      'Ultima carta! L’avversario ha 76 punti e un Cavallo in mano, che vale 25. Gioca il 7 di Coppe e chiudi il round.';

  @override
  String get tutCentounoTitle => 'Centouno!';

  @override
  String tutChainDone(String name) {
    return '+4! $name ha pescato quattro carte. Le catene arrivano fino a +8.';
  }

  @override
  String get tutChainPrompt =>
      'L’avversario ha giocato un 2 contro di te: rispondi con il 2 di Spade e la penalità sale a +4.';

  @override
  String get tutChainTitle => 'La catena di 2';

  @override
  String get tutDrawingDone =>
      'Se la carta pescata non fosse stata giocabile, il turno sarebbe passato con Passa.';

  @override
  String get tutDrawingPlay =>
      'Hai pescato il 6 di Coppe: è giocabile subito. Giocalo.';

  @override
  String get tutDrawingPrompt =>
      'Nessuna carta in mano è giocabile. Tocca il mazzo (o Pesca) per prendere una carta.';

  @override
  String get tutDrawingTitle => 'Pescare';

  @override
  String get tutFirstCardDone =>
      'Perfetto. Ogni carta giocata deve seguire il palo attivo oppure il valore della carta in cima agli scarti.';

  @override
  String get tutFirstCardPrompt =>
      'In cima agli scarti c’è il 5 di Coppe. Puoi giocare una carta di Coppe oppure un altro 5: tocca due volte una carta evidenziata.';

  @override
  String get tutFirstCardTitle => 'Palo o valore';

  @override
  String tutTwoDone(String name) {
    return '$name non aveva un 2: ha pescato due carte e perso il turno.';
  }

  @override
  String get tutTwoPrompt =>
      'Gioca il 2 di Coppe: l’avversario dovrà pescare due carte, a meno che non risponda con un altro 2.';

  @override
  String get tutTwoTitle => 'Due — pesca due';

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
  String get tutorialCavallo => 'Cavallo — cambia palo';

  @override
  String get tutorialCavalloBody =>
      'Il Cavallo (9) si gioca in qualsiasi momento e ti lascia scegliere il nuovo palo attivo con il Rituale dei Pali.';

  @override
  String get tutorialCompleteBody =>
      'Conosci tutte le carte speciali e il 101. Ora tocca a te.';

  @override
  String get tutorialCompleteTitle => 'Tutorial completato!';

  @override
  String get tutorialDraw => 'Pescare';

  @override
  String get tutorialDrawBody =>
      'Senza carte giocabili peschi dal mazzo. Se la carta pescata è valida puoi giocarla subito, altrimenti il turno passa.';

  @override
  String get tutorialExitBody => 'Potrai rifarlo dall’inizio quando vuoi.';

  @override
  String get tutorialExitTitle => 'Vuoi uscire dal tutorial?';

  @override
  String get tutorialFinish => 'Fine';

  @override
  String get tutorialGoal => 'Obiettivo';

  @override
  String get tutorialGoalBody =>
      'Libera la mano prima degli altri. Le carte che restano agli avversari diventano punti di penalità: chi supera 101 esce, chi arriva a 101 esatti torna a zero.';

  @override
  String get tutorialHint => 'Impara giocando, una regola alla volta';

  @override
  String get tutorialHintFollow =>
      'Segui il suggerimento: gioca la carta evidenziata.';

  @override
  String get tutorialMatch => 'Palo o valore';

  @override
  String get tutorialMatchBody =>
      'Puoi giocare una carta dello stesso palo attivo oppure dello stesso valore della carta in cima agli scarti.';

  @override
  String get tutorialOver101 => 'Oltre 101';

  @override
  String get tutorialOver101Body =>
      'Superare 101 significa uscire dalla partita. Resta in gioco chi gestisce meglio le carte alte.';

  @override
  String get tutorialPlayNow => 'GIOCA CONTRO IL COMPUTER';

  @override
  String get tutorialReplay => 'Rifai il tutorial';

  @override
  String get tutorialScoring => 'Punteggio';

  @override
  String get tutorialScoringBody =>
      'A fine round ogni carta rimasta vale il suo numero — Asso 1, Fante 8, Re 10 — tranne il Cavallo, che vale 25. I punti si sommano al totale.';

  @override
  String get tutorialTitle => 'Tutorial interattivo';

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
