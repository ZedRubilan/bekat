import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/network.dart';
import '../data/schedule.dart';
import 'mini_map.dart';
import 'stop_board.dart' show D;
import 'widgets.dart';

/// The display inside a bus: next stop in big letters, where you can change,
/// the whole line with the bus on it. Follows one simulated bus of the
/// chosen route (`?bus=<route id>` on the web).
class BusScreen extends StatefulWidget {
  const BusScreen({
    super.key,
    required this.app,
    this.routeId = '3',
    this.kiosk = false,
  });
  final AppState app;
  final String routeId;
  final bool kiosk;
  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen>
    with SingleTickerProviderStateMixin {
  late RouteDir dir = widget.app.net.route(widget.routeId).dirs.first;
  double? _trip;
  Timer? _t;
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  AppState get app => widget.app;
  Schedule get sched => app.sched;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// The bus we ride: keep it until the end of the line, then take the
  /// next one. First pick is a bus about a third of the way along.
  BusPos _bus() {
    final now = app.now;
    final cur = _trip == null ? null : sched.busOf(dir, _trip!, now);
    if (cur != null) return cur;
    final on = [
      for (final b in sched.positions(now))
        if (b.dir == dir) b,
    ];
    if (_trip == null) {
      // first pick: mid-route and close to its next stop — reads best on a demo
      double score(BusPos b) {
        final f = b.meters / dir.line.length;
        final k = (b.lastStop + 1).clamp(0, dir.stops.length - 1);
        final eta = sched.arrival(dir, b.tripStart, k) - now;
        return (f > 0.15 && f < 0.8 ? 0 : 100) + eta;
      }

      on.sort((a, b) => score(a).compareTo(score(b)));
    } else {
      on.sort((a, b) => a.meters.compareTo(b.meters));
    }
    if (on.isEmpty) return BusPos(dir, now, 0);
    _trip = on.first.tripStart;
    return on.first;
  }

  void _setRoute(BusRoute r) => setState(() {
    dir = r.dirs.first;
    _trip = null;
  });

  @override
  Widget build(BuildContext context) {
    final bus = _bus();
    final now = app.now;
    final lang = Lang.i.code;
    final other = lang == 'uz' ? 'ru' : 'uz';
    final i = bus.lastStop;
    final atStop = (bus.meters - dir.stopAt[i]).abs() < 1;
    final n = atStop ? i : (i + 1).clamp(0, dir.stops.length - 1);
    final next = dir.stops[n];
    final eta = sched.arrival(dir, bus.tripStart, n) - now;
    final last = n == dir.stops.length - 1;
    final changes = [
      for (final id in next.routeIds)
        if (id != dir.route.id) app.net.route(id),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final frac =
        i +
        (i < dir.stops.length - 1
            ? ((bus.meters - dir.stopAt[i]) /
                      (dir.stopAt[i + 1] - dir.stopAt[i]))
                  .clamp(0.0, 1.0)
            : 0.0);

    final nextPanel = _box(
      padding: EdgeInsets.all(wide ? 28 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (atStop
                          ? tr('thisStop')
                          : last
                          ? tr('lastStop')
                          : tr('nextStop'))
                      .toUpperCase(),
                  style: const TextStyle(
                    color: C.amber,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: c,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(next.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next.name.of(lang),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 58 : 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1.02,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next.name.of(other),
                        style: TextStyle(
                          color: D.ink2,
                          fontSize: wide ? 24 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: wide ? 26 : 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!atStop)
                      _chip(
                        Icons.schedule_rounded,
                        '≈ ${fmtMin(eta.clamp(0.5, 99).toDouble())}',
                      ),
                    if (changes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sync_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('changeTo'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            for (final r in changes)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: RouteBadge(r, size: 30),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 24),
            SizedBox(width: 280, child: _after(bus, n, now, lang)),
          ],
        ],
      ),
    );

    final map = _box(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => MiniMap(
          net: app.net,
          dark: true,
          focus: dir.route.shape,
          routes: {dir.route.id},
          buses: [bus],
          here: next.pos,
          pulse: _pulse.value,
          labels: [
            (dir.stops.first.pos, dir.stops.first.name.of(lang)),
            (dir.terminus.pos, dir.terminus.name.of(lang)),
          ],
        ),
      ),
    );

    final strip = _box(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: SizedBox(
        height: wide ? 178 : 170,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: frac),
          duration: const Duration(milliseconds: 600),
          builder: (_, f, _) => CustomPaint(
            size: Size.infinite,
            painter: _LinePainter(app.net, dir, f, lang),
          ),
        ),
      ),
    );

    final header = Row(
      children: [
        if (!widget.kiosk) ...[
          RoundButton(
            icon: Icons.arrow_back_rounded,
            dark: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
        ],
        RouteBadge(dir.route, size: wide ? 58 : 46),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tr('busScreen').toUpperCase(),
                    style: const TextStyle(
                      color: D.ink2,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DemoTag(tr('demo'), dark: true),
                ],
              ),
              Text(
                '${dir.stops.first.name.of(lang)} → ${dir.terminus.name.of(lang)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 26 : 19,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!widget.kiosk && wide)
          for (final r in app.net.routes)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Press(
                onTap: () => _setRoute(r),
                child: Opacity(
                  opacity: r == dir.route ? 1 : 0.35,
                  child: RouteBadge(r, size: 30),
                ),
              ),
            ),
        const SizedBox(width: 18),
        Text(
          fmtClock(now),
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 42 : 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final ticker = Container(
      height: 52,
      decoration: BoxDecoration(
        color: D.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.line),
      ),
      child: Ticker(
        text: tr('busTicker'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
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
                              Expanded(flex: 6, child: nextPanel),
                              const SizedBox(width: 18),
                              Expanded(flex: 4, child: map),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        strip,
                        const SizedBox(height: 14),
                        ticker,
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      header,
                      const SizedBox(height: 14),
                      nextPanel,
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: dir.stops.length * 74.0 + 160,
                          child: strip,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(height: 280, child: map),
                      const SizedBox(height: 14),
                      ticker,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// The three stops after the next one, with clock times.
  Widget _after(BusPos bus, int n, double now, String lang) {
    final rest = [
      for (var k = n + 1; k < dir.stops.length && k <= n + 3; k++) k,
    ];
    final toEnd = sched.arrival(dir, bus.tripStart, dir.stops.length - 1) - now;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rest.isNotEmpty) ...[
          Text(
            tr('further').toUpperCase(),
            style: const TextStyle(
              color: D.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          for (final k in rest)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: dir.route.color, width: 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dir.stops[k].name.of(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    fmtClock(sched.arrival(dir, bus.tripStart, k)),
                    style: const TextStyle(
                      color: D.ink2,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: D.line),
          const SizedBox(height: 14),
        ],
        Text(
          tr('toEnd').toUpperCase(),
          style: const TextStyle(
            color: D.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${dir.terminus.name.of(lang)} · ${fmtMin(toEnd.clamp(0, 999).toDouble())}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: C.amber,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: D.bg, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: D.bg,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _box({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: D.panel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: D.line),
    ),
    child: child,
  );
}

/// The whole line as a strip: passed stops dim, names slanted like on
/// metro maps, transfer badges under each stop, the bus between stops.
class _LinePainter extends CustomPainter {
  _LinePainter(this.net, this.dir, this.f, this.lang);
  final Network net;
  final RouteDir dir;
  final double f; // stop index + fraction to the next one
  final String lang;

  @override
  void paint(Canvas c, Size s) {
    final n = dir.stops.length;
    final y = s.height * 0.62;
    final x0 = 10.0, x1 = s.width - 110; // room for the slanted last name
    double xAt(double i) => x0 + (x1 - x0) * i / (n - 1);
    final col = dir.route.color;
    Paint line(Color c) => Paint()
      ..color = c
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x0, y), Offset(xAt(f), y), line(D.line));
    c.drawLine(Offset(xAt(f), y), Offset(x1, y), line(col));

    for (var i = 0; i < n; i++) {
      final st = dir.stops[i];
      final x = xAt(i.toDouble());
      final passed = i < f - 0.001;
      final end = i == 0 || i == n - 1;
      c.drawCircle(Offset(x, y), end ? 10 : 8, Paint()..color = D.panel);
      c.drawCircle(
        Offset(x, y),
        end ? 10 : 8,
        Paint()
          ..color = passed ? D.line : col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      // name, slanted
      final tp = TextPainter(
        text: TextSpan(
          text: st.name.of(lang),
          style: TextStyle(
            fontFamily: 'Inter',
            color: passed ? D.ink2.withValues(alpha: 0.6) : Colors.white,
            fontSize: 13.5,
            fontWeight: passed ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 150);
      c.save();
      c.translate(x - 2, y - 18);
      c.rotate(-0.6);
      tp.paint(c, Offset(0, -tp.height / 2));
      c.restore();
      // transfer badges
      var bx = x - (st.routeIds.length - 2) * 10.0;
      for (final id in st.routeIds) {
        if (id == dir.route.id) continue;
        final r = net.route(id);
        final o = Offset(bx, y + 26);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: o, width: 18, height: 18),
            const Radius.circular(6),
          ),
          Paint()..color = passed ? r.color.withValues(alpha: 0.35) : r.color,
        );
        final t = TextPainter(
          text: TextSpan(
            text: id,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        t.paint(c, o - Offset(t.width / 2, t.height / 2));
        bx += 20;
      }
    }
    // the bus
    final bx = xAt(f);
    c.drawCircle(
      Offset(bx, y),
      17,
      Paint()..color = col.withValues(alpha: 0.3),
    );
    c.drawCircle(Offset(bx, y), 13, Paint()..color = Colors.white);
    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
        style: TextStyle(
          fontFamily: Icons.directions_bus_rounded.fontFamily,
          package: Icons.directions_bus_rounded.fontPackage,
          fontSize: 18,
          color: col,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icon.paint(c, Offset(bx - icon.width / 2, y - icon.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LinePainter o) =>
      o.f != f || o.dir != dir || o.lang != lang;
}
