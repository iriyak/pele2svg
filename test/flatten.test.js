// The tests render small diagrams written for this package with the real pele (MIT License, Copyright (c) 2026
// kepano, https://github.com/obsidianmd/pele), which is installed as a dependency, and convert the output.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { render } from 'pele';
import { flatten, resolveVars } from '../pele2svg.mjs';

const flow = `flowchart LR
  A[Mermaid text] --> B{Decision}
  B -->|yes| C((Done))`;

test('resolveVars: value, fallback, nested', () => {
  assert.equal(resolveVars('var(--a)', { '--a': 'red' }), 'red');
  assert.equal(resolveVars('var(--x,#fff)', {}), '#fff');
  assert.equal(resolveVars('var(--a)', { '--a': 'var(--b,blue)' }), 'blue');
});

test('flatten: no CSS-dependent constructs are left', () => {
  const { svg, warnings } = flatten(render(flow).svg);
  assert.deepEqual(warnings, []);
  assert.doesNotMatch(svg, /var\(/);
  assert.doesNotMatch(svg, /\sstyle="/);
  assert.doesNotMatch(svg, /<style/);
  assert.doesNotMatch(svg, /currentColor/);
  assert.doesNotMatch(svg, /color-mix/);
});

test('flatten: theme variables override the defaults', () => {
  const { svg } = flatten(render(flow).svg, { '--pele-surface': '#123456' });
  assert.match(svg, /fill="#123456"/);
});

const example = name => readFileSync(new URL(`../examples/${name}.mmd`, import.meta.url), 'utf8');

test('flatten: --gt-font-mono replaces monospace', () => {
  const raw = render(example('eventmodeling-1')).svg;
  // precondition: without a theme the generic name monospace remains (it reaches the SVG via var())
  assert.match(flatten(raw).svg, /font-family="monospace"/);
  const { svg } = flatten(raw, { '--gt-font-mono': 'Consolas' });
  assert.doesNotMatch(svg, /font-family="monospace"/);
  assert.match(svg, /font-family="Consolas"/);
});

test('flatten: nested <svg> (icons) become <g>', () => {
  const raw = render(example('architecture-2')).svg;
  assert.ok((raw.match(/<svg\b/g) || []).length > 1); // precondition: the original SVG contains nested <svg> elements
  const { svg } = flatten(raw);
  assert.equal((svg.match(/<svg\b/g) || []).length, 1);
  assert.match(svg, /<g[^>]*transform="translate\([^"]*\) scale\(/);
});

test('flatten: simple <style> class rules become attributes', () => {
  const src = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8"><defs><style>.a,.b{fill:#bb5938}</style></defs>'
    + '<path d="M0 0h5v5z" class="a"/><rect width="8" height="8" class="b" style="fill:red"/></svg>';
  const { svg, warnings } = flatten(src);
  assert.deepEqual(warnings, []);
  assert.doesNotMatch(svg, /<style|<defs/);
  assert.match(svg, /<path d="M0 0h5v5z" class="a" fill="#bb5938"\/>/);
  assert.match(svg, /class="b" fill="#ff0000"/); // the element's own style wins (red, as hex)
});

test('flatten: <style> rules that cannot be inlined are kept and reported', () => {
  const src = '<svg xmlns="http://www.w3.org/2000/svg"><style>@media print{.a{fill:red}} rect{fill:blue}</style><rect class="a"/></svg>';
  const { svg, warnings } = flatten(src);
  assert.match(svg, /<style/);
  assert.ok(warnings.some(w => /<style> left/.test(w)));
});

test('flatten: color keywords become hex (Skia knows only some, and only in lower case)', () => {
  const src = '<svg xmlns="http://www.w3.org/2000/svg"><rect width="8" height="8" style="fill:Purple;stroke:#FFF"/>'
    + '<circle r="2" style="fill:grey"/><path d="M0 0" fill="LightGray" stroke="transparent"/><rect fill="none" stroke="red"/></svg>';
  const { svg } = flatten(src);
  assert.match(svg, /fill="#800080"/);
  assert.match(svg, /stroke="#FFF"/); // hex values are left alone
  assert.match(svg, /fill="#808080"/); // grey, which Skia draws as black
  assert.match(svg, /fill="#d3d3d3" stroke="none"/); // LightGray; transparent
  assert.match(svg, /fill="none" stroke="#ff0000"/);
});
