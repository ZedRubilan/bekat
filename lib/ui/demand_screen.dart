import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/demo_data.dart';
import '../data/network.dart';
import 'map_style.dart';
import 'map_view.dart' show ll;
import 'mini_map.dart';
import 'widgets.dart';

/// What the city would get from Bekat: where people want to go, where no
/// bus takes them, when they travel. City-wide numbers are samples; the
/// "on this device" card counts real searches made on this phone.
class DemandScreen extends StatefulWidget {
  const DemandScreen({super.key, required this.app, this.kiosk = false});
  final AppState app;
  final bool kiosk;
  @override
  State<DemandScreen> createState() => _DemandScreenState();
}

class _DemandScreenState extends State<DemandScreen> {
  int _period = 2; // 0 week, 1 month, 2 year
  bool _gapOnly = false;
  MapLibreMapController? _c;
  bool _ready = false;
  late final _points = heatPoints(widget.app.net);

  AppState get app => widget.app;
  double get _f => const [7 / 365, 30 / 365, 1.0][_period];

  Map<String, dynamic> _fc(Iterable<(Geo, double)> pts) => {
    'type': 'FeatureCollection',
    'features': [
      for (final (g, w) in pts)
        {
          'type': 'Feature',
          'properties': {'w': w},
          'geometry': {'type': 'Point', 'coordinates': g.lonLat},
        },
    ],
  };

  Future<void> _onStyle() async {
    final c = _c!;
    await c.addGeoJsonSource(
      'heat-all',
      _fc([for (final (g, w, _) in _points) (g, w)]),
    );
    await c.addGeoJsonSource(
      'heat-gap',
      _fc([
        for (final (g, w, gap) in _points)
          if (gap) (g, w),
        for (final g in app.noBus) (g, 1.0),
      ]),
    );
    await c.addGeoJsonSource('spots', {
      'type': 'FeatureCollection',
      'features': [
        for (var i = 0; i < hotspots.length; i++)
          {
            'type': 'Feature',
            'properties': {'n': '${i + 1}'},
            'geometry': {
              'type': 'Point',
              'coordinates': hotspots[i].pos.lonLat,
            },
          },
      ],
    });
    // one hue per layer, light → dark (magnitude)
    await c.addLayer(
      'heat-all',
      'heat-all',
      const HeatmapLayerProperties(
        heatmapWeight: ['get', 'w'],
        heatmapRadius: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          14,
          15,
          40,
        ],
        heatmapIntensity: 0.9,
        heatmapOpacity: 0.75,
        heatmapColor: [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'rgba(45,107,240,0)',
          0.25,
          'rgba(147,180,248,0.55)',
          0.55,
          '#5B8DF5',
          0.85,
          '#2D6BF0',
          1,
          '#1E3A8A',
        ],
      ),
      belowLayerId: 'stop-dot',
    );
    await c.addLayer(
      'heat-gap',
      'heat-gap',
      const HeatmapLayerProperties(
        heatmapWeight: ['get', 'w'],
        heatmapRadius: [
          'interpolate',
          ['linear'],
          ['zoom'],
          11,
          18,
          15,
          52,
        ],
        heatmapIntensity: 1.1,
        heatmapOpacity: 0.85,
        heatmapColor: [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'rgba(242,102,94,0)',
          0.2,
          'rgba(250,170,160,0.6)',
          0.5,
          '#F2665E',
          0.8,
          '#DC2626',
          1,
          '#991B1B',
        ],
      ),
      belowLayerId: 'stop-dot',
    );
    await c.addLayer(
      'spots',
      'spot-dot',
      const CircleLayerProperties(
        circleRadius: 11,
        circleColor: '#15171C',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
      ),
    );
    await c.addLayer(
      'spots',
      'spot-n',
      const SymbolLayerProperties(
        textField: ['get', 'n'],
        textFont: ['Noto Sans Bold'],
        textSize: 12,
        textColor: '#FFFFFF',
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );
    _ready = true;
    _applyToggle();
  }

