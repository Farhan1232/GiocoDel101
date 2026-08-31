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
  String get achOffline => 'Unlocked offline';

  @override
  String get achOnline => 'Unlocked online';

  @override
  String get achPrimaVittoriaBody => 'Win your first match';

  @override
  String get achPrimaVittoriaTitle => 'First Win';

  @override
  String get achServerHint =>
      'Online achievements are validated by the server; offline ones stay on this device.';

  @override
  String get achSfidanteBody => 'Complete a Daily Challenge';

  @override
  String get achSfidanteTitle => 'Challenger';

  @override
  String get achVendettaBody => 'Win the very next match after a defeat';

  @override
  String get achVendettaTitle => 'Vendetta';

  @override
  String get achVeteranoBody => 'Complete 25 matches';

  @override
  String get achVeteranoTitle => 'Veteran';

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
  String get bestComeback => 'Best comeback';

  @override
  String get botThinking => 'Thinking…';

  @override
  String get cancel => 'Cancel';

  @override
  String get cardBack => 'Card back';

  @override
  String cardName(String rank, String suit) {
    return '$rank of $suit';
  }

  @override
  String cardSemanticsNotPlayable(String card) {
    return '$card, not playable now';
  }

  @override
  String cardSemanticsPlayable(String card) {
    return '$card, playable';
  }

  @override
  String get cardsLeft => 'cards';

  @override
  String get cardsPlayed => 'Cards played';

  @override
  String centounoBody(String name) {
    return '$name is back to zero';
  }

  @override
  String get centounoTitle => 'CENTOUNO!';

  @override
  String get challengeEdgeBody =>
      'Start at 80 points against a hard opponent. One bad round and you are out.';

  @override
  String get challengeEdgeTitle => 'On the edge';

  @override
  String get challengeFullBody =>
      'Four players, hard opponents, no voluntary draw.';

  @override
  String get challengeFullTitle => 'Full table';

  @override
  String get challengeStormBody =>
      'An 8-card hand and unleashed chains of twos. Survive the storm.';

  @override
  String get challengeStormTitle => 'Storm of twos';

  @override
  String get challengeTightBody =>
      'Only 3 cards each. Few choices, no room for error.';

  @override
  String get challengeTightTitle => 'Tight hand';

  @override
  String get challengeZeroBody =>
      'Start at 94 points: find exactly 7 points and return to zero.';

  @override
  String get challengeZeroTitle => 'Back to zero';

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
  String get commonOff => 'Off';

  @override
  String get commonOn => 'On';

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
  String get dealerBadge => 'DEALER';

  @override
  String get deckTaglineIncisoOro => 'The house engraving, finished in gold.';

  @override
  String get deckTaglineNapoletane => 'The authentic Neapolitan cards.';

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
  String discardTop(String card) {
    return 'Discard: $card';
  }

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
  String get gadgetTaglineSigillo => 'A golden seal pressed into the felt.';

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
  String lastCardAnnounced(String name) {
    return '$name: LAST CARD!';
  }

  @override
  String get lastCardButton => 'LAST CARD';

  @override
  String get lastCardDeclared => 'LAST CARD!';

  @override
  String get lastCardPrompt => 'Declare LAST CARD before you play.';

  @override
  String get lastCardSemantics => 'Declare last card';

  @override
  String get leaderboardAllTime => 'All time';

  @override
  String get leaderboardEmpty => 'The leaderboard arrives with online play.';

  @override
  String get leaderboardLoadFailed => 'Could not load the leaderboard.';

  @override
  String get leaderboardLoadMore => 'Load more';

  @override
  String get leaderboardNoScoresYet =>
      'No scores yet — play online matches to appear here.';

  @override
  String get leaderboardNotRanked =>
      'You are not ranked yet: play online to get on the board.';

  @override
  String get leaderboardPoints => 'Points';

  @override
  String get leaderboardRank => 'Rank';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardWeekly => 'Weekly';

  @override
  String get leaderboardYourRank => 'Your rank';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get lobbyAway => 'Away';

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
      'The match starts once every seat is taken and every player is ready.';

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
  String get matchmakingBusy => 'You already have a match in progress.';

  @override
  String get matchmakingCancel => 'Cancel search';

  @override
  String get matchmakingCpuHint =>
      'No other players for now. You can play offline against the computer right away: it does not count for the leaderboard.';

  @override
  String get matchmakingCpuOffer => 'Continue against CPU';

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
  String missionBlockTwo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Block $n +2s with a Cavallo',
      one: 'Block one +2 with a Cavallo',
    );
    return '$_temp0';
  }

  @override
  String missionOnlineMatch(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Complete $n online matches',
      one: 'Complete one online match',
    );
    return '$_temp0';
  }

  @override
  String missionPlayAces(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n Aces',
      one: 'Play one Ace',
    );
    return '$_temp0';
  }

  @override
  String missionPlayMatches(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n matches',
      one: 'Play one match',
    );
    return '$_temp0';
  }

  @override
  String missionPlayTwos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Play $n 2s',
      one: 'Play one 2',
    );
    return '$_temp0';
  }

  @override
  String missionUseNine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Use $n Cavalli (9)',
      one: 'Use one Cavallo (9)',
    );
    return '$_temp0';
  }

  @override
  String missionWinMatch(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Win $n matches',
      one: 'Win one match',
    );
    return '$_temp0';
  }

  @override
  String get missionsClaim => 'CLAIM';

  @override
  String get missionsClaimFailed => 'Could not claim the reward.';

  @override
  String get missionsClaimed => 'Claimed';

  @override
  String get missionsCycleHint =>
      'New missions every day, on a seven-day cycle.';

  @override
  String get missionsEmpty => 'No missions today.';

  @override
  String get missionsLoadFailed => 'Could not load the online missions.';

  @override
  String get missionsOffline => 'Offline (this device)';

  @override
  String get missionsOnline => 'Online missions';

  @override
  String get missionsOnlineOnly => 'Online only';

  @override
  String missionsProgress(int done, int total) {
    return '$done/$total complete';
  }

  @override
  String missionsReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get missionsSignInHint =>
      'Sign in for online missions: the experience goes on your profile.';

  @override
  String get missionsTitle => 'Today’s missions';

  @override
  String get mode => 'Mode';

  @override
  String get modePassAndPlay => 'Pass & Play';

  @override
  String get modeVsComputer => 'Versus computer';

  @override
  String get music => 'Music';

  @override
  String get networkOffline => 'No connection';

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
  String get onlineDisconnected => 'Connection lost. Trying to reconnect...';

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
  String get onlineMoveRefused => 'Illegal move.';

  @override
  String get onlineMoveStale => 'The table had changed: try again';

  @override
  String get onlineNotYourTurn => 'It is not your turn.';

  @override
  String onlineOpponentLeft(String name) {
    return '$name left the match';
  }

  @override
  String get onlineQuickMatchHint => 'We find you an open table';

  @override
  String get onlineRejoinMatch => 'Rejoin the match';

  @override
  String get onlineRejoinMatchHint => 'An online match is waiting for you';

  @override
  String onlineRematchWaiting(int votes, int needed) {
    return 'Waiting for the others ($votes/$needed)';
  }

  @override
  String get onlineSignInRequired =>
      'Sign in or play as a guest to use online features.';

  @override
  String get onlineTitle => 'Play online';

  @override
  String onlineTurnSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get onlineUnavailableRetry =>
      'The online service cannot be reached. Offline play is still available.';

  @override
  String get passPhoneHint => 'Cards stay face down until you tap';

  @override
  String passPhoneTo(String name) {
    return 'PASS THE PHONE TO $name';
  }

  @override
  String get passTurn => 'Pass';

  @override
  String get pauseHint => 'The match is on hold: your opponents are waiting.';

  @override
  String get pauseResume => 'Resume';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get penalty => 'Penalty';

  @override
  String get play => 'PLAY';

  @override
  String get playerName => 'Your name';

  @override
  String get playersCount => 'Players';

  @override
  String premiumBuyFor(String price) {
    return 'Buy · $price';
  }

  @override
  String get premiumCancelled => 'Purchase cancelled.';

  @override
  String get premiumFailed =>
      'The purchase did not go through. Please try again.';

  @override
  String get premiumNetwork =>
      'No connection. Check your network and try again.';

  @override
  String get premiumNothingToRestore =>
      'No purchases to restore on this store account.';

  @override
  String get premiumOwnedElsewhere =>
      'This purchase is already linked to another game profile.';

  @override
  String get premiumPending => 'Purchase in progress…';

  @override
  String get premiumProductMissing =>
      'The product is not available in the store yet. Try again later.';

  @override
  String get premiumRestore => 'Restore purchases';

  @override
  String get premiumRestored => 'Purchases restored.';

  @override
  String get premiumSignInRequired =>
      'Sign in with an account to complete the purchase.';

  @override
  String get premiumStoreUnavailable =>
      'The store is not available on this device.';

  @override
  String get premiumSuccess => 'Purchase complete. Thank you!';

  @override
  String get premiumVerificationUnavailable =>
      'Purchase verification is not live yet. No payment is lost: please try again later.';

  @override
  String get premiumVerifyFailed =>
      'The purchase could not be verified right now. It is not lost: please try again.';

  @override
  String get premiumVerifying => 'Verifying the purchase…';

  @override
  String get profile => 'Profile';

  @override
  String get profileBestStreak => 'Best streak';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String profileLevelValue(int level) {
    return 'Level $level';
  }

  @override
  String get profileLosses => 'Losses';

  @override
  String get profileMatches => 'Matches';

  @override
  String profileNextLevel(int level) {
    return 'Next level: $level';
  }

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
  String profileXpProgress(int current, int target) {
    return '$current / $target XP';
  }

  @override
  String profileXpToNext(int xp) {
    return '$xp XP to go';
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
  String get replayAgain => 'Replay';

  @override
  String get replayLastHand => 'Replay last hand';

  @override
  String get resetStatistics => 'Reset statistics';

  @override
  String get resetStatisticsBody =>
      'All local progress will be erased. Continue?';

  @override
  String get resumeMatch => 'Continue match';

  @override
  String get resumeMatchHint => 'Pick up where you left off';

  @override
  String get roomAlreadyInMatch =>
      'You already have an online match in progress. Rejoin the table or leave it before opening another.';

  @override
  String get roomAlreadyStarted => 'The match has already started.';

  @override
  String get roomCreateFailed => 'Could not open the room. Try again.';

  @override
  String get roomFull => 'That room is full.';

  @override
  String get roomJoinFailed => 'Could not join the room. Try again.';

  @override
  String get roomNotFound => 'Room not found.';

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
  String get ruleNineBlock => 'Cavallo versus the 2';

  @override
  String get ruleNineBlockCancel => 'Cancels the chain';

  @override
  String get ruleNineBlockDisabled => 'Not allowed';

  @override
  String get ruleNineBlockPassOn => 'Passes the chain on';

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
  String get rulesActiveTitle => 'Rules for this match';

  @override
  String get savedFrom101 => 'SAFE!';

  @override
  String get sectionSettings => 'SETTINGS';

  @override
  String get sectionStatistics => 'STATISTICS';

  @override
  String get sessionExpired => 'Session expired. Sign in again.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAccount => 'ACCOUNT';

  @override
  String get settingsGuestLogoutBody =>
      'You are a guest: signing out loses this account and its online progress for good.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageItalian => 'Italian';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutBody =>
      'You will be signed out on this device. Progress saved to your account stays.';

  @override
  String get settingsLogoutGuest => 'Sign out (guest account)';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get setupOtherPlayers => 'Other players';

  @override
  String setupPlayerN(int n) {
    return 'Player $n';
  }

  @override
  String get setupResetRules => 'Reset rules';

  @override
  String get shopFootnote =>
      'One-time, permanent, cosmetic-only purchases. The full game stays free. Prices are managed by your device’s store.';

  @override
  String get shopInUse => 'In use';

  @override
  String get shopIntro =>
      'Optional cosmetics. No gameplay advantage: tables, deck, back and ornaments are beauty only.';

  @override
  String get shopItemCardBackGold => 'Gold Card Back';

  @override
  String get shopItemCardBackGoldBody =>
      'A struck-gold back for your cards. The faces stay the authentic Neapolitan ones.';

  @override
  String get shopItemDeckSpecial => 'Special Deck';

  @override
  String get shopItemDeckSpecialBody =>
      'The house engraved deck, finished in gold. The classic Neapolitan deck always stays available.';

  @override
  String get shopItemGadget => '101 Seal';

  @override
  String get shopItemGadgetBody =>
      'A gilded laurel seal pressed into the table felt.';

  @override
  String get shopItemTableClassic => 'Classic Table';

  @override
  String get shopItemTableClassicBody =>
      'The old circolo: green baize on dark walnut.';

  @override
  String get shopItemTableGold => 'Gold Table';

  @override
  String get shopItemTableGoldBody =>
      'A grand-salon table: struck-gold felt under warm light.';

  @override
  String get shopItemUnavailable =>
      'Not available in the store yet. Try again later.';

  @override
  String get shopOwned => 'Unlocked';

  @override
  String get shopRemove => 'Remove';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopUse => 'Use';

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
  String get statOnlineMatches => 'Online matches';

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
  String get statsOfflineHeading => 'OFFLINE — THIS DEVICE';

  @override
  String get statsOfflineHint =>
      'Matches against the computer never touch the online leaderboard.';

  @override
  String get statsOnlineHeading => 'ONLINE — PROFILE';

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
  String get tableTaglineClassico => 'Green baize, dark walnut, quiet.';

  @override
  String get tableTaglineMaiolica => 'Mediterranean ceramic, cobalt and sun';

  @override
  String get tableTaglineNapoli => 'Antique gold over the sleeping gulf';

  @override
  String get tableTaglineOro => 'Struck gold under chandelier light.';

  @override
  String get tableTaglineVesuvio => 'Warm ash and terracotta glow';

  @override
  String get tableTheme => 'Table';

  @override
  String get takePenalty => 'Take';

  @override
  String get turnSkipped => 'TURN SKIPPED';

  @override
  String tutAceDone(String name) {
    return '$name skipped a turn. With two players, the Ace hands the turn straight back to you.';
  }

  @override
  String get tutAcePrompt =>
      'Play the Ace of Cups: your opponent loses their turn.';

  @override
  String get tutAceTitle => 'Ace — skip';

  @override
  String get tutBlockDone =>
      'The Cavallo is also your defence against 2s. Use it wisely: there are only four in the deck.';

  @override
  String get tutBlockPrompt =>
      'A 2 is aimed at you and you have no 2 to answer. Play the Cavallo of Clubs to cancel the chain.';

  @override
  String get tutBlockSuit => 'Chain cancelled: nobody draws. Choose the suit.';

  @override
  String get tutBlockTitle => 'Cavallo versus the 2';

  @override
  String tutCavalloDone(String suit) {
    return 'The active suit is now $suit. The Cavallo does not set its own suit: it sets the one you choose.';
  }

  @override
  String get tutCavalloPrompt =>
      'The Cavallo (the 9) can always be played, on anything. Play the Cavallo of Swords.';

  @override
  String get tutCavalloSuit =>
      'Now name the new active suit: the one you hold most of is usually best.';

  @override
  String get tutCavalloTitle => 'Cavallo — change suit';

  @override
  String tutCentounoDone(String name) {
    return '76 + 25 = exactly 101: $name goes back to zero. Anyone who goes over 101 is eliminated. The last player standing wins.';
  }

  @override
  String get tutCentounoPrompt =>
      'Last card! Your opponent has 76 points and a Cavallo in hand, worth 25. Play the 7 of Cups and end the round.';

  @override
  String get tutCentounoTitle => 'One hundred and one!';

  @override
  String tutChainDone(String name) {
    return '+4! $name drew four cards. Chains go all the way up to +8.';
  }

  @override
  String get tutChainPrompt =>
      'Your opponent played a 2 against you: answer with the 2 of Swords and the penalty rises to +4.';

  @override
  String get tutChainTitle => 'Stacking 2s';

  @override
  String get tutDrawingDone =>
      'Had the drawn card not been playable, the turn would have passed with Pass.';

  @override
  String get tutDrawingPlay =>
      'You drew the 6 of Cups: it can be played at once. Play it.';

  @override
  String get tutDrawingPrompt =>
      'No card in your hand can be played. Tap the stock (or Draw) to take a card.';

  @override
  String get tutDrawingTitle => 'Drawing';

  @override
  String get tutFirstCardDone =>
      'Perfect. Every card played must follow the active suit or the value of the card on top of the discards.';

  @override
  String get tutFirstCardPrompt =>
      'The 5 of Cups is on top of the discard pile. You may play a Cup or another 5: double-tap a highlighted card.';

  @override
  String get tutFirstCardTitle => 'Suit or value';

  @override
  String tutTwoDone(String name) {
    return '$name had no 2: they drew two cards and lost their turn.';
  }

  @override
  String get tutTwoPrompt =>
      'Play the 2 of Cups: your opponent must draw two cards unless they answer with another 2.';

  @override
  String get tutTwoTitle => 'Two — draw two';

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
  String get tutorialCompleteBody =>
      'You know every special card and the 101. Now it’s your turn.';

  @override
  String get tutorialCompleteTitle => 'Tutorial complete!';

  @override
  String get tutorialDraw => 'Drawing';

  @override
  String get tutorialDrawBody =>
      'With no playable card you draw from the deck. If the drawn card is legal you may play it at once, otherwise the turn passes.';

  @override
  String get tutorialExitBody =>
      'You can start it again from the beginning any time.';

  @override
  String get tutorialExitTitle => 'Leave the tutorial?';

  @override
  String get tutorialFinish => 'Finish';

  @override
  String get tutorialGoal => 'Goal';

  @override
  String get tutorialGoalBody =>
      'Empty your hand before the others. The cards left in your opponents\' hands become penalty points: go over 101 and you are out, land on exactly 101 and you go back to zero.';

  @override
  String get tutorialHint => 'Learn by playing, one rule at a time';

  @override
  String get tutorialHintFollow =>
      'Follow the hint: play the highlighted card.';

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
  String get tutorialPlayNow => 'PLAY AGAINST THE COMPUTER';

  @override
  String get tutorialReplay => 'Replay the tutorial';

  @override
  String get tutorialScoring => 'Scoring';

  @override
  String get tutorialScoringBody =>
      'At the end of a round every card left is worth its number: Ace 1, Jack 8, Knight 9, King 10. The points add to your total.';

  @override
  String get tutorialTitle => 'Interactive tutorial';

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
