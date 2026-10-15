/// Everything in the game that was made with AI, so it can be replaced with
/// human-made work. The AI audit overlay (developer panel: long-press the
/// version number) highlights all of it on screen: every piece of text,
/// every drawing in [AiArt] painters or [AiMarked] widgets, and every sound
/// and music track as it plays.
///
/// To tick something off once it's replaced, add it to [replaced]: a
/// painter's class name (as the overlay labels it), a sound or music file
/// (as the overlay labels it), or a piece of text exactly as shown.
class AiInventory {
  AiInventory._();

  /// Sound effects, all AI-generated (assets/sounds).
  static const sounds = {
    'acro-braam', 'alert-1', 'alert-2', 'card-placed-1', 'card-placed-2', 'card-placed-3', 'card-shuffle-1', //
    'card-slide-1', 'card-slide-2', 'card-slide-3', 'click-1', 'click-2', 'click-3', 'click-4', 'click-5',
    'cough-1', 'cough-2', 'cough-3', 'cough-4', 'flash-bang', 'revolver-fired-1', 'revolver-fired-2',
    'revolver-fired-3', 'revolver-fired-4', 'revolver-loaded-1', 'ringing',
  };

  /// Music, all AI-generated (assets/music).
  static const music = {'menu-1', 'Oscuridad', 'Sombra'};

  /// Replaced with human-made work: no longer highlighted.
  static const Set<String> replaced = {};

  static bool isAi(String name) => !replaced.contains(name);
}
