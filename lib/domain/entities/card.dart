/// A standard playing card identified by an int 0..51
/// (`rank = id % 13 + 1`, `suit = id ~/ 13`).
enum Suit { spades, hearts, diamonds, clubs }

class PlayingCard {
  final int id;
  const PlayingCard(this.id);

  int get rank => id % 13 + 1; // 1 = Ace … 13 = King
  Suit get suit => Suit.values[id ~/ 13];
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  String get rankLabel => switch (rank) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rank',
      };

  String get suitSymbol => switch (suit) {
        Suit.spades => '♠',
        Suit.hearts => '♥',
        Suit.diamonds => '♦',
        Suit.clubs => '♣',
      };

  @override
  String toString() => '$rankLabel$suitSymbol';

  static List<int> fullDeck() => List.generate(52, (i) => i);
}
