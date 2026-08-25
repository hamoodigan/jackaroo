enum BotLevel { easy, normal, hard }

class PlayerSlot {
  final int seat;
  final String name;
  final bool isBot;
  final BotLevel level;

  const PlayerSlot({
    required this.seat,
    required this.name,
    this.isBot = false,
    this.level = BotLevel.normal,
  });

  int get team => seat % 2;
  int get partner => (seat + 2) % 4;

  PlayerSlot copyWith({String? name, bool? isBot, BotLevel? level}) =>
      PlayerSlot(
        seat: seat,
        name: name ?? this.name,
        isBot: isBot ?? this.isBot,
        level: level ?? this.level,
      );

  Map<String, dynamic> toJson() =>
      {'seat': seat, 'name': name, 'isBot': isBot, 'level': level.index};

  factory PlayerSlot.fromJson(Map<String, dynamic> j) => PlayerSlot(
        seat: j['seat'],
        name: j['name'],
        isBot: j['isBot'] ?? false,
        level: BotLevel.values[j['level'] ?? 1],
      );
}
