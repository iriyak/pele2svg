#!/usr/bin/env node
// Export the Mermaid sources behind every "All examples" page of pele.run (/examples/<type>)
// from a local clone of the pele repo, using pele's own code (website/src/lib/examples.ts)
// so that the result is the same as what the site builds.
//
// Usage:
//   node export-pele-examples.mjs --pele <pele repo> --out <output dir>
//
// Output layout (under --out):
//   <type>/layout-<group-slug>-<n>.mmd   layout cases (website/src/lib/layout-cases.ts)
//   <type>/doc-<n>.mmd                   documentation examples (tests/corpus/<type>-docs.json)
//   manifest.json                        index of every file with title, note, and kind
//
// Requires Node 18+ and `esbuild` resolvable from the pele repo (it already is, via vitest/vite).

import { createRequire } from 'node:module';
import { mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';

const args = new Map();
for (let i = 2; i < process.argv.length; i += 2) args.set(process.argv[i].replace(/^--/, ''), process.argv[i + 1]);
const peleDir = args.get('pele');
const outDir = args.get('out');
if (!peleDir || !outDir) {
  console.error('usage: node export-pele-examples.mjs --pele <pele repo> --out <output dir>');
  process.exit(2);
}

// esbuild: prefer the one in the pele repo, fall back to one next to this script.
let esbuild;
for (const base of [path.join(peleDir, 'package.json'), import.meta.url]) {
  try { esbuild = createRequire(base)('esbuild'); break; } catch { /* try next */ }
}
if (!esbuild) { console.error('esbuild not found. Run `npm install` in the pele repo first.'); process.exit(1); }

// Bundle examples.ts (it imports ./layout-cases) into one ES module and load it.
const built = await esbuild.build({
  entryPoints: [path.join(peleDir, 'website', 'src', 'lib', 'examples.ts')],
  bundle: true, format: 'esm', platform: 'node', write: false, logLevel: 'error',
});
const code = built.outputFiles[0].text;
const { examplePages } = await import('data:text/javascript;base64,' + Buffer.from(code).toString('base64'));

// Same input as website/src/lib/example-groups.ts: tests/corpus/*-docs.json keyed by path.
const corpusDir = path.join(peleDir, 'tests', 'corpus');
const corpora = {};
for (const name of (await readdir(corpusDir)).filter((n) => /-docs\.json$/.test(n)).sort()) {
  corpora[`${corpusDir}/${name}`] = JSON.parse(await readFile(path.join(corpusDir, name), 'utf8'));
}

const pages = examplePages(corpora);
const manifest = [];
const write = async (type, file, source, meta) => {
  const target = path.join(outDir, type, file);
  await mkdir(path.dirname(target), { recursive: true });
  await writeFile(target, source.trimEnd() + '\n', 'utf8');
  manifest.push({ type, file: `${type}/${file}`, ...meta });
};

// Start clean for the types we are about to write, so removed examples do not linger.
for (const page of pages) await rm(path.join(outDir, page.type), { recursive: true, force: true });

for (const page of pages) {
  for (const group of page.groups) {
    let n = 0;
    for (const item of group.cases) {
      await write(page.type, `layout-${group.slug}-${++n}.mmd`, item.source,
        { kind: 'layout', group: group.title, title: item.title, ...(item.note ? { note: item.note } : {}) });
    }
  }
  let n = 0;
  for (const source of page.sources) {
    await write(page.type, `doc-${++n}.mmd`, source, { kind: 'doc' });
  }
}

await mkdir(outDir, { recursive: true });
await writeFile(path.join(outDir, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n', 'utf8');

const counts = new Map();
for (const m of manifest) counts.set(m.type, (counts.get(m.type) ?? 0) + 1);
console.log(`wrote ${manifest.length} files for ${pages.length} types to ${outDir}`);
for (const [type, count] of counts) console.log(`  ${type}: ${count}`);
