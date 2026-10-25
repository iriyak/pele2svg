// Step 1 of the example gallery (docs/pele-upgrade.md); the gallery itself is written to out/ (git-ignored).
// For every source in test/fixtures/{featured,docs,layout}.json write
//   raw/<name>.svg   what Pele draws (needs a browser: CSS variables)
//   svg/<name>.svg   after pele2svg's flatten, with themes/gt-windows.json (what Skia gets)
//   data.json        one entry per example: corpus, type, name, size, warnings, or the error
// Run from anywhere: node scripts/gallery-svgs.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { render } from 'pele';
import { flatten } from '../pele2svg.mjs';

const root = new URL('../', import.meta.url);
const here = new URL('out/gallery/', root);
const theme = JSON.parse(readFileSync(new URL('themes/gt-windows.json', root), 'utf8'));
const dir = (name) => { const url = new URL(`${name}/`, here); mkdirSync(fileURLToPath(url), { recursive: true }); return url; };
const rawDir = dir('raw');
const svgDir = dir('svg');

const data = [];
for (const corpus of ['featured', 'docs', 'layout']) {
  const items = JSON.parse(readFileSync(new URL(`test/fixtures/${corpus}.json`, root), 'utf8'));
  for (const { name, source } of items) {
    const entry = { corpus, type: name.split('-')[0], name };
    try {
      const raw = render(source).svg;
      const { svg, warnings } = flatten(raw, theme);
      writeFileSync(new URL(`${name}.svg`, rawDir), raw);
      writeFileSync(new URL(`${name}.svg`, svgDir), svg);
      const box = svg.match(/viewBox="[\d.\-]+ [\d.\-]+ ([\d.]+) ([\d.]+)"/);
      entry.width = box ? Number(box[1]) : null;
      entry.height = box ? Number(box[2]) : null;
      if (warnings.length) entry.warnings = warnings;
    } catch (e) {
      entry.error = String(e.message).split('\n')[0];
    }
    data.push(entry);
  }
}
writeFileSync(new URL('data.json', here), JSON.stringify(data, null, 1));
console.log(`${data.length} examples, ${data.filter((e) => e.error).length} errors`);
