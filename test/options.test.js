// Render options (--render-options) and math ($$...$$ typeset with MathJax). The tests render with the real pele.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { render } from 'pele';
import { flatten, peleOptions } from '../pele2svg.mjs';

const hasMathJax = await import('mathjax-full/js/mathjax.js').then(() => true, () => false);
const skipMath = hasMathJax ? false : 'mathjax-full is not installed (optional dependency)';

const sequence = `sequenceDiagram
  participant A as Customer service
  participant B as Billing
  A->>B: A rather long message that asks for the invoice
  B-->>A: ok`;

test('peleOptions: unknown keys are refused', async () => {
  await assert.rejects(peleOptions({ maxwidth: 360 }), /unknown render option\(s\): maxwidth/);
});

test('peleOptions: JSON options reach Pele (maxWidth makes a narrower layout)', async () => {
  const wide = render(sequence);
  const narrow = render(sequence, await peleOptions({ maxWidth: 360 }));
  assert.ok(narrow.width < wide.width, `${narrow.width} should be less than ${wide.width}`);
});

test('CLI: --render-options file.json', () => {
  const dir = mkdtempSync(join(tmpdir(), 'pele2svg-'));
  try {
    writeFileSync(join(dir, 'in.mmd'), sequence);
    writeFileSync(join(dir, 'o.json'), '{"maxWidth":360}');
    const script = fileURLToPath(new URL('../pele2svg.mjs', import.meta.url));
    execFileSync(process.execPath, [script, '--render-options', join(dir, 'o.json'), join(dir, 'in.mmd'), join(dir, 'narrow.svg')]);
    execFileSync(process.execPath, [script, join(dir, 'in.mmd'), join(dir, 'wide.svg')]);
    const width = f => Number(/viewBox="0 0 ([\d.]+)/.exec(readFileSync(join(dir, f), 'utf8'))[1]);
    assert.ok(width('narrow.svg') < width('wide.svg'));
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

const withMath = {
  flowchart: 'flowchart LR\n  A["Energy $$E=mc^2$$"] --> B["$$\\int_0^1 x^2\\,dx=\\frac13$$"]',
  sequence: 'sequenceDiagram\n  A->>B: $$x^2+y^2$$\n  B-->>A: ok',
  class: 'classDiagram\n  class Circle["$$\\pi r^2$$"]\n  Circle : +area()',
  state: 'stateDiagram-v2\n  [*] --> S1\n  S1: $$\\alpha+\\beta$$\n  S1 --> [*]',
  er: 'erDiagram\n  A ||--o{ B : "$$n^2$$"',
  mindmap: 'mindmap\n  root(("$$\\sqrt{x}$$"))\n    child',
  kanban: 'kanban\n  Todo\n    t1["$$\\frac{a}{b}$$"]',
  block: 'block-beta\n  columns 2\n  a["$$x_1$$"] b',
  requirement: 'requirementDiagram\n  requirement r1 {\n    id: 1\n    text: "$$E=mc^2$$"\n    risk: high\n    verifymethod: test\n  }',
  swimlane: 'swimlane-beta LR\n  subgraph L1\n    A["$$a^2$$"]\n    B[next]\n  end\n  A --> B',
  usecase: 'usecase-beta\ndirection LR\nactor U\nC("$$\\int f$$")\nU --> C',
};

for (const [type, source] of Object.entries(withMath)) {
  test(`math: $$...$$ is typeset in a ${type} diagram and converts cleanly`, { skip: skipMath }, async () => {
    const raw = render(source, await peleOptions({ math: true })).svg;
    assert.match(raw, /class="pele-math"/);
    assert.doesNotMatch(raw, /\$\$/);
    const { svg, warnings } = flatten(raw);
    assert.deepEqual(warnings, []);
    assert.doesNotMatch(svg, /\$\$/);
    assert.doesNotMatch(svg, /="[\d.]+ex"/);   // sizes are pixels, or the nested <svg> would be scaled by 8.7 instead of 70
    assert.doesNotMatch(svg, /<use\b/);        // glyphs are inline paths
    assert.doesNotMatch(svg, /stroke="(?!none)[^"]*" stroke-width="0"/); // Skia draws a stroke of width 0 as 1 px, so the glyphs would look bold
    assert.equal((svg.match(/<svg\b/g) || []).length, 1);
  });
}

test('math: without the option the TeX source stays', () => {
  const raw = render(withMath.flowchart).svg;
  assert.match(raw, /\$\$E=mc\^2\$\$/);
});

test('math: the formula keeps the foreground color of the theme', { skip: skipMath }, async () => {
  const raw = render(withMath.flowchart, await peleOptions({ math: true })).svg;
  const { svg } = flatten(raw, { '--pele-fg': '#123456' });
  assert.match(svg, /fill="#123456"/);
  assert.doesNotMatch(svg, /currentColor/);
});
