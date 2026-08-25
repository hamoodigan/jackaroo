# Jackaroo

Flutter implementation of Jackaroo (marbles + cards, 2 teams of 2) for
web (installable PWA on iPhone/Android), Android APK and iOS.

## Why it exists
Popular Jackaroo apps force the Jack to swap one of *your* marbles with an
opponent's. On a physical board most families let the Jack swap **any two
marbles**. This app makes that a house-rule toggle (on by default), with
several other common variants.

## Run
```
flutter pub get
dart run tool/make_sounds.dart                        # only if assets/sounds is empty
flutter run -d chrome                                 # web
flutter build web --release --base-href /jackaroo/    # GitHub Pages
flutter build apk --release                           # Android
```

## Layout
- `lib/core/` - config (board sizes, timings), theme, translations (en/ar)
- `lib/domain/entities/` - cards, positions, rules, players, moves, GameState (JSON-serialisable)
- `lib/domain/engine/` - `JackarooEngine` (pure rules: legal moves + apply) and `BotEngine`
- `lib/data/` - settings storage, audio, `net/` online rooms (MQTT)
- `lib/presentation/` - GetX controllers, screens (home/setup/game/rules), board painter & widgets
- `test/` - engine rules, per-card tap flow, board geometry, host/client protocol, live broker check

## Rules implemented
A exit/1/11, K exit/13 (burns path), Q 12, J swap, 10 9 8 6 3 2, 7 (splittable),
5 (any marble), 4 backward, safe entry cells, exact home entry, partner play after
finishing, forced discard when no move.

## Online play
Play online → Create room → share the 4-letter code → friends Join → Start.
Rooms run over the free public HiveMQ MQTT broker (no account, no server);
the host is authoritative and runs the bots. See `lib/data/net/`.

## Board
The real octagonal Jackaroo board, traced from a photo: 76-hole loop with
eight apexes, base hole on each diagonal edge, 4-hole home lane along the
corner diagonal, waiting pockets in the notches, clockwise play.
