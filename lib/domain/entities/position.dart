import '../../core/config/game_config.dart';

/// Marble positions are plain ints so the state stays JSON-friendly:
///   -1        → waiting in base
///   0..75     → on the track, counted from the owner's entry cell
///   100..103  → in the owner's home lane
class Pos {
  Pos._();

  static const int base = -1;
  static const int homeBase = 100;

  static bool isBase(int p) => p == base;
  static bool isTrack(int p) => p >= 0 && p < GameConfig.trackLength;
  static bool isHome(int p) => p >= homeBase;
  static int homeIndex(int p) => p - homeBase;
  static int home(int i) => homeBase + i;

  /// Absolute track cell (0..75) of a seat's relative position.
  static int abs(int seat, int rel) =>
      (seat * GameConfig.cellsPerSide + GameConfig.entryOffset + rel) %
      GameConfig.trackLength;

  static int entryCell(int seat) => abs(seat, 0);

  /// Relative position (for [seat]) of an absolute cell.
  static int rel(int seat, int absCell) =>
      (absCell - entryCell(seat) + GameConfig.trackLength) %
      GameConfig.trackLength;
}
