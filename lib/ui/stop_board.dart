import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/demo_data.dart';
import '../data/network.dart';
import 'community_screen.dart' show kindColor, kindIconOf, kindName;
import 'mini_map.dart';
import 'widgets.dart';

/// Dark colours of the screens that hang at stops and inside buses.
class D {
  static const bg = Color(0xFF0B0E13);
  static const panel = Color(0xFF141922);
  static const line = Color(0xFF232A36);
  static const ink2 = Color(0xFF8E97A8);
  static const green = Color(0xFF4ADE80);
}

/// What a digital display at a bus stop would show: next buses, where each
/// one goes (a map of the lines through this stop with live buses), and
/// intercity departures at the bus station. Runs from the same web build
/// (`?board=<stop id>`), so a cheap screen with a browser is enough.
class StopBoard extends StatefulWidget {
  const StopBoard({
    super.key,
    required this.app,
    required this.stop,
    this.kiosk = false,
  });
  final AppState app;
  final Stop stop;

  /// Full-screen display mode: no back button.
  final bool kiosk;

  @override
  State<StopBoard> createState() => _StopBoardState();
}

class _StopBoardState extends State<StopBoard>
    with SingleTickerProviderStateMixin {
  late Stop stop = widget.stop;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  Timer? _t;

  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _pick() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PointerInterceptor(
      child: Guarded(
        child: StopPicker(
          app: app,
          onPick: (s) {
            Navigator.pop(context);
            setState(() => stop = s);
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final header = _header(wide);
    final deps = _Departures(app: app, stop: stop);
    final map = _panel(
      child: AnimatedBuilder(animation: _pulse, builder: (_, _) => _map()),
    );
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: D.bg,
          body: SafeArea(
            child: wide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                    child: Column(
                      children: [
                        header,
                        const SizedBox(height: 18),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 6, child: deps),
                              const SizedBox(width: 18),
                              Expanded(flex: 5, child: map),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _BottomBar(),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      header,
                      const SizedBox(height: 14),
                      deps,
                      const SizedBox(height: 14),
                      SizedBox(height: 330, child: map),
                      const SizedBox(height: 14),
                      const _BottomBar(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final now = app.now;
    final lang = Lang.i.code;
    return Row(
      children: [
        if (!widget.kiosk) ...[
          RoundButton(
            icon: Icons.arrow_back_rounded,
            dark: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
        ],
        Container(
          width: wide ? 58 : 46,
          height: wide ? 58 : 46,
          decoration: BoxDecoration(
            color: C.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: wide ? 34 : 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Press(
            onTap: widget.kiosk ? null : _pick,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (wide) ...[
                      Text(
                        tr('boardTitle').toUpperCase(),
                        style: const TextStyle(
                          color: D.ink2,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    DemoTag(tr('demo'), dark: true),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        stop.name.of(lang),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 34 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                        maxLines: wide ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.kiosk)
                      const Icon(
                        Icons.expand_more_rounded,
                        color: D.ink2,
                        size: 28,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmtClock(now),
              style: TextStyle(
                color: Colors.white,
                fontSize: wide ? 42 : 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (wide) ...[
              const SizedBox(height: 4),
              Text(
                fmtDate(DateTime.now()),
                style: const TextStyle(
                  color: D.ink2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _map() {
    final net = app.net;
    final ids = stop.routeIds.toSet();
    final routes = [for (final id in ids) net.route(id)];
    final lang = Lang.i.code;
    return Stack(
      children: [
        Positioned.fill(
          child: MiniMap(
            net: net,
            dark: true,
            focus: [for (final r in routes) ...r.shape],
            routes: ids,
            buses: [
              for (final b in app.sched.positions(app.now))
                if (ids.contains(b.dir.route.id)) b,
            ],
            here: stop.pos,
            hereLabel: tr('youAreHere'),
            pulse: _pulse.value,
            labels: [
              for (final r in routes)
                for (final s in {r.dirs[0].terminus, r.dirs[1].terminus})
                  (s.pos, s.name.of(lang)),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 14,
          right: 16,
          child: Row(
            children: [
              Text(
                tr('whereBusesGo'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              for (final r in routes)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: RouteBadge(r, size: 26),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
  padding: padding,
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: D.panel,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: D.line),
  ),
  child: child,
);

class _Departures extends StatelessWidget {
  const _Departures({required this.app, required this.stop});
  final AppState app;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final now = app.now;
    final lang = Lang.i.code;
    final rows = <(RouteDir, double, List<Stop>)>[];
    for (final d in app.net.dirs) {
      final i = d.stops.indexOf(stop);
      if (i < 0 || i == d.stops.length - 1) continue;
      final via = d.stops.sublist(i + 1, math.min(i + 3, d.stops.length - 1));
      rows.add((d, app.sched.waitAt(d, i, now), via));
    }
    rows.sort((a, b) => a.$2.compareTo(b.$2));
    final station = stop.kind == 'station' || stop.id == 'avtovokzal';
    final community = [
      for (final r in app.community)
        if (r.via.contains(stop.id)) r,
    ];
    final colHead = TextStyle(
      color: D.ink2.withValues(alpha: 0.8),
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
    return _panel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(tr('colRoute').toUpperCase(), style: colHead),
              ),
              Expanded(child: Text(tr('colTo').toUpperCase(), style: colHead)),
              Text(tr('colEta').toUpperCase(), style: colHead),
            ],
          ),
          const SizedBox(height: 6),
          for (final (d, w, via) in rows.take(station ? 2 : 6))
            _CityRow(d: d, wait: w, via: via, lang: lang),
          if (!station && community.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: C.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr('alsoHere'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final r in community.take(3)) _CommunityRow(r: r),
          ],
          if (station) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: C.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr('intercity'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final dep in nextDepartures(now, n: 6))
              _IntercityRow(dep: dep, now: now, lang: lang),
          ],
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.d,
    required this.wait,
    required this.via,
    required this.lang,
  });
  final RouteDir d;
  final double wait;
  final List<Stop> via;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final soon = wait < 1.5;
    final after = wait + d.route.headwayMin;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: D.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RouteBadge(d.route, size: 44),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.terminus.name.of(lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (via.isNotEmpty)
                  Text(
                    '${tr('via')} ${via.map((s) => s.name.of(lang)).join(' · ')}',
                    style: const TextStyle(
                      color: D.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              soon
                  ? _Blink(
                      child: Text(
                        tr('now').toUpperCase(),
                        style: const TextStyle(
                          color: D.green,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${wait.round()}',
                            style: const TextStyle(fontSize: 30),
                          ),
                          TextSpan(
                            text: ' ${tr('min')}',
                            style: const TextStyle(fontSize: 15, color: D.ink2),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        color: C.amber,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
              Text(
                '${tr('then')} ${after.round()} ${tr('min')}',
                style: const TextStyle(
                  color: D.ink2,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Damas / marshrutka that riders say stop here (approximate, no times).
class _CommunityRow extends StatelessWidget {
  const _CommunityRow({required this.r});
  final CommunityRoute r;

  @override
  Widget build(BuildContext context) {
    final col = kindColor(r.kind);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: D.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(kindIconOf(r.kind), color: col, size: 24),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r.from.of(Lang.i.code)} → ${r.to.of(Lang.i.code)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${kindName(r.kind)}${r.number.isEmpty ? '' : ' №${r.number}'} · ${fmtInt(r.price)} ${tr('som')} · ${r.confirms} 👍',
                  style: const TextStyle(
                    color: D.ink2,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tr('every')} ~${r.every} ${tr('min')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntercityRow extends StatelessWidget {
  const _IntercityRow({
    required this.dep,
    required this.now,
    required this.lang,
  });
  final Departure dep;
  final double now;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = dep.line;
    final left = dep.at - now;
    final (status, col) = left < 0
        ? (tr('departed'), D.ink2)
        : left < 5
        ? (tr('boarding'), D.green)
        : (tr('onTime'), D.ink2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: D.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              fmtClock(dep.at),
              style: const TextStyle(
                color: C.amber,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.to.of(lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${l.minibus ? tr('minibus') : tr('bus')} · ${fmtMin(l.minutes.toDouble())} · ${fmtInt(l.price)} ${tr('som')}',
                  style: const TextStyle(
                    color: D.ink2,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tr('platform')} ${l.platform}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: col,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Blink extends StatefulWidget {
  const _Blink({required this.child});
  final Widget child;
  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_a),
    child: widget.child,
  );
}

/// News line + QR to the app.
class _BottomBar extends StatelessWidget {
  const _BottomBar();
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: BoxDecoration(
      color: D.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: D.line),
    ),
    child: Row(
      children: [
        Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: C.amber,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(17)),
          ),
          child: const Icon(Icons.campaign_rounded, color: D.bg, size: 28),
        ),
        Expanded(
          child: Ticker(
            text: tr('boardTicker'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: D.line)),
          ),
          child: Row(
            children: [
              Text(
                tr('scanApp'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/img/qr.png',
                  width: 50,
                  height: 50,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Bottom-sheet list of stops (used by the board and the route form).
class StopPicker extends StatelessWidget {
  const StopPicker({super.key, required this.app, required this.onPick});
  final AppState app;
  final void Function(Stop) onPick;

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final stops = app.net.stops.values.toList()
      ..sort((a, b) => a.name.of(lang).compareTo(b.name.of(lang)));
    return Container(
      margin: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.xl),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final s in stops)
            ListTile(
              leading: Icon(kindIcon(s.kind), color: C.ink2),
              title: Text(s.name.of(lang), style: T.body),
              trailing: Wrap(
                spacing: 4,
                children: [
                  for (final id in s.routeIds)
                    RouteBadge(app.net.route(id), size: 22),
                ],
              ),
              onTap: () => onPick(s),
            ),
        ],
      ),
    );
  }
}
