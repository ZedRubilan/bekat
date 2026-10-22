import 'dart:math' as math;

import 'network.dart';

/// Sample data for the "Bekat 2.0" concept screens (stop board, intercity
/// departures, community routes, demand analytics). Everything here is
/// invented for the demo and is always shown with a "namuna" label;
/// coordinates and distances are real, counts and timetables are not.

// ---------------------------------------------------------------------------
// Intercity departures from the Namangan bus station.

class Intercity {
  const Intercity(
    this.to,
    this.first,
    this.every,
    this.minutes,
    this.price,
    this.platform, {
    this.minibus = false,
  });
  final L3 to;

  /// First departure (minutes since midnight) and interval, minutes.
  final int first, every;

  /// Travel time, minutes.
  final int minutes;
  final int price;
  final int platform;
  final bool minibus;
}

const intercity = <Intercity>[
  Intercity(L3('Chust', 'Чуст', 'Chust'), 6 * 60, 25, 55, 12000, 3),
  Intercity(
    L3('Kosonsoy', 'Касансай', 'Kosonsoy'),
    6 * 60 + 10,
    30,
    45,
    10000,
    4,
  ),
  Intercity(L3('Pop', 'Пап', 'Pop'), 6 * 60 + 20, 40, 75, 15000, 2),
  Intercity(
    L3('Chortoq', 'Чартак', 'Chortoq'),
    6 * 60 + 5,
    20,
    35,
    8000,
    5,
    minibus: true,
  ),
  Intercity(
    L3('Uchqo‘rg‘on', 'Учкурган', 'Uchkurgan'),
    6 * 60 + 15,
    35,
    50,
    10000,
    1,
  ),
  Intercity(
    L3('To‘raqo‘rg‘on', 'Туракурган', 'Turakurgan'),
    6 * 60,
    15,
    30,
    7000,
    6,
    minibus: true,
  ),
  Intercity(
    L3('Uychi', 'Уйчи', 'Uychi'),
    6 * 60 + 25,
    30,
    35,
    8000,
    5,
    minibus: true,
  ),
  Intercity(L3('Toshkent', 'Ташкент', 'Tashkent'), 7 * 60, 120, 300, 120000, 7),
];

class Departure {
  Departure(this.line, this.at);
  final Intercity line;
  final double at;
}

