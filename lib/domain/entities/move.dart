/// One playable action. Built by the engine (never by the UI) so every
/// move handed to `apply` is already legal.
enum MoveKind { exitBase, advance, back, swap, split, discard }

class MarbleRef {
  final int seat;
  final int idx;
  const MarbleRef(this.seat, this.idx);

  @override
  bool operator ==(Object other) =>
      other is MarbleRef && other.seat == seat && other.idx == idx;
  @override
  int get hashCode => seat * 8 + idx;
  @override
  String toString() => 'M$seat.$idx';

  Map<String, dynamic> toJson() => {'seat': seat, 'idx': idx};
  factory MarbleRef.fromJson(Map<String, dynamic> j) =>
      MarbleRef(j['seat'], j['idx']);
}

class Move {
  final int seat;
  final int cardId;
  final MoveKind kind;

  /// Primary marble (null for discard).
  final MarbleRef? marble;

  /// Steps for advance/back/split-first-part.
  final int steps;

  /// Destination of the primary marble (encoded like [Pos]).
  final int to;

  /// Second marble: the swap target, or the second half of a split.
  final MarbleRef? marble2;
  final int steps2;
  final int to2;

  const Move({
    required this.seat,
    required this.cardId,
    required this.kind,
    this.marble,
    this.steps = 0,
    this.to = 0,
    this.marble2,
    this.steps2 = 0,
    this.to2 = 0,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'card': cardId,
        'kind': kind.index,
        'm': marble?.toJson(),
        'steps': steps,
        'to': to,
        'm2': marble2?.toJson(),
        'steps2': steps2,
        'to2': to2,
      };

  factory Move.fromJson(Map<String, dynamic> j) => Move(
        seat: j['seat'],
        cardId: j['card'],
        kind: MoveKind.values[j['kind']],
        marble: j['m'] == null ? null : MarbleRef.fromJson(j['m']),
        steps: j['steps'] ?? 0,
        to: j['to'] ?? 0,
        marble2: j['m2'] == null ? null : MarbleRef.fromJson(j['m2']),
        steps2: j['steps2'] ?? 0,
        to2: j['to2'] ?? 0,
      );
}

/// What happened when a move was applied — the UI animates from this.
class MoveEvent {
  final MarbleRef marble;
  final int from;
  final int to;

  /// Absolute track cells crossed (for hop animation); empty for jumps.
  final List<int> path;
  final bool captured; // this marble was sent to base

  const MoveEvent(this.marble, this.from, this.to,
      {this.path = const [], this.captured = false});
}
