// Step 3 of the example gallery (docs/pele-upgrade.md); the gallery itself is in out/gallery (git-ignored).
// Reads data.json (gallery-svgs.mjs) and skia-metrics.json (Pele2svgExamples class >> exportGalleryPngs) and writes index.html:
// for every example, what a browser draws from Pele's own SVG (raw/) next to what Skia draws (skia/).
// Run: node scripts/gallery-index.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const here = new URL('../out/gallery/', import.meta.url);
const data = JSON.parse(readFileSync(new URL('data.json', here), 'utf8'));
const metrics = JSON.parse(readFileSync(new URL('skia-metrics.json', here), 'utf8'));
const byName = new Map(metrics.results.map(([name, width, height, opaque]) => [name, { width, height, opaque }]));
const failed = new Map(metrics.errors.map(([name, message]) => [name, message]));

// Reasons to look at an example first.
function flags(entry) {
  const found = [];
  const m = byName.get(entry.name);
  if (failed.has(entry.name)) found.push(`Skia failed: ${failed.get(entry.name)}`);
  else if (!m) found.push('not rendered by Skia');
  else {
    if (m.opaque !== null && m.opaque < 0.005) found.push('Skia drew (almost) nothing');
    if (entry.width && (Math.abs(m.width - entry.width) > 1 || Math.abs(m.height - entry.height) > 1)) found.push(`size ${m.width}x${m.height} differs from viewBox ${entry.width}x${entry.height}`);
  }
  for (const w of entry.warnings ?? []) found.push(w);
  return found;
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const rows = data.map((entry) => ({ entry, flags: flags(entry) }));
const types = [...new Set(data.map((e) => e.type))];
const flagged = rows.filter((r) => r.flags.length).length;

const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pele examples: browser and Skia</title>
<style>
  :root { --bg:#fffcf0; --fg:#100f0f; --muted:#6f6e69; --line:#cecdc3; --card:#f2f0e5; --warn:#b74583; }
  @media (prefers-color-scheme: dark) { :root { --bg:#1c1b1a; --fg:#cecdc3; --muted:#878580; --line:#403e3c; --card:#282726; --warn:#ce5d97; } }
  body { margin:0; background:var(--bg); color:var(--fg); font:15px/1.5 system-ui, sans-serif; }
  header { position:sticky; top:0; z-index:1; background:var(--bg); border-bottom:1px solid var(--line); padding:10px 16px; display:flex; flex-wrap:wrap; gap:12px; align-items:center; }
  header h1 { font-size:17px; margin:0 12px 0 0; }
  select, label { font:inherit; color:inherit; }
  select { background:var(--card); border:1px solid var(--line); border-radius:6px; padding:2px 6px; }
  main { padding:8px 16px 48px; }
  section { border-bottom:1px solid var(--line); padding:12px 0; }
  section h2 { font-size:14px; margin:0 0 8px; font-weight:600; }
  section h2 small { color:var(--muted); font-weight:400; margin-left:8px; }
  .flags { color:var(--warn); font-size:13px; margin:0 0 8px; }
  .pair { display:grid; grid-template-columns:repeat(auto-fit, minmax(min(100%, 360px), 1fr)); gap:12px; }
  figure { margin:0; overflow:auto; background:#fff; border:1px solid var(--line); border-radius:6px; padding:8px; }
  figcaption { color:#6f6e69; font-size:12px; margin-bottom:4px; }
  figure img { display:block; max-width:none; }
  [hidden] { display:none; }
</style></head><body>
<header>
  <h1>Pele examples: browser and Skia</h1>
  <label>Corpus <select id="corpus"><option value="">all</option>${['featured', 'docs', 'layout'].map((c) => `<option>${c}</option>`).join('')}</select></label>
  <label>Type <select id="type"><option value="">all</option>${types.map((t) => `<option>${esc(t)}</option>`).join('')}</select></label>
  <label><input type="checkbox" id="flagged"> only flagged (${flagged})</label>
  <span id="count" style="color:var(--muted)"></span>
</header>
<main>
${rows.map(({ entry, flags: f }) => `<section data-corpus="${entry.corpus}" data-type="${esc(entry.type)}" data-flagged="${f.length ? 1 : 0}" id="${esc(entry.name)}">
  <h2>${esc(entry.name)}<small>${entry.corpus}${entry.width ? ` · ${entry.width}×${entry.height}` : ''}</small></h2>
  ${f.length ? `<p class="flags">${f.map(esc).join(' / ')}</p>` : ''}
  <div class="pair">
    <figure><figcaption>Pele in the browser (raw SVG)</figcaption><img loading="lazy" src="raw/${esc(entry.name)}.svg" alt="${esc(entry.name)} drawn by the browser"></figure>
    <figure><figcaption>Skia in GToolkit (converted SVG)</figcaption><img loading="lazy" src="skia/${esc(entry.name)}.png"${entry.width ? ` width="${entry.width}"` : ''} alt="${esc(entry.name)} drawn by Skia"></figure>
  </div>
</section>`).join('\n')}
</main>
<script>
  const sections = [...document.querySelectorAll('section')];
  const corpus = document.getElementById('corpus'), type = document.getElementById('type'), flagged = document.getElementById('flagged');
  function apply() {
    let shown = 0;
    for (const s of sections) {
      const visible = (!corpus.value || s.dataset.corpus === corpus.value) && (!type.value || s.dataset.type === type.value) && (!flagged.checked || s.dataset.flagged === '1');
      s.hidden = !visible; if (visible) shown++;
    }
    document.getElementById('count').textContent = shown + ' of ' + sections.length;
  }
  for (const control of [corpus, type, flagged]) control.addEventListener('change', apply);
  apply();
</script>
</body></html>
`;
writeFileSync(new URL('index.html', here), html);
console.log(`index.html: ${rows.length} examples, ${flagged} flagged`);
