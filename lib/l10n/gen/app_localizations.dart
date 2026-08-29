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

  /// No description provided for @achievements.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi'**
  String get achievements;

  /// No description provided for @activeSuit.
  ///
  /// In it, this message translates to:
  /// **'Seme attivo'**
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

  /// No description provided for @backToZero.
  ///
  /// In it, this message translates to:
  /// **'RITORNO A ZERO'**
  String get backToZero;

  /// No description provided for @bestComeback.
  ///
  /// In it, this message translates to:
  /// **'Miglior rimonta'**
  String get bestComeback;

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

  /// No description provided for @chooseSuit.
  ///
  /// In it, this message translates to:
  /// **'Scegli il seme'**
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
  /// **'Gioca una carta dello stesso seme o valore.'**
  String get coachMatch;

  /// No description provided for @coachSpecials.
  ///
  /// In it, this message translates to:
  /// **'Asso salta il turno, 2 fa pescare, Cavallo cambia seme.'**
  String get coachSpecials;

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

  /// No description provided for @dailyCompleted.
  ///
  /// In it, this message translates to:
  /// **'Completata oggi'**
  String get dailyCompleted;

  /// No description provided for @dailyReward.
  ///
  /// In it, this message translates to:
  /// **'Ricompensa'**
  String get dailyReward;

  /// No description provided for @dailyStartHint.
  ///
  /// In it, this message translates to:
  /// **'Una configurazione diversa ogni giorno.'**
  String get dailyStartHint;

  /// No description provided for @dailyTitle.
  ///
  /// In it, this message translates to:
  /// **'Sfida del Giorno'**
  String get dailyTitle;

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

  /// No description provided for @finalPoints.
  ///
  /// In it, this message translates to:
  /// **'Punti finali'**
  String get finalPoints;

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

  /// No description provided for @largeCards.
  ///
  /// In it, this message translates to:
  /// **'Carte grandi'**
  String get largeCards;

  /// No description provided for @lastCard.
  ///
  /// In it, this message translates to:
  /// **'ULTIMA CARTA'**
  String get lastCard;

  /// No description provided for @locked.
  ///
  /// In it, this message translates to:
  /// **'Da sbloccare'**
  String get locked;

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
  /// **'Vs Computer'**
  String get modeVsComputer;

  /// No description provided for @music.
  ///
  /// In it, this message translates to:
  /// **'Musica'**
  String get music;

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

  /// No description provided for @passPhoneHint.
  ///
  /// In it, this message translates to:
  /// **'Le carte restano coperte fino al tuo tocco'**
  String get passPhoneHint;

  /// No description provided for @passTurn.
  ///
  /// In it, this message translates to:
  /// **'Passa'**
  String get passTurn;

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

  /// No description provided for @playDrawn.
  ///
  /// In it, this message translates to:
  /// **'Gioca la carta pescata'**
  String get playDrawn;

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
  /// **'Riprendi Partita'**
  String get resumeMatch;

  /// No description provided for @resumeMatchHint.
  ///
  /// In it, this message translates to:
  /// **'Continua da dove eri rimasto'**
  String get resumeMatchHint;

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
  /// **'Il 9 cambia seme in ogni momento'**
  String get ruleWildNineHint;

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

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @soundEffects.
  ///
  /// In it, this message translates to:
  /// **'Effetti sonori'**
  String get soundEffects;

  /// No description provided for @startChallenge.
  ///
  /// In it, this message translates to:
  /// **'ACCETTA LA SFIDA'**
  String get startChallenge;

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
  /// **'Seme preferito'**
  String get statFavouriteSuit;

  /// No description provided for @statMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite giocate'**
  String get statMatches;

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
  /// **'Cavallo — cambia seme'**
  String get tutorialCavallo;

  /// No description provided for @tutorialCavalloBody.
  ///
  /// In it, this message translates to:
  /// **'Il Cavallo (9) si gioca in qualsiasi momento e ti lascia scegliere il nuovo seme attivo con il Rituale dei Semi.'**
  String get tutorialCavalloBody;

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

  /// No description provided for @tutorialMatch.
  ///
  /// In it, this message translates to:
  /// **'Seme o valore'**
  String get tutorialMatch;

  /// No description provided for @tutorialMatchBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi giocare una carta dello stesso seme attivo oppure dello stesso valore della carta in cima agli scarti.'**
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

  /// No description provided for @yourTurn.
  ///
  /// In it, this message translates to:
  /// **'TOCCA A TE'**
  String get yourTurn;

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

  /// No description provided for @commonNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get commonNext;

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

  /// No description provided for @commonSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get commonSave;

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

  /// No description provided for @commonRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento…'**
  String get commonLoading;

  /// No description provided for @commonErrorTitle.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa è andato storto'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorBody.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a completare l’operazione. Riprova.'**
  String get commonErrorBody;

  /// No description provided for @commonEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Non c’è ancora nulla'**
  String get commonEmptyTitle;

  /// No description provided for @commonEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Quando ci saranno dati, li vedrai qui.'**
  String get commonEmptyBody;

  /// No description provided for @commonComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Disponibile a breve'**
  String get commonComingSoon;

  /// No description provided for @commonOptional.
  ///
  /// In it, this message translates to:
  /// **'facoltativo'**
  String get commonOptional;

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

  /// No description provided for @networkOnline.
  ///
  /// In it, this message translates to:
  /// **'Di nuovo online'**
  String get networkOnline;

  /// No description provided for @onboard1Title.
  ///
  /// In it, this message translates to:
  /// **'Carte napoletane'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In it, this message translates to:
  /// **'Un mazzo tradizionale da 40 carte — Denari, Coppe, Spade e Bastoni — disegnato a mano per lo schermo.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In it, this message translates to:
  /// **'Le regole del 101'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In it, this message translates to:
  /// **'L’Asso salta il turno, il 2 fa pescare, il Cavallo cambia seme. Arrivare a 101 esatti azzera il punteggio.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In it, this message translates to:
  /// **'Gioca con gli amici'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In it, this message translates to:
  /// **'Crea una stanza, condividi il codice e sfida da due a quattro giocatori online.'**
  String get onboard3Body;

  /// No description provided for @authTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi per giocare online e conservare i tuoi progressi.'**
  String get authSubtitle;

  /// No description provided for @authPlayAsGuest.
  ///
  /// In it, this message translates to:
  /// **'GIOCA COME OSPITE'**
  String get authPlayAsGuest;

  /// No description provided for @authSignIn.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get authSignIn;

  /// No description provided for @authRegister.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get authRegister;

  /// No description provided for @authGuestHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi creare un account in qualsiasi momento.'**
  String get authGuestHint;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In it, this message translates to:
  /// **'Continua con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In it, this message translates to:
  /// **'Continua con Apple'**
  String get authContinueWithApple;

  /// No description provided for @authSocialUnavailable.
  ///
  /// In it, this message translates to:
  /// **'L’accesso social non è ancora attivo.'**
  String get authSocialUnavailable;

  /// No description provided for @authBackendPending.
  ///
  /// In it, this message translates to:
  /// **'L’accesso sarà attivo quando il servizio online sarà collegato.'**
  String get authBackendPending;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginTitle;

  /// No description provided for @loginCta.
  ///
  /// In it, this message translates to:
  /// **'ACCEDI'**
  String get loginCta;

  /// No description provided for @fieldEmail.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get fieldConfirmPassword;

  /// No description provided for @fieldNickname.
  ///
  /// In it, this message translates to:
  /// **'Nickname'**
  String get fieldNickname;

  /// No description provided for @showPassword.
  ///
  /// In it, this message translates to:
  /// **'Mostra la password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In it, this message translates to:
  /// **'Nascondi la password'**
  String get hidePassword;

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

  /// No description provided for @signupTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea un account'**
  String get signupTitle;

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

  /// No description provided for @forgotTitle.
  ///
  /// In it, this message translates to:
  /// **'Recupera la password'**
  String get forgotTitle;

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

  /// No description provided for @forgotBackToLogin.
  ///
  /// In it, this message translates to:
  /// **'Torna all’accesso'**
  String get forgotBackToLogin;

  /// No description provided for @valRequired.
  ///
  /// In it, this message translates to:
  /// **'Campo obbligatorio'**
  String get valRequired;

  /// No description provided for @valEmailInvalid.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un’email valida'**
  String get valEmailInvalid;

  /// No description provided for @valPasswordShort.
  ///
  /// In it, this message translates to:
  /// **'La password deve avere almeno 8 caratteri'**
  String get valPasswordShort;

  /// No description provided for @valPasswordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non coincidono'**
  String get valPasswordMismatch;

  /// No description provided for @valNicknameShort.
  ///
  /// In it, this message translates to:
  /// **'Il nickname deve avere almeno 3 caratteri'**
  String get valNicknameShort;

  /// No description provided for @valNicknameLong.
  ///
  /// In it, this message translates to:
  /// **'Il nickname può avere al massimo 16 caratteri'**
  String get valNicknameLong;

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

  /// No description provided for @homePlayOffline.
  ///
  /// In it, this message translates to:
  /// **'GIOCA OFFLINE'**
  String get homePlayOffline;

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

  /// No description provided for @homeLeaderboard.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get homeLeaderboard;

  /// No description provided for @onlineTitle.
  ///
  /// In it, this message translates to:
  /// **'Gioca online'**
  String get onlineTitle;

  /// No description provided for @onlineQuickMatchHint.
  ///
  /// In it, this message translates to:
  /// **'Ti troviamo un tavolo libero'**
  String get onlineQuickMatchHint;

  /// No description provided for @onlineCreateRoomHint.
  ///
  /// In it, this message translates to:
  /// **'Invita gli amici con un codice'**
  String get onlineCreateRoomHint;

  /// No description provided for @onlineJoinRoomHint.
  ///
  /// In it, this message translates to:
  /// **'Hai un codice? Entra subito'**
  String get onlineJoinRoomHint;

  /// No description provided for @createRoomTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea una stanza'**
  String get createRoomTitle;

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

  /// No description provided for @createRoomHouseRules.
  ///
  /// In it, this message translates to:
  /// **'Regole della casa'**
  String get createRoomHouseRules;

  /// No description provided for @createRoomCta.
  ///
  /// In it, this message translates to:
  /// **'CREA LA STANZA'**
  String get createRoomCta;

  /// No description provided for @joinRoomTitle.
  ///
  /// In it, this message translates to:
  /// **'Entra in una stanza'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomBody.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il codice a sei caratteri che ti ha dato l’host.'**
  String get joinRoomBody;

  /// No description provided for @joinRoomPaste.
  ///
  /// In it, this message translates to:
  /// **'Incolla'**
  String get joinRoomPaste;

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

  /// No description provided for @lobbyTitle.
  ///
  /// In it, this message translates to:
  /// **'Sala d’attesa'**
  String get lobbyTitle;

  /// No description provided for @lobbyRoomCode.
  ///
  /// In it, this message translates to:
  /// **'Codice stanza'**
  String get lobbyRoomCode;

  /// No description provided for @lobbyHost.
  ///
  /// In it, this message translates to:
  /// **'Host'**
  String get lobbyHost;

  /// No description provided for @lobbyReady.
  ///
  /// In it, this message translates to:
  /// **'Pronto'**
  String get lobbyReady;

  /// No description provided for @lobbyNotReady.
  ///
  /// In it, this message translates to:
  /// **'In attesa'**
  String get lobbyNotReady;

  /// No description provided for @lobbyEmptySlot.
  ///
  /// In it, this message translates to:
  /// **'In attesa di un giocatore'**
  String get lobbyEmptySlot;

  /// No description provided for @lobbyLeave.
  ///
  /// In it, this message translates to:
  /// **'Esci dalla stanza'**
  String get lobbyLeave;

  /// No description provided for @lobbyShare.
  ///
  /// In it, this message translates to:
  /// **'Condividi il codice'**
  String get lobbyShare;

  /// No description provided for @lobbyCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice copiato'**
  String get lobbyCopied;

  /// No description provided for @lobbyStart.
  ///
  /// In it, this message translates to:
  /// **'INIZIA LA PARTITA'**
  String get lobbyStart;

  /// No description provided for @matchmakingTitle.
  ///
  /// In it, this message translates to:
  /// **'Ricerca in corso'**
  String get matchmakingTitle;

  /// No description provided for @matchmakingBody.
  ///
  /// In it, this message translates to:
  /// **'Stiamo cercando altri giocatori…'**
  String get matchmakingBody;

  /// No description provided for @matchmakingCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla la ricerca'**
  String get matchmakingCancel;

  /// No description provided for @profileLevel.
  ///
  /// In it, this message translates to:
  /// **'Livello'**
  String get profileLevel;

  /// No description provided for @profileXp.
  ///
  /// In it, this message translates to:
  /// **'Esperienza'**
  String get profileXp;

  /// No description provided for @profileMatches.
  ///
  /// In it, this message translates to:
  /// **'Partite'**
  String get profileMatches;

  /// No description provided for @profileWins.
  ///
  /// In it, this message translates to:
  /// **'Vittorie'**
  String get profileWins;

  /// No description provided for @profileLosses.
  ///
  /// In it, this message translates to:
  /// **'Sconfitte'**
  String get profileLosses;

  /// No description provided for @profileWinRate.
  ///
  /// In it, this message translates to:
  /// **'Vittorie %'**
  String get profileWinRate;

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

  /// No description provided for @editProfileTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica profilo'**
  String get editProfileTitle;

  /// No description provided for @editProfileAvatar.
  ///
  /// In it, this message translates to:
  /// **'Scegli un avatar'**
  String get editProfileAvatar;

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

  /// No description provided for @leaderboardAllTime.
  ///
  /// In it, this message translates to:
  /// **'Di sempre'**
  String get leaderboardAllTime;

  /// No description provided for @leaderboardRank.
  ///
  /// In it, this message translates to:
  /// **'Pos.'**
  String get leaderboardRank;

  /// No description provided for @leaderboardPoints.
  ///
  /// In it, this message translates to:
  /// **'Punti'**
  String get leaderboardPoints;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In it, this message translates to:
  /// **'La classifica sarà disponibile con il gioco online.'**
  String get leaderboardEmpty;

  /// No description provided for @achPrimaVittoriaTitle.
  ///
  /// In it, this message translates to:
  /// **'Prima Vittoria'**
  String get achPrimaVittoriaTitle;

  /// No description provided for @achPrimaVittoriaBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci la tua prima partita'**
  String get achPrimaVittoriaBody;

  /// No description provided for @achCentounoTitle.
  ///
  /// In it, this message translates to:
  /// **'Centouno!'**
  String get achCentounoTitle;

  /// No description provided for @achCentounoBody.
  ///
  /// In it, this message translates to:
  /// **'Arriva a 101 esatti e torna a zero'**
  String get achCentounoBody;

  /// No description provided for @achVendettaTitle.
  ///
  /// In it, this message translates to:
  /// **'Vendetta'**
  String get achVendettaTitle;

  /// No description provided for @achVendettaBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci una rivincita subito dopo una sconfitta'**
  String get achVendettaBody;

  /// No description provided for @achMaestroNoveTitle.
  ///
  /// In it, this message translates to:
  /// **'Maestro del Nove'**
  String get achMaestroNoveTitle;

  /// No description provided for @achMaestroNoveBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci dopo aver scelto tutti e quattro i semi col Cavallo'**
  String get achMaestroNoveBody;

  /// No description provided for @achImbattibileTitle.
  ///
  /// In it, this message translates to:
  /// **'Imbattibile'**
  String get achImbattibileTitle;

  /// No description provided for @achImbattibileBody.
  ///
  /// In it, this message translates to:
  /// **'Vinci cinque partite di fila'**
  String get achImbattibileBody;

  /// No description provided for @achVeteranoTitle.
  ///
  /// In it, this message translates to:
  /// **'Veterano'**
  String get achVeteranoTitle;

  /// No description provided for @achVeteranoBody.
  ///
  /// In it, this message translates to:
  /// **'Completa 25 partite'**
  String get achVeteranoBody;

  /// No description provided for @achLocked.
  ///
  /// In it, this message translates to:
  /// **'Da sbloccare'**
  String get achLocked;

  /// No description provided for @achUnlocked.
  ///
  /// In it, this message translates to:
  /// **'Sbloccato'**
  String get achUnlocked;

  /// No description provided for @dailyRewardTitle.
  ///
  /// In it, this message translates to:
  /// **'Ricompensa giornaliera'**
  String get dailyRewardTitle;

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

  /// No description provided for @dailyRewardClaimed.
  ///
  /// In it, this message translates to:
  /// **'Ritirata'**
  String get dailyRewardClaimed;

  /// No description provided for @dailyRewardTomorrow.
  ///
  /// In it, this message translates to:
  /// **'Torna domani'**
  String get dailyRewardTomorrow;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageItalian;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get settingsLanguageEnglish;

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

  /// No description provided for @settingsAccount.
  ///
  /// In it, this message translates to:
  /// **'ACCOUNT'**
  String get settingsAccount;

  /// No description provided for @settingsLogout.
  ///
  /// In it, this message translates to:
  /// **'Esci dall’account'**
  String get settingsLogout;

  /// No description provided for @settingsLinkPending.
  ///
  /// In it, this message translates to:
  /// **'Il link sarà disponibile alla pubblicazione.'**
  String get settingsLinkPending;

  /// No description provided for @tableRules.
  ///
  /// In it, this message translates to:
  /// **'Regole'**
  String get tableRules;

  /// No description provided for @tableTurnTimer.
  ///
  /// In it, this message translates to:
  /// **'Tempo'**
  String get tableTurnTimer;

  /// No description provided for @passPhoneTo.
  ///
  /// In it, this message translates to:
  /// **'PASSA IL TELEFONO A {name}'**
  String passPhoneTo(String name);

  /// No description provided for @lobbyPlayerSlot.
  ///
  /// In it, this message translates to:
  /// **'Posto {index}'**
  String lobbyPlayerSlot(int index);

  /// No description provided for @dailyRewardDay.
  ///
  /// In it, this message translates to:
  /// **'Giorno {day}'**
  String dailyRewardDay(int day);

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

  /// No description provided for @createRoomTimerSeconds.
  ///
  /// In it, this message translates to:
  /// **'{seconds} secondi'**
  String createRoomTimerSeconds(int seconds);

  /// No description provided for @profileLevelValue.
  ///
  /// In it, this message translates to:
  /// **'Livello {level}'**
  String profileLevelValue(int level);

  /// No description provided for @profileXpProgress.
  ///
  /// In it, this message translates to:
  /// **'{current} / {target} XP'**
  String profileXpProgress(int current, int target);
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
