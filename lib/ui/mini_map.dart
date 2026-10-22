import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/network.dart';
import '../data/schedule.dart';

/// A light-weight schematic map drawn from the network data: route shapes,
/// stops, buses, a "you are here" dot. No tiles, so it works offline on a
/// bus-stop screen and inside lists.
class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.net,
    required this.focus,
    this.routes,
    this.paths = const [],
    this.buses = const [],
    this.here,
    this.hereLabel,
    this.pulse = 0,
    this.dark = false,
    this.labels = const [],
  });
  final Network net;

  /// Points that must be visible (the camera fits them).
  final List<Geo> focus;

  /// Routes drawn in colour; others are faint. Null = all in colour.
  final Set<String>? routes;

  /// Dashed approximate paths (community routes).
  final List<(List<Geo>, Color)> paths;
  final List<BusPos> buses;
  final Geo? here;
  final String? hereLabel;
  final double pulse;
  final bool dark;
  final List<(Geo, String)> labels;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _MiniMapPainter(this), size: Size.infinite);
}

class _MiniMapPainter extends CustomPainter {
  _MiniMapPainter(this.m);
  final MiniMap m;

  late double _k, _lat0, _lon0, _cos, _ox, _oy;

  Offset _p(Geo g) =>
      Offset(_ox + (g.lon - _lon0) * _cos * _k, _oy - (g.lat - _lat0) * _k);

  void _fit(Size s) {
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final g in m.focus) {
      minLat = math.min(minLat, g.lat);
      maxLat = math.max(maxLat, g.lat);
      minLon = math.min(minLon, g.lon);
      maxLon = math.max(maxLon, g.lon);
    }
    _lat0 = (minLat + maxLat) / 2;
    _lon0 = (minLon + maxLon) / 2;
    _cos = math.cos(_lat0 * math.pi / 180);
    final w = math.max((maxLon - minLon) * _cos, 0.004);
    final h = math.max(maxLat - minLat, 0.004);
    const pad = 34.0;
    _k = math.min((s.width - 2 * pad) / w, (s.height - 2 * pad) / h);
    _ox = s.width / 2;
    _oy = s.height / 2;
  }

  Path _line(List<Geo> pts) {
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = _p(pts[i]);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  @override
  void paint(Canvas c, Size s) {
    if (m.focus.isEmpty) return;
    _fit(s);
    final bg = m.dark ? const Color(0xFF151A22) : const Color(0xFFF4F6FA);
    final faint = m.dark ? Colors.white10 : const Color(0x14000000);
    c.clipRect(Offset.zero & s);
    c.drawRect(Offset.zero & s, Paint()..color = bg);

    // dot grid, every ~400 m
    final step = math.max(400 / 111000 * _k, 14.0);
    final dot = Paint()
      ..color = m.dark ? Colors.white10 : const Color(0x12000000);
    for (var x = (s.width / 2) % step; x < s.width; x += step) {
      for (var y = (s.height / 2) % step; y < s.height; y += step) {
        c.drawCircle(Offset(x, y), 1, dot);
      }
    }

    Paint stroke(Color col, double w) => Paint()
      ..color = col
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hi = [
      for (final r in m.net.routes)
        if (m.routes == null || m.routes!.contains(r.id)) r,
    ];
    for (final r in m.net.routes) {
      if (!hi.contains(r)) c.drawPath(_line(r.shape), stroke(faint, 3));
    }
    for (final r in hi) {
      c.drawPath(_line(r.shape), stroke(bg, 8));
    }
    for (final r in hi) {
      c.drawPath(_line(r.shape), stroke(r.color, 4.5));
    }
    for (final r in hi) {
      for (final st in r.dirs.first.stops) {
        final o = _p(st.pos);
        c.drawCircle(o, 4, Paint()..color = bg);
        c.drawCircle(o, 4, stroke(r.color, 2.2));
      }
    }

    // community routes: dashed, they are approximate
    for (final (pts, col) in m.paths) {
      if (pts.length < 2) continue;
      final path = _line(pts);
      c.drawPath(path, stroke(bg, 8));
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 13) {
          c.drawPath(metric.extractPath(d, d + 7), stroke(col, 4.5));
        }
      }
      for (final g in [pts.first, pts.last]) {
        c.drawCircle(_p(g), 6, Paint()..color = col);
        c.drawCircle(_p(g), 2.5, Paint()..color = Colors.white);
      }
    }

    for (final b in m.buses) {
      final o = _p(b.point.$1);
      c.drawCircle(o, 8, Paint()..color = bg);
      c.drawCircle(o, 6, Paint()..color = b.dir.route.color);
      c.drawCircle(o, 2.2, Paint()..color = Colors.white);
    }

    for (final (g, t) in m.labels) {
      _text(c, s, t, _p(g), 9, 12, FontWeight.w700);
    }

    if (m.here != null) {
      final o = _p(m.here!);
      c.drawCircle(
        o,
        10 + 18 * m.pulse,
        Paint()..color = C.blue.withValues(alpha: 0.35 * (1 - m.pulse)),
      );
      c.drawCircle(o, 10, Paint()..color = Colors.white);
      c.drawCircle(o, 7, Paint()..color = C.blue);
      if (m.hereLabel != null) {
        _text(c, s, m.hereLabel!, o, 15, 13, FontWeight.w800);
      }
    }
  }

  /// Label to the right of [p], or to the left when it would leave the map.
  void _text(
    Canvas c,
    Size s,
    String t,
    Offset p,
    double dx,
    double size,
    FontWeight w,
  ) {
    final halo = m.dark ? const Color(0xFF151A22) : Colors.white;
    TextPainter layout(Paint paint) => TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          fontWeight: w,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fg = layout(Paint()..color = m.dark ? Colors.white : C.ink);
    final bgText = layout(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = halo,
    );
    var x = p.dx + dx;
    if (x + fg.width > s.width - 6) x = p.dx - dx - fg.width;
    final at = Offset(x, p.dy - fg.height / 2);
    bgText.paint(c, at);
    fg.paint(c, at);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter o) => true;
}

/// Amber "namuna / пример / sample" pill — every invented number wears one.
class DemoTag extends StatelessWidget {
  const DemoTag(this.text, {super.key, this.dark = false});
  final String text;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: dark ? const Color(0x33F5A524) : const Color(0xFFFFF3DC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.science_rounded,
          size: 13,
          color: dark ? C.amber : const Color(0xFFB7791F),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: dark ? C.amber : const Color(0xFFB7791F),
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

/// Endless right-to-left news line, like on real stop displays.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;
  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final w = tp.width + 80;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, _) => LayoutBuilder(
          builder: (_, box) {
            final x = box.maxWidth - (box.maxWidth + w) * _a.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      widget.text,
                      style: widget.style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
