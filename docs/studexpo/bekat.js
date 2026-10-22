// StudEXPO-2026 deck (7 slides). Build: cd docs/studexpo && npm install && node bekat.js
// Screens come from docs/assets (python3 docs/make_assets.py); deck-only images from ./assets.
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");
const { icon, setup } = require("./common.js");
const { applyTheme } = require("../deck/apply_theme.js");

const A = (f) => [path.join(__dirname, "assets", f), path.join(__dirname, "..", "assets", f)].find((p) => fs.existsSync(p));
const OUT = process.argv[2] || path.join(__dirname, "..", "Bekat StudEXPO-2026.pptx");
const R = 1016 / 1952;

// Палитра приложения (lib/core/theme.dart)
const THEME = {
  name: "Bekat", headFontFace: "Calibri", bodyFontFace: "Calibri",
  colors: {
    dk1: "15171C", lt1: "FFFFFF", dk2: "1E2024", lt2: "EEF1F6",
    accent1: "2D6BF0", accent2: "E53935", accent3: "22A55B", accent4: "F59E0B",
    accent5: "8B5CF6", accent6: "5B6270", hlink: "2D6BF0", folHlink: "8B5CF6",
  },
};
// Цвета маршрутов из assets/data/network.json — это данные, а не тема
const ROUTES = [["1", "E53935"], ["2", "1E6FE8"], ["3", "22A55B"], ["5", "F59E0B"], ["7", "8B5CF6"], ["9", "06B6D4"]];

