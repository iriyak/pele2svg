// mermaidToSvg(): Mermaid text in, flattened SVG out (the library form of what the command line does). Uses the real pele.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mermaidToSvg } from '../pele2svg.mjs';

const hasMathJax = await import('mathjax-full/js/mathjax.js').then(() => true, () => false);
const skipMath = hasMathJax ? false : 'mathjax-full is not installed (optional dependency)';

const flow = 'flowchart LR\n  A --> B';
const sequence = `sequenceDiagram
  participant A as Customer service
  participant B as Billing
  A->>B: A rather long message that asks for the invoice
  B-->>A: ok`;
const width = svg => Number(/viewBox="0 0 ([\d.]+)/.exec(svg)[1]);

test('mermaidToSvg: converts a diagram to plain SVG with no warnings', async () => {
  const { svg, warnings } = await mermaidToSvg(flow);
  assert.deepEqual(warnings, []);
  assert.match(svg, /^<svg\b/);
  assert.doesNotMatch(svg, /var\(|<style\b|color-mix\(/);
});

test('mermaidToSvg: the theme reaches the output', async () => {
  const { svg } = await mermaidToSvg(flow, { theme: { '--pele-fg': '#123456' } });
  assert.match(svg, /#123456/);
});

test('mermaidToSvg: renderOptions reach Pele (maxWidth makes a narrower layout)', async () => {
  const wide = await mermaidToSvg(sequence);
  const narrow = await mermaidToSvg(sequence, { renderOptions: { maxWidth: 360 } });
  assert.ok(width(narrow.svg) < width(wide.svg));
});

test('mermaidToSvg: an unknown render option is refused', async () => {
  await assert.rejects(mermaidToSvg(flow, { renderOptions: { maxwidth: 360 } }), /unknown render option\(s\): maxwidth/);
});

test('mermaidToSvg: invalid Mermaid throws', async () => {
  await assert.rejects(mermaidToSvg('this is not a diagram ::'));
});

test('mermaidToSvg: $$...$$ is typeset with math: true and stays as TeX without it', { skip: skipMath }, async () => {
  const source = 'flowchart LR\n  A["Energy $$E=mc^2$$"] --> B';
  const typeset = await mermaidToSvg(source, { renderOptions: { math: true } });
  assert.deepEqual(typeset.warnings, []);
  assert.doesNotMatch(typeset.svg, /\$\$/);
  assert.match(typeset.svg, /<path\b/);
  const plain = await mermaidToSvg(source);
  assert.match(plain.svg, /\$\$E=mc\^2\$\$/);
});

test('mermaidToSvg: math: true costs nothing for a source without $$ (same SVG as without it)', async () => {
  const a = await mermaidToSvg(flow, { renderOptions: { math: true } });
  const b = await mermaidToSvg(flow);
  assert.equal(a.svg, b.svg);
});
