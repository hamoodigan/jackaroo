import 'package:get/get.dart';

import '../../data/local_storage.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/rules.dart';

/// Holds the "new game" form; remembers the last setup between sessions.
class SetupController extends GetxController {
  final LocalStorage store;
  SetupController(this.store);

  final players = <PlayerSlot>[].obs;
  final rules = const RuleSet().obs;

  @override
  void onInit() {
    super.onInit();
    final saved = store.lastSetup;
    if (saved != null) {
      try {
        players.assignAll((saved['players'] as List)
            .map((p) => PlayerSlot.fromJson(Map<String, dynamic>.from(p))));
        rules.value = RuleSet.fromJson(Map<String, dynamic>.from(saved['rules']));
      } catch (_) {
        _defaults();
      }
    }
    if (players.length != 4) _defaults();
  }

  void _defaults() {
    players.assignAll([
      const PlayerSlot(seat: 0, name: 'You'),
      const PlayerSlot(seat: 1, name: 'Bot 1', isBot: true),
      const PlayerSlot(seat: 2, name: 'Bot 2', isBot: true),
      const PlayerSlot(seat: 3, name: 'Bot 3', isBot: true),
    ]);
  }

  void setName(int seat, String name) =>
      players[seat] = players[seat].copyWith(name: name.trim());

  void toggleBot(int seat, bool bot) =>
      players[seat] = players[seat].copyWith(isBot: bot);

  void setLevel(int seat, BotLevel level) =>
      players[seat] = players[seat].copyWith(level: level);

  void setRules(RuleSet r) => rules.value = r;

  List<PlayerSlot> finalPlayers() {
    final out = <PlayerSlot>[];
    for (final p in players) {
      final name = p.name.isEmpty
          ? (p.isBot ? 'Bot ${p.seat + 1}' : 'Player ${p.seat + 1}')
          : p.name;
      out.add(p.copyWith(name: name));
    }
    store.lastSetup = {
      'players': out.map((p) => p.toJson()).toList(),
      'rules': rules.value.toJson(),
    };
    return out;
  }
}
