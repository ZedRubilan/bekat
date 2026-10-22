import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/demo_data.dart';
import '../data/network.dart';
import 'mini_map.dart';
import 'stop_board.dart' show StopPicker;
import 'widgets.dart';

Color kindColor(RideKind k) => switch (k) {
  RideKind.damas => const Color(0xFF0EA5A4),
  RideKind.marshrutka => const Color(0xFFEA580C),
  RideKind.taxi => const Color(0xFFDB2777),
};

IconData kindIconOf(RideKind k) => switch (k) {
  RideKind.damas => Icons.airport_shuttle_rounded,
  RideKind.marshrutka => Icons.directions_bus_filled_rounded,
  RideKind.taxi => Icons.local_taxi_rounded,
};

String kindName(RideKind k) => tr(k.name);

/// Routes the city doesn't publish — damas, marshrutkas, shared taxis —
/// added and confirmed by the people who ride them.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.app});
  final AppState app;
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  RideKind? _kind;
  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    app.addListener(_rebuild);
  }

  @override
  void dispose() {
    app.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _open(CommunityRoute r) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PointerInterceptor(
      child: Guarded(
        child: _RouteSheet(app: app, r: r),
      ),
    ),
  );

  Future<void> _add() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AddRouteScreen(app: app)));
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('thanksSent')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = [
      for (final r in app.community)
        if (_kind == null || r.kind == _kind) r,
    ];
    final mine = app.community.where((r) => r.mine).length;
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: C.bg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            backgroundColor: C.blue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_road_rounded),
            label: Text(
              tr('addRoute'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  children: [
                    Row(
                      children: [
                        RoundButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        DemoTag(tr('demoData')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(tr('community'), style: T.display),
                    const SizedBox(height: 6),
                    Text(tr('communitySub'), style: T.sub),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _Stat(fmtInt(342 + mine), tr('statIdeas'), C.blue),
                        const SizedBox(width: 10),
                        _Stat('58', tr('statVerified'), C.green),
                        const SizedBox(width: 10),
                        _Stat(fmtInt(1240), tr('statPeople'), C.coral),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filter(null, tr('all')),
                          for (final k in RideKind.values)
                            _filter(k, kindName(k)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final r in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RouteCard(
                          app: app,
                          r: r,
                          onTap: () => _open(r),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filter(RideKind? k, String label) {
    final on = _kind == k;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Press(
        onTap: () => setState(() => _kind = k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: on ? C.night : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: on ? null : softShadow(0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (k != null) ...[
                Icon(
                  kindIconOf(k),
                  size: 18,
                  color: on ? Colors.white : kindColor(k),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: T.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : C.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.m),
        boxShadow: softShadow(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: T.metric.copyWith(fontSize: 24, color: color)),
          const SizedBox(height: 4),
          Text(label, style: T.cap, maxLines: 2),
        ],
      ),
    ),
  );
}

String _title(CommunityRoute r) =>
    '${kindName(r.kind)}${r.number.isEmpty ? '' : ' №${r.number}'}';

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.r);
  final CommunityRoute r;
  @override
  Widget build(BuildContext context) {
    final ok = r.status == Review.verified;
    final col = ok ? C.green : const Color(0xFFB7791F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE3F6EA) : const Color(0xFFFFF3DC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            size: 14,
            color: col,
          ),
          const SizedBox(width: 4),
          Text(
            ok ? tr('verified') : tr('inReview'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: col,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.app, required this.r, required this.onTap});
  final AppState app;
  final CommunityRoute r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final via = [
      for (final id in r.via.skip(1).take(r.via.length - 2))
        if (app.net.stops[id] != null) app.net.stops[id]!.name.of(lang),
    ];
    final col = kindColor(r.kind);
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.l),
          boxShadow: softShadow(0.07),
          border: r.mine ? Border.all(color: C.blue, width: 1.5) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(kindIconOf(r.kind), color: col, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _title(r).toUpperCase(),
                        style: TextStyle(
                          color: col,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      _StatusChip(r),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.from.of(Lang.i.code)} → ${r.to.of(Lang.i.code)}',
                    style: T.h,
                  ),
                  if (via.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${tr('via')} ${via.join(' · ')}',
                      style: T.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _meta(
                        Icons.payments_rounded,
                        '${fmtInt(r.price)} ${tr('som')}',
                      ),
                      _meta(
                        Icons.update_rounded,
                        '${tr('every')} ${r.every} ${tr('min')}',
                      ),
                      const Spacer(),
                      Icon(
                        app.confirmed.contains(r.id)
                            ? Icons.thumb_up_alt_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 17,
                        color: C.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${r.confirms}',
                        style: T.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: C.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 16, color: C.ink3),
        const SizedBox(width: 4),
        Text(t, style: T.sub.copyWith(fontSize: 13)),
      ],
    ),
  );
}

class _RouteSheet extends StatefulWidget {
  const _RouteSheet({required this.app, required this.r});
  final AppState app;
  final CommunityRoute r;
  @override
  State<_RouteSheet> createState() => _RouteSheetState();
}

class _RouteSheetState extends State<_RouteSheet> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app, r = widget.r;
    final lang = Lang.i.code;
    final path = r.path(app.net);
    final done = app.confirmed.contains(r.id);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.xl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(kindIconOf(r.kind), color: kindColor(r.kind)),
                const SizedBox(width: 8),
                Text(_title(r), style: T.h.copyWith(color: kindColor(r.kind))),
                const Spacer(),
                _StatusChip(r),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${r.from.of(Lang.i.code)} → ${r.to.of(Lang.i.code)}',
              style: T.title,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(R.m),
              child: SizedBox(
                height: 220,
                child: MiniMap(
                  net: app.net,
                  focus: path,
                  routes: const {},
                  paths: [(path, kindColor(r.kind))],
                  labels: [
                    for (final id in r.via)
                      if (app.net.stops[id] != null)
                        (
                          app.net.stops[id]!.pos,
                          app.net.stops[id]!.name.of(lang),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(tr('approxPath'), style: T.cap),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _kv(Icons.payments_rounded, '${fmtInt(r.price)} ${tr('som')}'),
                _kv(Icons.schedule_rounded, r.hours),
                _kv(
                  Icons.update_rounded,
                  '${tr('every')} ${r.every} ${tr('min')}',
                ),
                _kv(
                  Icons.person_rounded,
                  '${r.mine ? tr('you') : r.author} · ${r.daysAgo == 0 ? tr('today') : '${r.daysAgo} ${tr('daysAgo')}'}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('thanksReport')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(tr('reportError')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: done
                        ? null
                        : () {
                            app.confirm(r);
                            setState(() {});
                          },
                    icon: Icon(
                      done ? Icons.check_rounded : Icons.thumb_up_alt_rounded,
                    ),
                    label: Text(
                      '${done ? tr('confirmed') : tr('confirm')} · ${r.confirms}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.blue,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(IconData i, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 18, color: C.ink2),
      const SizedBox(width: 6),
      Text(t, style: T.body),
    ],
  );
}

// ---------------------------------------------------------------------------

/// "Add a route": kind, ends, stops on the way, fare, interval, hours.
/// Saved on the phone and marked "in review" — moderation is a later stage.
class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key, required this.app});
  final AppState app;
  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  RideKind kind = RideKind.damas;
  final _number = TextEditingController();
  Stop? from, to;
  final via = <Stop>[];
  int price = 3000, every = 10;
  TimeOfDay start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 20, minute: 0);

  AppState get app => widget.app;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<Stop?> _pickStop() => showModalBottomSheet<Stop>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => PointerInterceptor(
      child: Guarded(
        child: StopPicker(app: app, onPick: (s) => Navigator.pop(ctx, s)),
      ),
    ),
  );

  String _t(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _save() {
    app.addRoute(
      CommunityRoute(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        kind: kind,
        number: _number.text.trim(),
        from: from!.name,
        to: to!.name,
        via: [from!.id, for (final s in via) s.id, to!.id],
        price: price,
        hours: '${_t(start)}–${_t(end)}',
        every: every,
        confirms: 1,
        author: '',
        status: Review.review,
        daysAgo: 0,
        mine: true,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final path = [
      if (from != null) from!.pos,
      for (final s in via) s.pos,
      if (to != null) to!.pos,
    ];
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: C.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    Row(
                      children: [
                        RoundButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        DemoTag(tr('demo')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(tr('addRoute'), style: T.display),
                    const SizedBox(height: 6),
                    Text(tr('addRouteSub'), style: T.sub),
                    const SizedBox(height: 20),
                    _label(tr('transportKind')),
                    Row(
                      children: [
                        for (final k in RideKind.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Press(
                                onTap: () => setState(() => kind = k),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: kind == k
                                        ? kindColor(k)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(R.m),
                                    boxShadow: softShadow(0.06),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        kindIconOf(k),
                                        size: 30,
                                        color: kind == k
                                            ? Colors.white
                                            : kindColor(k),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        kindName(k),
                                        style: T.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: kind == k
                                              ? Colors.white
                                              : C.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(tr('routeNumber')),
                    _box(
                      TextField(
                        controller: _number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: tr('routeNumberHint'),
                        ),
                        style: T.h,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(tr('stopsOnWay')),
                    _box(
                      Column(
                        children: [
                          _stopRow(C.blue, tr('from'), from, () async {
                            final s = await _pickStop();
                            if (s != null) setState(() => from = s);
                          }),
                          for (var i = 0; i < via.length; i++)
                            _stopRow(
                              C.ink3,
                              tr('via'),
                              via[i],
                              null,
                              onRemove: () => setState(() => via.removeAt(i)),
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              final s = await _pickStop();
                              if (s != null) setState(() => via.add(s));
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: Text(tr('addStop')),
                          ),
                          _stopRow(C.coral, tr('to'), to, () async {
                            final s = await _pickStop();
                            if (s != null) setState(() => to = s);
                          }),
                        ],
                      ),
                    ),
                    if (path.length >= 2) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(R.m),
                        child: SizedBox(
                          height: 200,
                          child: MiniMap(
                            net: app.net,
                            focus: path,
                            routes: const {},
                            paths: [(path, kindColor(kind))],
                            labels: [
                              if (from != null)
                                (from!.pos, from!.name.of(lang)),
                              if (to != null) (to!.pos, to!.name.of(lang)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _label(tr('fare')),
                    _chips<int>(
                      [2000, 3000, 4000, 5000],
                      price,
                      (v) => '${fmtInt(v)} ${tr('som')}',
                      (v) => setState(() => price = v),
                    ),
                    const SizedBox(height: 16),
                    _label(tr('interval')),
                    _chips<int>(
                      [5, 10, 15, 20, 30],
                      every,
                      (v) => '$v ${tr('min')}',
                      (v) => setState(() => every = v),
                    ),
                    const SizedBox(height: 16),
                    _label(tr('workHours')),
                    Row(
                      children: [
                        Expanded(child: _timeTile(start, (t) => start = t)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('—', style: T.h),
                        ),
                        Expanded(child: _timeTile(end, (t) => end = t)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: from != null && to != null && from != to
                            ? _save
                            : null,
                        icon: const Icon(Icons.send_rounded),
                        label: Text(
                          tr('send'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: C.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('moderationNote'),
                      style: T.cap,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(t.toUpperCase(), style: T.cap.copyWith(letterSpacing: 0.8)),
  );

  Widget _box(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(R.m),
      boxShadow: softShadow(0.06),
    ),
    child: child,
  );

  Widget _stopRow(
    Color dot,
    String label,
    Stop? s,
    VoidCallback? onTap, {
    VoidCallback? onRemove,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dot,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: dot.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    ),
    title: Text(label, style: T.cap),
    subtitle: Text(
      s?.name.of(Lang.i.code) ?? tr('chooseStop'),
      style: T.h.copyWith(color: s == null ? C.ink3 : C.ink),
    ),
    trailing: onRemove != null
        ? IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: C.ink3),
          )
        : const Icon(Icons.chevron_right_rounded, color: C.ink3),
  );

  Widget _chips<V>(
    List<V> values,
    V selected,
    String Function(V) label,
    void Function(V) onTap,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        Press(
          onTap: () => onTap(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: v == selected ? C.night : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: softShadow(0.05),
            ),
            child: Text(
              label(v),
              style: T.body.copyWith(
                fontWeight: FontWeight.w700,
                color: v == selected ? Colors.white : C.ink,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _timeTile(TimeOfDay t, void Function(TimeOfDay) set) => Press(
    onTap: () async {
      final r = await showTimePicker(
        context: context,
        initialTime: t,
        builder: (c, child) => PointerInterceptor(
          child: Guarded(
            child: MediaQuery(
              data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          ),
        ),
      );
      if (r != null) setState(() => set(r));
    },
    child: _box(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: C.ink2),
            const SizedBox(width: 10),
            Text(_t(t), style: T.title),
          ],
        ),
      ),
    ),
  );
}
