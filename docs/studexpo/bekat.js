// StudEXPO-2026 deck (7 slides). Build: cd docs/studexpo && npm install && node bekat.js
// Screens come from docs/assets (python3 docs/make_assets.py); deck-only images from ./assets.
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");
const sharp = require("sharp");
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

  // Картинка, обрезанная под рамку w×h (дюймы) со скруглёнными углами, как у карточек
  const rounded = async (file, w, h, r = 0.14) => {
    const dpi = 180, pw = Math.round(w * dpi), ph = Math.round(h * dpi), pr = Math.round(r * dpi);
    const mask = Buffer.from(`<svg width="${pw}" height="${ph}"><rect width="${pw}" height="${ph}" rx="${pr}" ry="${pr}"/></svg>`);
    const buf = await sharp(file).resize(pw, ph, { fit: "cover" }).composite([{ input: mask, blend: "dest-in" }]).png().toBuffer();
    return "image/png;base64," + buf.toString("base64");
  };
  // Картинка сцены с подписью-плашкой в левом нижнем углу. Если рядом лежит фото
  // (assets/photo_*.jpg), берём его, иначе нарисованную иллюстрацию scene_*.png.
  // h — высота; ширина — по пропорциям файла, но не шире maxW (тогда фото обрезается).
  const scene = async (s, kind, x, y, h, maxW, name, chip, photoChip) => {
    const photo = A(`photo_${kind}.jpg`), file = photo || A(`scene_${kind}.png`);
    if (photo) chip = photoChip;
    const { width: iw, height: ih } = await sharp(file).metadata();
    const w = Math.min(h * iw / ih, maxW);
    if (x < 0) x = 12.63 - w; // x < 0: flush with the right margin
    s.addImage({ data: await rounded(file, w, h), x, y, w, h, shadow: { type: "outer", color: HEX.dk1, opacity: 0.16, blur: 12, offset: 3, angle: 90 }, objectName: name, altText: (photo ? "Концепт: " : "Иллюстрация: ") + name });
    s.addText(chip, { x: x + 0.15, y: y + h - 0.5, w: Math.min(w - 0.3, 0.3 + chip.length * 0.078), h: 0.34, shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.08, fill: { color: C.text2, transparency: 10 }, fontSize: 11, bold: true, color: C.background1, margin: [0, 0.1, 0, 0.1], valign: "middle", isTextBox: true, objectName: "Подпись: " + name });
  };
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
  const sw = (7.05 - 0.25) / 2, sh = 1.12;
  stats.forEach(([n, l], i) => {
    const x = 0.7 + (i % 2) * (sw + 0.25), y = 1.95 + Math.floor(i / 2) * (sh + 0.2);
    card(s, x, y, sw, sh, "Факт " + (i + 1));
    headBody(s, n, l, { x: x + 0.25, y, w: sw - 0.35, h: sh, valign: "middle", objectName: "Факт " + (i + 1) + " текст" }, [28, 13], [i === 3 ? C.accent2 : C.accent1, C.accent6]);
  });
  const probs = [
    ["MdAltRoute", "Маршруты меняются", "автобусов всё больше, схемы движения обновляются"],
    ["MdLocalTaxi", "Нет прямого автобуса — такси", "пассажир не знает, где можно пересесть"],
    ["MdForum", "Расписание — в Telegram", "рейсы Наманган–Чуст знают только в группах вокзалов"],
  ];
  for (let i = 0; i < probs.length; i++) {
    const [ic, h, d] = probs[i];
    const y = 4.55 + i * 0.66;
    await circleIcon(s, ic, 0.7, y, 0.52, { c: C.accent2, t: 88 }, HEX.accent2, "Проблема " + (i + 1));
    headBody(s, h, d, { x: 1.4, y: y - 0.03, w: 6.35, h: 0.62, objectName: "Проблема " + (i + 1) + " текст" }, [16, 13]);
  }
  await scene(s, "problem", -1, 1.85, 5.1, 4.53, "Растерянный пассажир на остановке", "Иллюстрация", "Концепт");
  s.addText("Источники: namstat.uz (01.04.2026), yuz.uz (03.10.2026), gazeta.uz (24.09.2026), OpenStreetMap (14.10.2026)", { x: 0.7, y: 6.6, w: 7.05, h: 0.4, fontSize: 9, italic: true, color: C.accent6, margin: 0, valign: "top", isTextBox: true, objectName: "Источники" });
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
  const colW = 3.8, gap = (11.93 - 3 * colW) / 2, ph = 3.6;
  for (let i = 0; i < cols.length; i++) {
    const [f, ic, h, d] = cols[i];
    const x = 0.7 + i * (colW + gap);
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.85, w: colW, h: 3.95, rectRadius: 0.2, fill: { color: C.accent1, transparency: 90 }, line: { type: "none" }, objectName: "Фон " + (i + 1) });
    phone(s, A(f + ".png"), R, x + (colW - ph * R) / 2, 2.02, ph, h);
    await circleIcon(s, ic, x, 6.0, 0.55, { c: C.accent1 }, HEX.lt1, "Функция " + (i + 1));
    headBody(s, h, d, { x: x + 0.7, y: 5.95, w: colW - 0.7, h: 1.05, objectName: "Функция " + (i + 1) + " текст" });
  }
  s.addNotes("Пассажир просто выбирает, куда ему нужно. Bekat ищет место по названию — латиницей или кириллицей, предлагает варианты пути: автобус, пересадка и пешком, с временем в минутах, а в пути показывает остановки и сколько осталось ехать.");

  // ================= 4. Схема и алгоритм =================
  pres.addSection({ title: "Технология" });
  s = pres.addSlide({ masterName: "Content", sectionTitle: "Технология" });
  s.addText("ГЛАВНАЯ ИДЕЯ", { placeholder: "label" });
  s.addText("Вся сеть — на одной схеме, как в метро", { placeholder: "title" });
  card(s, 0.7, 1.85, 6.5, 4.05, "Рамка схемы");
  s.addImage({ path: A("scheme_ru.png"), x: 1.3, y: 1.9, w: 5.3, h: 5.3 * 2050 / 3000, objectName: "Схема маршрутов", altText: "Схема автобусных маршрутов Намангана в стиле метро" });
  s.addText("№1–3 — подтверждённые маршруты; №5, 7, 9 и промежуточные остановки — пример", { x: 0.95, y: 5.5, w: 6.1, h: 0.3, fontSize: 10, italic: true, color: C.accent6, margin: 0, isTextBox: true, objectName: "Пометка о данных" });
  await scene(s, "stop", 7.45, 1.85, 4.05, 5.18, "Остановка со схемой Bekat и QR-кодом", "Та же схема на остановке · QR → приложение", "Концепт: схема и QR на остановке");
  const ideas = [
    ["MdSyncAlt", "Пересадки", "RAPTOR соединяет несколько маршрутов"],
    ["MdNearMe", "Ближайшая точка", "нет автобуса — ведём до ближайшей остановки"],
    ["MdWifiOff", "Без интернета", "путь считается в телефоне меньше чем за секунду"],
    ["MdViewInAr", "3D-карта города", "MapLibre + OpenStreetMap, автобусы по расписанию"],
  ];
  const iw = (11.93 - 3 * 0.25) / 4;
  for (let i = 0; i < ideas.length; i++) {
    const [ic, h, d] = ideas[i];
    const x = 0.7 + i * (iw + 0.25);
    await circleIcon(s, ic, x, 6.12, 0.5, { c: C.accent1, t: 88 }, HEX.accent1, "Идея " + (i + 1));
    headBody(s, h, d, { x: x + 0.62, y: 6.08, w: iw - 0.62, h: 0.9, objectName: "Идея " + (i + 1) + " текст" }, [15, 12]);
  }
  s.addNotes("Главная идея — вся автобусная сеть на одной схеме, как карта метро: сразу видно, где маршруты пересекаются. Внутри работает алгоритм RAPTOR: он находит путь с пересадками прямо в телефоне, без интернета, меньше чем за секунду. А если до места автобус не идёт, Bekat ведёт до ближайшей остановки. Эту же схему можно повесить на остановке: человек видит всю сеть, наводит камеру на QR-код и сразу скачивает приложение. Честно: подтверждены маршруты 1–3, остальные — пример до полевого сбора данных.");

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
  s.addText("Экран в автобусе, табло и данные для города", { placeholder: "title" });
  await scene(s, "inbus", 0.7, 1.85, 4.62, 6.33, "Экран Bekat в салоне автобуса", "1  Экран в салоне", "1  Экран в салоне · концепт");
  s.addText("Следующая остановка крупно, где пересесть и вся линия — пассажир сразу понимает, куда едет автобус", { x: 0.7, y: 6.55, w: 6.33, h: 0.45, fontSize: 12, color: C.accent6, margin: 0, valign: "top", isTextBox: true, objectName: "Подпись салона" });
  const feats = [
    ["f_board_ru.png", "2. Табло на остановке", "любой экран с браузером: какой автобус, через сколько минут; междугородние рейсы"],
    ["f_demand_ru.png", "3. Карта спроса", "где ищут, но автобуса нет — довод хокимияту для новой остановки"],
    ["f_community_ru.png", "4. Маршруты от жителей", "дамасы и маршрутки: добавляют и подтверждают сами"],
  ];
  const fx = 7.35, tw = 2.35, th = tw * 9 / 16;
  for (const [i, [f, h, d]] of feats.entries()) {
    const y = 1.85 + i * (th + 0.22);
    s.addImage({ data: await rounded(A(f), tw, th, 0.1), x: fx, y, w: tw, h: th, shadow: { type: "outer", color: HEX.dk1, opacity: 0.18, blur: 10, offset: 3, angle: 90 }, objectName: "Экран " + (i + 2), altText: "Скриншот прототипа: " + h });
    headBody(s, h, d, { x: fx + tw + 0.2, y: y + 0.02, w: 12.63 - fx - tw - 0.2, h: th, objectName: "Bekat 2.0 текст " + (i + 2) }, [15, 12]);
  }
  s.addText("Пример: данные на этих экранах — демонстрационные", { x: fx, y: 6.5, w: 12.63 - fx, h: 0.45, shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.08, fill: { color: C.accent4, transparency: 82 }, fontSize: 11, bold: true, color: C.text1, margin: [0, 0.1, 0, 0.1], valign: "middle", isTextBox: true, objectName: "Пометка пример" });
  s.addNotes("Следующие этапы мы уже можем показать вживую — на демо-данных. Первое: экран в салоне — следующая остановка крупно и где пересесть, так пассажир сразу понимает, куда едет его автобус. Второе: табло на остановке. Это та же веб-страница приложения, ей хватает дешёвого экрана с браузером: какой автобус через сколько минут, куда он идёт, а на автовокзале — междугородние рейсы, которые сейчас знают только в Telegram-группах. Третье: карта спроса для хокимията — где люди ищут маршрут, но автобуса нет; это довод, где нужна новая остановка. И четвёртое: дамасы и маршрутки, которые добавляют и подтверждают сами жители. Все цифры на этих экранах — пример.");

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
