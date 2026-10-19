#!/usr/bin/env node
// pele2svg.mjs — convert SVG produced by pele (a Mermaid renderer) into plain SVG that
// renderers without a CSS engine can draw (Skia's SVG module, GToolkit's BlSkiaSvgElement, ...).
//
// pele writes colors and fonts as CSS (custom properties, style attributes, color-mix(), ...).
// This script rewrites all of it as SVG presentation attributes:
//   1. CSS variables  var(--x, fallback)         -> the actual value (themes can override --pele-*)
//   2. style on the root <svg> (font: ...)       -> font-family / font-size attributes
//   3. style="fill:..;stroke:..;rx:.."           -> attributes of the same name
//                                                   (CSS beats attributes, so existing ones are replaced)
//   4. currentColor                              -> the foreground color (--pele-fg)
//   5. color-mix(in srgb, A p%, B)               -> a computed #rrggbb
//   6. nested <svg class="pele-icon" ...>        -> <g transform="translate() scale()">
//   7. <a href=...>                              -> <g>  (links are useless in a Skia view)
//   8. <image href="http...">                    -> removed (cannot be fetched by the renderer)
//   9. font-family="monospace" and other generic -> the real font names given by
//      family names                                 --gt-font-mono / --gt-font-sans / --gt-font-serif
//  10. <style> rules  .name{...}              -> style attribute of the elements with that class (then step 3)
//
// Usage:
//   node pele2svg.mjs input.mmd output.svg [theme.json]
//   node pele2svg.mjs --batch sources.json outdir [theme.json]
//       sources.json = [{"name":"flowchart-1","source":"flowchart LR\n A-->B"}, ...]
// theme.json example: {"--pele-bg":"#fffcf0","--pele-fg":"#100f0f","--pele-accent":"#205ea6",
//                      "--gt-font-mono":"Consolas"}
import { readFileSync, writeFileSync, mkdirSync, realpathSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// ---------- var() ----------
// var(--name) / var(--name, fallback). The fallback may contain one level of parentheses, e.g. rgb(...).
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

// ---------- colors ----------
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

// color-mix(in srgb, A p%, B q%)  (plain linear interpolation in sRGB; opaque colors only)
const MIX_RE = /color-mix\(\s*in\s+srgb\s*,\s*((?:#[0-9a-fA-F]{3,6}|rgb\([^)]*\)|[a-z]+))(?:\s+([\d.]+)%)?\s*,\s*((?:#[0-9a-fA-F]{3,6}|rgb\([^)]*\)|[a-z]+))(?:\s+([\d.]+)%)?\s*\)/g;
function resolveColorMix(str, warnings) {
  return str.replace(MIX_RE, (whole, c1, p1, c2, p2) => {
    const a = parseColor(c1), b = parseColor(c2);
    if (!a || !b) { warnings.push(`cannot resolve color-mix: ${whole}`); return whole; }
    let w1 = p1 !== undefined ? +p1 : p2 !== undefined ? 100 - +p2 : 50;
    let w2 = p2 !== undefined ? +p2 : 100 - w1;
    const sum = w1 + w2; w1 /= sum; w2 /= sum;
    return hex(a.map((v, i) => v * w1 + b[i] * w2));
  });
}

// ---------- per-tag processing ----------
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
    if (k >= 0) out.splice(k, 1); // CSS wins over attributes, so an existing attribute of the same name is replaced
    out.push([name, value]);
  }
  return out;
}

// nested <svg x y width height viewBox>  ->  <g transform>
function nestedSvgToG(attrs) {
  const get = n => attrs.find(([k]) => k === n)?.[1];
  const vb = get('viewBox')?.trim().split(/[\s,]+/).map(Number);
  const x = parseFloat(get('x') ?? 0), y = parseFloat(get('y') ?? 0);
  const w = parseFloat(get('width')), h = parseFloat(get('height'));
  let t = `translate(${x} ${y})`;
  if (vb && vb.length === 4 && w > 0 && h > 0) {
    const s = Math.min(w / vb[2], h / vb[3]); // equivalent to preserveAspectRatio=xMidYMid meet
    const dx = (w - vb[2] * s) / 2 - vb[0] * s, dy = (h - vb[3] * s) / 2 - vb[1] * s;
    t = `translate(${+(x + dx).toFixed(4)} ${+(y + dy).toFixed(4)}) scale(${+s.toFixed(6)})`;
  }
  const drop = new Set(['x', 'y', 'width', 'height', 'viewBox', 'xmlns', 'preserveAspectRatio']);
  const rest = attrs.filter(([k]) => !drop.has(k));
  return [...rest, ['transform', t]];
}

// <style> rules of the form  .name { declarations }  (also  .a, .b { ... })  -> added to the style attribute of
// every element that has the class (the element's own style stays last, so it wins). The <style> element is
// removed when all its rules were of that simple form; anything else (tag or id selectors, @media, ...) is kept
// and reported by the final check.
function inlineClassRules(svg) {
  const sheets = [...svg.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/g)];
  if (!sheets.length) return svg;
  const rules = [];
  let simple = true;
  for (const [, css] of sheets) {
    const text = css.replace(/\/\*[\s\S]*?\*\//g, '').replace(/<!\[CDATA\[|\]\]>/g, '');
    if (text.includes('@')) { simple = false; continue; }
    for (const m of text.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const classes = [];
      for (const sel of m[1].split(',').map(x => x.trim())) {
        if (/^\.[\w-]+$/.test(sel)) classes.push(sel.slice(1)); else simple = false;
      }
      if (classes.length) rules.push({ classes, decls: m[2].trim().replace(/;$/, '') });
    }
    if (text.replace(/[^{}]+\{[^{}]*\}/g, '').trim() !== '') simple = false;
  }
  if (rules.length) {
    svg = svg.replace(TAG_RE, (m, tag, a, selfClose) => {
      const attrs = parseAttrs(a);
      const cls = attrs.find(([k]) => k === 'class')?.[1].split(/\s+/);
      if (!cls) return m;
      const decls = rules.filter(r => r.classes.some(x => cls.includes(x))).map(r => r.decls);
      if (!decls.length) return m;
      const i = attrs.findIndex(([k]) => k === 'style');
      if (i >= 0) decls.push(attrs[i][1]); else attrs.push(['style', '']);
      attrs[i >= 0 ? i : attrs.length - 1][1] = decls.join(';');
      return `<${tag}${buildAttrs(attrs)}${selfClose ? '/' : ''}>`;
    });
  }
  if (simple) svg = svg.replace(/<style\b[^>]*>[\s\S]*?<\/style>/g, '').replace(/<defs>\s*<\/defs>/g, '');
  return svg;
}

export function flatten(svg, theme = {}) {
  const warnings = [];
  const vars = { ...theme };

  // 1. Collect custom properties from the style of the root <svg>
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
    // a raw " inside an attribute value is invalid XML, so escape it as &quot;
    svg = svg.replace(/^(<svg\b[^>]*?)\sstyle="[^"]*"/,
      `$1 font-family="${fontFamily.replace(/"/g, '&quot;')}" font-size="16"`);
  }
  svg = inlineClassRules(svg);
  const fg = vars['--_fg'] ?? vars['--pele-fg'] ?? '#000000';

  // 2. Resolve every remaining var(), and turn currentColor into the foreground color
  svg = resolveVars(svg, vars);
  svg = svg.replace(/currentColor/g, fg);

  // 3. Nested <svg> (icons) -> <g>: pair every non-root <svg ...> with its </svg>
  let depth = 0;
  svg = svg.replace(/<svg\b((?:\s+[\w:-]+="[^"]*")*)\s*>|<\/svg>/g, (m, a) => {
    if (m === '</svg>') return --depth === 0 ? m : '</g>';
    return depth++ === 0 ? m : `<g${buildAttrs(nestedSvgToG(parseAttrs(a)))}>`;
  });

  // 4. style -> attributes, tag by tag
  svg = svg.replace(TAG_RE, (m, tag, a, selfClose) => {
    if (!/\sstyle="/.test(a)) return m;
    return `<${tag}${buildAttrs(styleToAttrs(parseAttrs(a)))}${selfClose ? '/' : ''}>`;
  });

  // 5. color-mix()
  svg = resolveColorMix(svg, warnings);

  // 6. <a> -> <g>
  svg = svg.replace(/<a\b((?:\s+[\w:-]+="[^"]*")*)\s*>/g, '<g>').replace(/<\/a>/g, '</g>');

  // 7. <image> with an external URL
  svg = svg.replace(/<image\b[^>]*\shref="https?:[^"]*"[^>]*\/>|<image\b[^>]*\shref="https?:[^"]*"[^>]*>\s*<\/image>/g, () => {
    warnings.push('removed an <image> with an external URL');
    return '';
  });

  // 7b. Generic font family names -> real font names
  //     Skia's SVG module may not resolve generic names such as monospace / sans-serif.
  //     Pass --gt-font-mono / --gt-font-sans / --gt-font-serif in the theme to replace them.
  //     (Skia may treat font-family as a single name, so give one name rather than a fallback list.)
  const generic = {
    monospace: vars['--gt-font-mono'],
    'sans-serif': vars['--gt-font-sans'],
    serif: vars['--gt-font-serif'],
  };
  svg = svg.replace(/font-family="([^"]*)"/g, (m, f) => {
    const to = generic[f.trim()];
    return to ? `font-family="${to.replace(/"/g, '&quot;')}"` : m;
  });

  // 8. Check for anything left behind
  if (/var\(/.test(svg)) warnings.push('unresolved var() left in the output');
  if (/<style\b/i.test(svg)) warnings.push('<style> left in the output');
  if (/color-mix\(/.test(svg)) warnings.push('color-mix() left in the output');
  return { svg, warnings };
}

// ---------- CLI ----------
async function main(argv) {
  const themeOf = f => (f ? JSON.parse(readFileSync(f, 'utf8')) : {});
  if (argv[0] === '--svg') {
    // Post-process an SVG that Pele has already produced (Pele itself is not needed)
    const [, inFile, outFile, themeFile] = argv;
    if (!inFile || !outFile) throw new Error(USAGE);
    const input = readFileSync(inFile, 'utf8');
    const flat = flatten(input, themeOf(themeFile));
    writeFileSync(outFile, flat.svg);
    for (const w of new Set(flat.warnings)) console.error('warning:', w);
    if (flat.svg === input) console.error('note: nothing to change; is this an SVG made by Pele?');
    console.log('wrote', outFile);
    return;
  }
  const { render } = await import('pele');
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
        console.error(`${name}: conversion failed: ${e.message}`);
      }
    }
    console.log(`ok=${ok} failed=${failed} withWarnings=${warned} -> ${outDir}`);
  } else {
    const [inFile, outFile, themeFile] = argv;
    const { svg } = render(readFileSync(inFile, 'utf8'));
    const flat = flatten(svg, themeOf(themeFile));
    writeFileSync(outFile, flat.svg);
    for (const w of new Set(flat.warnings)) console.error('warning:', w);
    console.log('wrote', outFile);
  }
}

const USAGE = `Usage:
  pele2svg input.mmd output.svg [theme.json]
  pele2svg --svg input.svg output.svg [theme.json]
  pele2svg --batch sources.json outdir [theme.json]`;

// Run the CLI only when executed directly (npm bins are symlinks, so compare real paths)
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
  main(args).catch(e => {
    // one readable line instead of a Node stack trace (also useful when called from another program)
    console.error(`pele2svg: ${e && e.message ? e.message : e}`);
    process.exit(1);
  });
}
