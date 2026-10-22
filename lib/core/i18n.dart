import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny trilingual dictionary. Text in Bekat is deliberately short.
class Lang extends ChangeNotifier {
  Lang._();
  static final Lang i = Lang._();

  String code = 'uz';
  static const codes = ['uz', 'ru', 'en'];
  static const labels = {'uz': 'O‘zbekcha', 'ru': 'Русский', 'en': 'English'};

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      code = p.getString('lang') ?? 'uz';
    } catch (_) {}
  }

  Future<void> set(String c) async {
    code = c;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString('lang', c);
    } catch (_) {}
  }

  String t(String key) => (_s[key] ?? const {})[code] ?? _s[key]?['uz'] ?? key;
}

String tr(String key) => Lang.i.t(key);

/// Formats minutes as '12 daq' / '1 soat 5 daq'.
String fmtMin(double m) {
  final v = m.round().clamp(0, 9999);
  if (v < 60) return '$v ${tr('min')}';
  return '${v ~/ 60} ${tr('hour')} ${v % 60} ${tr('min')}';
}

String fmtClock(double minutes) {
  final m = minutes.round() % (24 * 60);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

const _days = {
  'uz': [
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ],
  'ru': [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ],
  'en': [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ],
};
const _months = {
  'uz': [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ],
  'ru': [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ],
  'en': [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
};

/// 'Payshanba, 22 oktabr' / 'четверг, 22 октября' / 'Thursday, 22 October'.
String fmtDate(DateTime d) {
  final c = Lang.i.code;
  return '${_days[c]![d.weekday - 1]}, ${d.day} ${_months[c]![d.month - 1]}';
}

String fmtMeters(double m) => m < 1000
    ? '${(m / 10).round() * 10} m'
    : '${(m / 1000).toStringAsFixed(1)} km';

const _s = <String, Map<String, String>>{
  'whereTo': {'uz': 'Qayerga borasiz?', 'ru': 'Куда едем?', 'en': 'Where to?'},
  'from': {'uz': 'Qayerdan', 'ru': 'Откуда', 'en': 'From'},
  'to': {'uz': 'Qayerga', 'ru': 'Куда', 'en': 'To'},
  'myPlace': {'uz': 'Men turgan joy', 'ru': 'Моё место', 'en': 'My location'},
  'pinned': {
    'uz': 'Xaritadagi nuqta',
    'ru': 'Точка на карте',
    'en': 'Point on map',
  },
  'min': {'uz': 'daq', 'ru': 'мин', 'en': 'min'},
  'hour': {'uz': 'soat', 'ru': 'ч', 'en': 'h'},
  'go': {'uz': 'Yo‘lga', 'ru': 'Поехали', 'en': 'Go'},
  'walk': {'uz': 'Piyoda', 'ru': 'Пешком', 'en': 'Walk'},
  'transfer': {'uz': 'almashinuv', 'ru': 'пересадка', 'en': 'transfer'},
  'transfers': {'uz': 'almashinuv', 'ru': 'пересадки', 'en': 'transfers'},
  'direct': {'uz': 'To‘g‘ridan-to‘g‘ri', 'ru': 'Без пересадок', 'en': 'Direct'},
  'busIn': {'uz': 'Avtobus', 'ru': 'Автобус через', 'en': 'Bus in'},
  'stopsLeft': {
    'uz': 'Bekat qoldi',
    'ru': 'Осталось остановок',
    'en': 'Stops left',
  },
  'timeLeft': {'uz': 'Yetib borish', 'ru': 'В пути', 'en': 'Time left'},
  'arrive': {'uz': 'Yetib borasiz', 'ru': 'Прибытие', 'en': 'Arrive'},
  'board': {'uz': 'Chiqing', 'ru': 'Садитесь', 'en': 'Board'},
  'alight': {'uz': 'Tushing', 'ru': 'Выходите', 'en': 'Get off'},
  'change': {'uz': 'Almashing', 'ru': 'Пересадка', 'en': 'Change'},
  'stops': {'uz': 'bekat', 'ru': 'ост.', 'en': 'stops'},
  'toward': {'uz': 'tomon', 'ru': 'в сторону', 'en': 'towards'},
  'closest': {
    'uz': 'Manzilga avtobus bormaydi — eng yaqin yo‘l',
    'ru': 'Автобус не доходит — ближайший путь',
    'en': 'No bus goes there — closest way',
  },
  'leftOnFoot': {
    'uz': 'qolgani piyoda',
    'ru': 'остаток пешком',
    'en': 'rest on foot',
  },
  'noRoute': {
    'uz': 'Yo‘l topilmadi',
    'ru': 'Маршрут не найден',
    'en': 'No route found',
  },
  'scheme': {'uz': 'Sxema', 'ru': 'Схема', 'en': 'Lines'},
  'map': {'uz': 'Xarita', 'ru': 'Карта', 'en': 'Map'},
  'nearby': {'uz': 'Yaqin bekat', 'ru': 'Рядом', 'en': 'Nearby'},
  'next': {'uz': 'Keyingi', 'ru': 'Ближайшие', 'en': 'Next'},
  'now': {'uz': 'hozir', 'ru': 'сейчас', 'en': 'now'},
  'demo': {'uz': 'namuna', 'ru': 'пример', 'en': 'sample'},
  'search': {
    'uz': 'Joy yoki bekat',
    'ru': 'Место или остановка',
    'en': 'Place or stop',
  },
  'tapMap': {
    'uz': 'yoki xaritaga bosing',
    'ru': 'или нажмите на карту',
    'en': 'or tap the map',
  },
  'fromHere': {'uz': 'Shu yerdan', 'ru': 'Отсюда', 'en': 'From here'},
  'toHere': {'uz': 'Shu yerga', 'ru': 'Сюда', 'en': 'To here'},
  'lines': {'uz': 'Yo‘nalishlar', 'ru': 'Маршруты', 'en': 'Routes'},
  'settings': {'uz': 'Sozlamalar', 'ru': 'Настройки', 'en': 'Settings'},
  'language': {'uz': 'Til', 'ru': 'Язык', 'en': 'Language'},
  'bigText': {'uz': 'Yirik yozuv', 'ru': 'Крупный текст', 'en': 'Large text'},
  'flatMap': {
    'uz': 'Xarita tepadan (2D)',
    'ru': 'Карта сверху (2D)',
    'en': 'Top-down map (2D)',
  },
  'flatMapSub': {
    'uz': 'Sekin telefonlarda tezroq',
    'ru': 'Быстрее на слабых телефонах',
    'en': 'Faster on low-end phones',
  },
  'about': {'uz': 'Ilova haqida', 'ru': 'О приложении', 'en': 'About'},
  'end': {'uz': 'Tugatish', 'ru': 'Завершить', 'en': 'End'},
  'onBus': {'uz': 'Avtobusdasiz', 'ru': 'Вы в автобусе', 'en': 'On the bus'},
  'waiting': {
    'uz': 'Bekatga boring',
    'ru': 'Идите к остановке',
    'en': 'Walk to the stop',
  },
  'arrived': {
    'uz': 'Yetib keldingiz!',
    'ru': 'Вы на месте!',
    'en': 'You have arrived!',
  },
  'busArrives': {
    'uz': 'Avtobus keladi',
    'ru': 'Автобус придёт',
    'en': 'Bus arrives',
  },
  'kmh': {'uz': 'km/s', 'ru': 'км/ч', 'en': 'km/h'},
  'tagline': {
    'uz': 'Namangan avtobuslari',
    'ru': 'Автобусы Намангана',
    'en': 'Namangan buses',
  },
  'aboutText': {
    'uz':
        'Bekat — Namangan shahar avtobuslari uchun marshrut xaritasi. №1, №2, №3 yo‘nalishlari va oxirgi bekatlari rasmiy manbalardan; oraliq bekatlar va №5, №7, №9 — namuna. Avtobus vaqtlari qatnov oralig‘i asosida taxminiy. Xarita: © OpenStreetMap, OpenFreeMap.',
    'ru':
        'Bekat — карта маршрутов автобусов Намангана. Маршруты №1, №2, №3 и их конечные — из официальных источников; промежуточные остановки и №5, №7, №9 — пример. Время прибытия рассчитано по интервалу движения. Карта: © OpenStreetMap, OpenFreeMap.',
    'en':
        'Bekat — bus route map for Namangan. Routes 1, 2, 3 and their end stops come from official sources; intermediate stops and routes 5, 7, 9 are samples. Arrival times are estimated from the service interval. Map: © OpenStreetMap, OpenFreeMap.',
  },
  'author': {
    'uz':
        'Mualliflar: Qodirov Ulug‘bek, Zamalitdinov Salim (NamDTU, 37-ATT-23)',
    'ru': 'Авторы: Кодиров Улугбек, Замалитдинов Салим (НамГТУ, 37-АТТ-23)',
    'en': 'Authors: Ulugbek Kodirov, Salim Zamalitdinov (NamSTU, 37-ATT-23)',
  },
  'estimated': {
    'uz': 'taxminiy vaqt',
    'ru': 'примерное время',
    'en': 'estimated',
  },
  'future': {'uz': 'Kelajak', 'ru': 'Будущее', 'en': 'Future'},
  'futureSub': {
    'uz':
        'Keyingi bosqichlar g‘oyalari — prototipda namuna ma’lumotlar bilan ishlaydi',
    'ru': 'Идеи следующих этапов — в прототипе работают на демо-данных',
    'en': 'Ideas for the next stages — working demos on sample data',
  },
  'demoData': {
    'uz': 'namuna ma’lumot',
    'ru': 'демо-данные',
    'en': 'sample data',
  },
  'open': {'uz': 'Ochish', 'ru': 'Открыть', 'en': 'Open'},
  'fBoard': {
    'uz': 'Bekat tablosi',
    'ru': 'Табло на остановке',
    'en': 'Stop display',
  },
  'fBoardText': {
    'uz':
        'Bekatdagi ekran: qaysi avtobus necha daqiqada keladi, qayerga boradi, xaritada jonli avtobuslar.',
    'ru':
        'Экран на остановке: какой автобус через сколько минут, куда он идёт, живые автобусы на карте.',
    'en':
        'A screen at the stop: which bus comes when, where it goes, live buses on a map.',
  },
  'fBus': {
    'uz': 'Avtobus ichidagi ekran',
    'ru': 'Экран в автобусе',
    'en': 'In-bus screen',
  },
  'fBusText': {
    'uz':
        'Keyingi bekat katta harflarda, almashinuvlar va butun yo‘nalish chizig‘i.',
    'ru': 'Следующая остановка крупно, пересадки и вся линия маршрута.',
    'en': 'Next stop in big letters, transfers and the whole line.',
  },
  'fCommunity': {
    'uz': 'Jamoa yo‘nalishlari',
    'ru': 'Маршруты от жителей',
    'en': 'Community routes',
  },
  'fCommunityText': {
    'uz':
        'Damas, marshrutka, yo‘nalishli taksi — odamlar qo‘shadi va tasdiqlaydi.',
    'ru':
        'Дамасы, маршрутки, маршрутные такси — жители добавляют и подтверждают.',
    'en':
        'Damas vans, minibuses, shared taxis — added and confirmed by riders.',
  },
  'fDemand': {
    'uz': 'Hokimiyat uchun panel',
    'ru': 'Панель для хокимията',
    'en': 'City dashboard',
  },
  'fDemandText': {
    'uz': 'Talab xaritasi: odamlar qayerga boradi va qayerga avtobus yetmaydi.',
    'ru': 'Карта спроса: куда люди едут и куда не хватает автобусов.',
    'en': 'Demand map: where people go and where buses don’t reach.',
  },
  'roadmap': {'uz': 'Yo‘l xaritasi', 'ru': 'Дорожная карта', 'en': 'Road map'},
  'stage': {'uz': 'Bosqich', 'ru': 'Этап', 'en': 'Stage'},
  'rm0t': {'uz': 'Prototip', 'ru': 'Прототип', 'en': 'Prototype'},
  'rm0d': {
    'uz': 'Xarita, almashinuvli marshrut, metro sxemasi — tayyor.',
    'ru': 'Карта, путь с пересадками, схема как в метро — готово.',
    'en': 'Map, trips with transfers, metro-style diagram — done.',
  },
  'rm1t': {
    'uz': 'Haqiqiy ma’lumotlar',
    'ru': 'Реальные данные',
    'en': 'Real data',
  },
  'rm1d': {
    'uz':
        'GPS bilan yo‘nalishlarni yig‘ish (GTFS), shaharlararo reyslar, bekatlarda QR-sxemalar.',
    'ru':
        'Сбор маршрутов с GPS (GTFS), междугородние рейсы, QR-схемы на остановках.',
    'en': 'GPS survey of routes (GTFS), intercity trips, QR maps at stops.',
  },
  'rm2t': {
    'uz': 'Jamoa va tahlil',
    'ru': 'Сообщество и аналитика',
    'en': 'Community & analytics',
  },
  'rm2d': {
    'uz': 'Server, jamoa yo‘nalishlari va moderatsiya, anonim talab xaritasi.',
    'ru': 'Сервер, маршруты от жителей с модерацией, анонимная карта спроса.',
    'en': 'Server, moderated community routes, anonymous demand map.',
  },
  'rm3t': {
    'uz': 'Jonli avtobuslar',
    'ru': 'Живые автобусы',
    'en': 'Live buses',
  },
  'rm3d': {
    'uz': 'Avtobuslarda GPS, aniq kelish vaqti, bekat va salon ekranlari.',
    'ru':
        'GPS в автобусах, точное время прибытия, табло на остановках и в салоне.',
    'en': 'GPS on buses, real arrival times, stop and in-bus displays.',
  },
  'rm4t': {
    'uz': 'Butun O‘zbekiston',
    'ru': 'Весь Узбекистан',
    'en': 'All of Uzbekistan',
  },
  'rm4d': {
    'uz': 'Andijon, Farg‘ona va boshqa shaharlar.',
    'ru': 'Андижан, Фергана и другие города.',
    'en': 'Andijan, Fergana and other cities.',
  },
  'boardTitle': {
    'uz': 'Bekat tablosi',
    'ru': 'Табло остановки',
    'en': 'Stop display',
  },
  'boardBtn': {'uz': 'Tablo', 'ru': 'Табло', 'en': 'Display'},
  'youAreHere': {
    'uz': 'Siz shu yerdasiz',
    'ru': 'Вы здесь',
    'en': 'You are here',
  },
  'whereBusesGo': {
    'uz': 'Avtobuslar qayerga boradi',
    'ru': 'Куда идут автобусы',
    'en': 'Where the buses go',
  },
  'colRoute': {'uz': 'Yo‘nalish', 'ru': 'Маршрут', 'en': 'Route'},
  'colTo': {'uz': 'Qayerga', 'ru': 'Куда', 'en': 'To'},
  'colEta': {'uz': 'Keladi', 'ru': 'Прибудет', 'en': 'Arrives'},
  'via': {'uz': 'orqali', 'ru': 'через', 'en': 'via'},
  'then': {'uz': 'keyin', 'ru': 'затем', 'en': 'then'},
  'intercity': {
    'uz': 'Shaharlararo reyslar',
    'ru': 'Междугородние рейсы',
    'en': 'Intercity departures',
  },
  'departed': {'uz': 'Jo‘nadi', 'ru': 'Отправился', 'en': 'Departed'},
  'boarding': {
    'uz': 'Chiqish boshlandi',
    'ru': 'Идёт посадка',
    'en': 'Boarding',
  },
  'onTime': {'uz': 'O‘z vaqtida', 'ru': 'По расписанию', 'en': 'On time'},
  'bus': {'uz': 'Avtobus', 'ru': 'Автобус', 'en': 'Bus'},
  'minibus': {'uz': 'Marshrutka', 'ru': 'Маршрутка', 'en': 'Minibus'},
  'som': {'uz': 'so‘m', 'ru': 'сум', 'en': 'sum'},
  'platform': {'uz': 'Peron', 'ru': 'Перрон', 'en': 'Bay'},
  'boardTicker': {
    'uz':
        'Bu ekran — namuna: vaqtlar jadval asosida taxminiy  •  №1, №2, №3 yo‘nalishlari tasdiqlangan, qolganlari namuna  •  Ilovani yuklab oling — QR kodni skanerlang  •  Keksalar va homilador ayollarga joy bering',
    'ru':
        'Это экран-пример: время рассчитано по расписанию  •  Маршруты №1, №2, №3 подтверждены, остальные — пример  •  Скачайте приложение — отсканируйте QR-код  •  Уступайте место пожилым и беременным',
    'en':
        'This is a sample screen: times are estimated from the timetable  •  Routes 1, 2, 3 are confirmed, others are samples  •  Get the app — scan the QR code  •  Offer your seat to elderly and pregnant passengers',
  },
  'scanApp': {
    'uz': 'Bekat\nilovasi',
    'ru': 'Приложение\nBekat',
    'en': 'Bekat\napp',
  },
  'busScreen': {
    'uz': 'Avtobus ekrani',
    'ru': 'Экран в салоне',
    'en': 'In-bus screen',
  },
  'nextStop': {
    'uz': 'Keyingi bekat',
    'ru': 'Следующая остановка',
    'en': 'Next stop',
  },
  'thisStop': {'uz': 'Bekat', 'ru': 'Остановка', 'en': 'Now at'},
  'lastStop': {'uz': 'Oxirgi bekat', 'ru': 'Конечная', 'en': 'Last stop'},
  'changeTo': {'uz': 'Almashinuv:', 'ru': 'Пересадка:', 'en': 'Change to:'},
  'busTicker': {
    'uz':
        'Namuna ekran  •  Yo‘l haqini karta yoki QR orqali to‘lash mumkin  •  Keksalarga joy bering  •  Avtobus qayerga borishini Bekat ilovasida ko‘ring',
    'ru':
        'Экран-пример  •  Оплата проезда картой или по QR  •  Уступайте место пожилым  •  Куда идёт автобус — смотрите в приложении Bekat',
    'en':
        'Sample screen  •  Pay the fare by card or QR  •  Offer your seat to the elderly  •  See where every bus goes in the Bekat app',
  },
  'damas': {'uz': 'Damas', 'ru': 'Дамас', 'en': 'Damas'},
  'marshrutka': {'uz': 'Marshrutka', 'ru': 'Маршрутка', 'en': 'Minibus'},
  'taxi': {
    'uz': 'Yo‘nalishli taksi',
    'ru': 'Маршрутное такси',
    'en': 'Shared taxi',
  },
  'community': {
    'uz': 'Jamoa yo‘nalishlari',
    'ru': 'Маршруты от жителей',
    'en': 'Community routes',
  },
  'communitySub': {
    'uz':
        'Rasmiy jadvalda yo‘q transport: damas, marshrutka, taksi. Odamlar qo‘shadi, boshqalar tasdiqlaydi.',
    'ru':
        'Транспорт, которого нет в официальном расписании: дамасы, маршрутки, такси. Жители добавляют, другие подтверждают.',
    'en':
        'Transport the official timetable doesn’t have. People add it, others confirm.',
  },
  'statIdeas': {'uz': 'taklif', 'ru': 'предложений', 'en': 'suggestions'},
  'statVerified': {
    'uz': 'tasdiqlangan',
    'ru': 'подтверждено',
    'en': 'verified',
  },
  'statPeople': {'uz': 'ishtirokchi', 'ru': 'участников', 'en': 'contributors'},
  'all': {'uz': 'Hammasi', 'ru': 'Все', 'en': 'All'},
  'verified': {'uz': 'Tasdiqlangan', 'ru': 'Подтверждён', 'en': 'Verified'},
  'inReview': {'uz': 'Tekshiruvda', 'ru': 'На проверке', 'en': 'In review'},
  'every': {'uz': 'har', 'ru': 'каждые', 'en': 'every'},
  'approxPath': {
    'uz': 'Yo‘l taxminiy — haydovchilar biroz boshqacha yurishi mumkin',
    'ru': 'Путь примерный — водители могут ехать немного иначе',
    'en': 'The path is approximate — drivers may vary it',
  },
  'you': {'uz': 'Siz', 'ru': 'Вы', 'en': 'You'},
  'today': {'uz': 'bugun', 'ru': 'сегодня', 'en': 'today'},
  'daysAgo': {'uz': 'kun oldin', 'ru': 'дн. назад', 'en': 'days ago'},
  'thanksReport': {
    'uz': 'Rahmat! Xabar moderatorga yuborildi (namuna)',
    'ru': 'Спасибо! Сообщение отправлено модератору (пример)',
    'en': 'Thanks! Sent to a moderator (sample)',
  },
  'thanksSent': {
    'uz': 'Rahmat! Yo‘nalish tekshiruvga yuborildi',
    'ru': 'Спасибо! Маршрут отправлен на проверку',
    'en': 'Thanks! The route was sent for review',
  },
  'reportError': {'uz': 'Xato bor', 'ru': 'Есть ошибка', 'en': 'Report'},
  'confirm': {'uz': 'Tasdiqlayman', 'ru': 'Подтверждаю', 'en': 'Confirm'},
  'confirmed': {
    'uz': 'Tasdiqladingiz',
    'ru': 'Подтверждено',
    'en': 'Confirmed',
  },
  'addRoute': {
    'uz': 'Yo‘nalish qo‘shish',
    'ru': 'Добавить маршрут',
    'en': 'Add a route',
  },
  'addRouteSub': {
    'uz':
        'Qaysi transportda qayerdan qayerga borasiz? Boshqalarga ham yordam bering.',
    'ru': 'На чём и откуда куда вы ездите? Помогите другим.',
    'en': 'What do you ride, from where to where? Help others.',
  },
  'transportKind': {
    'uz': 'Transport turi',
    'ru': 'Вид транспорта',
    'en': 'Kind',
  },
  'routeNumber': {
    'uz': 'Raqami (bo‘lsa)',
    'ru': 'Номер (если есть)',
    'en': 'Number (if any)',
  },
  'routeNumberHint': {
    'uz': 'masalan, 12',
    'ru': 'например, 12',
    'en': 'e.g. 12',
  },
  'stopsOnWay': {'uz': 'Yo‘l', 'ru': 'Путь', 'en': 'Path'},
  'addStop': {
    'uz': 'Oraliq bekat qo‘shish',
    'ru': 'Добавить остановку по пути',
    'en': 'Add a stop on the way',
  },
  'chooseStop': {
    'uz': 'Bekatni tanlang',
    'ru': 'Выберите остановку',
    'en': 'Choose a stop',
  },
  'fare': {'uz': 'Yo‘l haqi', 'ru': 'Стоимость', 'en': 'Fare'},
  'interval': {
    'uz': 'Qatnov oralig‘i',
    'ru': 'Как часто ходит',
    'en': 'How often',
  },
  'workHours': {'uz': 'Ish vaqti', 'ru': 'Время работы', 'en': 'Hours'},
  'send': {'uz': 'Yuborish', 'ru': 'Отправить', 'en': 'Send'},
  'moderationNote': {
    'uz':
        'Yo‘nalish 3 kishi tasdiqlagach va moderatsiyadan so‘ng xaritada chiqadi. Prototipda faqat shu telefonda saqlanadi.',
    'ru':
        'Маршрут появится на карте после 3 подтверждений и модерации. В прототипе сохраняется только на этом телефоне.',
    'en':
        'A route appears on the map after 3 confirmations and moderation. In the prototype it is stored on this phone only.',
  },
  'demandFor': {
    'uz': 'Hokimiyat va transport bo‘limi uchun',
    'ru': 'Для хокимията и управления транспорта',
    'en': 'For the city and transport office',
  },
  'demandTitle': {
    'uz': 'Talab xaritasi · Namangan',
    'ru': 'Карта спроса · Наманган',
    'en': 'Demand map · Namangan',
  },
  'week': {'uz': '7 kun', 'ru': '7 дней', 'en': '7 days'},
  'month': {'uz': '30 kun', 'ru': '30 дней', 'en': '30 days'},
  'year': {'uz': '1 yil', 'ru': '1 год', 'en': '1 year'},
  'periodWord0': {
    'uz': 'so‘nggi 7 kun',
    'ru': 'за 7 дней',
    'en': 'last 7 days',
  },
  'periodWord1': {
    'uz': 'so‘nggi 30 kun',
    'ru': 'за 30 дней',
    'en': 'last 30 days',
  },
  'periodWord2': {
    'uz': 'so‘nggi 12 oy',
    'ru': 'за 12 месяцев',
    'en': 'last 12 months',
  },
  'report': {'uz': 'Hisobot', 'ru': 'Отчёт', 'en': 'Report'},
  'reportSoon': {
    'uz': 'PDF hisobot — keyingi bosqichda (namuna)',
    'ru': 'PDF-отчёт — на следующем этапе (пример)',
    'en': 'PDF report — next stage (sample)',
  },
  'allSearches': {
    'uz': 'Barcha qidiruvlar',
    'ru': 'Все запросы',
    'en': 'All searches',
  },
  'noBusThere': {
    'uz': 'Avtobus yo‘q joylar',
    'ru': 'Нет автобуса',
    'en': 'No bus there',
  },
  'searchDensity': {
    'uz': 'Qidiruvlar zichligi',
    'ru': 'Плотность запросов',
    'en': 'Search density',
  },
  'low': {'uz': 'kam', 'ru': 'мало', 'en': 'low'},
  'high': {'uz': 'ko‘p', 'ru': 'много', 'en': 'high'},
  'kpiSearches': {'uz': 'Qidiruvlar', 'ru': 'Запросов', 'en': 'Searches'},
  'kpiUsers': {'uz': 'Foydalanuvchilar', 'ru': 'Пользователей', 'en': 'Users'},
  'kpiNoBus': {'uz': 'Avtobussiz', 'ru': 'Без автобуса', 'en': 'No bus'},
  'kpiIdeas': {'uz': 'Takliflar', 'ru': 'Идей жителей', 'en': 'Ideas'},
  'searchesWord': {'uz': 'qidiruv', 'ru': 'запросов', 'en': 'searches'},
  'hotspotsTitle': {
    'uz': 'Avtobus yetmaydigan joylar',
    'ru': 'Куда не хватает автобусов',
    'en': 'Where buses don’t reach',
  },
  'hotspotsSub': {
    'uz': 'Ko‘p qidiriladi, lekin 1 km ichida bekat yo‘q',
    'ru': 'Часто ищут, но остановки нет в радиусе 1 км',
    'en': 'Searched often, no stop within 1 km',
  },
  'nearestStop': {
    'uz': 'eng yaqin bekat',
    'ru': 'ближайшая остановка',
    'en': 'nearest stop',
  },
  'hourlyTitle': {
    'uz': 'Qachon qidirishadi',
    'ru': 'Когда ищут',
    'en': 'When people search',
  },
  'hourlySub': {
    'uz': 'Kun soatlari bo‘yicha qidiruvlar',
    'ru': 'Запросы по часам суток',
    'en': 'Searches by hour of day',
  },
  'pairsTitle': {
    'uz': 'Eng ko‘p qidirilgan yo‘llar',
    'ru': 'Самые частые маршруты',
    'en': 'Most searched trips',
  },
  'withTransfer': {
    'uz': 'almashinuv bilan',
    'ru': 'с пересадкой',
    'en': 'with transfer',
  },
  'recoTitle': {
    'uz': 'Tavsiyalar',
    'ru': 'Рекомендации',
    'en': 'Recommendations',
  },
  'reco1': {
    'uz': '{p} yonida yangi bekat: hozir eng yaqini — {s}, {d}.',
    'ru': 'Новая остановка у объекта «{p}»: сейчас ближайшая — {s}, {d}.',
    'en': 'New stop near {p}: the nearest now is {s}, {d} away.',
  },
  'reco2': {
    'uz':
        '№1 va №3: ertalab 7–9 da qatnov oralig‘ini 8–10 daqiqadan 6 daqiqaga qisqartirish.',
    'ru': '№1 и №3: утром с 7 до 9 сократить интервал с 8–10 до 6 минут.',
    'en': 'Routes 1 and 3: cut the 7–9 am interval from 8–10 to 6 minutes.',
  },
  'reco3': {
    'uz':
        'Damas «G‘uzal — Chorsu» (128 tasdiq): rasmiy yo‘nalish sifatida ko‘rib chiqish.',
    'ru':
        'Дамас «Гузал — Чорсу» (128 подтверждений): рассмотреть как официальный маршрут.',
    'en':
        'Damas “Guzal — Chorsu” (128 confirmations): consider as an official route.',
  },
  'onDevice': {
    'uz': 'Bu telefonda — haqiqiy',
    'ru': 'На этом телефоне — реально',
    'en': 'On this phone — real',
  },
  'onDeviceText': {
    'uz': '{n} ta qidiruv, {m} tasida avtobus topilmadi — ular xaritada qizil.',
    'ru': '{n} запросов, в {m} автобус не найден — они на карте красным.',
    'en': '{n} searches, {m} with no bus — shown in red on the map.',
  },
  'privacy': {
    'uz':
        'Faqat anonim, umumlashtirilgan ma’lumot: shaxs va yo‘l tarixi saqlanmaydi.',
    'ru':
        'Только анонимные агрегированные данные: ни личности, ни истории поездок.',
    'en': 'Only anonymous, aggregated data: no identities, no trip histories.',
  },
  'alsoHere': {
    'uz': 'Bu yerdan yana: jamoa yo‘nalishlari',
    'ru': 'Отсюда же: маршруты от жителей',
    'en': 'Also from here: community routes',
  },
  'further': {'uz': 'Keyin', 'ru': 'Далее', 'en': 'After that'},
  'toEnd': {'uz': 'Oxirgi bekatgacha', 'ru': 'До конечной', 'en': 'To the end'},
};
