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