(async () => {
  const pres = new pptxgen();
  pres.title = "Bekat — StudEXPO-2026";
  pres.author = "Кодиров Улугбек, Замалитдинов Салим";
  const { C, HEX, phone, circleIcon, card, headBody } = setup(pres, THEME);

  const routeDots = (s, x, y, d, gap) => ROUTES.forEach(([n, col], i) =>
    s.addText(n, { x: x + i * (d + gap), y, w: d, h: d, shape: pres.shapes.OVAL, fill: { color: col }, line: { type: "none" }, fontSize: Math.round(d * 30), bold: true, color: "FFFFFF", align: "center", valign: "middle", margin: 0, isTextBox: true, objectName: "Маршрут " + n }));

  // ================= 1. Титул =================
  pres.addSection({ title: "Вступление" });
  let s = pres.addSlide({ masterName: "Dark", sectionTitle: "Вступление" });
  s.addShape(pres.shapes.OVAL, { x: 7.6, y: -0.9, w: 6.6, h: 6.6, fill: { color: C.accent1, transparency: 55 }, line: { type: "none" }, objectName: "Фоновый круг" });
  s.addImage({ path: A("icon_round.png"), x: 0.7, y: 0.65, w: 0.85, h: 0.85, objectName: "Значок Bekat" });
  headBody(s, "STUDEXPO-2026", "Мобильные и веб-приложения", { x: 1.8, y: 0.65, w: 5.9, h: 0.85, valign: "middle", objectName: "Метка" }, [15, 14], [C.background1, C.background2]);
  s.addText("Bekat", { x: 0.7, y: 1.85, w: 6.8, h: 1.3, fontSize: 80, bold: true, color: C.background1, fontFace: THEME.headFontFace, margin: 0, isTextBox: true, objectName: "Название" });
  s.addText("Умная карта автобусных маршрутов Намангана: путь даже с пересадками", { x: 0.7, y: 3.2, w: 6.6, h: 1.1, fontSize: 26, color: C.background2, margin: 0, valign: "top", isTextBox: true, objectName: "Подзаголовок" });
  routeDots(s, 0.7, 4.65, 0.55, 0.2);
  headBody(s, "Кодиров Улугбек · Замалитдинов Салим", "НамГТУ, группа 37-АТТ-23 (r)", { x: 0.7, y: 6.15, w: 6.8, h: 0.75, objectName: "Авторы" }, [15, 15], [C.background1, C.background2]);
  phone(s, A("phone_05_plan_ru.png"), R, 10.2, 1.5, 5.4, "Варианты пути");
  phone(s, A("phone_02_home_ru.png"), R, 7.75, 0.7, 6.1, "Главный экран");
  s.addNotes("Здравствуйте! Мы — Кодиров Улугбек и Замалитдинов Салим, НамГТУ. Наш проект — Bekat, умная карта автобусных маршрутов Намангана. Она отвечает на простой вопрос пассажира: как доехать — даже если прямого автобуса нет.");

  // ================= 2. Проблема =================
  pres.addSection({ title: "Проблема" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Проблема" });
  s.addText("ПРОБЛЕМА", { placeholder: "label" });
  s.addText("«Какой автобус? Где пересесть?»", { placeholder: "title" });
  const stats = [["731,3 тыс.", "жителей Намангана"], ["130", "современных автобусов"], ["10", "маршрутов по брутто-контракту"], ["0", "маршрутов на открытой карте (OSM)"]];
  const sw = (11.93 - 3 * 0.3) / 4;
  stats.forEach(([n, l], i) => {
    const x = 0.7 + i * (sw + 0.3);
    card(s, x, 1.95, sw, 1.9, "Факт " + (i + 1));
    headBody(s, n, l, { x: x + 0.25, y: 1.95, w: sw - 0.35, h: 1.9, valign: "middle", objectName: "Факт " + (i + 1) + " текст" }, [34, 15], [i === 3 ? C.accent2 : C.accent1, C.accent6]);
  });
  const probs = [
    ["MdAltRoute", "Маршруты меняются", "автобусов всё больше, схемы движения обновляются"],
    ["MdLocalTaxi", "Нет прямого автобуса — такси", "пассажир не знает, где можно пересесть"],
    ["MdForum", "Расписание — в Telegram", "междугородние рейсы (Наманган–Чуст) знают только в группах вокзалов"],
  ];
  for (let i = 0; i < probs.length; i++) {
    const [ic, h, d] = probs[i];
    const x = 0.7 + i * ((11.93 - 0.6) / 3 + 0.3);
    await circleIcon(s, ic, x, 4.55, 0.65, { c: C.accent2, t: 88 }, HEX.accent2, "Проблема " + (i + 1));
    headBody(s, h, d, { x: x + 0.85, y: 4.52, w: (11.93 - 0.6) / 3 - 0.9, h: 1.3, objectName: "Проблема " + (i + 1) + " текст" }, [18, 15]);
  }
  s.addText("Источники: namstat.uz (01.04.2026), yuz.uz (03.10.2026), gazeta.uz (24.09.2026), запрос к OpenStreetMap (14.10.2026)", { x: 0.7, y: 6.55, w: 11, h: 0.35, fontSize: 11, italic: true, color: C.accent6, margin: 0, isTextBox: true, objectName: "Источники" });
  s.addNotes("В Намангане больше 730 тысяч жителей, по городу ходят 130 современных автобусов, 10 маршрутов работают по брутто-контракту. Но на открытой карте OpenStreetMap нет ни одного маршрута города. Если прямого автобуса нет, пассажир не знает, где пересесть, и едет на такси. А чтобы узнать, когда идёт автобус в Чуст, нужно состоять в Telegram-группе автовокзала.");

  // ================= 3. Решение =================
  pres.addSection({ title: "Решение" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Решение" });
  s.addText("РЕШЕНИЕ", { placeholder: "label" });
  s.addText("Выберите место — увидите путь", { placeholder: "title" });
  const cols = [
    ["phone_04_search_ru", "MdSearch", "Поиск места", "69 мест: остановки, рынки, вузы — латиницей и кириллицей"],
    ["phone_05_plan_ru", "MdDirectionsBus", "Варианты пути", "автобус + пересадка + пешком, время в минутах"],
    ["phone_06_trip_ru", "MdNavigation", "В пути", "остановки и время до цели"],
  ];
  const colW = 3.8, gap = (11.93 - 3 * colW) / 2, ph = 3.95;
  for (let i = 0; i < cols.length; i++) {
    const [f, ic, h, d] = cols[i];
    const x = 0.7 + i * (colW + gap);
    phone(s, A(f + ".png"), R, x + (colW - ph * R) / 2, 1.85, ph, h);
    await circleIcon(s, ic, x, 6.0, 0.55, { c: C.accent1 }, HEX.lt1, "Функция " + (i + 1));
    headBody(s, h, d, { x: x + 0.7, y: 5.95, w: colW - 0.7, h: 1.05, objectName: "Функция " + (i + 1) + " текст" });
  }
  s.addNotes("Пассажир просто выбирает, куда ему нужно. Bekat ищет место по названию — латиницей или кириллицей, предлагает варианты пути: автобус, пересадка и пешком, с временем в минутах, а в пути показывает остановки и сколько осталось ехать.");

  // ================= 4. Схема и алгоритм =================
  pres.addSection({ title: "Технология" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Технология" });
  s.addText("ГЛАВНАЯ ИДЕЯ", { placeholder: "label" });
  s.addText("Вся сеть — на одной схеме, как в метро", { placeholder: "title" });
  card(s, 0.7, 1.9, 7.55, 5.17, "Рамка схемы");
  s.addImage({ path: A("scheme_ru.png"), x: 1.125, y: 2.0, w: 6.7, h: 6.7 * 2050 / 3000, objectName: "Схема маршрутов", altText: "Схема автобусных маршрутов Намангана в стиле метро" });
  s.addText("№1–3 — подтверждённые маршруты; №5, 7, 9 и промежуточные остановки — пример", { x: 0.95, y: 6.65, w: 7.1, h: 0.35, fontSize: 11, italic: true, color: C.accent6, margin: 0, isTextBox: true, objectName: "Пометка о данных" });
  const ideas = [
    ["MdSyncAlt", "Пересадки", "алгоритм RAPTOR соединяет несколько маршрутов"],
    ["MdNearMe", "Ближайшая точка", "куда автобус не идёт — до ближайшей остановки"],
    ["MdWifiOff", "В телефоне, без интернета", "маршрут считается меньше чем за секунду"],
    ["MdViewInAr", "3D-карта города", "MapLibre + OpenStreetMap, автобусы по расписанию"],
  ];
  for (let i = 0; i < ideas.length; i++) {
    const [ic, h, d] = ideas[i];
    const y = 1.9 + i * 1.3;
    await circleIcon(s, ic, 8.65, y + 0.05, 0.6, { c: C.accent1, t: 88 }, HEX.accent1, "Идея " + (i + 1));
    headBody(s, h, d, { x: 9.45, y, w: 3.2, h: 1.15, objectName: "Идея " + (i + 1) + " текст" }, [18, 14]);
  }
  s.addNotes("Главная идея — вся автобусная сеть на одной схеме, как карта метро: сразу видно, где маршруты пересекаются. Внутри работает алгоритм RAPTOR: он находит путь с пересадками прямо в телефоне, без интернета, меньше чем за секунду. А если до места автобус не идёт, Bekat ведёт до ближайшей остановки. Честно: подтверждены маршруты 1–3, остальные — пример до полевого сбора данных.");

  // ================= 5. Отличие и модель =================
  pres.addSection({ title: "Ценность" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Ценность" });
  s.addText("ЧЕМ ОТЛИЧАЕТСЯ", { placeholder: "label" });
  s.addText("Не ещё одна карта, а схема сети и данные для города", { placeholder: "title" });
  const hdr = (t, fill) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: fill }, align: "center" } });
  const cell = (t, good) => ({ text: t, options: { color: good ? C.accent3 : C.accent6, bold: !!good, align: "center" } });
  const demo = { text: "пример ✓", options: { color: C.accent4, bold: true, align: "center" } };
  const rows = [
    [hdr("", C.text2), hdr("Яндекс Карты", C.text2), hdr("Bekat", C.accent1)],
    [{ text: "Схема всей сети", options: { bold: true } }, cell("нет"), cell("есть", true)],
    [{ text: "Режим «ближайшая точка»", options: { bold: true } }, cell("нет"), cell("есть", true)],
    [{ text: "Карта спроса для хокимията", options: { bold: true } }, cell("нет"), demo],
    [{ text: "Табло и экран в автобусе", options: { bold: true } }, cell("нет"), demo],
    [{ text: "Дамасы и маршрутки от жителей", options: { bold: true } }, cell("нет"), demo],
    [{ text: "База маршрутов Намангана", options: { bold: true } }, cell("закрытая"), cell("открытая", true)],
    [{ text: "Живые автобусы", options: { bold: true } }, cell("есть"), cell("GPS — 2-й этап")],
  ];
  s.addTable(rows, { x: 0.7, y: 2.45, w: 7.6, colW: [3.4, 2.1, 2.1], rowH: 0.56, fontSize: 15, color: C.text1, fill: { color: C.background1 }, border: { type: "solid", pt: 1, color: HEX.lt2 }, valign: "middle", margin: [0, 0.12, 0, 0.12], objectName: "Сравнение" });
  const biz = [
    ["MdPeople", "Жители", "приложение бесплатно"],
    ["MdAccountBalance", "Хокимият", "годовая подписка: карта спроса и изменения маршрутов"],
    ["MdDirectionsBus", "Перевозчики", "больше пассажиров, подключение GPS-данных"],
  ];
  s.addText("Bekat против Яндекс Карт", { x: 0.7, y: 1.95, w: 7.6, h: 0.4, fontSize: 15, bold: true, color: C.accent1, margin: 0, isTextBox: true, objectName: "Сравнение заголовок" });
  s.addText("Кто выигрывает", { x: 8.75, y: 1.95, w: 3.9, h: 0.4, fontSize: 15, bold: true, color: C.accent1, margin: 0, isTextBox: true, objectName: "Модель заголовок" });
  for (let i = 0; i < biz.length; i++) {
    const [ic, h, d] = biz[i];
    const y = 2.5 + i * 1.5;
    card(s, 8.75, y, 3.88, 1.3, "Модель " + (i + 1));
    await circleIcon(s, ic, 8.92, y + 0.33, 0.6, { c: C.accent3, t: 85 }, HEX.accent3, "Модель " + (i + 1));
    headBody(s, h, d, { x: 9.7, y, w: 2.85, h: 1.3, valign: "middle", objectName: "Модель " + (i + 1) + " текст" }, [17, 14]);
  }
  s.addNotes("Яндекс Карты уже показывают автобусы в Намангане — мы это признаём. Наше отличие — схема всей сети, режим «ближайшая точка», открытая база маршрутов, а дальше — табло, маршруты дамасов от жителей и анонимная карта спроса для хокимията: где люди ищут маршрут, но автобуса нет. Эти три функции уже есть в прототипе как пример на демо-данных. Для жителей приложение бесплатно, хокимият может получать аналитику по годовой подписке, а перевозчики — больше пассажиров.");

  // ================= 6. Bekat 2.0 (демо-экраны) =================
  pres.addSection({ title: "Bekat 2.0" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Bekat 2.0" });
  s.addText("BEKAT 2.0 · УЖЕ В ПРОТОТИПЕ", { placeholder: "label" });
  s.addText("Табло, экран в автобусе и данные для города", { placeholder: "title" });
  const shots = [
    ["f_board_ru.png", "Табло на остановке"],
    ["f_bus_ru.png", "Экран в салоне"],
    ["f_demand_ru.png", "Карта спроса"],
    ["f_community_ru.png", "Маршруты от жителей"],
  ];
  const tw = 4.4, th = tw * 9 / 16, tg = 0.15, ty = 1.85;
  shots.forEach(([f, cap], i) => {
    const x = 0.7 + (i % 2) * (tw + tg), y = ty + Math.floor(i / 2) * (th + tg);
    s.addImage({ path: A(f), x, y, w: tw, h: th, rounding: false, shadow: { type: "outer", color: HEX.dk1, opacity: 0.18, blur: 10, offset: 3, angle: 90 }, objectName: "Экран " + (i + 1), altText: "Скриншот прототипа: " + cap });
    s.addText((i + 1) + "  " + cap, { x: x + 0.12, y: y + th - 0.47, w: 2.3, h: 0.35, shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.08, fill: { color: C.text2, transparency: 8 }, fontSize: 12, bold: true, color: C.background1, margin: [0, 0.1, 0, 0.1], valign: "middle", isTextBox: true, objectName: "Подпись " + (i + 1) });
  });
  const fx = 0.7 + 2 * tw + tg + 0.35, fw = 12.63 - fx;
  const feats = [
    ["MdDepartureBoard", "Табло", "любой экран с браузером: какой автобус, через сколько минут, куда идёт; междугородние рейсы"],
    ["MdDirectionsBus", "В салоне", "следующая остановка крупно, пересадки, вся линия"],
    ["MdInsights", "Для хокимията", "где ищут, но автобуса нет — довод для новой остановки"],
    ["MdGroups", "От жителей", "дамасы и маршрутки: добавляют и подтверждают"],
  ];
  for (let i = 0; i < feats.length; i++) {
    const [ic, h, d] = feats[i];
    const y = ty + i * 1.1;
    await circleIcon(s, ic, fx, y + 0.02, 0.5, { c: C.accent1, t: 88 }, HEX.accent1, "Bekat 2.0 " + (i + 1));
    headBody(s, (i + 1) + ". " + h, d, { x: fx + 0.65, y, w: fw - 0.65, h: 1.0, objectName: "Bekat 2.0 текст " + (i + 1) }, [15, 12]);
  }
  s.addText("Пример: данные на этих экранах — демонстрационные", { x: fx, y: 6.45, w: fw, h: 0.5, shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.08, fill: { color: C.accent4, transparency: 82 }, fontSize: 11, bold: true, color: C.text1, margin: [0, 0.1, 0, 0.1], valign: "middle", isTextBox: true, objectName: "Пометка пример" });
  s.addNotes("Следующие этапы мы уже можем показать вживую — на демо-данных. Первое: табло на остановке. Это та же веб-страница приложения, ей хватает дешёвого экрана с браузером: какой автобус через сколько минут, куда он идёт, а на автовокзале — междугородние рейсы, которые сейчас знают только в Telegram-группах. Второе: экран в салоне — следующая остановка крупно и где пересесть. Третье: карта спроса для хокимията — где люди ищут маршрут, но автобуса нет; это довод, где нужна новая остановка. И четвёртое: дамасы и маршрутки, которые добавляют и подтверждают сами жители. Все цифры на этих экранах — пример.");

  // ================= 7. Статус и следующий шаг =================
  pres.addSection({ title: "Следующий шаг" });
  s = pres.addSlide({ masterName: "Dark", sectionTitle: "Следующий шаг" });
  s.addText("СТАТУС", { x: 0.7, y: 0.6, w: 7.8, h: 0.4, fontSize: 13, bold: true, color: C.accent4, charSpacing: 2, margin: 0, isTextBox: true, objectName: "Метка" });
  s.addText("Прототип работает — дальше пилот со 100+ пассажирами", { x: 0.7, y: 1.0, w: 7.9, h: 1.4, fontSize: 36, bold: true, color: C.background1, fontFace: THEME.headFontFace, margin: 0, valign: "top", isTextBox: true, objectName: "Заголовок" });
  const done = [["6", "маршрутов (3 подтверждённых)"], ["36", "остановок на карте"], ["69", "мест в поиске"]];
  done.forEach(([n, l], i) => headBody(s, n, l, { x: 0.7 + i * 2.65, y: 2.75, w: 2.5, h: 1.25, objectName: "Статус " + (i + 1) }, [40, 15], [C.accent4, C.background2]));
  headBody(s, "Дальше", "GPS-сбор маршрутов и междугородних рейсов → пилот → маршруты от жителей и карта спроса → GPS автобусов и табло → Андижан, Фергана", { x: 0.7, y: 4.2, w: 7.9, h: 1.0, objectName: "План" }, [17, 15], [C.background1, C.background2]);
  s.addImage({ path: A("icon_round.png"), x: 0.7, y: 5.85, w: 0.95, h: 0.95, objectName: "Значок" });
  headBody(s, "Кодиров Улугбек — автор · Замалитдинов Салим — соавтор", "+998 90 555 80 91 · salzamov@gmail.com", { x: 1.85, y: 5.85, w: 6.9, h: 0.95, valign: "middle", objectName: "Контакты" }, [17, 15], [C.background1, C.background2]);
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 9.15, y: 1.0, w: 3.48, h: 4.95, rectRadius: 0.2, fill: { color: C.background1 }, line: { type: "none" }, objectName: "Карточка QR" });
  s.addImage({ path: A("qr.png"), x: 9.44, y: 1.3, w: 2.9, h: 2.9, objectName: "QR-код", altText: "QR-код: zedrubilan.github.io/bekat" });
  s.addText([
    { text: "Скачайте и попробуйте", options: { bold: true, fontSize: 20, color: C.text1, breakLine: true } },
    { text: "Android, iPhone и браузер", options: { fontSize: 15, color: C.accent6, breakLine: true } },
    { text: "zedrubilan.github.io/bekat", options: { fontSize: 12, color: C.accent1 } },
  ], { x: 9.35, y: 4.45, w: 3.08, h: 1.4, margin: 0, align: "center", valign: "top", isTextBox: true, objectName: "Подпись QR" });
  s.addText("Спасибо!", { x: 9.15, y: 6.15, w: 3.48, h: 0.65, fontSize: 28, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true, objectName: "Спасибо" });
  s.addNotes("Прототип уже работает на Android, iPhone и в браузере: 6 маршрутов, из них 3 подтверждены, 36 остановок и 69 мест в поиске. Дальше — собрать с GPS все маршруты города и междугородние рейсы, провести пилот со 100+ пассажирами, открыть маршруты от жителей и карту спроса, затем подключить GPS автобусов и табло на остановках и выйти в Андижан и Фергану. Отсканируйте QR-код — и попробуйте сами. Спасибо!");

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("wrote", OUT);
})();
