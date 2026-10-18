#!/usr/bin/env node
// pele2svg.mjs — pele の SVG を「CSS エンジンを持たないレンダラー」(Skia SVG / GT の
// BlSkiaSvgElement など) でも描ける素朴な SVG に変換する。
//
// pele の出力が CSS に頼っている箇所を、すべて SVG のプレゼンテーション属性に展開する:
//   1. CSS 変数  var(--x, fallback)          → 実際の色・値 (テーマ上書き可)
//   2. ルート <svg> の style (font: 等)       → font-family / font-size 属性
//   3. style="fill:..;stroke:..;rx:.."        → 同名の属性 (CSS は属性より強いので属性を置き換える)
//   4. currentColor                           → 前景色 (--pele-fg)
//   5. color-mix(in srgb, A p%, B)            → 計算済みの #rrggbb
//   6. 入れ子 <svg class="pele-icon" ...>     → <g transform="translate() scale()">
//   7. <a href=...>                           → <g> (リンクは GT では使えないため)
//   8. 外部 URL の <image href="http...">     → 削除 (GT からは取得できないため)
//
// 使い方:
//   node pele2svg.mjs input.mmd output.svg [theme.json]
//   node pele2svg.mjs --batch sources.json outdir [theme.json]
//       sources.json = [{"name":"flowchart-1","source":"flowchart LR\n A-->B"}, ...]
//   9. font-family="monospace" 等の総称名    → --gt-font-mono 等で指定した実フォント名
// theme.json 例: {"--pele-bg":"#fffcf0","--pele-fg":"#100f0f","--pele-accent":"#205ea6",
//                 "--gt-font-mono":"Consolas"}
import { readFileSync, writeFileSync, mkdirSync, realpathSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// ---------- var() ----------
// var(--name) / var(--name, fallback)。fallback は括弧1段まで許容 (rgb(...) など)
const VAR_RE = /var\(\s*(--[\w-]+)\s*(?:,\s*((?:[^()]|\([^()]*\))*))?\)/g;

export function resolveVars(str, vars) {
  let prev, guard = 0;
  do {
    prev = str;
    str = str.replace(VAR_RE, (_, name, fallback) =>
      vars[name] !== undefined ? vars[name] : fallback !== undefined ? fallback.trim() : '');
  } while (str !== prev && guard++ < 20);
  return str;
}

// ---------- 色 ----------
const NAMED = { white: [255, 255, 255], black: [0, 0, 0] };
function parseColor(s) {
  s = s.trim().toLowerCase();
  if (NAMED[s]) return NAMED[s];
  let m = s.match(/^#([0-9a-f]{3})$/);
  if (m) return [...m[1]].map(c => parseInt(c + c, 16));
  m = s.match(/^#([0-9a-f]{6})$/);
  if (m) return [0, 2, 4].map(i => parseInt(m[1].slice(i, i + 2), 16));
  m = s.match(/^rgb\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)\s*\)$/);
  if (m) return [+m[1], +m[2], +m[3]];
  return null;
}
const hex = rgb => '#' + rgb.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')).join('');

// color-mix(in srgb, A p%, B q%)  (sRGB の単純な線形補間。不透明色のみ対応)
const MIX_RE = /color-mix\(\s*in\s+srgb\s*,\s*((?:#[0-9a-fA-F]{3,6}|rgb\([^)]*\)|[a-z]+))(?:\s+([\d.]+)%)?\s*,\s*((?:#[0-9a-fA-F]{3,6}|rgb\([^)]*\)|[a-z]+))(?:\s+([\d.]+)%)?\s*\)/g;
function resolveColorMix(str, warnings) {
  return str.replace(MIX_RE, (whole, c1, p1, c2, p2) => {
    const a = parseColor(c1), b = parseColor(c2);
    if (!a || !b) { warnings.push(`color-mix を解決できません: ${whole}`); return whole; }
    let w1 = p1 !== undefined ? +p1 : p2 !== undefined ? 100 - +p2 : 50;
    let w2 = p2 !== undefined ? +p2 : 100 - w1;
    const sum = w1 + w2; w1 /= sum; w2 /= sum;
    return hex(a.map((v, i) => v * w1 + b[i] * w2));
  });
}

// ---------- タグ単位の処理 ----------
const TAG_RE = /<([a-zA-Z][\w:-]*)((?:\s+[\w:-]+="[^"]*")*)\s*(\/?)>/g;
const ATTR_RE = /([\w:-]+)="([^"]*)"/g;
const parseAttrs = s => [...s.matchAll(ATTR_RE)].map(m => [m[1], m[2]]);
const buildAttrs = list => list.map(([k, v]) => ` ${k}="${v}"`).join('');

function styleToAttrs(attrs) {
  const i = attrs.findIndex(([k]) => k === 'style');
  if (i < 0) return attrs;
  const decls = attrs[i][1].split(';').map(d => d.trim()).filter(Boolean);
  const out = attrs.filter(([k]) => k !== 'style');
  for (const d of decls) {
    const j = d.indexOf(':');
    if (j < 0) continue;
    const name = d.slice(0, j).trim();
    let value = d.slice(j + 1).trim().replace(/\s*!important$/, '');
    if ((name === 'rx' || name === 'ry') && /px$/.test(value)) value = value.slice(0, -2);
    const k = out.findIndex(([n]) => n === name);
    if (k >= 0) out.splice(k, 1); // CSS は属性より強い → 同名の属性は置き換える
    out.push([name, value]);
  }
  return out;
}

// 入れ子 <svg x y width height viewBox> → <g transform>
function nestedSvgToG(attrs) {
  const get = n => attrs.find(([k]) => k === n)?.[1];
  const vb = get('viewBox')?.trim().split(/[\s,]+/).map(Number);
  const x = parseFloat(get('x') ?? 0), y = parseFloat(get('y') ?? 0);
  const w = parseFloat(get('width')), h = parseFloat(get('height'));
  let t = `translate(${x} ${y})`;
  if (vb && vb.length === 4 && w > 0 && h > 0) {
    const s = Math.min(w / vb[2], h / vb[3]); // preserveAspectRatio=xMidYMid meet 相当
    const dx = (w - vb[2] * s) / 2 - vb[0] * s, dy = (h - vb[3] * s) / 2 - vb[1] * s;
    t = `translate(${+(x + dx).toFixed(4)} ${+(y + dy).toFixed(4)}) scale(${+s.toFixed(6)})`;
  }
  const drop = new Set(['x', 'y', 'width', 'height', 'viewBox', 'xmlns', 'preserveAspectRatio']);
  const rest = attrs.filter(([k]) => !drop.has(k));
  return [...rest, ['transform', t]];
}

export function flatten(svg, theme = {}) {
  const warnings = [];
  const vars = { ...theme };

  // 1. ルート <svg> の style から変数を集める
  const rootMatch = svg.match(/^<svg\b[^>]*?\sstyle="([^"]*)"/);
  if (rootMatch) {
    const decls = rootMatch[1].split(';').map(s => s.trim()).filter(Boolean);
    const raw = {};
    for (const d of decls) {
      const i = d.indexOf(':');
      if (i < 0) continue;
      const k = d.slice(0, i).trim();
      if (k.startsWith('--')) raw[k] = d.slice(i + 1).trim();
    }
    for (const [k, v] of Object.entries(raw)) if (vars[k] === undefined) vars[k] = resolveVars(v, vars);
    const ff = decls.find(d => d.startsWith('font-family:'));
    const fontFamily = ff ? resolveVars(ff.slice('font-family:'.length).trim(), vars) : 'sans-serif';
    // 属性値の中の " は XML 的に不正なので &quot; にする
    svg = svg.replace(/^(<svg\b[^>]*?)\sstyle="[^"]*"/,
      `$1 font-family="${fontFamily.replace(/"/g, '&quot;')}" font-size="16"`);
  }
  const fg = vars['--_fg'] ?? vars['--pele-fg'] ?? '#000000';

  // 2. 残りの var() を全部解決し、currentColor は前景色にする
  svg = resolveVars(svg, vars);
  svg = svg.replace(/currentColor/g, fg);

  // 3. 入れ子 <svg>(アイコン) → <g>。ルート以外の <svg ...> と </svg> を対応づけて置換
  let depth = 0;
  svg = svg.replace(/<svg\b((?:\s+[\w:-]+="[^"]*")*)\s*>|<\/svg>/g, (m, a) => {
    if (m === '</svg>') return --depth === 0 ? m : '</g>';
    return depth++ === 0 ? m : `<g${buildAttrs(nestedSvgToG(parseAttrs(a)))}>`;
  });

  // 4. タグごとに style → 属性
  svg = svg.replace(TAG_RE, (m, tag, a, selfClose) => {
    if (!/\sstyle="/.test(a)) return m;
    return `<${tag}${buildAttrs(styleToAttrs(parseAttrs(a)))}${selfClose ? '/' : ''}>`;
  });

  // 5. color-mix()
  svg = resolveColorMix(svg, warnings);

  // 6. <a> → <g>
  svg = svg.replace(/<a\b((?:\s+[\w:-]+="[^"]*")*)\s*>/g, '<g>').replace(/<\/a>/g, '</g>');

  // 7. 外部 URL の <image>
  svg = svg.replace(/<image\b[^>]*\shref="https?:[^"]*"[^>]*\/>|<image\b[^>]*\shref="https?:[^"]*"[^>]*>\s*<\/image>/g, () => {
    warnings.push('外部 URL の <image> を削除しました');
    return '';
  });

  // 7b. 総称フォント名 → 実フォント名
  //     Skia の SVG は monospace / sans-serif などの総称名を解決しないことがある。
  //     theme に --gt-font-mono / --gt-font-sans / --gt-font-serif を渡すと置き換える。
  //     (Skia は font-family を1つの名前として扱う可能性があるため、候補リストではなく単一名を推奨)
  const generic = {
    monospace: vars['--gt-font-mono'],
    'sans-serif': vars['--gt-font-sans'],
    serif: vars['--gt-font-serif'],
  };
  svg = svg.replace(/font-family="([^"]*)"/g, (m, f) => {
    const to = generic[f.trim()];
    return to ? `font-family="${to.replace(/"/g, '&quot;')}"` : m;
  });

  // 8. 取りこぼしの検査
  if (/var\(/.test(svg)) warnings.push('解決できない var() が残っています');
  if (/<style\b/i.test(svg)) warnings.push('<style> が残っています');
  if (/color-mix\(/.test(svg)) warnings.push('color-mix() が残っています');
  return { svg, warnings };
}

// ---------- CLI ----------
async function main(argv) {
  const { render } = await import('pele');
  const themeOf = f => (f ? JSON.parse(readFileSync(f, 'utf8')) : {});
  if (argv[0] === '--batch') {
    const [, listFile, outDir, themeFile] = argv;
    const theme = themeOf(themeFile);
    mkdirSync(outDir, { recursive: true });
    let ok = 0, failed = 0, warned = 0;
    for (const { name, source } of JSON.parse(readFileSync(listFile, 'utf8'))) {
      try {
        const { svg } = render(source);
        const flat = flatten(svg, theme);
        writeFileSync(`${outDir}/${name}.svg`, flat.svg);
        ok++;
        if (flat.warnings.length) { warned++; console.error(`${name}: ${[...new Set(flat.warnings)].join(' / ')}`); }
      } catch (e) {
        failed++;
        console.error(`${name}: 変換失敗 ${e.message}`);
      }
    }
    console.log(`ok=${ok} failed=${failed} withWarnings=${warned} → ${outDir}`);
  } else {
    const [inFile, outFile, themeFile] = argv;
    const { svg } = render(readFileSync(inFile, 'utf8'));
    const flat = flatten(svg, themeOf(themeFile));
    writeFileSync(outFile, flat.svg);
    for (const w of new Set(flat.warnings)) console.error('warning:', w);
    console.log('wrote', outFile);
  }
}

const USAGE = `使い方:
  pele2svg input.mmd output.svg [theme.json]
  pele2svg --batch sources.json outdir [theme.json]`;

// 直接実行されたときだけ CLI を動かす (npm の bin はシンボリックリンクなので realpath で比較)
const isMain = (() => {
  try { return process.argv[1] && pathToFileURL(realpathSync(process.argv[1])).href === import.meta.url; }
  catch { return false; }
})();
if (isMain) {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === '-h' || args[0] === '--help') {
    console.log(USAGE);
    process.exit(args.length === 0 ? 1 : 0);
  }
  main(args);
}
