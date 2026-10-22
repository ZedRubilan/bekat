// Общие помощники для коротких конкурсных презентаций (pptxgenjs, LAYOUT_WIDE 13.333 x 7.5)
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const md = require("react-icons/md");

async function icon(name, hex, px = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(md[name], { color: "#" + hex, size: px }));
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

function setup(pres, THEME) {
  pres.layout = "LAYOUT_WIDE";
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  const C = pres.SchemeColor;
  const HEX = THEME.colors;

  const shadow = () => ({ type: "outer", color: HEX.dk1, opacity: 0.12, blur: 12, offset: 3, angle: 90 });
  const phoneShadow = () => ({ type: "outer", color: "000000", opacity: 0.3, blur: 18, offset: 6, angle: 90 });

  pres.defineSlideMaster({ title: "Dark", background: { color: C.text2 } });
  const contentPh = (x, w) => [
    { placeholder: { options: { name: "label", type: "body", x, y: 0.45, w, h: 0.4, fontSize: 13, bold: true, color: C.accent1, charSpacing: 2, margin: 0 }, text: "" } },
    { placeholder: { options: { name: "title", type: "title", x, y: 0.85, w, h: 0.85, fontSize: 36, bold: true, color: C.text1, margin: 0, valign: "top", align: "left" }, text: "" } },
  ];
  const num = { x: 12.2, y: 7.05, w: 0.5, h: 0.3, fontSize: 10, color: C.accent6, align: "right" };
  pres.defineSlideMaster({ title: "Content", background: { color: C.background2 }, objects: contentPh(0.7, 11.9), slideNumber: num });
  pres.defineSlideMaster({ title: "Photo Left", background: { color: C.background2 }, objects: contentPh(5.9, 6.7), slideNumber: { ...num } });

  // ratio = ширина / высота картинки телефона
  const phone = (s, file, ratio, x, y, h, name, withShadow = true) =>
    s.addImage({ path: file, x, y, h, w: h * ratio, shadow: withShadow ? phoneShadow() : undefined, objectName: name, altText: `Скриншот приложения: ${name}` });

  const circleIcon = async (s, name, x, y, d, fill, fg, objName) => {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fill.c, transparency: fill.t || 0 }, line: { type: "none" }, objectName: objName + " круг" });
    const p = d * 0.22;
    s.addImage({ data: await icon(name, fg), x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p, objectName: objName + " иконка" });
  };

  // Карточка: белый скруглённый прямоугольник с тенью
  const card = (s, x, y, w, h, name, fill = C.background1) =>
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.12, fill: { color: fill }, line: { type: "none" }, shadow: shadow(), objectName: name });

  // Заголовок + пояснение одним текстовым блоком
  const headBody = (s, head, body, opts, sizes = [18, 14], colors = [C.text1, C.accent6]) =>
    s.addText([
      { text: head, options: { bold: true, fontSize: sizes[0], color: colors[0], breakLine: true } },
      { text: body, options: { fontSize: sizes[1], color: colors[1] } },
    ], { margin: 0, valign: "top", isTextBox: true, ...opts });

  return { C, HEX, shadow, phone, circleIcon, card, headBody };
}

module.exports = { icon, setup };
