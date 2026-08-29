// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountGuestLabel => 'Guest';

  @override
  String get accountGuestUpgradeHint =>
      'Create an account to keep your progress on every device.';

  @override
  String accountSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get accountSignedOut => 'Not signed in';

  @override
  String get achCatenaBody => 'Take a chain of 2s up to +6';

  @override
  String get achCatenaTitle => 'Chain!';

  @override
  String get achCentounoBody => 'Land on exactly 101 and go back to zero';

  @override
  String get achCentounoTitle => 'One Hundred and One!';

  @override
  String get achImbattibileBody => 'Win five matches in a row';

  @override
  String get achImbattibileTitle => 'Unbeatable';

  @override
  String get achLocked => 'Locked';

  @override
  String get achMaestroNoveBody =>
      'Win after choosing all four suits with the Knight';

  @override
  String get achMaestroNoveTitle => 'Master of the Nine';

  @override
  String get achManoPerfettaBody => 'Win a round without drawing a single card';

  @override
  String get achManoPerfettaTitle => 'Perfect Hand';

  @override
  String get achPrimaVittoriaBody => 'Win your first match';

  @override
  String get achPrimaVittoriaTitle => 'First Win';

  @override
  String get achSfidanteBody => 'Complete a Daily Challenge';

  @override
  String get achSfidanteTitle => 'Challenger';

  @override
  String get achUnlocked => 'Unlocked';

  @override
  String get achVendettaBody => 'Win the very next match after a defeat';

  @override
  String get achVendettaTitle => 'Vendetta';

  @override
  String get achVeteranoBody => 'Complete 25 matches';

  @override
  String get achVeteranoTitle => 'Veteran';

  @override
  String get achievementUnlockedToast => 'Achievement unlocked';

  @override
  String get achievements => 'Achievements';

  @override
  String get activeSuit => 'Active suit';

  @override
  String get advancedRules => 'Advanced rules';

  @override
  String get animationFast => 'Fast';

  @override
  String get animationNormal => 'Normal';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String get appName => 'Gioco del 101';

  @override
  String get appTagline => 'The Neapolitan classic, reimagined';

  @override
  String get authBackendPending =>
      'Sign-in becomes active once the online service is connected.';

  @override
  String authConfirmEmailBody(String email) {
    return 'We sent a confirmation link to $email. Open it, then sign in.';
  }

  @override
  String get authConfirmEmailTitle => 'Check your email';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authErrorEmailTaken =>
      'An account with this email already exists.';

  @override
  String get authErrorGuestDisabled =>
      'Guest access is not enabled on this server.';

  @override
  String get authErrorInvalidCredentials => 'Email or password is not correct.';

  @override
  String get authErrorNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrorUnknown => 'Something went wrong while signing in.';

  @override
  String get authErrorWeakPassword => 'Choose a stronger password.';

  @override
  String get authGuestFailed => 'We couldn\'t start a guest session.';

  @override
  String get authGuestHint => 'You can create an account at any time.';

  @override
  String get authPlayAsGuest => 'PLAY AS GUEST';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSocialUnavailable => 'Social sign-in is not enabled yet.';

  @override
  String get authSubtitle => 'Sign in to play online and keep your progress.';

  @override
  String get authTitle => 'Welcome';

  @override
  String get backToZero => 'BACK TO ZERO';

  @override
  String get bestComeback => 'Best comeback';

  @override
  String get cancel => 'Cancel';

  @override
  String get cardBack => 'Card back';

  @override
  String get cardsLeft => 'cards';

  @override
  String get cardsPlayed => 'Cards played';

  @override
  String get chooseSuit => 'Choose the suit';

  @override
  String get coachDraw => 'No legal card? Tap the deck to draw.';

  @override
  String get coachFateRing =>
      'The ring shows how far you are from 101. Exactly 101 sends you back to zero.';

  @override
  String get coachMatch => 'Play a card of the same suit or value.';

  @override
  String get coachSpecials =>
      'Ace skips the turn, 2 makes you draw, Knight changes suit.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonEmptyBody => 'When there is data, it will show up here.';

  @override
  String get commonEmptyTitle => 'Nothing here yet';

  @override
  String get commonErrorBody => 'We could not complete that. Please try again.';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonNext => 'Next';

  @override
  String get commonOptional => 'optional';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonStart => 'Start';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueGame => 'Continue';

  @override
  String get createRoomCta => 'CREATE ROOM';

  @override
  String get createRoomHouseRules => 'House rules';

  @override
  String get createRoomName => 'Room name';

  @override
  String get createRoomNameHint => 'e.g. Marco\'s table';

  @override
  String get createRoomPrivate => 'Private room';

  @override
  String get createRoomPrivateHint => 'Joinable by code only';

  @override
  String get createRoomTimer => 'Turn timer';

  @override
  String get createRoomTimerOff => 'Off';

  @override
  String createRoomTimerSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get createRoomTitle => 'Create a room';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get dailyChallengeDone => 'Challenge complete';

  @override
  String get dailyCompleted => 'Completed today';

  @override
  String get dailyReward => 'Reward';

  @override
  String dailyRewardBalance(int coins) {
    return '$coins coins';
  }

  @override
  String get dailyRewardBody =>
      'Come back every day — the reward grows up to the seventh.';

  @override
  String get dailyRewardClaim => 'CLAIM';

  @override
  String get dailyRewardClaimFailed => 'Could not claim the reward. Try again.';

  @override
  String get dailyRewardClaimed => 'Claimed';

  @override
  String get dailyRewardClaimedToday => 'Claimed today. Come back tomorrow!';

  @override
  String dailyRewardDay(int day) {
    return 'Day $day';
  }

  @override
  String get dailyRewardGuestHint =>
      'Create an account to claim daily rewards.';

  @override
  String get dailyRewardTitle => 'Daily reward';

  @override
  String get dailyRewardTomorrow => 'Come back tomorrow';

  @override
  String get dailyStartHint => 'A different setup every day.';

  @override
  String get dailyTitle => 'Daily Challenge';

  @override
  String get defaultDifficulty => 'Default difficulty';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get discardPile => 'Discard';

  @override
  String get drawCard => 'Draw';

  @override
  String get drawPile => 'Deck';

  @override
  String get editProfileAvatar => 'Choose an avatar';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get eliminated => 'ELIMINATED';

  @override
  String get exit => 'Leave';

  @override
  String get exitBody => 'The match will be saved automatically.';

  @override
  String get exitTitle => 'Leave the match?';

  @override
  String get exitToMenu => 'Exit to Menu';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String get fieldPassword => 'Password';

  @override
  String get finalPoints => 'Final points';

  @override
  String get forgotBackToLogin => 'Back to sign in';

  @override
  String get forgotBody =>
      'Enter your email and we will send you a link to reset your password.';

  @override
  String get forgotCta => 'SEND LINK';

  @override
  String forgotSentBody(String email) {
    return 'If an account exists for $email, a reset link is on its way.';
  }

  @override
  String get forgotSentTitle => 'Email sent';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get gotIt => 'Got it';

  @override
  String get haptics => 'Vibration';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get highContrast => 'High contrast';

  @override
  String get home => 'Home';

  @override
  String get homeCreateRoom => 'CREATE ROOM';

  @override
  String get homeJoinRoom => 'JOIN A ROOM';

  @override
  String get homeLeaderboard => 'Leaderboard';

  @override
  String get homeMissions => 'Missions';

  @override
  String get homeMissionsHint => 'Today\'s objectives';

  @override
  String get homePlayOffline => 'PLAY OFFLINE';

  @override
  String get homePlayOnline => 'PLAY ONLINE';

  @override
  String get homeQuickMatch => 'QUICK MATCH';

  @override
  String get howToPlay => 'How to Play';

  @override
  String get howToPlayHint => 'The rules in a minute';

  @override
  String get imReady => 'I\'M READY';

  @override
  String get joinRoomBody => 'Enter the six-character code the host gave you.';

  @override
  String get joinRoomCta => 'JOIN';

  @override
  String get joinRoomInvalid => 'The code must be six characters';

  @override
  String get joinRoomPaste => 'Paste';

  @override
  String get joinRoomTitle => 'Join a room';

  @override
  String get largeCards => 'Large cards';

  @override
  String get lastCard => 'LAST CARD';

  @override
  String get leaderboardAllTime => 'All time';

  @override
  String get leaderboardEmpty => 'The leaderboard arrives with online play.';

  @override
  String get leaderboardLoadFailed => 'Could not load the leaderboard.';

  @override
  String get leaderboardNoScoresYet =>
      'No scores yet — play online matches to appear here.';

  @override
  String get leaderboardPoints => 'Points';

  @override
  String get leaderboardRank => 'Rank';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardWeekly => 'Weekly';

  @override
  String get lobbyAway => 'Away';

  @override
  String get lobbyConnected => 'Connected';

  @override
  String get lobbyCopied => 'Code copied';

  @override
  String get lobbyEmptySlot => 'Waiting for a player';

  @override
  String get lobbyHost => 'Host';

  @override
  String get lobbyLeave => 'Leave room';

  @override
  String get lobbyNotReady => 'Not ready';

  @override
  String get lobbyNotReadyToggle => 'Not ready';

  @override
  String lobbyPlayerSlot(int index) {
    return 'Seat $index';
  }

  @override
  String get lobbyReady => 'Ready';

  @override
  String get lobbyReadyToggle => 'I’m ready';

  @override
  String get lobbyRoomCode => 'Room code';

  @override
  String get lobbyShare => 'Share code';

  @override
  String get lobbyStart => 'START MATCH';

  @override
  String lobbyStartFailed(String reason) {
    return 'Could not start: $reason';
  }

  @override
  String get lobbyStartPending =>
      'Starting online matches arrives in the next update.';

  @override
  String get lobbyStarting => 'The match is about to start…';

  @override
  String get lobbyTitle => 'Lobby';

  @override
  String get lobbyWaitingForHost => 'Waiting for the host to start…';

  @override
  String get lobbyWaitingForPlayers => 'Waiting for more players…';

  @override
  String get locked => 'Locked';

  @override
  String get loginCta => 'SIGN IN';

  @override
  String get loginForgot => 'Forgot your password?';

  @override
  String get loginNoAccount => 'No account yet?';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get longestChain => 'Longest chain';

  @override
  String get matchWinner => 'WINNER';

  @override
  String get matchmakingBody => 'Looking for other players…';

  @override
  String get matchmakingBusy => 'You already have a match in progress.';

  @override
  String get matchmakingCancel => 'Cancel search';

  @override
  String matchmakingElapsed(int seconds) {
    return 'Waiting ${seconds}s';
  }

  @override
  String matchmakingFound(int found, int total) {
    return '$found of $total players';
  }

  @override
  String get matchmakingMatched => 'Table found!';

  @override
  String get matchmakingPending => 'Quick match queues are not open yet.';

  @override
  String get matchmakingPlayers => 'Players at the table';

  @override
  String get matchmakingSearch => 'Find a match';

  @override
  String matchmakingSearching(int count) {
    return 'Looking for real players for a table of $count…';
  }

  @override
  String get matchmakingTitle => 'Searching';

  @override
  String get mode => 'Mode';

  @override
  String get modePassAndPlay => 'Pass & Play';

  @override
  String get modeVsComputer => 'Vs Computer';

  @override
  String get music => 'Music';

  @override
  String get networkOffline => 'No connection';

  @override
  String get networkOnline => 'Back online';

  @override
  String get networkReconnecting => 'Reconnecting…';

  @override
  String get newGame => 'New Game';

  @override
  String get newMatch => 'New Match';

  @override
  String get nextRound => 'Next Round';

  @override
  String get noStatsYet => 'Play a match to start collecting data.';

  @override
  String get onboard1Body =>
      'A traditional 40-card deck — Coins, Cups, Swords and Clubs — drawn by hand for the screen.';

  @override
  String get onboard1Title => 'Neapolitan cards';

  @override
  String get onboard2Body =>
      'The Ace skips a turn, the 2 makes you draw, the Knight changes suit. Landing on exactly 101 resets your score.';

  @override
  String get onboard2Title => 'The 101 rules';

  @override
  String get onboard3Body =>
      'Create a room, share the code and take on two to four players online.';

  @override
  String get onboard3Title => 'Play with friends';

  @override
  String get onlineCreateRoomHint => 'Invite friends with a code';

  @override
  String get onlineDisconnected => 'Connection lost';

  @override
  String get onlineForfeit => 'Leave';

  @override
  String get onlineForfeitBody =>
      'The match will count as a loss and you cannot rejoin.';

  @override
  String get onlineForfeitTitle => 'Leave the match?';

  @override
  String get onlineJoinRoomHint => 'Got a code? Jump straight in';

  @override
  String get onlineMatchAbandoned => 'The match was abandoned';

  @override
  String get onlineMoveRefused => 'Illegal move';

  @override
  String get onlineMoveStale => 'The table had changed: try again';

  @override
  String onlineNextRoundAuto(int seconds) {
    return 'Next round starts in ${seconds}s';
  }

  @override
  String onlineOpponentLeft(String name) {
    return '$name left the match';
  }

  @override
  String get onlineQuickMatchHint => 'We find you an open table';

  @override
  String get onlineReconnecting => 'Reconnecting…';

  @override
  String get onlineRejoinMatch => 'Rejoin the match';

  @override
  String get onlineRejoinMatchHint => 'An online match is waiting for you';

  @override
  String onlineRematchAsked(String name) {
    return '$name wants a rematch';
  }

  @override
  String get onlineRematchRequested => 'Rematch requested';

  @override
  String onlineRematchWaiting(int votes, int needed) {
    return 'Waiting for the others ($votes/$needed)';
  }

  @override
  String onlineServerMoved(String name) {
    return 'The server played for $name';
  }

  @override
  String get onlineSignInRequired =>
      'Sign in or play as a guest to use online features.';

  @override
  String get onlineSyncing => 'Updating the table…';

  @override
  String get onlineTimedOut => 'Time is up';

  @override
  String get onlineTitle => 'Play online';

  @override
  String onlineTurnSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String onlineWaitingFor(String name) {
    return '$name’s turn';
  }

  @override
  String get onlineYouForfeited => 'You left the match';

  @override
  String get passPhoneHint => 'Cards stay face down until you tap';

  @override
  String passPhoneTo(String name) {
    return 'PASS THE PHONE TO $name';
  }

  @override
  String get passTurn => 'Pass';

  @override
  String get penalty => 'Penalty';

  @override
  String get play => 'PLAY';

  @override
  String get playDrawn => 'Play the drawn card';

  @override
  String get playerName => 'Your name';

  @override
  String get playersCount => 'Players';

  @override
  String get profile => 'Profile';

  @override
  String get profileBestStreak => 'Best streak';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileLevel => 'Level';

  @override
  String profileLevelValue(int level) {
    return 'Level $level';
  }

  @override
  String get profileLosses => 'Losses';

  @override
  String get profileMatches => 'Matches';

  @override
  String get profileNicknameTaken => 'That nickname is already taken.';

  @override
  String get profileRating => 'Rating';

  @override
  String get profileSaveFailed => 'Could not save your profile. Try again.';

  @override
  String get profileWinRate => 'Win rate';

  @override
  String get profileWins => 'Wins';

  @override
  String get profileXp => 'Experience';

  @override
  String profileXpProgress(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String get rankAce => 'Ace';

  @override
  String get rankCavallo => 'Knight';

  @override
  String get rankFante => 'Jack';

  @override
  String get rankRe => 'King';

  @override
  String get reaction1 => 'Nice move!';

  @override
  String get reaction2 => 'Go on!';

  @override
  String get reaction3 => 'Lucky you!';

  @override
  String get reaction4 => 'Nooo!';

  @override
  String get reaction5 => 'Your turn!';

  @override
  String get reaction6 => 'Draw!';

  @override
  String get reaction7 => 'Well played!';

  @override
  String get reaction8 => 'Rematch!';

  @override
  String get reactionAhahaha => 'Ahahaha! 😂';

  @override
  String get reactionBellaMossa => 'Nice move! 😎';

  @override
  String get reactionBravo => 'Bravo! 👏';

  @override
  String get reactionCheFortuna => 'Lucky! 🍀';

  @override
  String get reactionCiao => 'Ciao! 👋';

  @override
  String get reactionGg => 'GG! 🤝';

  @override
  String get reactionMammaMia => 'Mamma mia! 😱';

  @override
  String get reactionRateLimited => 'Wait a moment before the next reaction';

  @override
  String get reactionRivincita => 'Rematch? 🔁';

  @override
  String get reactions => 'Reactions';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get rematch => 'Rematch';

  @override
  String get replayLastHand => 'Replay last hand';

  @override
  String get resetStatistics => 'Reset statistics';

  @override
  String get resetStatisticsBody =>
      'All local progress will be erased. Continue?';

  @override
  String get resumeMatch => 'Resume Match';

  @override
  String get resumeMatchHint => 'Pick up where you left off';

  @override
  String get roomCreateFailed => 'Could not open the room. Try again.';

  @override
  String get roomFull => 'That room is full.';

  @override
  String get roomJoinFailed => 'Could not join the room. Try again.';

  @override
  String get roomNotFound => 'No open room has that code.';

  @override
  String get round => 'Round';

  @override
  String get roundComplete => 'ROUND COMPLETE';

  @override
  String get roundWinner => 'Round winner';

  @override
  String get roundsPlayed => 'Rounds played';

  @override
  String get ruleEliminate => 'Elimination past 101';

  @override
  String get ruleEliminateHint => 'Going over 101 knocks you out';

  @override
  String get ruleExactReset => 'Back to zero at 101';

  @override
  String get ruleExactResetHint => 'Exactly 101 resets your score';

  @override
  String get ruleStackTwos => 'Stacking 2s';

  @override
  String get ruleStackTwosHint => '2s can be chained';

  @override
  String get ruleVoluntaryDraw => 'Voluntary draw';

  @override
  String get ruleVoluntaryDrawHint => 'You may draw even holding a card';

  @override
  String get ruleWildNine => 'Cavallo always playable';

  @override
  String get ruleWildNineHint => 'The 9 changes suit at any time';

  @override
  String get savedFrom101 => 'SAFE!';

  @override
  String get sectionSettings => 'SETTINGS';

  @override
  String get sectionStatistics => 'STATISTICS';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageItalian => 'Italian';

  @override
  String get settingsLinkPending => 'The link becomes available at release.';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutBody =>
      'You will be signed out on this device. Progress saved to your account stays.';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get showPassword => 'Show password';

  @override
  String get signupCta => 'SIGN UP';

  @override
  String get signupHaveAccount => 'Already have an account?';

  @override
  String get signupTitle => 'Create an account';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get startChallenge => 'ACCEPT THE CHALLENGE';

  @override
  String get startMatch => 'START MATCH';

  @override
  String get startingHand => 'Starting cards';

  @override
  String get statAces => 'Aces used';

  @override
  String get statBestStreak => 'Best streak';

  @override
  String get statCards => 'Cards played';

  @override
  String get statChain => 'Longest chain';

  @override
  String get statComeback => 'Biggest comeback';

  @override
  String get statFavouriteSuit => 'Favourite suit';

  @override
  String get statMatches => 'Matches played';

  @override
  String get statResets => 'Returns from 101';

  @override
  String get statRoundsWon => 'Rounds won';

  @override
  String get statStreak => 'Current streak';

  @override
  String get statTwos => '+2 cards played';

  @override
  String get statWinRate => 'Win rate';

  @override
  String get statWins => 'Matches won';

  @override
  String get statistics => 'Statistics';

  @override
  String get suitBastoni => 'Clubs';

  @override
  String get suitCoppe => 'Cups';

  @override
  String get suitDenari => 'Coins';

  @override
  String get suitSpade => 'Swords';

  @override
  String get tableRules => 'Rules';

  @override
  String get tableTheme => 'Table';

  @override
  String get tableTurnTimer => 'Time';

  @override
  String get takePenalty => 'Take';

  @override
  String get turnSkipped => 'TURN SKIPPED';

  @override
  String get tutorial101 => 'Exactly 101';

  @override
  String get tutorial101Body =>
      'Landing on exactly 101 resets your score to zero. It is the twist that can turn a whole match around.';

  @override
  String get tutorialAce => 'Ace — skip the turn';

  @override
  String get tutorialAceBody =>
      'The Ace makes the next player lose their turn. With two players, the turn comes straight back to you.';

  @override
  String get tutorialCavallo => 'Knight — change suit';

  @override
  String get tutorialCavalloBody =>
      'The Knight (9) can be played at any moment and lets you choose the new active suit with the Suit Ritual.';

  @override
  String get tutorialDraw => 'Drawing';

  @override
  String get tutorialDrawBody =>
      'With no playable card you draw from the deck. If the drawn card is legal you may play it at once, otherwise the turn passes.';

  @override
  String get tutorialGoal => 'Goal';

  @override
  String get tutorialGoalBody =>
      'Empty your hand before the others. The cards left in your opponents\' hands become penalty points: go over 101 and you are out, land on exactly 101 and you go back to zero.';

  @override
  String get tutorialMatch => 'Suit or value';

  @override
  String get tutorialMatchBody =>
      'You may play a card of the active suit, or one of the same value as the card on top of the discard pile.';

  @override
  String get tutorialOver101 => 'Past 101';

  @override
  String get tutorialOver101Body =>
      'Going over 101 means leaving the match. Whoever manages the high cards best stays in.';

  @override
  String get tutorialScoring => 'Scoring';

  @override
  String get tutorialScoringBody =>
      'At the end of a round every card left is worth its number: Ace 1, Jack 8, Knight 9, King 10. The points add to your total.';

  @override
  String get tutorialTwo => 'Two — draw two';

  @override
  String get tutorialTwoBody =>
      'The 2 forces the next player to draw two cards. Holding another 2 they can raise: +4, +6, +8. Whoever stops draws the lot and loses the turn.';

  @override
  String get tutorialWin => 'Winning the match';

  @override
  String get tutorialWinBody =>
      'The match ends when a single player is left standing. That player wins the Gioco del 101.';

  @override
  String get valEmailInvalid => 'Enter a valid email address';

  @override
  String get valNicknameLong => 'The nickname can be at most 16 characters';

  @override
  String get valNicknameShort => 'The nickname must be at least 3 characters';

  @override
  String get valPasswordMismatch => 'The passwords do not match';

  @override
  String get valPasswordShort => 'The password must be at least 8 characters';

  @override
  String get valRequired => 'This field is required';

  @override
  String get yourTurn => 'YOUR TURN';
}