  void _applyToggle() {
    if (!_ready) return;
    _c?.setLayerVisibility('heat-all', !_gapOnly);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= 1000;
    final st = DemandStats.year.scaled(_f);
    final map = _mapCard(wide);
    final side = <Widget>[
      _kpis(st, wide ? 4 : 2),
      const SizedBox(height: 14),
      _hotspotsCard(),
      const SizedBox(height: 14),
      _HourlyCard(searches: st.searches),
      const SizedBox(height: 14),
      _pairsCard(),
      const SizedBox(height: 14),
      _recoCard(),
      const SizedBox(height: 14),
      _deviceCard(),
    ];
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: C.bg,
          body: SafeArea(
            child: wide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Column(
                      children: [
                        _header(true),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 11, child: map),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 9,
                                child: ListView(children: side),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _header(false),
                      const SizedBox(height: 14),
                      SizedBox(height: 380, child: map),
                      const SizedBox(height: 14),
                      ...side,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr('demandFor').toUpperCase(),
              style: T.cap.copyWith(letterSpacing: 1.2, color: C.blue),
            ),
            DemoTag(tr('demoData')),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          tr('demandTitle'),
          style: wide ? T.display : T.title.copyWith(fontSize: 26),
        ),
      ],
    );
    final period = SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 0, label: Text(tr('week'))),
        ButtonSegment(value: 1, label: Text(tr('month'))),
        ButtonSegment(value: 2, label: Text(tr('year'))),
      ],
      selected: {_period},
      showSelectedIcon: false,
      onSelectionChanged: (s) => setState(() => _period = s.first),
    );
    final back = widget.kiosk
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(right: 14),
            child: RoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          );
    if (wide) {
      return Row(
        children: [
          back,
          Expanded(child: title),
          period,
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download_rounded),
            label: Text(tr('report')),
            style: FilledButton.styleFrom(
              backgroundColor: C.night,
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            back,
            Expanded(child: title),
          ],
        ),
        const SizedBox(height: 12),
        period,
      ],
    );
  }

  void _export() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(tr('reportSoon')),
      behavior: SnackBarBehavior.floating,
    ),
  );

  Widget _card({required Widget child, Color? color, EdgeInsets? padding}) =>
      Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(R.l),
          boxShadow: softShadow(0.06),
        ),
        child: child,
      );

  Widget _mapCard(bool wide) => ClipRRect(
    borderRadius: BorderRadius.circular(R.l),
    child: Stack(
      children: [
        Positioned.fill(
          child: MapLibreMap(
            styleString: buildStyle(app.net, Lang.i.code),
            initialCameraPosition: CameraPosition(
              target: ll(const Geo(41.006, 71.632)),
              zoom: wide ? 11.85 : 10.9,
              tilt: 0,
            ),
            onMapCreated: (c) => _c = c,
            onStyleLoadedCallback: _onStyle,
            compassEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            minMaxZoomPreference: const MinMaxZoomPreference(10.5, 16),
            webPreserveDrawingBuffer: true,
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: PointerInterceptor(
            child: Guarded(
              child: Row(
                children: [
                  _toggle(false, tr('allSearches'), C.blue),
                  const SizedBox(width: 8),
                  _toggle(true, tr('noBusThere'), C.coral),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 36,
          child: PointerInterceptor(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: softShadow(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('searchDensity'),
                    style: T.cap.copyWith(color: C.ink2),
                  ),
                  const SizedBox(height: 6),
                  if (!_gapOnly)
                    _ramp(const [
                      Color(0x332D6BF0),
                      Color(0xFF5B8DF5),
                      Color(0xFF1E3A8A),
                    ]),
                  if (!_gapOnly) const SizedBox(height: 4),
                  _ramp(const [
                    Color(0x40F2665E),
                    Color(0xFFF2665E),
                    Color(0xFF991B1B),
                  ]),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: [
                        Text(tr('low'), style: T.cap),
                        const Spacer(),
                        Text(tr('high'), style: T.cap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ramp(List<Color> cs) => Container(
    width: 150,
    height: 8,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      gradient: LinearGradient(colors: cs),
    ),
  );

  Widget _toggle(bool gap, String label, Color col) {
    final on = _gapOnly == gap;
    return Press(
      onTap: () {
        setState(() => _gapOnly = gap);
        _applyToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? C.night : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: col, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: T.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: on ? Colors.white : C.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpis(DemandStats st, int perRow) {
    final tiles = [
      (
        Icons.search_rounded,
        tr('kpiSearches'),
        fmtInt(st.searches),
        C.blue,
        '',
      ),
      (Icons.people_alt_rounded, tr('kpiUsers'), fmtInt(st.users), C.green, ''),
      (
        Icons.wrong_location_rounded,
        tr('kpiNoBus'),
        '${(st.noBusShare * 100).toStringAsFixed(1)}%',
        C.coral,
        '${fmtInt((st.searches * st.noBusShare).round())} ${tr('searchesWord')}',
      ),
      (
        Icons.add_road_rounded,
        tr('kpiIdeas'),
        fmtInt(st.ideas),
        const Color(0xFF8B5CF6),
        '',
      ),
    ];
    return LayoutBuilder(
      builder: (_, box) {
        const gap = 10.0;
        final tw = (box.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, label, value, col, sub) in tiles)
              SizedBox(
                width: tw,
                child: _card(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 17, color: col),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              style: T.cap.copyWith(color: C.ink2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: T.metric.copyWith(fontSize: 26, color: C.ink),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub.isEmpty ? tr('periodWord$_period') : sub,
                        style: T.cap,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _title(String t, [String? sub]) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: T.h),
        if (sub != null) Text(sub, style: T.sub.copyWith(fontSize: 13)),
      ],
    ),
  );

  Widget _hotspotsCard() {
    final lang = Lang.i.code;
    final top = hotspots.first.perYear;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(tr('hotspotsTitle'), tr('hotspotsSub')),
          for (var i = 0; i < hotspots.length; i++)
            Builder(
              builder: (_) {
                final h = hotspots[i];
                final (stop, d) = app.net.nearestStop(h.pos);
                final v = (h.perYear * _f).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: C.night,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    h.name.of(lang),
                                    style: T.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  fmtInt(v),
                                  style: T.body.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: h.perYear / top,
                                minHeight: 7,
                                color: C.coral,
                                backgroundColor: C.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tr('nearestStop')}: ${stop.name.of(lang)} · ${fmtMeters(d)}',
                              style: T.cap,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _pairsCard() {
    final lang = Lang.i.code;
    final net = app.net;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(tr('pairsTitle')),
          for (final (a, b, n) in topPairs)
            Builder(
              builder: (_) {
                final sa = net.stops[a]!, sb = net.stops[b]!;
                final direct = [
                  for (final id in sa.routeIds)
                    if (sb.routeIds.contains(id)) net.route(id),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sa.name.of(lang)} → ${sb.name.of(lang)}',
                          style: T.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (direct.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr('withTransfer'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: C.coral,
                            ),
                          ),
                        )
                      else
                        for (final r in direct)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: RouteBadge(r, size: 22),
                          ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64,
                        child: Text(
                          fmtInt((n * _f).round()),
                          textAlign: TextAlign.right,
                          style: T.body.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _recoCard() {
    final lang = Lang.i.code;
    final h = hotspots.first;
    final (stop, d) = app.net.nearestStop(h.pos);
    final items = [
      (
        Icons.add_location_alt_rounded,
        tr('reco1')
            .replaceAll('{p}', h.name.of(lang))
            .replaceAll('{s}', stop.name.of(lang))
            .replaceAll('{d}', fmtMeters(d)),
      ),
      (Icons.speed_rounded, tr('reco2')),
      (Icons.airport_shuttle_rounded, tr('reco3')),
    ];
    return _card(
      color: C.night,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: C.amber, size: 20),
              const SizedBox(width: 8),
              Text(tr('recoTitle'), style: T.h.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _deviceCard() => _card(
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: C.blueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.smartphone_rounded, color: C.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('onDevice'), style: T.h),
              const SizedBox(height: 2),
              Text(
                tr('onDeviceText')
                    .replaceAll('{n}', '${app.searches}')
                    .replaceAll('{m}', '${app.noBus.length}'),
                style: T.sub.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(tr('privacy'), style: T.cap),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Searches by hour of day: one series, bars, peaks labelled, hover/tap
/// shows the value.
class _HourlyCard extends StatefulWidget {
  const _HourlyCard({required this.searches});
  final int searches;
  @override
  State<_HourlyCard> createState() => _HourlyCardState();
}

class _HourlyCardState extends State<_HourlyCard> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final peak = [for (var h = 0; h < 24; h++) h]
      ..sort((a, b) => hourly[b].compareTo(hourly[a]));
    final h = _hover;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.l),
        boxShadow: softShadow(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr('hourlyTitle'), style: T.h)),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: h == null ? 0 : 1,
                child: Text(
                  h == null
                      ? ''
                      : '${h.toString().padLeft(2, '0')}:00 · ${fmtInt((widget.searches * hourly[h]).round())}',
                  style: T.body.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Text(tr('hourlySub'), style: T.sub.copyWith(fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (_, box) {
                final bw = box.maxWidth / 24;
                int at(Offset p) => (p.dx / bw).floor().clamp(0, 23);
                return MouseRegion(
                  onHover: (e) => setState(() => _hover = at(e.localPosition)),
                  onExit: (_) => setState(() => _hover = null),
                  child: GestureDetector(
                    onTapDown: (e) =>
                        setState(() => _hover = at(e.localPosition)),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _BarsPainter(hourly, h, peak.take(2).toSet()),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.v, this.hover, this.peaks);
  final List<double> v;
  final int? hover;
  final Set<int> peaks;

  @override
  void paint(Canvas c, Size s) {
    const axis = 18.0, top = 18.0;
    final h = s.height - axis - top;
    final mx = v.reduce(math.max);
    final bw = s.width / v.length;
    // recessive baseline
    c.drawLine(
      Offset(0, top + h),
      Offset(s.width, top + h),
      Paint()
        ..color = C.line
        ..strokeWidth = 1,
    );
    for (var i = 0; i < v.length; i++) {
      final bh = math.max(2.0, h * v[i] / mx);
      final r = Rect.fromLTWH(i * bw + 1, top + h - bh, bw - 2, bh);
      c.drawRRect(
        RRect.fromRectAndCorners(
          r,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()
          ..color = hover == null || hover == i
              ? C.blue
              : C.blue.withValues(alpha: 0.35),
      );
      if (peaks.contains(i)) {
        _text(
          c,
          '${i.toString().padLeft(2, '0')}:00',
          Offset(r.center.dx, r.top - 3),
          C.ink,
          true,
        );
      }
      if (i % 6 == 0 || i == 23) {
        _text(c, '$i', Offset(r.center.dx, top + h + 15), C.ink3, false);
      }
    }
  }

  void _text(Canvas c, String t, Offset bottomCenter, Color col, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: col,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, bottomCenter - Offset(tp.width / 2, tp.height));
  }

  @override
  bool shouldRepaint(covariant _BarsPainter o) => o.hover != hover;
}
