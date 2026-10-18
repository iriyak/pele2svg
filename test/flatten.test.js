import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { render } from 'pele';
import { flatten, resolveVars } from '../pele2svg.mjs';

const flow = `flowchart LR
  A[Mermaid text] --> B{Decision}
  B -->|yes| C((Done))`;

test('resolveVars: 値あり・フォールバック・入れ子', () => {
  assert.equal(resolveVars('var(--a)', { '--a': 'red' }), 'red');
  assert.equal(resolveVars('var(--x,#fff)', {}), '#fff');
  assert.equal(resolveVars('var(--a)', { '--a': 'var(--b,blue)' }), 'blue');
});

test('flatten: CSS 依存の記述が残らない', () => {
  const { svg, warnings } = flatten(render(flow).svg);
  assert.deepEqual(warnings, []);
  assert.doesNotMatch(svg, /var\(/);
  assert.doesNotMatch(svg, /\sstyle="/);
  assert.doesNotMatch(svg, /<style/);
  assert.doesNotMatch(svg, /currentColor/);
  assert.doesNotMatch(svg, /color-mix/);
});

test('flatten: テーマ変数を上書きできる', () => {
  const { svg } = flatten(render(flow).svg, { '--pele-surface': '#123456' });
  assert.match(svg, /fill="#123456"/);
});

const example = name => readFileSync(new URL(`../examples/${name}.mmd`, import.meta.url), 'utf8');

test('flatten: monospace を --gt-font-mono で置き換える', () => {
  const raw = render(example('eventmodeling-1')).svg;
  // 前提: 何も指定しなければ総称名 monospace が残る (元の SVG では var() 経由)
  assert.match(flatten(raw).svg, /font-family="monospace"/);
  const { svg } = flatten(raw, { '--gt-font-mono': 'Consolas' });
  assert.doesNotMatch(svg, /font-family="monospace"/);
  assert.match(svg, /font-family="Consolas"/);
});

test('flatten: 入れ子 <svg>(アイコン)が <g> になる', () => {
  const raw = render(example('architecture-2')).svg;
  assert.ok((raw.match(/<svg\b/g) || []).length > 1); // 前提: 元の SVG は入れ子 <svg> を持つ
  const { svg } = flatten(raw);
  assert.equal((svg.match(/<svg\b/g) || []).length, 1);
  assert.match(svg, /<g[^>]*transform="translate\([^"]*\) scale\(/);
});