/// The next [n] intercity departures after [now] (minutes since midnight).
List<Departure> nextDepartures(double now, {int n = 7}) {
  final out = <Departure>[];
  for (final l in intercity) {
    var t = l.first.toDouble();
    if (now - 3 > t) t += ((now - 3 - t) / l.every).ceil() * l.every;
    for (var k = 0; k < 3 && t < 22 * 60; k++, t += l.every) {
      out.add(Departure(l, t));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(n).toList();
}

// ---------------------------------------------------------------------------
// Community routes: damas, marshrutka, shared taxis that people add.

enum RideKind { damas, marshrutka, taxi }

enum Review { verified, review }

class CommunityRoute {
  CommunityRoute({
    required this.id,
    required this.kind,
    required this.number,
    required this.from,
    required this.to,
    required this.via,
    required this.price,
    required this.hours,
    required this.every,
    required this.confirms,
    required this.author,
    required this.status,
    required this.daysAgo,
    this.mine = false,
  });
  final String id;
  final RideKind kind;
  final String number;
  final L3 from, to;

  /// Stop ids along the way (first and last are the ends).
  final List<String> via;
  final int price;
  final String hours;
  final int every;
  int confirms;
  final String author;
  final Review status;
  final int daysAgo;
  final bool mine;

  List<Geo> path(Network net) => [
    for (final id in via)
      if (net.stops[id] != null) net.stops[id]!.pos,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'number': number,
    'from': [from.uz, from.ru, from.en],
    'to': [to.uz, to.ru, to.en],
    'via': via,
    'price': price,
    'hours': hours,
    'every': every,
    'confirms': confirms,
  };

  factory CommunityRoute.fromJson(Map<String, dynamic> j) => CommunityRoute(
    id: j['id'] as String,
    kind: RideKind.values.byName(j['kind'] as String),
    number: j['number'] as String,
    from: _l3(j['from'] as List),
    to: _l3(j['to'] as List),
    via: (j['via'] as List).cast<String>(),
    price: j['price'] as int,
    hours: j['hours'] as String,
    every: j['every'] as int,
    confirms: j['confirms'] as int,
    author: '',
    status: Review.review,
    daysAgo: 0,
    mine: true,
  );
}

L3 _l3(List l) => L3(l[0] as String, l[1] as String, l[2] as String);

List<CommunityRoute> sampleCommunity() => [
  CommunityRoute(
    id: 'c1',
    kind: RideKind.damas,
    number: '',
    from: L3('G‘uzal', 'Гузал', 'Guzal'),
    to: L3('Chorsu', 'Чорсу', 'Chorsu'),
    via: ['bolalar', 'nanay', 'chorsu'],
    price: 3000,
    hours: '06:30–20:00',
    every: 5,
    confirms: 128,
    author: 'Akmal T.',
    status: Review.verified,
    daysAgo: 12,
  ),
  CommunityRoute(
    id: 'c2',
    kind: RideKind.marshrutka,
    number: '12',
    from: L3('Yangi Namangan', 'Янги Наманган', 'Yangi Namangan'),
    to: L3('Chorsu', 'Чорсу', 'Chorsu'),
    via: ['yangi_nam', 'oromgoh', 'xorazm', 'bolalar', 'nanay', 'chorsu'],
    price: 3000,
    hours: '06:00–21:00',
    every: 8,
    confirms: 96,
    author: 'Dilnoza R.',
    status: Review.verified,
    daysAgo: 20,
  ),
  CommunityRoute(
    id: 'c3',
    kind: RideKind.damas,
    number: '',
    from: L3('Lola bozori', 'Рынок Лола', 'Lola bazaar'),
    to: L3('Taxtako‘prik', 'Тахтакуприк', 'Takhtakuprik'),
    via: ['lola', 'namdu', 'uychi', 'taxtakoprik'],
    price: 3000,
    hours: '07:00–19:00',
    every: 7,
    confirms: 71,
    author: 'Sherzod M.',
    status: Review.verified,
    daysAgo: 6,
  ),
  CommunityRoute(
    id: 'c4',
    kind: RideKind.marshrutka,
    number: '30',
    from: L3('Otchopar', 'Отчопар', 'Otchopar'),
    to: L3('Sardoba bozori', 'Рынок Сардоба', 'Sardoba bazaar'),
    via: ['otchopar', 'diyor', 'vokzal', 'kardio', 'sardoba'],
    price: 3000,
    hours: '06:30–20:30',
    every: 10,
    confirms: 54,
    author: 'Bekzod A.',
    status: Review.verified,
    daysAgo: 31,
  ),
  CommunityRoute(
    id: 'c5',
    kind: RideKind.taxi,
    number: '',
    from: L3('Uychi ko‘chasi', 'Улица Уйчи', 'Uychi street'),
    to: L3('Temir yo‘l vokzali', 'Ж/д вокзал', 'Railway station'),
    via: ['uychi', 'chorsu', 'hokimlik', 'kichkintoy', 'vokzal'],
    price: 5000,
    hours: '07:00–22:00',
    every: 4,
    confirms: 33,
    author: 'Nodira K.',
    status: Review.review,
    daysAgo: 3,
  ),
  CommunityRoute(
    id: 'c6',
    kind: RideKind.damas,
    number: '',
    from: L3('Aeroport', 'Аэропорт', 'Airport'),
    to: L3('Yashil bozor', 'Зелёный базар', 'Green bazaar'),
    via: ['aeroport', 'toqimachi', 'yashil'],
    price: 3000,
    hours: '07:00–18:00',
    every: 15,
    confirms: 9,
    author: 'Jasur O.',
    status: Review.review,
    daysAgo: 1,
  ),
];

// ---------------------------------------------------------------------------
// Demand analytics (what a city dashboard would show after a year).

/// A place people search for where no bus stop is near. The location is a
/// real point from OpenStreetMap; [perYear] is a sample number.
class Hotspot {
  const Hotspot(this.name, this.pos, this.perYear);
  final L3 name;
  final Geo pos;
  final int perYear;
}

const hotspots = <Hotspot>[
  Hotspot(
    L3(
      'Suv xo‘jaligi shifoxonasi',
      'Больница водного хозяйства',
      'Water board hospital',
    ),
    Geo(41.04163, 71.66752),
    48200,
  ),
  Hotspot(
    L3(
      'Yangi O‘zbekiston bog‘i',
      'Парк Новый Узбекистан',
      'New Uzbekistan park',
    ),
    Geo(41.00238, 71.56127),
    41700,
  ),
  Hotspot(
    L3(
      'Biznes va fan universiteti',
      'Университет бизнеса и науки',
      'University of Business and Science',
    ),
    Geo(40.96531, 71.69618),
    36900,
  ),
  Hotspot(
    L3('5-son texnikum', 'Техникум №5', 'Technical college No. 5'),
    Geo(40.96475, 71.66407),
    29300,
  ),
  Hotspot(
    L3('Rovuston bekati', 'Станция Раустан', 'Rovuston station'),
    Geo(40.98054, 71.58838),
    23800,
  ),
  Hotspot(
    L3(
      'Bolalar fizioterapiya markazi',
      'Центр детской физиотерапии',
      'Children’s physiotherapy centre',
    ),
    Geo(40.97959, 71.65042),
    17400,
  ),
  Hotspot(
    L3(
      'Pedagogika kolleji',
      'Педагогический колледж',
      'Teacher training college',
    ),
    Geo(40.99468, 71.70276),
    14100,
  ),
];

/// Most searched origin → destination pairs (stop ids, searches per year).
const topPairs = <(String, String, int)>[
  ('otchopar', 'chorsu', 64120),
  ('yuksalish', 'chorsu', 51870),
  ('namdtu_r', 'yangibozor', 38450),
  ('vokzal', 'namdu', 33210),
  ('avtovokzal', 'taxtakoprik', 27960),
];

/// Share of searches by hour of day (sums to ~1), morning and evening peaks.
final List<double> hourly = () {
  double bump(double h, double mu, double s) =>
      math.exp(-math.pow(h - mu, 2) / (2 * s * s));
  final raw = [
    for (var h = 0; h < 24; h++)
      h < 5
          ? 0.004
          : 0.02 +
                bump(h + .0, 8, 1.2) +
                0.5 * bump(h + .0, 13, 1.5) +
                0.85 * bump(h + .0, 18, 1.4),
  ];
  final sum = raw.fold(0.0, (a, b) => a + b);
  return [for (final v in raw) v / sum];
}();

/// Headline numbers for one year; shorter periods scale down.
class DemandStats {
  const DemandStats(this.searches, this.users, this.noBusShare, this.ideas);
  final int searches, users;
  final double noBusShare;
  final int ideas;

  static const year = DemandStats(1284560, 86400, 0.182, 342);

  DemandStats scaled(double f) => DemandStats(
    (searches * f).round(),
    (users * math.pow(f, 0.55)).round(),
    noBusShare,
    (ideas * math.pow(f, 0.7)).round(),
  );
}

/// Weighted points for the heatmap: unmet demand gathers around [hotspots],
/// served demand around stops (busier the more routes meet there).
/// Seeded, so every screenshot looks the same.
List<(Geo, double, bool)> heatPoints(Network net) {
  final rnd = math.Random(7);
  double g() {
    // Box–Muller
    final u = 1 - rnd.nextDouble(), v = rnd.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  final out = <(Geo, double, bool)>[];
  const m = 1 / 111000.0; // degrees per metre (latitude)
  for (final h in hotspots) {
    final n = (h.perYear / 1200).round();
    for (var i = 0; i < n; i++) {
      out.add((
        Geo(h.pos.lat + g() * 260 * m, h.pos.lon + g() * 340 * m),
        0.6 + rnd.nextDouble() * 0.4,
        true,
      ));
    }
  }
  for (final s in net.stops.values) {
    final n = 6 + s.routeIds.length * 9;
    for (var i = 0; i < n; i++) {
      out.add((
        Geo(s.pos.lat + g() * 180 * m, s.pos.lon + g() * 230 * m),
        0.3 + rnd.nextDouble() * 0.5,
        false,
      ));
    }
  }
  return out;
}

/// Groups digits: 1284560 → "1 284 560".
String fmtInt(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}
