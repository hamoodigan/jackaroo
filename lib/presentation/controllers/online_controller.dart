import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../data/local_storage.dart';
import '../../data/net/net_config.dart';
import '../../data/net/online_session.dart';
import '../../data/net/room_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/rules.dart';
import 'game_controller.dart';
import 'settings_controller.dart';

class LobbyPlayer {
  final int seat;
  final String name;
  final String? id; // null → open seat (bot at start)
  const LobbyPlayer({required this.seat, required this.name, this.id});

  bool get isOpen => id == null;

  Map<String, dynamic> toJson() => {'seat': seat, 'name': name, 'id': id};
  factory LobbyPlayer.fromJson(Map<String, dynamic> j) =>
      LobbyPlayer(seat: j['seat'], name: j['name'] ?? '', id: j['id']);
}

/// Lobby flow for online rooms: create / join / start. When a room starts,
/// it builds the [GameController] with an [OnlineSession] and opens /game.
class OnlineController extends GetxController {
  final RoomService net;
  final LocalStorage store;
  OnlineController(this.net, this.store);

  final name = ''.obs;
  final code = RxnString();
  final isHost = false.obs;
  final players = <LobbyPlayer>[].obs;
  final rules = const RuleSet().obs;
  final busy = false.obs;
  final error = RxnString();
  final started = false.obs;

  late final String myId = net.clientId;
  final _rng = Random();
  Map<String, dynamic>? _snapshot;
  int _snapshotSeq = 0;
  Timer? _joinTimer;

  String get base => '${NetConfig.topicRoot}/${code.value}';
  int? get mySeat =>
      players.firstWhereOrNull((p) => p.id == myId)?.seat;

  @override
  void onInit() {
    super.onInit();
    name.value = store.playerName;
    ever(name, (v) => store.playerName = v);
  }

  String get _displayName => name.value.trim().isEmpty ? 'Player' : name.value.trim();

  Future<bool> _connect() async {
    busy.value = true;
    error.value = null;
    final ok = await net.connect();
    busy.value = false;
    if (!ok) error.value = 'connection_failed'.tr;
    return ok;
  }

  // ── host ──────────────────────────────────────────────────────────────

  Future<void> create() async {
    if (!await _connect()) return;
    leave(silent: true);
    code.value = RoomService.newCode(_rng);
    isHost.value = true;
    started.value = false;
    players.assignAll([
      LobbyPlayer(seat: 0, name: _displayName, id: myId),
      for (var s = 1; s < GameConfig.seats; s++)
        LobbyPlayer(seat: s, name: 'open_seat'.tr),
    ]);
    net.subscribe('$base/join', _onJoin);
    net.subscribe('$base/leave', _onLeave);
    _publishLobby();
  }

  void _publishLobby() {
    net.publish(
      '$base/lobby',
      {
        'host': myId,
        'started': started.value,
        'rules': rules.value.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
      },
      retain: true,
    );
  }

  void _onJoin(Map<String, dynamic> j) {
    if (!isHost.value || started.value) return;
    final id = j['id'] as String?;
    if (id == null || players.any((p) => p.id == id)) {
      _publishLobby();
      return;
    }
    final idx = players.indexWhere((p) => p.isOpen);
    if (idx < 0) {
      _publishLobby(); // full — joiner will time out
      return;
    }
    players[idx] = LobbyPlayer(seat: idx, name: (j['name'] ?? 'Player').toString(), id: id);
    _publishLobby();
  }

  void _onLeave(Map<String, dynamic> j) {
    if (!isHost.value || started.value) return;
    final id = j['id'];
    final idx = players.indexWhere((p) => p.id == id);
    if (idx > 0) {
      players[idx] = LobbyPlayer(seat: idx, name: 'open_seat'.tr);
      _publishLobby();
    }
  }

  void setRules(RuleSet r) {
    rules.value = r;
    if (isHost.value) _publishLobby();
  }

  /// Host: open seats become bots, game state is created and broadcast.
  void start() {
    if (!isHost.value) return;
    final slots = <PlayerSlot>[
      for (final p in players)
        PlayerSlot(
          seat: p.seat,
          name: p.isOpen ? 'Bot ${p.seat + 1}' : p.name,
          isBot: p.isOpen,
        ),
    ];
    started.value = true;
    _publishLobby();
    final session = OnlineSession(net: net, base: base, mySeat: 0, isHost: true);
    _launch(slots, session);
  }

  // ── client ────────────────────────────────────────────────────────────

  Future<void> join(String rawCode) async {
    final c = rawCode.trim().toUpperCase();
    if (c.length != NetConfig.codeLength) {
      error.value = 'enter_code'.tr;
      return;
    }
    if (!await _connect()) return;
    leave(silent: true);
    code.value = c;
    isHost.value = false;
    started.value = false;
    players.clear();
    busy.value = true;
    net.subscribe('$base/lobby', _onLobby);
    net.subscribe('$base/state', _onState);
    net.publish('$base/join', {'id': myId, 'name': _displayName});
    _joinTimer?.cancel();
    _joinTimer = Timer(const Duration(seconds: 8), () {
      if (mySeat == null) {
        busy.value = false;
        error.value = players.isEmpty ? 'room_not_found'.tr : 'room_full'.tr;
        leave(silent: true);
      }
    });
  }

  void _onLobby(Map<String, dynamic> j) {
    if (isHost.value) return;
    final list = (j['players'] as List? ?? [])
        .map((p) => LobbyPlayer.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    players.assignAll(list);
    if (j['rules'] != null) {
      rules.value = RuleSet.fromJson(Map<String, dynamic>.from(j['rules']));
    }
    if (mySeat != null) {
      busy.value = false;
      _joinTimer?.cancel();
    }
    final st = j['started'] == true;
    if (st && !started.value && mySeat != null) {
      started.value = true;
      _tryLaunchClient();
    }
  }

  void _onState(Map<String, dynamic> j) {
    if (isHost.value) return;
    _snapshot = Map<String, dynamic>.from(j['state'] ?? {});
    _snapshotSeq = j['seq'] ?? 0;
    if (started.value) _tryLaunchClient();
  }

  bool _launched = false;

  void _tryLaunchClient() {
    if (_launched || _snapshot == null || mySeat == null) return;
    final slots = <PlayerSlot>[
      for (final p in players)
        PlayerSlot(seat: p.seat, name: p.isOpen ? 'Bot ${p.seat + 1}' : p.name, isBot: p.isOpen),
    ];
    final session = OnlineSession(
      net: net,
      base: base,
      mySeat: mySeat!,
      isHost: false,
      initialState: _snapshot,
      initialSeq: _snapshotSeq,
    );
    _launch(slots, session);
  }

  void _launch(List<PlayerSlot> slots, OnlineSession session) {
    _launched = true;
    final settings = Get.find<SettingsController>();
    Get.delete<GameController>(force: true);
    Get.put(GameController(
      players: slots,
      rules: rules.value,
      hideHands: false,
      audio: settings.audio,
      online: session,
    ));
    Get.offNamed('/game');
  }

  /// Leaves the current room (host clears the retained lobby).
  void leave({bool silent = false}) {
    _joinTimer?.cancel();
    if (code.value != null) {
      if (isHost.value) {
        net.clearRetained('$base/lobby');
        net.clearRetained('$base/state');
      } else if (!started.value) {
        net.publish('$base/leave', {'id': myId});
      }
      net.unsubscribePrefix(base);
    }
    code.value = null;
    players.clear();
    isHost.value = false;
    started.value = false;
    _launched = false;
    _snapshot = null;
    busy.value = false;
    if (!silent) error.value = null;
  }
}
