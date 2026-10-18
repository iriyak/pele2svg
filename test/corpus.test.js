// Corpus tests: run pele2svg over every Mermaid source in test/fixtures/ and check that the
// output is plain SVG, whatever the diagram type. See test/fixtures/README.md for the sources.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { render } from 'pele';
import { flatten } from '../pele2svg.mjs';

const here = new URL('.', import.meta.url);
const load = name => JSON.parse(readFileSync(new URL(`fixtures/${name}.json`, here), 'utf8'));
const corpora = { featured: load('featured'), docs: load('docs'), reference: load('reference') };
const theme = name => JSON.parse(readFileSync(new URL(`../themes/${name}.json`, here), 'utf8'));

// Constructs that a renderer without a CSS engine cannot handle.
const CSS_LEFTOVERS = {
  'var()': /var\(/,
  'style attribute': /\sstyle="/,
  '<style> element': /<style\b/i,
  currentColor: /currentColor/,
  'color-mix()': /color-mix\(/,
  '<a> element': /<a\b/,
  'external <image>': /<image\b[^>]*href="https?:/,
};

// A small well-formedness check: balanced tags, quoted attributes, no bare "&".
function xmlProblem(svg) {
  if (/&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/.test(svg)) return 'bare "&"';
  const stack = [];
  const tag = /<(\/?)([A-Za-z][\w:.-]*)((?:\s+[\w:.-]+="[^"]*")*)\s*(\/?)>/g;
  let last = 0, m;
  const bad = text => /</.test(text);
  while ((m = tag.exec(svg))) {
    if (bad(svg.slice(last, m.index).replace(/<!--[\s\S]*?-->/g, ''))) return `malformed markup near offset ${last}`;
    last = tag.lastIndex;
    const [, close, name, , selfClose] = m;
    if (close) { if (stack.pop() !== name) return `unbalanced </${name}>`; }
    else if (!selfClose) stack.push(name);
  }
  if (bad(svg.slice(last))) return 'malformed markup at the end';
  return stack.length ? `unclosed <${stack.at(-1)}>` : null;
}

// Problems of one converted example; [] when it is fine.
function problems(svg, warnings, allowedWarnings = []) {
  const found = [];
  for (const [what, re] of Object.entries(CSS_LEFTOVERS)) if (re.test(svg)) found.push(what);
  if ((svg.match(/<svg\b/g) || []).length !== 1) found.push('nested <svg>');
  const xml = xmlProblem(svg);
  if (xml) found.push(xml);
  for (const w of warnings) if (!allowedWarnings.includes(w)) found.push(`warning: ${w}`);
  return found;
}

// The only warning the examples are expected to raise: one flowchart example embeds an external image.
const EXPECTED_WARNINGS = ['removed an <image> with an external URL'];

for (const [corpus, items] of Object.entries(corpora)) {
  test(`${corpus} (${items.length} sources): converted output is plain, well-formed SVG`, () => {
    const failures = [];
    for (const { name, source } of items) {
      try {
        const { svg, warnings } = flatten(render(source).svg);
        for (const p of problems(svg, warnings, EXPECTED_WARNINGS)) failures.push(`${name}: ${p}`);
      } catch (e) {
        failures.push(`${name}: ${e.message.split('\n')[0]}`);
      }
    }
    assert.deepEqual(failures, []);
  });
}

test('flatten is idempotent: converting converted output changes nothing', () => {
  const failures = [];
  for (const { name, source } of [...corpora.featured, ...corpora.docs]) {
    const once = flatten(render(source).svg).svg;
    if (flatten(once).svg !== once) failures.push(name);
  }
  assert.deepEqual(failures, []);
});

for (const name of readdirSync(new URL('../themes/', here)).filter(f => f.endsWith('.json')).map(f => f.slice(0, -5))) {
  test(`theme ${name}: every featured example still converts cleanly`, () => {
    const vars = theme(name);
    const failures = [];
    for (const { name: id, source } of corpora.featured) {
      const { svg, warnings } = flatten(render(source).svg, vars);
      for (const p of problems(svg, warnings, EXPECTED_WARNINGS)) failures.push(`${id}: ${p}`);
      for (const [key, generic] of [['--gt-font-mono', 'monospace'], ['--gt-font-sans', 'sans-serif'], ['--gt-font-serif', 'serif']]) {
        if (vars[key] && svg.includes(`font-family="${generic}"`)) failures.push(`${id}: font-family="${generic}" not replaced`);
      }
    }
    assert.deepEqual(failures, []);
  });
}

test('theme color overrides reach every featured example', () => {
  const failures = [];
  for (const { name, source } of corpora.featured) {
    const { svg } = flatten(render(source).svg, { '--pele-fg': '#123abc' });
    if (!svg.includes('#123abc')) failures.push(name);
  }
  assert.deepEqual(failures, []);
});

test('CLI --batch converts a whole corpus file', () => {
  const dir = mkdtempSync(join(tmpdir(), 'pele2svg-'));
  try {
    const script = fileURLToPath(new URL('../pele2svg.mjs', here));
    const list = fileURLToPath(new URL('fixtures/featured.json', here));
    const out = execFileSync(process.execPath, [script, '--batch', list, dir], { encoding: 'utf8' });
    assert.match(out, new RegExp(`ok=${corpora.featured.length} failed=0 `));
    assert.equal(readdirSync(dir).length, corpora.featured.length);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
