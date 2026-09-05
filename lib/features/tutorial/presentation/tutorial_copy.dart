import '../../../app/localization/app_strings.dart';
import '../../game/domain/card_suit.dart';
import '../domain/tutorial_lessons.dart';

/// Resolves each lesson's copy from the ARB files, so the tutorial reads in
/// the player's language without the lesson table carrying any text.
extension TutorialCopy on AppLocalizations {
  String tutorialLessonTitle(TutorialLessonId id) => switch (id) {
    TutorialLessonId.firstCard => tutFirstCardTitle,
    TutorialLessonId.drawing => tutDrawingTitle,
    TutorialLessonId.ace => tutAceTitle,
    TutorialLessonId.two => tutTwoTitle,
    TutorialLessonId.chain => tutChainTitle,
    TutorialLessonId.cavallo => tutCavalloTitle,
    TutorialLessonId.block => tutBlockTitle,
    TutorialLessonId.centouno => tutCentounoTitle,
  };

  /// The prompt for step [step] of the lesson (0-based).
  String tutorialLessonPrompt(TutorialLessonId id, int step) => switch (id) {
    TutorialLessonId.firstCard => tutFirstCardPrompt,
    TutorialLessonId.drawing => step == 0 ? tutDrawingPrompt : tutDrawingPlay,
    TutorialLessonId.ace => tutAcePrompt,
    TutorialLessonId.two => tutTwoPrompt,
    TutorialLessonId.chain => tutChainPrompt,
    TutorialLessonId.cavallo => step == 0 ? tutCavalloPrompt : tutCavalloSuit,
    TutorialLessonId.block => step == 0 ? tutBlockPrompt : tutBlockSuit,
    TutorialLessonId.centouno => tutCentounoPrompt,
  };

  String tutorialLessonDone(
    TutorialLessonId id, {
    CardSuit? suit,
    String opponent = '',
  }) => switch (id) {
    TutorialLessonId.firstCard => tutFirstCardDone,
    TutorialLessonId.drawing => tutDrawingDone,
    TutorialLessonId.ace => tutAceDone(opponent),
    TutorialLessonId.two => tutTwoDone(opponent),
    TutorialLessonId.chain => tutChainDone(opponent),
    TutorialLessonId.cavallo => tutCavalloDone(
      suit == null ? '' : suitName(suit),
    ),
    TutorialLessonId.block => tutBlockDone,
    TutorialLessonId.centouno => tutCentounoDone(opponent),
  };

  String suitName(CardSuit suit) => switch (suit) {
    CardSuit.denari => suitDenari,
    CardSuit.coppe => suitCoppe,
    CardSuit.spade => suitSpade,
    CardSuit.bastoni => suitBastoni,
  };
}
