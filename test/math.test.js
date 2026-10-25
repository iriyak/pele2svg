// A formula on its own: mathToSvg() and the --math / --math-batch commands (MathJax 3, optional dependency).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { mathToSvg } from '../pele2svg.mjs';

const hasMathJax = await import('mathjax-full/js/mathjax.js').then(() => true, () => false);
const skip = hasMathJax ? false : 'mathjax-full is not installed (optional dependency)';
const script = fileURLToPath(new URL('../pele2svg.mjs', import.meta.url));

const formulas = {
  tex: '\\int_0^1 x^2\\,dx=\\frac13',
  mathml: '<math><mfrac><mi>a</mi><mi>b</mi></mfrac></math>',
  asciimath: 'sum_(i=1)^n i^3=((n(n+1))/2)^2',
};

for (const [format, source] of Object.entries(formulas)) {
  test(`mathToSvg: ${format} gives plain SVG that is as big as its pixel size`, { skip }, async () => {
    const { svg, width, height } = await mathToSvg(source, { format });
    assert.equal((svg.match(/<svg\b/g) || []).length, 1);
    assert.match(svg, new RegExp(`^<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`));
    assert.doesNotMatch(svg, /currentColor|<use\b|<style\b|="[\d.]+ex"/);
    assert.doesNotMatch(svg, /stroke="(?!none)[^"]*" stroke-width="0"/);
    assert.ok(width > 0 && height > 0);
  });
}

test('mathToSvg: color, size and display', { skip }, async () => {
  const plain = await mathToSvg('E=mc^2');
  assert.match(plain.svg, /fill="#000000"/);
  const blue = await mathToSvg('E=mc^2', { color: '#205ea6' });
  assert.match(blue.svg, /fill="#205ea6"/);
  const big = await mathToSvg('E=mc^2', { size: 32 });
  assert.ok(Math.abs(big.width / plain.width - 2) < 0.01);
  const display = await mathToSvg('\\sum_{i=1}^n i', { display: true });
  const inline = await mathToSvg('\\sum_{i=1}^n i');
  assert.ok(display.height > inline.height);
});

test('mathToSvg: errors are thrown', { skip }, async () => {
  await assert.rejects(mathToSvg('\\frac{'), /Missing close brace/);
  await assert.rejects(mathToSvg('x', { format: 'latex' }), /unknown math format: latex/);
});

test('CLI: --math and --math-batch', { skip }, () => {
  const dir = mkdtempSync(join(tmpdir(), 'pele2svg-'));
  try {
    writeFileSync(join(dir, 'f.txt'), 'E=mc^2\n');
    execFileSync(process.execPath, [script, '--math', '--display', '--size', '24', '--color', '#205ea6', join(dir, 'f.txt'), join(dir, 'f.svg')]);
    assert.match(readFileSync(join(dir, 'f.svg'), 'utf8'), /fill="#205ea6"/);
    writeFileSync(join(dir, 'l.json'), JSON.stringify([
      { name: 'a', source: 'x^2' },
      { name: 'b', source: formulas.mathml, format: 'mathml' },
      { name: 'c', source: '\\frac{' },
    ]));
    execFileSync(process.execPath, [script, '--math-batch', join(dir, 'l.json'), join(dir, 'out')], { stdio: 'pipe' });
    assert.deepEqual(readdirSync(join(dir, 'out')).sort(), ['a.svg', 'b.svg']);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
