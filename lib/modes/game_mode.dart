enum GameMode { donut, badBatch }

extension GameModeInfo on GameMode {
  String get label => switch (this) {
        GameMode.donut => 'Donut',
        GameMode.badBatch => 'Bad Batch',
      };

  String get tagline => switch (this) {
        GameMode.donut => 'Trick-taking. Get to zero, avoid the donut.',
        GameMode.badBatch => 'Fill in the blanks with the worst answer you have. 18+',
      };

  /// Shows the adult content warning before the first game.
  bool get adult => this == GameMode.badBatch;

  static GameMode fromName(String? name) =>
      GameMode.values.firstWhere((element) => element.name == name, orElse: () => GameMode.donut);
}
