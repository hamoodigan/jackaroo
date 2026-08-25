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

  /// A 10 may instead make the next player throw away a random card and
  /// lose their turn.
  final bool tenSkip;

  /// A Queen may instead steal a random card from the next player (into
  /// your hand) and skip their turn.
  final bool queenSteal;

  const RuleSet({
    this.jackSwapAny = true,
    this.fiveMovesAny = true,
    this.kingBurnsPath = true,
    this.canBurnPartner = true,
    this.sevenSplit = true,
    this.tenSkip = true,
    this.queenSteal = true,
  });

  RuleSet copyWith({
    bool? jackSwapAny,
    bool? fiveMovesAny,
    bool? kingBurnsPath,
    bool? canBurnPartner,
    bool? sevenSplit,
    bool? tenSkip,
    bool? queenSteal,
  }) =>
      RuleSet(
        jackSwapAny: jackSwapAny ?? this.jackSwapAny,
        fiveMovesAny: fiveMovesAny ?? this.fiveMovesAny,
        kingBurnsPath: kingBurnsPath ?? this.kingBurnsPath,
        canBurnPartner: canBurnPartner ?? this.canBurnPartner,
        sevenSplit: sevenSplit ?? this.sevenSplit,
        tenSkip: tenSkip ?? this.tenSkip,
        queenSteal: queenSteal ?? this.queenSteal,
      );

  Map<String, dynamic> toJson() => {
        'jackSwapAny': jackSwapAny,
        'fiveMovesAny': fiveMovesAny,
        'kingBurnsPath': kingBurnsPath,
        'canBurnPartner': canBurnPartner,
        'sevenSplit': sevenSplit,
        'tenSkip': tenSkip,
        'queenSteal': queenSteal,
      };

  factory RuleSet.fromJson(Map<String, dynamic> j) => RuleSet(
        jackSwapAny: j['jackSwapAny'] ?? true,
        fiveMovesAny: j['fiveMovesAny'] ?? true,
        kingBurnsPath: j['kingBurnsPath'] ?? true,
        canBurnPartner: j['canBurnPartner'] ?? true,
        sevenSplit: j['sevenSplit'] ?? true,
        tenSkip: j['tenSkip'] ?? true,
        queenSteal: j['queenSteal'] ?? true,
      );
}
