/// Works out what a finished match pays. Pure functions: the profile applies
/// the result.
class RewardLine {
  const RewardLine(this.label, {this.xp = 0, this.crumbs = 0, this.glaze = 0});

  final String label;
  final int xp;
  final int crumbs;
  final int glaze;
}

class MatchRewards {
  const MatchRewards(this.lines);

  final List<RewardLine> lines;

  int get xp => lines.fold(0, (sum, line) => sum + line.xp);
  int get crumbs => lines.fold(0, (sum, line) => sum + line.crumbs);
  int get glaze => lines.fold(0, (sum, line) => sum + line.glaze);
}

/// A finished offline Donut match from the local player's point of view.
class DonutMatchSummary {
  const DonutMatchSummary({
    required this.placement,
    required this.players,
    required this.tricks,
    required this.donuts,
    required this.hands,
    required this.suddenDeath,
    required this.duration,
    this.firstWinToday = false,
  });

  /// 1 for the champion.
  final int placement;
  final int players;

  /// Tricks taken over the whole match.
  final int tricks;
  final int donuts;
  final int hands;

  /// Whether the match went to sudden death and you were in it.
  final bool suddenDeath;
  final Duration duration;
  final bool firstWinToday;

  bool get won => placement == 1;
}

MatchRewards donutMatchRewards(DonutMatchSummary match) {
  final lines = <RewardLine>[
    const RewardLine('Match played', xp: 100, crumbs: 50),
  ];
  switch (match.placement) {
    case 1:
      lines.add(const RewardLine('Victory', xp: 250, crumbs: 150));
    case 2:
      lines.add(const RewardLine('Runner-up', xp: 120, crumbs: 75));
    case 3:
      lines.add(const RewardLine('Third place', xp: 60, crumbs: 40));
  }
  if (match.tricks > 0) {
    lines.add(RewardLine('${match.tricks} trick${match.tricks == 1 ? '' : 's'} taken',
        xp: 12 * match.tricks, crumbs: 6 * match.tricks));
  }
  if (match.hands > 0) lines.add(RewardLine('${match.hands} hands played', xp: 15 * match.hands));
  if (match.donuts == 0 && match.hands >= 3) {
    lines.add(const RewardLine('Clean sheet: no donuts', xp: 80, crumbs: 40));
  }
  if (match.suddenDeath) {
    lines.add(RewardLine(match.won ? 'Sudden death survivor' : 'Sudden death', xp: match.won ? 150 : 60));
  }
  if (match.players >= 6) {
    lines.add(const RewardLine('Full table', xp: 40, crumbs: 20));
  }
  if (match.firstWinToday && match.won) {
    lines.add(const RewardLine('First win of the day', xp: 200, crumbs: 100));
  }
  return MatchRewards(lines);
}
