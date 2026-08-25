/// House rules. Every toggle defaults to the way the game is played on a
/// physical board; the "app" variants can be switched on in setup.
class RuleSet {
  /// Jack may swap ANY two marbles on the track (board rule). When false,
  /// one of the swapped marbles must be your own (app rule).
  final bool jackSwapAny;

  /// A 5 may move any marble on the track — even an opponent's.
  final bool fiveMovesAny;

  /// A King moving 13 burns every marble it passes.
  final bool kingBurnsPath;

  /// You may land on (and burn) your partner's marbles.
  final bool canBurnPartner;

  /// A 7 may be split between two marbles.
  final bool sevenSplit;

  const RuleSet({
    this.jackSwapAny = true,
    this.fiveMovesAny = true,
    this.kingBurnsPath = true,
    this.canBurnPartner = true,
    this.sevenSplit = true,
  });

  RuleSet copyWith({
    bool? jackSwapAny,
    bool? fiveMovesAny,
    bool? kingBurnsPath,
    bool? canBurnPartner,
    bool? sevenSplit,
  }) =>
      RuleSet(
        jackSwapAny: jackSwapAny ?? this.jackSwapAny,
        fiveMovesAny: fiveMovesAny ?? this.fiveMovesAny,
        kingBurnsPath: kingBurnsPath ?? this.kingBurnsPath,
        canBurnPartner: canBurnPartner ?? this.canBurnPartner,
        sevenSplit: sevenSplit ?? this.sevenSplit,
      );

  Map<String, dynamic> toJson() => {
        'jackSwapAny': jackSwapAny,
        'fiveMovesAny': fiveMovesAny,
        'kingBurnsPath': kingBurnsPath,
        'canBurnPartner': canBurnPartner,
        'sevenSplit': sevenSplit,
      };

  factory RuleSet.fromJson(Map<String, dynamic> j) => RuleSet(
        jackSwapAny: j['jackSwapAny'] ?? true,
        fiveMovesAny: j['fiveMovesAny'] ?? true,
        kingBurnsPath: j['kingBurnsPath'] ?? true,
        canBurnPartner: j['canBurnPartner'] ?? true,
        sevenSplit: j['sevenSplit'] ?? true,
      );
}
