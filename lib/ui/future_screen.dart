import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import 'bus_screen.dart';
import 'community_screen.dart';
import 'demand_screen.dart';
import 'mini_map.dart';
import 'stop_board.dart';
import 'widgets.dart';

Future<void> openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(
              begin: 0.97,
              end: 1.0,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );

/// "Bekat 2.0": the four ideas of the next stages, each as a working demo
/// on sample data, plus the road map.
class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key, required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final near = app.net.nearestStop(app.origin.pos).$1;
    final cards = [
      _Feature(
        icon: Icons.departure_board_rounded,
        colors: const [Color(0xFF0B0E13), Color(0xFF26303F)],
        accent: C.amber,
        title: tr('fBoard'),
        text: tr('fBoardText'),
        onTap: () => openPage(context, StopBoard(app: app, stop: near)),
        extra: tr('intercity'),
        onExtra: () => openPage(
          context,
          StopBoard(app: app, stop: app.net.stops['avtovokzal']!),
        ),
      ),
      _Feature(
        icon: Icons.directions_bus_rounded,
        colors: const [Color(0xFF14532D), Color(0xFF22A55B)],
        accent: const Color(0xFF7CE0A3),
        title: tr('fBus'),
        text: tr('fBusText'),
        onTap: () => openPage(context, BusScreen(app: app)),
      ),
      _Feature(
        icon: Icons.groups_rounded,
        colors: const [Color(0xFF0E7490), Color(0xFF0EA5A4)],
        accent: const Color(0xFFA5F3FC),
        title: tr('fCommunity'),
        text: tr('fCommunityText'),
        onTap: () => openPage(context, CommunityScreen(app: app)),
      ),
      _Feature(
        icon: Icons.insights_rounded,
        colors: const [Color(0xFF1E3A8A), Color(0xFF2D6BF0)],
        accent: const Color(0xFFBFD3FF),
        title: tr('fDemand'),
        text: tr('fDemandText'),
        onTap: () => openPage(context, DemandScreen(app: app)),
      ),
    ];
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: C.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 700 ? 2 : 1;
                    const gap = 12.0;
                    final cw = (box.maxWidth - 32 - gap * (cols - 1)) / cols;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Bekat', style: T.display),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(bottom: 3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: C.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '2.0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(tr('futureSub'), style: T.sub),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final c in cards)
                              SizedBox(width: cw, child: c),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(tr('roadmap'), style: T.title),
                        const SizedBox(height: 12),
                        const _Roadmap(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.colors,
    required this.accent,
    required this.title,
    required this.text,
    required this.onTap,
    this.extra,
    this.onExtra,
  });
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final String title, text;
  final VoidCallback onTap;
  final String? extra;
  final VoidCallback? onExtra;

  @override
  Widget build(BuildContext context) => Press(
    onTap: onTap,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.l),
        boxShadow: softShadow(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 118,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -16,
                  bottom: -26,
                  child: Icon(
                    icon,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.h.copyWith(fontSize: 19)),
                const SizedBox(height: 4),
                Text(text, style: T.sub.copyWith(height: 1.35)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      tr('open'),
                      style: T.body.copyWith(
                        color: C.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: C.blue,
                    ),
                    const Spacer(),
                    if (extra != null)
                      Press(
                        onTap: onExtra,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: C.muted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                size: 16,
                                color: C.ink2,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                extra!,
                                style: T.sub.copyWith(
                                  color: C.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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

class _Roadmap extends StatelessWidget {
  const _Roadmap();
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.check_rounded, 'rm0'),
      (Icons.satellite_alt_rounded, 'rm1'),
      (Icons.groups_rounded, 'rm2'),
      (Icons.sensors_rounded, 'rm3'),
      (Icons.public_rounded, 'rm4'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.l),
        boxShadow: softShadow(0.06),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: i == 0 ? C.green : C.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].$1,
                          size: 18,
                          color: i == 0 ? Colors.white : C.ink2,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: C.line,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tr('stage')} $i · ${tr('${steps[i].$2}t')}',
                            style: T.h.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('${steps[i].$2}d'),
                            style: T.sub.copyWith(fontSize: 13, height: 1.35),
                          ),
                        ],
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
}
