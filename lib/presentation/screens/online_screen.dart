import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/online_controller.dart';

class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OnlineController>();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) c.leave(silent: true);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.background),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          c.leave(silent: true);
                          Get.back();
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.gold),
                      ),
                      Text('online_title'.tr, style: AppTheme.display(22, color: AppTheme.gold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Obx(() => c.code.value == null
                          ? _EntryForm(c: c)
                          : _Lobby(c: c)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryForm extends StatefulWidget {
  final OnlineController c;
  const _EntryForm({required this.c});

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      children: [
        Obx(() {
          final saved = c.savedRoom.value;
          if (saved == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _Big(
              label: 'rejoin_room'.trParams({'code': saved}),
              icon: Icons.replay_rounded,
              busy: c.busy.value,
              onTap: c.rejoin,
            ),
          );
        }),
        Text('your_name'.tr.toUpperCase(), style: _label),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: c.name.value,
          maxLength: 14,
          decoration: InputDecoration(hintText: 'name_hint'.tr, counterText: ''),
          style: const TextStyle(fontWeight: FontWeight.w700),
          onChanged: (v) => c.name.value = v,
        ),
        const SizedBox(height: 26),
        Obx(() => _Big(
              label: 'create_room'.tr,
              icon: Icons.add_circle_rounded,
              primary: true,
              busy: c.busy.value,
              onTap: c.create,
            )),
        const SizedBox(height: 28),
        Text('join_room'.tr.toUpperCase(), style: _label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(hintText: 'enter_code'.tr, counterText: ''),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 20),
                onSubmitted: c.join,
              ),
            ),
            const SizedBox(width: 10),
            Obx(() => SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surfaceHi,
                      foregroundColor: AppTheme.ivory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: c.busy.value ? null : () => c.join(_code.text),
                    child: Text('join_room'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (c.busy.value) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('connecting'.tr, style: const TextStyle(color: AppTheme.muted)),
              ],
            );
          }
          final e = c.error.value;
          if (e == null) return const SizedBox.shrink();
          return Text(e,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFB4A8), fontWeight: FontWeight.w600));
        }),
      ],
    );
  }

  static const _label = TextStyle(
      color: AppTheme.muted, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w800);
}

class _Lobby extends StatelessWidget {
  final OnlineController c;
  const _Lobby({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      children: [
        Text('room_code'.tr.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.muted, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: c.code.value ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${c.code.value} ✓'), duration: const Duration(seconds: 1)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.2), blurRadius: 24)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.code.value ?? '', style: AppTheme.title(40)),
                const SizedBox(width: 12),
                const Icon(Icons.copy_rounded, color: AppTheme.muted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Text(
              c.isHost.value ? 'share_code_hint'.tr : 'waiting_host'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            )),
        const SizedBox(height: 22),
        Obx(() => Column(
              children: [
                for (var s = 0; s < GameConfig.seats; s++) _seat(s),
              ],
            )),
        const SizedBox(height: 22),
        Obx(() => c.isHost.value
            ? _Big(
                label: 'start_game'.tr,
                icon: Icons.play_arrow_rounded,
                primary: true,
                onTap: c.start,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('waiting_host'.tr, style: const TextStyle(color: AppTheme.muted)),
                ],
              )),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            c.leave();
            Get.back();
          },
          icon: const Icon(Icons.logout_rounded, color: AppTheme.muted),
          label: Text('leave'.tr, style: const TextStyle(color: AppTheme.muted)),
        ),
      ],
    );
  }

  Widget _seat(int s) {
    final p = c.players.firstWhereOrNull((p) => p.seat == s);
    final color = AppTheme.seat(s);
    final open = p == null || p.isOpen;
    final me = p?.id == c.myId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: open ? AppTheme.surface.withValues(alpha: 0.5) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: open ? Colors.white10 : color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [Color.lerp(color, Colors.white, 0.5)!, color, AppTheme.seatDark[s]],
              ),
            ),
            child: Center(
              child: Text(s % 2 == 0 ? 'A' : 'B',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              open ? 'open_seat'.tr : p.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: open ? AppTheme.muted : AppTheme.ivory,
                fontStyle: open ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (s == 0)
            _tag('host'.tr)
          else if (open)
            Icon(Icons.smart_toy_rounded, size: 16, color: AppTheme.muted.withValues(alpha: 0.6)),
          if (me) ...[const SizedBox(width: 6), _tag('you'.tr)],
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(t,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.gold)),
      );
}

class _Big extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool busy;
  final VoidCallback onTap;
  const _Big({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: primary
                ? const LinearGradient(colors: [Color(0xFFFFE08A), AppTheme.goldDeep])
                : null,
            color: primary ? null : AppTheme.surface,
            boxShadow: [
              BoxShadow(
                  color: (primary ? AppTheme.gold : Colors.black).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primary ? AppTheme.bgBottom : AppTheme.gold, size: 26),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primary ? AppTheme.bgBottom : AppTheme.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
