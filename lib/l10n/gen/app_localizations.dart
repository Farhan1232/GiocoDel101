import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @accountGuestLabel.
  ///
  /// In it, this message translates to:
  /// **'Ospite'**
  String get accountGuestLabel;

  /// No description provided for @accountGuestUpgradeHint.
  ///
  /// In it, this message translates to:
  /// **'Crea un account per conservare i progressi su tutti i dispositivi.'**
  String get accountGuestUpgradeHint;

  /// No description provided for @accountSignedInAs.
  ///
  /// In it, this message translates to:
  /// **'Accesso come {name}'**
  String accountSignedInAs(String name);

  /// No description provided for @accountSignedOut.
  ///
  /// In it, this message translates to:
  /// **'Non hai effettuato l’accesso'**
  String get accountSignedOut;

  /// No description provided for @achCatenaBody.
  ///
  /// In it, this message translates to:
  /// **'Porta una catena di 2 fino a +6'**
  String get achCatenaBody;

  /// No description provided for @achCatenaTitle.
  ///
  /// In it, this message translates to:
  /// **'Catena!'**
  String get achCatenaTitle;

  /// No description provided for @achCentounoBody.
  ///
  /// In it, this message translates to:
  /// **'Arriva a 101 esatti e torna a zero'**
  String get achCentounoBody;

  /// No description provided for @achCentounoTitle.
  ///
  /// In it, this message translates to:
  /// **'Centouno!'**
  String get achCentounoTitle;

  /// No description provided for @achImbattibileBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci cinque partite di fila'**
  String get achImbattibileBody;

  /// No description provided for @achImbattibileTitle.
  ///
  /// In it, this message translates to:
  /// **'Imbattibile'**
  String get achImbattibileTitle;

  /// No description provided for @achLocked.
  ///
  /// In it, this message translates to:
  /// **'Da sbloccare'**
  String get achLocked;

  /// No description provided for @achMaestroNoveBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci dopo aver scelto tutti e quattro i pali col Cavallo'**
  String get achMaestroNoveBody;

  /// No description provided for @achMaestroNoveTitle.
  ///
  /// In it, this message translates to:
  /// **'Maestro del Nove'**
  String get achMaestroNoveTitle;

  /// No description provided for @achManoPerfettaBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci un round senza pescare nemmeno una carta'**
  String get achManoPerfettaBody;

  /// No description provided for @achManoPerfettaTitle.
  ///
  /// In it, this message translates to:
  /// **'Mano Perfetta'**
  String get achManoPerfettaTitle;

  /// No description provided for @achOffline.
  ///
  /// In it, this message translates to:
  /// **'Sbloccato offline'**
  String get achOffline;

  /// No description provided for @achOnline.
  ///
  /// In it, this message translates to:
  /// **'Sbloccato online'**
  String get achOnline;

  /// No description provided for @achPrimaVittoriaBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci la tua prima partita'**
  String get achPrimaVittoriaBody;

  /// No description provided for @achPrimaVittoriaTitle.
  ///
  /// In it, this message translates to:
  /// **'Prima Vittoria'**
  String get achPrimaVittoriaTitle;

  /// No description provided for @achServerHint.
  ///
  /// In it, this message translates to:
  /// **'Gli obiettivi online sono convalidati dal server; quelli offline restano su questo dispositivo.'**
  String get achServerHint;

  /// No description provided for @achSfidanteBody.
  ///
  /// In it, this message translates to:
  /// **'Completa una Sfida del Giorno'**
  String get achSfidanteBody;

  /// No description provided for @achSfidanteTitle.
  ///
  /// In it, this message translates to:
  /// **'Sfidante'**
  String get achSfidanteTitle;

  /// No description provided for @achVendettaBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci subito dopo una sconfitta'**
  String get achVendettaBody;

  /// No description provided for @achVendettaTitle.
  ///
  /// In it, this message translates to:
  /// **'Vendetta'**
  String get achVendettaTitle;

  /// No description provided for @achVeteranoBody.
  ///
  /// In it, this message translates to:
  /// **'Completa 25 partite'**
  String get achVeteranoBody;

  /// No description provided for @achVeteranoTitle.
  ///
  /// In it, this message translates to:
  /// **'Veterano'**
  String get achVeteranoTitle;

  /// No description provided for @achievements.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi'**
  String get achievements;

  /// No description provided for @activeSuit.
  ///
  /// In it, this message translates to:
  /// **'Palo attivo'**
  String get activeSuit;

  /// No description provided for @advancedRules.
  ///
  /// In it, this message translates to:
  /// **'Regole avanzate'**
  String get advancedRules;

  /// No description provided for @animationFast.
  ///
  /// In it, this message translates to:
  /// **'Veloce'**
  String get animationFast;

  /// No description provided for @animationNormal.
  ///
  /// In it, this message translates to:
  /// **'Normale'**
  String get animationNormal;

  /// No description provided for @animationSpeed.
  ///
  /// In it, this message translates to:
  /// **'Velocità animazioni'**
  String get animationSpeed;

  /// No description provided for @appName.
  ///
  /// In it, this message translates to:
  /// **'Gioco del 101'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In it, this message translates to:
  /// **'Il classico napoletano, rivisitato'**
  String get appTagline;

  /// No description provided for @authBackendPending.
  ///
  /// In it, this message translates to:
  /// **'L’accesso sarà attivo quando il servizio online sarà collegato.'**
  String get authBackendPending;

  /// No description provided for @authConfirmEmailBody.
  ///
  /// In it, this message translates to:
  /// **'Abbiamo inviato un link di conferma a {email}. Aprilo, poi accedi.'**
  String authConfirmEmailBody(String email);

  /// No description provided for @authConfirmEmailTitle.
  ///
  /// In it, this message translates to:
  /// **'Controlla la tua email'**
  String get authConfirmEmailTitle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In it, this message translates to:
  /// **'Continua con Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In it, this message translates to:
  /// **'Continua con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In it, this message translates to:
  /// **'Esiste già un account con questa email.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorGuestDisabled.
  ///
  /// In it, this message translates to:
  /// **'L’accesso ospite non è attivo su questo server.'**
  String get authErrorGuestDisabled;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In it, this message translates to:
  /// **'Email o password non corretti.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorNetwork.
  ///
  /// In it, this message translates to:
  /// **'Nessuna connessione. Controlla la rete e riprova.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In it, this message translates to:
  /// **'Troppi tentativi. Attendi un momento e riprova.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorUnknown.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa è andato storto durante l’accesso.'**
  String get authErrorUnknown;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In it, this message translates to:
  /// **'Scegli una password più sicura.'**
  String get authErrorWeakPassword;

  /// No description provided for @authGuestFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile avviare la sessione ospite.'**
  String get authGuestFailed;

  /// No description provided for @authGuestHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi creare un account in qualsiasi momento.'**
  String get authGuestHint;

  /// No description provided for @authPlayAsGuest.
  ///
  /// In it, this message translates to:
  /// **'GIOCA COME OSPITE'**
  String get authPlayAsGuest;

  /// No description provided for @authRegister.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get authRegister;

  /// No description provided for @authSignIn.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get authSignIn;

  /// No description provided for @authSocialUnavailable.
  ///
  /// In it, this message translates to:
  /// **'L’accesso social non è ancora attivo.'**
  String get authSocialUnavailable;

  /// No description provided for @authSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi per giocare online e conservare i tuoi progressi.'**
  String get authSubtitle;

  /// No description provided for @authTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto'**
  String get authTitle;

  /// No description provided for @bestComeback.
  ///
  /// In it, this message translates to:
  /// **'Miglior rimonta'**
  String get bestComeback;

  /// No description provided for @botThinking.
  ///
  /// In it, this message translates to:
  /// **'Sta pensando…'**
  String get botThinking;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @cardBack.
  ///
  /// In it, this message translates to:
  /// **'Dorso delle carte'**
  String get cardBack;

  /// No description provided for @cardName.
  ///
  /// In it, this message translates to:
  /// **'{rank} di {suit}'**
  String cardName(String rank, String suit);

  /// No description provided for @cardSemanticsNotPlayable.
  ///
  /// In it, this message translates to:
  /// **'{card}, non giocabile ora'**
  String cardSemanticsNotPlayable(String card);

  /// No description provided for @cardSemanticsPlayable.
  ///
  /// In it, this message translates to:
  /// **'{card}, giocabile'**
  String cardSemanticsPlayable(String card);

  /// No description provided for @cardsLeft.
  ///
  /// In it, this message translates to:
  /// **'carte'**
  String get cardsLeft;

  /// No description provided for @cardsPlayed.
  ///
  /// In it, this message translates to:
  /// **'Carte giocate'**
  String get cardsPlayed;

  /// No description provided for @centounoBody.
  ///
  /// In it, this message translates to:
  /// **'{name} torna a zero'**
  String centounoBody(String name);

  /// No description provided for @centounoTitle.
  ///
  /// In it, this message translates to:
  /// **'CENTOUNO!'**
  String get centounoTitle;

  /// No description provided for @challengeEdgeBody.
  ///
  /// In it, this message translates to:
  /// **'Parti da 80 punti contro un avversario difficile. Un round sbagliato e sei fuori.'**
  String get challengeEdgeBody;

  /// No description provided for @challengeEdgeTitle.
  ///
  /// In it, this message translates to:
  /// **'Sull’orlo'**
  String get challengeEdgeTitle;

  /// No description provided for @challengeFullBody.
  ///
  /// In it, this message translates to:
  /// **'Quattro giocatori, avversari difficili, nessuna pesca volontaria.'**
  String get challengeFullBody;

  /// No description provided for @challengeFullTitle.
  ///
  /// In it, this message translates to:
  /// **'Tavolo pieno'**
  String get challengeFullTitle;

  /// No description provided for @challengeStormBody.
  ///
  /// In it, this message translates to:
  /// **'Mano da 8 carte e catene di 2 scatenate. Sopravvivi alla tempesta.'**
  String get challengeStormBody;

  /// No description provided for @challengeStormTitle.
  ///
  /// In it, this message translates to:
  /// **'Tempesta di due'**
  String get challengeStormTitle;

  /// No description provided for @challengeTightBody.
  ///
  /// In it, this message translates to:
  /// **'Solo 3 carte a testa. Poche scelte, nessun margine di errore.'**
  String get challengeTightBody;

  /// No description provided for @challengeTightTitle.
  ///
  /// In it, this message translates to:
  /// **'Mano stretta'**
  String get challengeTightTitle;

  /// No description provided for @challengeZeroBody.
  ///
  /// In it, this message translates to:
  /// **'Parti da 94 punti: trova i 7 punti esatti e torna a zero.'**
  String get challengeZeroBody;

  /// No description provided for @challengeZeroTitle.
  ///
  /// In it, this message translates to:
  /// **'Ritorno a zero'**
  String get challengeZeroTitle;

  /// No description provided for @chooseSuit.
  ///
  /// In it, this message translates to:
  /// **'Scegli il palo'**
  String get chooseSuit;

  /// No description provided for @coachDraw.
  ///
  /// In it, this message translates to:
  /// **'Nessuna carta valida? Tocca il mazzo per pescare.'**
  String get coachDraw;

  /// No description provided for @coachFateRing.
  ///
  /// In it, this message translates to:
  /// **'L’anello mostra quanto manca a 101. A 101 esatti torni a zero.'**
  String get coachFateRing;

  /// No description provided for @coachMatch.
  ///
  /// In it, this message translates to:
  /// **'Gioca una carta dello stesso palo o valore.'**
  String get coachMatch;

  /// No description provided for @coachSpecials.
  ///
  /// In it, this message translates to:
  /// **'Asso salta il turno, 2 fa pescare, Cavallo cambia palo.'**
  String get coachSpecials;

  /// No description provided for @commonBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get commonClose;

  /// No description provided for @commonComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Disponibile a breve'**
  String get commonComingSoon;

  /// No description provided for @commonEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Non c’è ancora nulla'**
  String get commonEmptyTitle;

  /// No description provided for @commonErrorBody.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a completare l’operazione. Riprova.'**
  String get commonErrorBody;

  /// No description provided for @commonErrorTitle.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa è andato storto'**
  String get commonErrorTitle;

  /// No description provided for @commonLoading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento…'**
  String get commonLoading;

  /// No description provided for @commonNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get commonNext;

  /// No description provided for @commonOff.
  ///
  /// In it, this message translates to:
  /// **'Disattivata'**
  String get commonOff;

  /// No description provided for @commonOn.
  ///
  /// In it, this message translates to:
  /// **'Attiva'**
  String get commonOn;

  /// No description provided for @commonOptional.
  ///
  /// In it, this message translates to:
  /// **'facoltativo'**
  String get commonOptional;

  /// No description provided for @commonRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get commonSave;

  /// No description provided for @commonSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get commonSkip;

  /// No description provided for @commonStart.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get commonStart;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @continueGame.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get continueGame;

  /// No description provided for @createRoomCta.
  ///
  /// In it, this message translates to:
  /// **'CREA LA STANZA'**
  String get createRoomCta;

  /// No description provided for @createRoomHouseRules.
  ///
  /// In it, this message translates to:
  /// **'Regole della casa'**
  String get createRoomHouseRules;

  /// No description provided for @createRoomName.
  ///
  /// In it, this message translates to:
  /// **'Nome della stanza'**
  String get createRoomName;

  /// No description provided for @createRoomNameHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Tavolo di Marco'**
  String get createRoomNameHint;

  /// No description provided for @createRoomPrivate.
  ///
  /// In it, this message translates to:
  /// **'Stanza privata'**
  String get createRoomPrivate;

  /// No description provided for @createRoomPrivateHint.
  ///
  /// In it, this message translates to:
  /// **'Si entra solo con il codice'**
  String get createRoomPrivateHint;

  /// No description provided for @createRoomTimer.
  ///
  /// In it, this message translates to:
  /// **'Timer del turno'**
  String get createRoomTimer;

  /// No description provided for @createRoomTimerOff.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get createRoomTimerOff;

  /// No description provided for @createRoomTimerSeconds.
  ///
  /// In it, this message translates to:
  /// **'{seconds} secondi'**
  String createRoomTimerSeconds(int seconds);

  /// No description provided for @createRoomTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea una stanza'**
  String get createRoomTitle;

  /// No description provided for @dailyChallenge.
  ///
  /// In it, this message translates to:
  /// **'Sfida del Giorno'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeDone.
  ///
  /// In it, this message translates to:
  /// **'Sfida completata'**
  String get dailyChallengeDone;

  /// No description provided for @dailyReward.
  ///
  /// In it, this message translates to:
  /// **'Ricompensa'**
  String get dailyReward;

  /// No description provided for @dailyRewardBalance.
  ///
  /// In it, this message translates to:
  /// **'{coins} monete'**
  String dailyRewardBalance(int coins);

  /// No description provided for @dailyRewardBody.
  ///
  /// In it, this message translates to:
  /// **'Torna ogni giorno: la ricompensa cresce fino al settimo.'**
  String get dailyRewardBody;

  /// No description provided for @dailyRewardClaim.
  ///
  /// In it, this message translates to:
  /// **'RITIRA'**
  String get dailyRewardClaim;

  /// No description provided for @dailyRewardClaimFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile riscuotere il premio. Riprova.'**
  String get dailyRewardClaimFailed;

  /// No description provided for @dailyRewardClaimed.
  ///
  /// In it, this message translates to:
  /// **'Ritirata'**
  String get dailyRewardClaimed;

  /// No description provided for @dailyRewardClaimedToday.
  ///
  /// In it, this message translates to:
  /// **'Riscosso oggi. Torna domani!'**
  String get dailyRewardClaimedToday;

  /// No description provided for @dailyRewardDay.
  ///
  /// In it, this message translates to:
  /// **'Giorno {day}'**
  String dailyRewardDay(int day);

  /// No description provided for @dailyRewardGuestHint.
  ///
  /// In it, this message translates to:
  /// **'Crea un account per riscuotere i premi giornalieri.'**
  String get dailyRewardGuestHint;

  /// No description provided for @dailyRewardTitle.
  ///
  /// In it, this message translates to:
  /// **'Ricompensa giornaliera'**
  String get dailyRewardTitle;

  /// No description provided for @dailyRewardTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Torna domani'**
  String get dailyRewardTomorrow;

  /// No description provided for @defaultDifficulty.
  ///
  /// In it, this message translates to:
  /// **'Difficoltà predefinita'**
  String get defaultDifficulty;

  /// No description provided for @difficulty.
  ///
  /// In it, this message translates to:
  /// **'Difficoltà'**
  String get difficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In it, this message translates to:
  /// **'Facile'**
  String get difficultyEasy;

  /// No description provided for @difficultyHard.
  ///
  /// In it, this message translates to:
  /// **'Difficile'**
  String get difficultyHard;

  /// No description provided for @difficultyNormal.
  ///
  /// In it, this message translates to:
  /// **'Normale'**
  String get difficultyNormal;

  /// No description provided for @discardPile.
  ///
  /// In it, this message translates to:
  /// **'Scarti'**
  String get discardPile;

  /// No description provided for @discardTop.
  ///
  /// In it, this message translates to:
  /// **'Scarti: {card}'**
  String discardTop(String card);

  /// No description provided for @drawCard.
  ///
  /// In it, this message translates to:
  /// **'Pesca'**
  String get drawCard;

  /// No description provided for @drawPile.
  ///
  /// In it, this message translates to:
  /// **'Mazzo'**
  String get drawPile;

  /// No description provided for @editProfileAvatar.
  ///
  /// In it, this message translates to:
  /// **'Scegli un avatar'**
  String get editProfileAvatar;

  /// No description provided for @editProfileTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica profilo'**
  String get editProfileTitle;

  /// No description provided for @eliminated.
  ///
  /// In it, this message translates to:
  /// **'ELIMINATO'**
  String get eliminated;

  /// No description provided for @exit.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get exit;

  /// No description provided for @exitBody.
  ///
  /// In it, this message translates to:
  /// **'La partita verrà salvata automaticamente.'**
  String get exitBody;

  /// No description provided for @exitTitle.
  ///
  /// In it, this message translates to:
  /// **'Vuoi uscire?'**
  String get exitTitle;

  /// No description provided for @exitToMenu.
  ///
  /// In it, this message translates to:
  /// **'Esci al Menu'**
  String get exitToMenu;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get fieldConfirmPassword;

  /// No description provided for @fieldEmail.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldNickname.
  ///
  /// In it, this message translates to:
  /// **'Nickname'**
  String get fieldNickname;

  /// No description provided for @fieldPassword.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @finalPoints.
  ///
  /// In it, this message translates to:
  /// **'Punti finali'**
  String get finalPoints;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In it, this message translates to:
  /// **'Torna all’accesso'**
  String get forgotBackToLogin;

  /// No description provided for @forgotBody.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua email: ti invieremo un link per reimpostare la password.'**
  String get forgotBody;

  /// No description provided for @forgotCta.
  ///
  /// In it, this message translates to:
  /// **'INVIA IL LINK'**
  String get forgotCta;

  /// No description provided for @forgotSentBody.
  ///
  /// In it, this message translates to:
  /// **'Se esiste un account per {email}, il link per reimpostare la password è in arrivo.'**
  String forgotSentBody(String email);

  /// No description provided for @forgotSentTitle.
  ///
  /// In it, this message translates to:
  /// **'Email inviata'**
  String get forgotSentTitle;

  /// No description provided for @forgotTitle.
  ///
  /// In it, this message translates to:
  /// **'Recupera la password'**
  String get forgotTitle;

  /// No description provided for @gotIt.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get gotIt;

  /// No description provided for @haptics.
  ///
  /// In it, this message translates to:
  /// **'Vibrazione'**
  String get haptics;

  /// No description provided for @hidePassword.
  ///
  /// In it, this message translates to:
  /// **'Nascondi la password'**
  String get hidePassword;

  /// No description provided for @highContrast.
  ///
  /// In it, this message translates to:
  /// **'Alto contrasto'**
  String get highContrast;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeCreateRoom.
  ///
  /// In it, this message translates to:
  /// **'CREA STANZA'**
  String get homeCreateRoom;

  /// No description provided for @homeJoinRoom.
  ///
  /// In it, this message translates to:
  /// **'ENTRA IN UNA STANZA'**
  String get homeJoinRoom;

  /// No description provided for @homeLeaderboard.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get homeLeaderboard;

  /// No description provided for @homeMissions.
  ///
  /// In it, this message translates to:
  /// **'Missioni'**
  String get homeMissions;

  /// No description provided for @homeMissionsHint.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi di oggi'**
  String get homeMissionsHint;

  /// No description provided for @homePlayOffline.
  ///
  /// In it, this message translates to:
  /// **'GIOCA OFFLINE'**
  String get homePlayOffline;

  /// No description provided for @homePlayOnline.
  ///
  /// In it, this message translates to:
  /// **'GIOCA ONLINE'**
  String get homePlayOnline;

  /// No description provided for @homeQuickMatch.
  ///
  /// In it, this message translates to:
  /// **'PARTITA RAPIDA'**
  String get homeQuickMatch;

  /// No description provided for @howToPlay.
  ///
  /// In it, this message translates to:
  /// **'Come si Gioca'**
  String get howToPlay;

  /// No description provided for @howToPlayHint.
  ///
  /// In it, this message translates to:
  /// **'Regole in un minuto'**
  String get howToPlayHint;

  /// No description provided for @imReady.
  ///
  /// In it, this message translates to:
  /// **'SONO PRONTO'**
  String get imReady;

  /// No description provided for @joinRoomBody.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il codice a sei caratteri che ti ha dato l’host.'**
  String get joinRoomBody;

  /// No description provided for @joinRoomCta.
  ///
  /// In it, this message translates to:
  /// **'ENTRA'**
  String get joinRoomCta;

  /// No description provided for @joinRoomInvalid.
  ///
  /// In it, this message translates to:
  /// **'Il codice deve avere sei caratteri'**
  String get joinRoomInvalid;

  /// No description provided for @joinRoomPaste.
  ///
  /// In it, this message translates to:
  /// **'Incolla'**
  String get joinRoomPaste;

  /// No description provided for @joinRoomTitle.
  ///
  /// In it, this message translates to:
  /// **'Entra in una stanza'**
  String get joinRoomTitle;

  /// No description provided for @largeCards.
  ///
  /// In it, this message translates to:
  /// **'Carte grandi'**
  String get largeCards;

  /// No description provided for @leaderboardAllTime.
  ///
  /// In it, this message translates to:
  /// **'Di sempre'**
  String get leaderboardAllTime;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In it, this message translates to:
  /// **'La classifica sarà disponibile con il gioco online.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardLoadFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare la classifica.'**
  String get leaderboardLoadFailed;

  /// No description provided for @leaderboardLoadMore.
  ///
  /// In it, this message translates to:
  /// **'Carica altri'**
  String get leaderboardLoadMore;

  /// No description provided for @leaderboardNoScoresYet.
  ///
  /// In it, this message translates to:
  /// **'Ancora nessun punteggio: gioca partite online per comparire qui.'**
  String get leaderboardNoScoresYet;

  /// No description provided for @leaderboardNotRanked.
  ///
  /// In it, this message translates to:
  /// **'Non sei ancora in classifica: gioca online per entrarci.'**
  String get leaderboardNotRanked;

  /// No description provided for @leaderboardPoints.
  ///
  /// In it, this message translates to:
  /// **'Punti'**
  String get leaderboardPoints;

  /// No description provided for @leaderboardRank.
  ///
  /// In it, this message translates to:
  /// **'Pos.'**
  String get leaderboardRank;

  /// No description provided for @leaderboardTitle.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardWeekly.
  ///
  /// In it, this message translates to:
  /// **'Settimanale'**
  String get leaderboardWeekly;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione'**
  String get leaderboardYourRank;

  /// No description provided for @lobbyAway.
  ///
  /// In it, this message translates to:
  /// **'Assente'**
  String get lobbyAway;

  /// No description provided for @lobbyCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice copiato'**
  String get lobbyCopied;

  /// No description provided for @lobbyEmptySlot.
  ///
  /// In it, this message translates to:
  /// **'In attesa di un giocatore'**
  String get lobbyEmptySlot;

  /// No description provided for @lobbyHost.
  ///
  /// In it, this message translates to:
  /// **'Host'**
  String get lobbyHost;

  /// No description provided for @lobbyLeave.
  ///
  /// In it, this message translates to:
  /// **'Esci dalla stanza'**
  String get lobbyLeave;

  /// No description provided for @lobbyNotReady.
  ///
  /// In it, this message translates to:
  /// **'In attesa'**
  String get lobbyNotReady;

  /// No description provided for @lobbyNotReadyToggle.
  ///
  /// In it, this message translates to:
  /// **'Non sono pronto'**
  String get lobbyNotReadyToggle;

  /// No description provided for @lobbyReady.
  ///
  /// In it, this message translates to:
  /// **'Pronto'**
  String get lobbyReady;

  /// No description provided for @lobbyReadyToggle.
  ///
  /// In it, this message translates to:
  /// **'Sono pronto'**
  String get lobbyReadyToggle;

  /// No description provided for @lobbyRoomCode.
  ///
  /// In it, this message translates to:
  /// **'Codice stanza'**
  String get lobbyRoomCode;

  /// No description provided for @lobbyShare.
  ///
  /// In it, this message translates to:
  /// **'Condividi il codice'**
  String get lobbyShare;

  /// No description provided for @lobbyStart.
  ///
  /// In it, this message translates to:
  /// **'INIZIA LA PARTITA'**
  String get lobbyStart;

  /// No description provided for @lobbyStartFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile avviare: {reason}'**
  String lobbyStartFailed(String reason);

  /// No description provided for @lobbyStartPending.
  ///
  /// In it, this message translates to:
  /// **'La partita parte quando tutti i posti sono occupati e ogni giocatore è pronto.'**
  String get lobbyStartPending;

  /// No description provided for @lobbyStarting.
  ///
  /// In it, this message translates to:
  /// **'La partita sta per iniziare…'**
  String get lobbyStarting;

  /// No description provided for @lobbyTitle.
  ///
  /// In it, this message translates to:
  /// **'Sala d’attesa'**
  String get lobbyTitle;

  /// No description provided for @lobbyWaitingForHost.
  ///
  /// In it, this message translates to:
  /// **'In attesa che l’host avvii la partita…'**
  String get lobbyWaitingForHost;

  /// No description provided for @lobbyWaitingForPlayers.
  ///
  /// In it, this message translates to:
  /// **'In attesa di altri giocatori…'**
  String get lobbyWaitingForPlayers;

  /// No description provided for @locked.
  ///
  /// In it, this message translates to:
  /// **'Da sbloccare'**
  String get locked;

  /// No description provided for @loginCta.
  ///
  /// In it, this message translates to:
  /// **'ACCEDI'**
  String get loginCta;

  /// No description provided for @loginForgot.
  ///
  /// In it, this message translates to:
  /// **'Password dimenticata?'**
  String get loginForgot;

  /// No description provided for @loginNoAccount.
  ///
  /// In it, this message translates to:
  /// **'Non hai un account?'**
  String get loginNoAccount;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginTitle;

  /// No description provided for @longestChain.
  ///
  /// In it, this message translates to:
  /// **'Catena più lunga'**
  String get longestChain;

  /// No description provided for @matchWinner.
  ///
  /// In it, this message translates to:
  /// **'VINCITORE'**
  String get matchWinner;

  /// No description provided for @matchmakingBusy.
  ///
  /// In it, this message translates to:
  /// **'Hai già una partita in corso.'**
  String get matchmakingBusy;

  /// No description provided for @matchmakingCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla la ricerca'**
  String get matchmakingCancel;

  /// No description provided for @matchmakingCpuHint.
  ///
  /// In it, this message translates to:
  /// **'Nessun altro giocatore per ora. Puoi giocare subito offline contro il computer: non vale per la classifica.'**
  String get matchmakingCpuHint;

  /// No description provided for @matchmakingCpuOffer.
  ///
  /// In it, this message translates to:
  /// **'Continua contro CPU'**
  String get matchmakingCpuOffer;

  /// No description provided for @matchmakingElapsed.
  ///
  /// In it, this message translates to:
  /// **'Tempo di attesa {seconds}s'**
  String matchmakingElapsed(int seconds);

  /// No description provided for @matchmakingFound.
  ///
  /// In it, this message translates to:
  /// **'{found} di {total} giocatori'**
  String matchmakingFound(int found, int total);

  /// No description provided for @matchmakingMatched.
  ///
  /// In it, this message translates to:
  /// **'Tavolo trovato!'**
  String get matchmakingMatched;

  /// No description provided for @matchmakingPlayers.
  ///
  /// In it, this message translates to:
  /// **'Giocatori al tavolo'**
  String get matchmakingPlayers;

  /// No description provided for @matchmakingSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca partita'**
  String get matchmakingSearch;

  /// No description provided for @matchmakingSearching.
  ///
  /// In it, this message translates to:
  /// **'Cerchiamo altri giocatori veri per un tavolo da {count}…'**
  String matchmakingSearching(int count);

  /// No description provided for @matchmakingTitle.
  ///
  /// In it, this message translates to:
  /// **'Ricerca in corso'**
  String get matchmakingTitle;

  /// No description provided for @missionBlockTwo.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Blocca un +2 con il Cavallo} other{Blocca {n} +2 con il Cavallo}}'**
  String missionBlockTwo(int n);

  /// No description provided for @missionOnlineMatch.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Completa una partita online} other{Completa {n} partite online}}'**
  String missionOnlineMatch(int n);

  /// No description provided for @missionPlayAces.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Gioca un Asso} other{Gioca {n} Assi}}'**
  String missionPlayAces(int n);

  /// No description provided for @missionPlayMatches.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Gioca una partita} other{Gioca {n} partite}}'**
  String missionPlayMatches(int n);

  /// No description provided for @missionPlayTwos.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Gioca un 2} other{Gioca {n} carte 2}}'**
  String missionPlayTwos(int n);

  /// No description provided for @missionUseNine.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Usa un Cavallo (9)} other{Usa {n} Cavalli (9)}}'**
  String missionUseNine(int n);

  /// No description provided for @missionWinMatch.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Vinci una partita} other{Vinci {n} partite}}'**
  String missionWinMatch(int n);

  /// No description provided for @missionsClaim.
  ///
  /// In it, this message translates to:
  /// **'RISCUOTI'**
  String get missionsClaim;

  /// No description provided for @missionsClaimFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile riscuotere la ricompensa.'**
  String get missionsClaimFailed;

  /// No description provided for @missionsClaimed.
  ///
  /// In it, this message translates to:
  /// **'Riscossa'**
  String get missionsClaimed;

  /// No description provided for @missionsCycleHint.
  ///
  /// In it, this message translates to:
  /// **'Nuove missioni ogni giorno, su un ciclo di sette giorni.'**
  String get missionsCycleHint;

  /// No description provided for @missionsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna missione oggi.'**
  String get missionsEmpty;

  /// No description provided for @missionsLoadFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile caricare le missioni online.'**
  String get missionsLoadFailed;

  /// No description provided for @missionsOffline.
  ///
  /// In it, this message translates to:
  /// **'Offline (questo dispositivo)'**
  String get missionsOffline;

  /// No description provided for @missionsOnline.
  ///
  /// In it, this message translates to:
  /// **'Missioni online'**
  String get missionsOnline;

  /// No description provided for @missionsOnlineOnly.
  ///
  /// In it, this message translates to:
  /// **'Solo online'**
  String get missionsOnlineOnly;

  /// No description provided for @missionsProgress.
  ///
  /// In it, this message translates to:
  /// **'{done}/{total} completate'**
  String missionsProgress(int done, int total);

  /// No description provided for @missionsReward.
  ///
  /// In it, this message translates to:
  /// **'+{xp} XP'**
  String missionsReward(int xp);

  /// No description provided for @missionsSignInHint.
  ///
  /// In it, this message translates to:
  /// **'Accedi per le missioni online: l’esperienza va sul tuo profilo.'**
  String get missionsSignInHint;

  /// No description provided for @missionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Missioni del giorno'**
  String get missionsTitle;

  /// No description provided for @mode.
  ///
  /// In it, this message translates to:
  /// **'Modalità'**
  String get mode;

  /// No description provided for @modePassAndPlay.
  ///
  /// In it, this message translates to:
  /// **'Passa & Gioca'**
  String get modePassAndPlay;

  /// No description provided for @modeVsComputer.
  ///
  /// In it, this message translates to:
  /// **'Contro il computer'**
  String get modeVsComputer;

  /// No description provided for @music.
  ///
  /// In it, this message translates to:
  /// **'Musica'**
  String get music;

  /// No description provided for @networkOffline.
  ///
  /// In it, this message translates to:
  /// **'Nessuna connessione'**
  String get networkOffline;

  /// No description provided for @networkReconnecting.
  ///
  /// In it, this message translates to:
  /// **'Riconnessione…'**
  String get networkReconnecting;

  /// No description provided for @newGame.
  ///
  /// In it, this message translates to:
  /// **'Nuova Partita'**
  String get newGame;

  /// No description provided for @newMatch.
  ///
  /// In it, this message translates to:
  /// **'Nuova Partita'**
  String get newMatch;

  /// No description provided for @nextRound.
  ///
  /// In it, this message translates to:
  /// **'Prossimo Round'**
  String get nextRound;

  /// No description provided for @noStatsYet.
  ///
  /// In it, this message translates to:
  /// **'Gioca una partita per iniziare a raccogliere dati.'**
  String get noStatsYet;

  /// No description provided for @onboard1Body.
  ///
  /// In it, this message translates to:
  /// **'Un mazzo tradizionale da 40 carte — Denari, Coppe, Spade e Bastoni — disegnato a mano per lo schermo.'**
  String get onboard1Body;

  /// No description provided for @onboard1Title.
  ///
  /// In it, this message translates to:
  /// **'Carte napoletane'**
  String get onboard1Title;

  /// No description provided for @onboard2Body.
  ///
  /// In it, this message translates to:
  /// **'L’Asso salta il turno, il 2 fa pescare, il Cavallo cambia palo. Arrivare a 101 esatti azzera il punteggio.'**
  String get onboard2Body;

  /// No description provided for @onboard2Title.
  ///
  /// In it, this message translates to:
  /// **'Le regole del 101'**
  String get onboard2Title;

  /// No description provided for @onboard3Body.
  ///
  /// In it, this message translates to:
  /// **'Crea una stanza, condividi il codice e sfida da due a quattro giocatori online.'**
  String get onboard3Body;

  /// No description provided for @onboard3Title.
  ///
  /// In it, this message translates to:
  /// **'Gioca con gli amici'**
  String get onboard3Title;

  /// No description provided for @onlineCreateRoomHint.
  ///
  /// In it, this message translates to:
  /// **'Invita gli amici con un codice'**
  String get onlineCreateRoomHint;

  /// No description provided for @onlineDisconnected.
  ///
  /// In it, this message translates to:
  /// **'Connessione persa. Tentativo di riconnessione...'**
  String get onlineDisconnected;

  /// No description provided for @onlineForfeit.
  ///
  /// In it, this message translates to:
  /// **'Abbandona'**
  String get onlineForfeit;

  /// No description provided for @onlineForfeitBody.
  ///
  /// In it, this message translates to:
  /// **'La partita verrà data persa e non potrai rientrare.'**
  String get onlineForfeitBody;

  /// No description provided for @onlineForfeitTitle.
  ///
  /// In it, this message translates to:
  /// **'Abbandoni la partita?'**
  String get onlineForfeitTitle;

  /// No description provided for @onlineJoinRoomHint.
  ///
  /// In it, this message translates to:
  /// **'Hai un codice? Entra subito'**
  String get onlineJoinRoomHint;

  /// No description provided for @onlineMatchAbandoned.
  ///
  /// In it, this message translates to:
  /// **'La partita è stata abbandonata'**
  String get onlineMatchAbandoned;

  /// No description provided for @onlineMoveRefused.
  ///
  /// In it, this message translates to:
  /// **'Mossa non valida.'**
  String get onlineMoveRefused;

  /// No description provided for @onlineMoveStale.
  ///
  /// In it, this message translates to:
  /// **'Il tavolo era cambiato: riprova'**
  String get onlineMoveStale;

  /// No description provided for @onlineNotYourTurn.
  ///
  /// In it, this message translates to:
  /// **'Non è il tuo turno.'**
  String get onlineNotYourTurn;

  /// No description provided for @onlineOpponentLeft.
  ///
  /// In it, this message translates to:
  /// **'{name} ha abbandonato la partita'**
  String onlineOpponentLeft(String name);

  /// No description provided for @onlineQuickMatchHint.
  ///
  /// In it, this message translates to:
  /// **'Ti troviamo un tavolo libero'**
  String get onlineQuickMatchHint;

  /// No description provided for @onlineRejoinMatch.
  ///
  /// In it, this message translates to:
  /// **'Rientra nella partita'**
  String get onlineRejoinMatch;

  /// No description provided for @onlineRejoinMatchHint.
  ///
  /// In it, this message translates to:
  /// **'Una partita online ti sta aspettando'**
  String get onlineRejoinMatchHint;

  /// No description provided for @onlineRematchWaiting.
  ///
  /// In it, this message translates to:
  /// **'In attesa degli altri ({votes}/{needed})'**
  String onlineRematchWaiting(int votes, int needed);

  /// No description provided for @onlineSignInRequired.
  ///
  /// In it, this message translates to:
  /// **'Accedi o gioca come ospite per usare le funzioni online.'**
  String get onlineSignInRequired;

  /// No description provided for @onlineTitle.
  ///
  /// In it, this message translates to:
  /// **'Gioca online'**
  String get onlineTitle;

  /// No description provided for @onlineTurnSeconds.
  ///
  /// In it, this message translates to:
  /// **'{seconds}s'**
  String onlineTurnSeconds(int seconds);

  /// No description provided for @onlineUnavailableRetry.
  ///
  /// In it, this message translates to:
  /// **'Servizio online non raggiungibile. Il gioco offline resta disponibile.'**
  String get onlineUnavailableRetry;

  /// No description provided for @passPhoneHint.
  ///
  /// In it, this message translates to:
  /// **'Le carte restano coperte fino al tuo tocco'**
  String get passPhoneHint;

  /// No description provided for @passPhoneTo.
  ///
  /// In it, this message translates to:
  /// **'PASSA IL TELEFONO A {name}'**
  String passPhoneTo(String name);

  /// No description provided for @passTurn.
  ///
  /// In it, this message translates to:
  /// **'Passa'**
  String get passTurn;

  /// No description provided for @pauseHint.
  ///
  /// In it, this message translates to:
  /// **'La partita è ferma: gli avversari aspettano.'**
  String get pauseHint;

  /// No description provided for @pauseResume.
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get pauseResume;

  /// No description provided for @pauseTitle.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get pauseTitle;

  /// No description provided for @penalty.
  ///
  /// In it, this message translates to:
  /// **'Penalità'**
  String get penalty;

  /// No description provided for @play.
  ///
  /// In it, this message translates to:
  /// **'GIOCA'**
  String get play;

  /// No description provided for @playerName.
  ///
  /// In it, this message translates to:
  /// **'Il tuo nome'**
  String get playerName;

  /// No description provided for @playersCount.
  ///
  /// In it, this message translates to:
  /// **'Giocatori'**
  String get playersCount;

  /// No description provided for @profile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get profile;

  /// No description provided for @profileBestStreak.
  ///
  /// In it, this message translates to:
  /// **'Serie migliore'**
  String get profileBestStreak;

  /// No description provided for @profileEdit.
  ///
  /// In it, this message translates to:
  /// **'Modifica profilo'**
  String get profileEdit;

  /// No description provided for @profileLevelValue.
  ///
  /// In it, this message translates to:
  /// **'Livello {level}'**
  String profileLevelValue(int level);

  /// No description provided for @profileLosses.
  ///
  /// In it, this message translates to:
  /// **'Sconfitte'**
  String get profileLosses;

  /// No description provided for @profileMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite'**
  String get profileMatches;

  /// No description provided for @profileNextLevel.
  ///
  /// In it, this message translates to:
  /// **'Prossimo livello: {level}'**
  String profileNextLevel(int level);

  /// No description provided for @profileNicknameTaken.
  ///
  /// In it, this message translates to:
  /// **'Questo nickname è già in uso.'**
  String get profileNicknameTaken;

  /// No description provided for @profileRating.
  ///
  /// In it, this message translates to:
  /// **'Punteggio'**
  String get profileRating;

  /// No description provided for @profileSaveFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile salvare il profilo. Riprova.'**
  String get profileSaveFailed;

  /// No description provided for @profileWinRate.
  ///
  /// In it, this message translates to:
  /// **'Vittorie %'**
  String get profileWinRate;

  /// No description provided for @profileWins.
  ///
  /// In it, this message translates to:
  /// **'Vittorie'**
  String get profileWins;

  /// No description provided for @profileXpProgress.
  ///
  /// In it, this message translates to:
  /// **'{current} / {target} XP'**
  String profileXpProgress(int current, int target);

  /// No description provided for @profileXpToNext.
  ///
  /// In it, this message translates to:
  /// **'Mancano {xp} XP'**
  String profileXpToNext(int xp);

  /// No description provided for @rankAce.
  ///
  /// In it, this message translates to:
  /// **'Asso'**
  String get rankAce;

  /// No description provided for @rankCavallo.
  ///
  /// In it, this message translates to:
  /// **'Cavallo'**
  String get rankCavallo;

  /// No description provided for @rankFante.
  ///
  /// In it, this message translates to:
  /// **'Fante'**
  String get rankFante;

  /// No description provided for @rankRe.
  ///
  /// In it, this message translates to:
  /// **'Re'**
  String get rankRe;

  /// No description provided for @reaction1.
  ///
  /// In it, this message translates to:
  /// **'Bella mossa!'**
  String get reaction1;

  /// No description provided for @reaction2.
  ///
  /// In it, this message translates to:
  /// **'Vai!'**
  String get reaction2;

  /// No description provided for @reaction3.
  ///
  /// In it, this message translates to:
  /// **'Che fortuna!'**
  String get reaction3;

  /// No description provided for @reaction4.
  ///
  /// In it, this message translates to:
  /// **'Nooo!'**
  String get reaction4;

  /// No description provided for @reaction5.
  ///
  /// In it, this message translates to:
  /// **'Tocca a te!'**
  String get reaction5;

  /// No description provided for @reaction6.
  ///
  /// In it, this message translates to:
  /// **'Pesca!'**
  String get reaction6;

  /// No description provided for @reaction7.
  ///
  /// In it, this message translates to:
  /// **'Bravo!'**
  String get reaction7;

  /// No description provided for @reaction8.
  ///
  /// In it, this message translates to:
  /// **'Rivincita!'**
  String get reaction8;

  /// No description provided for @reactionAhahaha.
  ///
  /// In it, this message translates to:
  /// **'Ahahaha! 😂'**
  String get reactionAhahaha;

  /// No description provided for @reactionBellaMossa.
  ///
  /// In it, this message translates to:
  /// **'Bella mossa! 😎'**
  String get reactionBellaMossa;

  /// No description provided for @reactionBravo.
  ///
  /// In it, this message translates to:
  /// **'Bravo! 👏'**
  String get reactionBravo;

  /// No description provided for @reactionCheFortuna.
  ///
  /// In it, this message translates to:
  /// **'Che fortuna! 🍀'**
  String get reactionCheFortuna;

  /// No description provided for @reactionCiao.
  ///
  /// In it, this message translates to:
  /// **'Ciao! 👋'**
  String get reactionCiao;

  /// No description provided for @reactionGg.
  ///
  /// In it, this message translates to:
  /// **'GG! 🤝'**
  String get reactionGg;

  /// No description provided for @reactionMammaMia.
  ///
  /// In it, this message translates to:
  /// **'Mamma mia! 😱'**
  String get reactionMammaMia;

  /// No description provided for @reactionRateLimited.
  ///
  /// In it, this message translates to:
  /// **'Aspetta un attimo prima della prossima reazione'**
  String get reactionRateLimited;

  /// No description provided for @reactionRivincita.
  ///
  /// In it, this message translates to:
  /// **'Rivincita? 🔁'**
  String get reactionRivincita;

  /// No description provided for @reactions.
  ///
  /// In it, this message translates to:
  /// **'Reazioni'**
  String get reactions;

  /// No description provided for @reduceMotion.
  ///
  /// In it, this message translates to:
  /// **'Riduci movimento'**
  String get reduceMotion;

  /// No description provided for @rematch.
  ///
  /// In it, this message translates to:
  /// **'Rivincita'**
  String get rematch;

  /// No description provided for @replayAgain.
  ///
  /// In it, this message translates to:
  /// **'Rivedi'**
  String get replayAgain;

  /// No description provided for @replayLastHand.
  ///
  /// In it, this message translates to:
  /// **'Rivedi ultima mano'**
  String get replayLastHand;

  /// No description provided for @resetStatistics.
  ///
  /// In it, this message translates to:
  /// **'Azzera statistiche'**
  String get resetStatistics;

  /// No description provided for @resetStatisticsBody.
  ///
  /// In it, this message translates to:
  /// **'Tutti i progressi locali verranno cancellati. Vuoi continuare?'**
  String get resetStatisticsBody;

  /// No description provided for @resumeMatch.
  ///
  /// In it, this message translates to:
  /// **'Continua partita'**
  String get resumeMatch;

  /// No description provided for @resumeMatchHint.
  ///
  /// In it, this message translates to:
  /// **'Continua da dove eri rimasto'**
  String get resumeMatchHint;

  /// No description provided for @roomAlreadyInMatch.
  ///
  /// In it, this message translates to:
  /// **'Hai già una partita online in corso. Rientra al tavolo o abbandonala prima di aprirne un’altra.'**
  String get roomAlreadyInMatch;

  /// No description provided for @roomAlreadyStarted.
  ///
  /// In it, this message translates to:
  /// **'La partita è già iniziata.'**
  String get roomAlreadyStarted;

  /// No description provided for @roomCreateFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire la stanza. Riprova.'**
  String get roomCreateFailed;

  /// No description provided for @roomFull.
  ///
  /// In it, this message translates to:
  /// **'La stanza è piena.'**
  String get roomFull;

  /// No description provided for @roomJoinFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile entrare nella stanza. Riprova.'**
  String get roomJoinFailed;

  /// No description provided for @roomNotFound.
  ///
  /// In it, this message translates to:
  /// **'Stanza non trovata.'**
  String get roomNotFound;

  /// No description provided for @round.
  ///
  /// In it, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @roundComplete.
  ///
  /// In it, this message translates to:
  /// **'ROUND COMPLETATO'**
  String get roundComplete;

  /// No description provided for @roundWinner.
  ///
  /// In it, this message translates to:
  /// **'Vince il round'**
  String get roundWinner;

  /// No description provided for @roundsPlayed.
  ///
  /// In it, this message translates to:
  /// **'Round giocati'**
  String get roundsPlayed;

  /// No description provided for @ruleEliminate.
  ///
  /// In it, this message translates to:
  /// **'Eliminazione oltre 101'**
  String get ruleEliminate;

  /// No description provided for @ruleEliminateHint.
  ///
  /// In it, this message translates to:
  /// **'Chi supera 101 esce dalla partita'**
  String get ruleEliminateHint;

  /// No description provided for @ruleExactReset.
  ///
  /// In it, this message translates to:
  /// **'Ritorno a zero a 101'**
  String get ruleExactReset;

  /// No description provided for @ruleExactResetHint.
  ///
  /// In it, this message translates to:
  /// **'Esattamente 101 azzera il punteggio'**
  String get ruleExactResetHint;

  /// No description provided for @ruleNineBlock.
  ///
  /// In it, this message translates to:
  /// **'Cavallo contro il 2'**
  String get ruleNineBlock;

  /// No description provided for @ruleNineBlockCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla la catena'**
  String get ruleNineBlockCancel;

  /// No description provided for @ruleNineBlockDisabled.
  ///
  /// In it, this message translates to:
  /// **'Non consentito'**
  String get ruleNineBlockDisabled;

  /// No description provided for @ruleNineBlockPassOn.
  ///
  /// In it, this message translates to:
  /// **'Passa la catena'**
  String get ruleNineBlockPassOn;

  /// No description provided for @ruleStackTwos.
  ///
  /// In it, this message translates to:
  /// **'Somma dei 2'**
  String get ruleStackTwos;

  /// No description provided for @ruleStackTwosHint.
  ///
  /// In it, this message translates to:
  /// **'I 2 si possono incatenare'**
  String get ruleStackTwosHint;

  /// No description provided for @ruleVoluntaryDraw.
  ///
  /// In it, this message translates to:
  /// **'Pesca volontaria'**
  String get ruleVoluntaryDraw;

  /// No description provided for @ruleVoluntaryDrawHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi pescare anche se hai una carta'**
  String get ruleVoluntaryDrawHint;

  /// No description provided for @ruleWildNine.
  ///
  /// In it, this message translates to:
  /// **'Cavallo sempre giocabile'**
  String get ruleWildNine;

  /// No description provided for @ruleWildNineHint.
  ///
  /// In it, this message translates to:
  /// **'Il 9 cambia palo in ogni momento'**
  String get ruleWildNineHint;

  /// No description provided for @rulesActiveTitle.
  ///
  /// In it, this message translates to:
  /// **'Regole di questa partita'**
  String get rulesActiveTitle;

  /// No description provided for @savedFrom101.
  ///
  /// In it, this message translates to:
  /// **'SALVO!'**
  String get savedFrom101;

  /// No description provided for @sectionSettings.
  ///
  /// In it, this message translates to:
  /// **'IMPOSTAZIONI'**
  String get sectionSettings;

  /// No description provided for @sectionStatistics.
  ///
  /// In it, this message translates to:
  /// **'STATISTICHE'**
  String get sectionStatistics;

  /// No description provided for @sessionExpired.
  ///
  /// In it, this message translates to:
  /// **'Sessione scaduta. Accedi di nuovo.'**
  String get sessionExpired;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @settingsAccount.
  ///
  /// In it, this message translates to:
  /// **'ACCOUNT'**
  String get settingsAccount;

  /// No description provided for @settingsGuestLogoutBody.
  ///
  /// In it, this message translates to:
  /// **'Sei un ospite: uscendo perderai questo account e i suoi progressi online per sempre.'**
  String get settingsGuestLogoutBody;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageItalian;

  /// No description provided for @settingsLinkPending.
  ///
  /// In it, this message translates to:
  /// **'Il link sarà disponibile alla pubblicazione.'**
  String get settingsLinkPending;

  /// No description provided for @settingsLogout.
  ///
  /// In it, this message translates to:
  /// **'Esci dall’account'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutBody.
  ///
  /// In it, this message translates to:
  /// **'Uscirai dall’account su questo dispositivo. I progressi salvati sull’account restano.'**
  String get settingsLogoutBody;

  /// No description provided for @settingsLogoutGuest.
  ///
  /// In it, this message translates to:
  /// **'Esci (account ospite)'**
  String get settingsLogoutGuest;

  /// No description provided for @settingsPrivacy.
  ///
  /// In it, this message translates to:
  /// **'Informativa sulla privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In it, this message translates to:
  /// **'Termini di servizio'**
  String get settingsTerms;

  /// No description provided for @setupOtherPlayers.
  ///
  /// In it, this message translates to:
  /// **'Altri giocatori'**
  String get setupOtherPlayers;

  /// No description provided for @setupPlayerN.
  ///
  /// In it, this message translates to:
  /// **'Giocatore {n}'**
  String setupPlayerN(int n);

  /// No description provided for @setupResetRules.
  ///
  /// In it, this message translates to:
  /// **'Ripristina regole'**
  String get setupResetRules;

  /// No description provided for @showPassword.
  ///
  /// In it, this message translates to:
  /// **'Mostra la password'**
  String get showPassword;

  /// No description provided for @signupCta.
  ///
  /// In it, this message translates to:
  /// **'REGISTRATI'**
  String get signupCta;

  /// No description provided for @signupHaveAccount.
  ///
  /// In it, this message translates to:
  /// **'Hai già un account?'**
  String get signupHaveAccount;

  /// No description provided for @signupTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea un account'**
  String get signupTitle;

  /// No description provided for @soundEffects.
  ///
  /// In it, this message translates to:
  /// **'Effetti sonori'**
  String get soundEffects;

  /// No description provided for @startMatch.
  ///
  /// In it, this message translates to:
  /// **'INIZIA PARTITA'**
  String get startMatch;

  /// No description provided for @startingHand.
  ///
  /// In it, this message translates to:
  /// **'Carte iniziali'**
  String get startingHand;

  /// No description provided for @statAces.
  ///
  /// In it, this message translates to:
  /// **'Assi usati'**
  String get statAces;

  /// No description provided for @statBestStreak.
  ///
  /// In it, this message translates to:
  /// **'Serie migliore'**
  String get statBestStreak;

  /// No description provided for @statCards.
  ///
  /// In it, this message translates to:
  /// **'Carte giocate'**
  String get statCards;

  /// No description provided for @statChain.
  ///
  /// In it, this message translates to:
  /// **'Catena più lunga'**
  String get statChain;

  /// No description provided for @statComeback.
  ///
  /// In it, this message translates to:
  /// **'Rimonta più grande'**
  String get statComeback;

  /// No description provided for @statFavouriteSuit.
  ///
  /// In it, this message translates to:
  /// **'Palo preferito'**
  String get statFavouriteSuit;

  /// No description provided for @statMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite giocate'**
  String get statMatches;

  /// No description provided for @statOnlineMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite online'**
  String get statOnlineMatches;

  /// No description provided for @statResets.
  ///
  /// In it, this message translates to:
  /// **'Ritorni da 101'**
  String get statResets;

  /// No description provided for @statRoundsWon.
  ///
  /// In it, this message translates to:
  /// **'Round vinti'**
  String get statRoundsWon;

  /// No description provided for @statStreak.
  ///
  /// In it, this message translates to:
  /// **'Serie attuale'**
  String get statStreak;

  /// No description provided for @statTwos.
  ///
  /// In it, this message translates to:
  /// **'Carte +2 giocate'**
  String get statTwos;

  /// No description provided for @statWinRate.
  ///
  /// In it, this message translates to:
  /// **'Percentuale vittorie'**
  String get statWinRate;

  /// No description provided for @statWins.
  ///
  /// In it, this message translates to:
  /// **'Partite vinte'**
  String get statWins;

  /// No description provided for @statistics.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statistics;

  /// No description provided for @statsOfflineHeading.
  ///
  /// In it, this message translates to:
  /// **'OFFLINE — QUESTO DISPOSITIVO'**
  String get statsOfflineHeading;

  /// No description provided for @statsOfflineHint.
  ///
  /// In it, this message translates to:
  /// **'Le partite contro il computer non toccano la classifica online.'**
  String get statsOfflineHint;

  /// No description provided for @statsOnlineHeading.
  ///
  /// In it, this message translates to:
  /// **'ONLINE — PROFILO'**
  String get statsOnlineHeading;

  /// No description provided for @suitBastoni.
  ///
  /// In it, this message translates to:
  /// **'Bastoni'**
  String get suitBastoni;

  /// No description provided for @suitCoppe.
  ///
  /// In it, this message translates to:
  /// **'Coppe'**
  String get suitCoppe;

  /// No description provided for @suitDenari.
  ///
  /// In it, this message translates to:
  /// **'Denari'**
  String get suitDenari;

  /// No description provided for @suitSpade.
  ///
  /// In it, this message translates to:
  /// **'Spade'**
  String get suitSpade;

  /// No description provided for @tableRules.
  ///
  /// In it, this message translates to:
  /// **'Regole'**
  String get tableRules;

  /// No description provided for @tableTaglineMaiolica.
  ///
  /// In it, this message translates to:
  /// **'Ceramica mediterranea, cobalto e sole'**
  String get tableTaglineMaiolica;

  /// No description provided for @tableTaglineNapoli.
  ///
  /// In it, this message translates to:
  /// **'Oro antico sul golfo che dorme'**
  String get tableTaglineNapoli;

  /// No description provided for @tableTaglineVesuvio.
  ///
  /// In it, this message translates to:
  /// **'Cenere calda e bagliori di terracotta'**
  String get tableTaglineVesuvio;

  /// No description provided for @tableTheme.
  ///
  /// In it, this message translates to:
  /// **'Tavolo'**
  String get tableTheme;

  /// No description provided for @takePenalty.
  ///
  /// In it, this message translates to:
  /// **'Prendi'**
  String get takePenalty;

  /// No description provided for @turnSkipped.
  ///
  /// In it, this message translates to:
  /// **'TURNO SALTATO'**
  String get turnSkipped;

  /// No description provided for @tutAceDone.
  ///
  /// In it, this message translates to:
  /// **'{name} ha saltato il turno. In due, l’Asso ti riporta subito al tuo turno.'**
  String tutAceDone(String name);

  /// No description provided for @tutAcePrompt.
  ///
  /// In it, this message translates to:
  /// **'Gioca l’Asso di Coppe: l’avversario perde il turno.'**
  String get tutAcePrompt;

  /// No description provided for @tutAceTitle.
  ///
  /// In it, this message translates to:
  /// **'Asso — salta il turno'**
  String get tutAceTitle;

  /// No description provided for @tutBlockDone.
  ///
  /// In it, this message translates to:
  /// **'Il Cavallo è anche la tua difesa contro i 2. Usalo con giudizio: nel mazzo ce ne sono solo quattro.'**
  String get tutBlockDone;

  /// No description provided for @tutBlockPrompt.
  ///
  /// In it, this message translates to:
  /// **'Un 2 ti minaccia e non hai 2 da rispondere. Gioca il Cavallo di Bastoni per annullare la catena.'**
  String get tutBlockPrompt;

  /// No description provided for @tutBlockSuit.
  ///
  /// In it, this message translates to:
  /// **'Catena annullata: nessuno pesca. Scegli il palo.'**
  String get tutBlockSuit;

  /// No description provided for @tutBlockTitle.
  ///
  /// In it, this message translates to:
  /// **'Cavallo contro il 2'**
  String get tutBlockTitle;

  /// No description provided for @tutCavalloDone.
  ///
  /// In it, this message translates to:
  /// **'Il palo attivo ora è {suit}. Il Cavallo non impone il proprio palo: impone quello che scegli tu.'**
  String tutCavalloDone(String suit);

  /// No description provided for @tutCavalloPrompt.
  ///
  /// In it, this message translates to:
  /// **'Il Cavallo (il 9) si gioca sempre, su qualsiasi carta. Gioca il Cavallo di Spade.'**
  String get tutCavalloPrompt;

  /// No description provided for @tutCavalloSuit.
  ///
  /// In it, this message translates to:
  /// **'Ora scegli il nuovo palo attivo: conviene quello di cui hai più carte.'**
  String get tutCavalloSuit;

  /// No description provided for @tutCavalloTitle.
  ///
  /// In it, this message translates to:
  /// **'Cavallo — cambia palo'**
  String get tutCavalloTitle;

  /// No description provided for @tutCentounoDone.
  ///
  /// In it, this message translates to:
  /// **'92 + 9 = 101 esatti: {name} torna a zero. Chi invece supera 101 viene eliminato. Vince chi resta per ultimo.'**
  String tutCentounoDone(String name);

  /// No description provided for @tutCentounoPrompt.
  ///
  /// In it, this message translates to:
  /// **'Ultima carta! L’avversario ha 92 punti e un Cavallo (9) in mano. Gioca il 7 di Coppe e chiudi il round.'**
  String get tutCentounoPrompt;

  /// No description provided for @tutCentounoTitle.
  ///
  /// In it, this message translates to:
  /// **'Centouno!'**
  String get tutCentounoTitle;

  /// No description provided for @tutChainDone.
  ///
  /// In it, this message translates to:
  /// **'+4! {name} ha pescato quattro carte. Le catene arrivano fino a +8.'**
  String tutChainDone(String name);

  /// No description provided for @tutChainPrompt.
  ///
  /// In it, this message translates to:
  /// **'L’avversario ha giocato un 2 contro di te: rispondi con il 2 di Spade e la penalità sale a +4.'**
  String get tutChainPrompt;

  /// No description provided for @tutChainTitle.
  ///
  /// In it, this message translates to:
  /// **'La catena di 2'**
  String get tutChainTitle;

  /// No description provided for @tutDrawingDone.
  ///
  /// In it, this message translates to:
  /// **'Se la carta pescata non fosse stata giocabile, il turno sarebbe passato con Passa.'**
  String get tutDrawingDone;

  /// No description provided for @tutDrawingPlay.
  ///
  /// In it, this message translates to:
  /// **'Hai pescato il 6 di Coppe: è giocabile subito. Giocalo.'**
  String get tutDrawingPlay;

  /// No description provided for @tutDrawingPrompt.
  ///
  /// In it, this message translates to:
  /// **'Nessuna carta in mano è giocabile. Tocca il mazzo (o Pesca) per prendere una carta.'**
  String get tutDrawingPrompt;

  /// No description provided for @tutDrawingTitle.
  ///
  /// In it, this message translates to:
  /// **'Pescare'**
  String get tutDrawingTitle;

  /// No description provided for @tutFirstCardDone.
  ///
  /// In it, this message translates to:
  /// **'Perfetto. Ogni carta giocata deve seguire il palo attivo oppure il valore della carta in cima agli scarti.'**
  String get tutFirstCardDone;

  /// No description provided for @tutFirstCardPrompt.
  ///
  /// In it, this message translates to:
  /// **'In cima agli scarti c’è il 5 di Coppe. Puoi giocare una carta di Coppe oppure un altro 5: tocca due volte una carta evidenziata.'**
  String get tutFirstCardPrompt;

  /// No description provided for @tutFirstCardTitle.
  ///
  /// In it, this message translates to:
  /// **'Palo o valore'**
  String get tutFirstCardTitle;

  /// No description provided for @tutTwoDone.
  ///
  /// In it, this message translates to:
  /// **'{name} non aveva un 2: ha pescato due carte e perso il turno.'**
  String tutTwoDone(String name);

  /// No description provided for @tutTwoPrompt.
  ///
  /// In it, this message translates to:
  /// **'Gioca il 2 di Coppe: l’avversario dovrà pescare due carte, a meno che non risponda con un altro 2.'**
  String get tutTwoPrompt;

  /// No description provided for @tutTwoTitle.
  ///
  /// In it, this message translates to:
  /// **'Due — pesca due'**
  String get tutTwoTitle;

  /// No description provided for @tutorial101.
  ///
  /// In it, this message translates to:
  /// **'101 esatti'**
  String get tutorial101;

  /// No description provided for @tutorial101Body.
  ///
  /// In it, this message translates to:
  /// **'Arrivare esattamente a 101 azzera il punteggio. È il colpo di scena che può ribaltare una partita.'**
  String get tutorial101Body;

  /// No description provided for @tutorialAce.
  ///
  /// In it, this message translates to:
  /// **'Asso — salta il turno'**
  String get tutorialAce;

  /// No description provided for @tutorialAceBody.
  ///
  /// In it, this message translates to:
  /// **'L’Asso fa saltare il turno al giocatore successivo. In due, il turno torna subito a te.'**
  String get tutorialAceBody;

  /// No description provided for @tutorialCavallo.
  ///
  /// In it, this message translates to:
  /// **'Cavallo — cambia palo'**
  String get tutorialCavallo;

  /// No description provided for @tutorialCavalloBody.
  ///
  /// In it, this message translates to:
  /// **'Il Cavallo (9) si gioca in qualsiasi momento e ti lascia scegliere il nuovo palo attivo con il Rituale dei Pali.'**
  String get tutorialCavalloBody;

  /// No description provided for @tutorialCompleteBody.
  ///
  /// In it, this message translates to:
  /// **'Conosci tutte le carte speciali e il 101. Ora tocca a te.'**
  String get tutorialCompleteBody;

  /// No description provided for @tutorialCompleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutorial completato!'**
  String get tutorialCompleteTitle;

  /// No description provided for @tutorialDraw.
  ///
  /// In it, this message translates to:
  /// **'Pescare'**
  String get tutorialDraw;

  /// No description provided for @tutorialDrawBody.
  ///
  /// In it, this message translates to:
  /// **'Senza carte giocabili peschi dal mazzo. Se la carta pescata è valida puoi giocarla subito, altrimenti il turno passa.'**
  String get tutorialDrawBody;

  /// No description provided for @tutorialExitBody.
  ///
  /// In it, this message translates to:
  /// **'Potrai rifarlo dall’inizio quando vuoi.'**
  String get tutorialExitBody;

  /// No description provided for @tutorialExitTitle.
  ///
  /// In it, this message translates to:
  /// **'Vuoi uscire dal tutorial?'**
  String get tutorialExitTitle;

  /// No description provided for @tutorialFinish.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get tutorialFinish;

  /// No description provided for @tutorialGoal.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo'**
  String get tutorialGoal;

  /// No description provided for @tutorialGoalBody.
  ///
  /// In it, this message translates to:
  /// **'Libera la mano prima degli altri. Le carte che restano agli avversari diventano punti di penalità: chi supera 101 esce, chi arriva a 101 esatti torna a zero.'**
  String get tutorialGoalBody;

  /// No description provided for @tutorialHint.
  ///
  /// In it, this message translates to:
  /// **'Impara giocando, una regola alla volta'**
  String get tutorialHint;

  /// No description provided for @tutorialHintFollow.
  ///
  /// In it, this message translates to:
  /// **'Segui il suggerimento: gioca la carta evidenziata.'**
  String get tutorialHintFollow;

  /// No description provided for @tutorialMatch.
  ///
  /// In it, this message translates to:
  /// **'Palo o valore'**
  String get tutorialMatch;

  /// No description provided for @tutorialMatchBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi giocare una carta dello stesso palo attivo oppure dello stesso valore della carta in cima agli scarti.'**
  String get tutorialMatchBody;

  /// No description provided for @tutorialOver101.
  ///
  /// In it, this message translates to:
  /// **'Oltre 101'**
  String get tutorialOver101;

  /// No description provided for @tutorialOver101Body.
  ///
  /// In it, this message translates to:
  /// **'Superare 101 significa uscire dalla partita. Resta in gioco chi gestisce meglio le carte alte.'**
  String get tutorialOver101Body;

  /// No description provided for @tutorialPlayNow.
  ///
  /// In it, this message translates to:
  /// **'GIOCA CONTRO IL COMPUTER'**
  String get tutorialPlayNow;

  /// No description provided for @tutorialReplay.
  ///
  /// In it, this message translates to:
  /// **'Rifai il tutorial'**
  String get tutorialReplay;

  /// No description provided for @tutorialScoring.
  ///
  /// In it, this message translates to:
  /// **'Punteggio'**
  String get tutorialScoring;

  /// No description provided for @tutorialScoringBody.
  ///
  /// In it, this message translates to:
  /// **'A fine round ogni carta rimasta vale il suo numero: Asso 1, Fante 8, Cavallo 9, Re 10. I punti si sommano al totale.'**
  String get tutorialScoringBody;

  /// No description provided for @tutorialTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutorial interattivo'**
  String get tutorialTitle;

  /// No description provided for @tutorialTwo.
  ///
  /// In it, this message translates to:
  /// **'Due — pesca due'**
  String get tutorialTwo;

  /// No description provided for @tutorialTwoBody.
  ///
  /// In it, this message translates to:
  /// **'Il 2 obbliga il prossimo a pescare due carte. Se ha un altro 2 può rilanciare: +4, +6, +8. Chi si ferma pesca tutto e perde il turno.'**
  String get tutorialTwoBody;

  /// No description provided for @tutorialWin.
  ///
  /// In it, this message translates to:
  /// **'Vincere la partita'**
  String get tutorialWin;

  /// No description provided for @tutorialWinBody.
  ///
  /// In it, this message translates to:
  /// **'La partita finisce quando resta un solo giocatore in gioco. È lui il vincitore del Gioco del 101.'**
  String get tutorialWinBody;

  /// No description provided for @valEmailInvalid.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un’email valida'**
  String get valEmailInvalid;

  /// No description provided for @valNicknameLong.
  ///
  /// In it, this message translates to:
  /// **'Il nickname può avere al massimo 16 caratteri'**
  String get valNicknameLong;

  /// No description provided for @valNicknameShort.
  ///
  /// In it, this message translates to:
  /// **'Il nickname deve avere almeno 3 caratteri'**
  String get valNicknameShort;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non coincidono'**
  String get valPasswordMismatch;

  /// No description provided for @valPasswordShort.
  ///
  /// In it, this message translates to:
  /// **'La password deve avere almeno 8 caratteri'**
  String get valPasswordShort;

  /// No description provided for @valRequired.
  ///
  /// In it, this message translates to:
  /// **'Campo obbligatorio'**
  String get valRequired;

  /// No description provided for @yourTurn.
  ///
  /// In it, this message translates to:
  /// **'TOCCA A TE'**
  String get yourTurn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
