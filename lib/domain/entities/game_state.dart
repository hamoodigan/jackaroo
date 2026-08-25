import '../../core/config/game_config.dart';
import 'player.dart';
import 'position.dart';
import 'rules.dart';

/// Complete, serialisable snapshot of a match. Kept deliberately plain so
/// the same document can later live in a realtime database for online play.
class GameState {
  final List<PlayerSlot> players;
  final RuleSet rules;

  /// marbles[seat][idx] → position (see [Pos]).
  final List<List<int>> marbles;

  /// hands[seat] → card ids.
  final List<List<int>> hands;
  List<int> deck;
  List<int> discard;

  int turn;
  int round;
  int? winnerTeam;

  /// Per-seat counters shown on the result screen.
  final List<int> captures;
  final List<int> movesPlayed;

  GameState({
    required this.players,
    required this.rules,
    required this.marbles,
    required this.hands,
    required this.deck,
    required this.discard,
    this.turn = 0,
    this.round = 0,
    this.winnerTeam,
    List<int>? captures,
    List<int>? movesPlayed,
  })  : captures = captures ?? List.filled(GameConfig.seats, 0),
        movesPlayed = movesPlayed ?? List.filled(GameConfig.seats, 0);

  factory GameState.fresh(List<PlayerSlot> players, RuleSet rules) => GameState(
        players: players,
        rules: rules,
        marbles: List.generate(GameConfig.seats,
            (_) => List.filled(GameConfig.marblesPerPlayer, Pos.base)),
        hands: List.generate(GameConfig.seats, (_) => <int>[]),
        deck: [],
        discard: [],
      );

  int teamOf(int seat) => seat % 2;
  int partnerOf(int seat) => (seat + 2) % GameConfig.seats;

  bool allHome(int seat) => marbles[seat].every(Pos.isHome);
  int homeCount(int seat) => marbles[seat].where(Pos.isHome).length;

  bool teamFinished(int team) =>
      allHome(team) && allHome(team + 2);

  bool get isOver => winnerTeam != null;

  /// Which seat's marbles [seat] controls this turn: its own, or the
  /// partner's once all its own marbles are home.
  int controlledSeat(int seat) => allHome(seat) ? partnerOf(seat) : seat;

  /// (seat, idx) of the marble on absolute track [cell], if any.
  (int, int)? occupant(int cell) {
    for (var s = 0; s < GameConfig.seats; s++) {
      for (var i = 0; i < GameConfig.marblesPerPlayer; i++) {
        final p = marbles[s][i];
        if (Pos.isTrack(p) && Pos.abs(s, p) == cell) return (s, i);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'rules': rules.toJson(),
        'marbles': marbles,
        'hands': hands,
        'deck': deck,
        'discard': discard,
        'turn': turn,
        'round': round,
        'winnerTeam': winnerTeam,
        'captures': captures,
        'movesPlayed': movesPlayed,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        players: (j['players'] as List)
            .map((p) => PlayerSlot.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        rules: RuleSet.fromJson(Map<String, dynamic>.from(j['rules'])),
        marbles: (j['marbles'] as List)
            .map((r) => List<int>.from(r as List))
            .toList(),
        hands: (j['hands'] as List)
            .map((r) => List<int>.from(r as List))
            .toList(),
        deck: List<int>.from(j['deck']),
        discard: List<int>.from(j['discard']),
        turn: j['turn'] ?? 0,
        round: j['round'] ?? 0,
        winnerTeam: j['winnerTeam'],
        captures: j['captures'] == null ? null : List<int>.from(j['captures']),
        movesPlayed:
            j['movesPlayed'] == null ? null : List<int>.from(j['movesPlayed']),
      );
}
