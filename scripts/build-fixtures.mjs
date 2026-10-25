#!/usr/bin/env node
// Rebuild test/fixtures/{featured,docs,layout}.json from a local clone of the pele repo.
//
// It runs pele's own selection code (website/src/lib/examples.ts), the code that builds
// https://pele.run/examples, so the fixtures match what the site shows:
//
//   featured.json  exampleGroups()  the examples on the /examples page, up to two per diagram type
//                                    (name: <type>-<n>)
//   docs.json      examplePages()   "Documentation examples" of each /examples/<type> page,
//                                    from tests/corpus/<type>-docs.json (name: <type>-<nn>)
//   layout.json    examplePages()   the layout cases drawn first on each /examples/<type> page
//                                    (name: <type>-layout-<group>-<n>)
//
// reference.json (Pele's own conformance corpus) is not touched.
//
// Usage (from the pele2svg directory, after `npm install` there and in the pele repo):
//   node scripts/build-fixtures.mjs --pele <pele repo> [--pele2svg .] [--out test/fixtures]
//
// `exampleGroups` skips an example that Pele cannot draw, so it needs a renderer. The renderer is
// the `pele` package installed in pele2svg (the one the tests use), not the one in the clone.

import { createRequire } from 'node:module';
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const args = new Map();
for (let i = 2; i < process.argv.length; i += 2) args.set(process.argv[i].replace(/^--/, ''), process.argv[i + 1]);
const peleDir = args.get('pele');
if (!peleDir) {
  console.error('usage: node scripts/build-fixtures.mjs --pele <pele repo> [--pele2svg .] [--out test/fixtures]');
  process.exit(2);
}
const p2sDir = path.resolve(args.get('pele2svg') ?? '.');
const outDir = path.resolve(args.get('out') ?? path.join(p2sDir, 'test', 'fixtures'));

let esbuild;
for (const base of [path.join(peleDir, 'package.json'), import.meta.url]) {
  try { esbuild = createRequire(base)('esbuild'); break; } catch { /* try next */ }
}
if (!esbuild) { console.error('esbuild not found. Run `npm install` in the pele repo first.'); process.exit(1); }

// The renderer: the pele package installed next to pele2svg.
const peleRoot = path.join(p2sDir, 'node_modules', 'pele');
const peleManifest = JSON.parse(await readFile(path.join(peleRoot, 'package.json'), 'utf8'));
const { render } = await import(pathToFileURL(path.join(peleRoot, peleManifest.module ?? peleManifest.main)).href);
const draw = (source) => { try { return render(source).svg; } catch { return undefined; } };

// pele's selection code, bundled into one module.
const built = await esbuild.build({
  entryPoints: [path.join(peleDir, 'website', 'src', 'lib', 'examples.ts')],
  bundle: true, format: 'esm', platform: 'node', write: false, logLevel: 'error',
});
const { exampleGroups, examplePages } = await import('data:text/javascript;base64,' + Buffer.from(built.outputFiles[0].text).toString('base64'));

const corpusDir = path.join(peleDir, 'tests', 'corpus');
const corpora = {};
for (const name of (await readdir(corpusDir)).filter((n) => /-docs\.json$/.test(n)).sort()) {
  corpora[`${corpusDir}/${name}`] = JSON.parse(await readFile(path.join(corpusDir, name), 'utf8'));
}

const pad = (n, width) => String(n).padStart(width, '0');
const featured = exampleGroups(corpora, draw).flatMap((g) => g.sources.map((source, i) => ({ name: `${g.type}-${i + 1}`, source })));
const pages = examplePages(corpora);
const docs = pages.flatMap((p) => p.sources.map((source, i) => ({ name: `${p.type}-${pad(i + 1, 2)}`, source })));
const layout = pages.flatMap((p) => p.groups.flatMap((g) => g.cases.map((c, i) => ({ name: `${p.type}-layout-${g.slug}-${i + 1}`, source: c.source }))));

await mkdir(outDir, { recursive: true });
for (const [file, items] of Object.entries({ featured, docs, layout })) {
  await writeFile(path.join(outDir, `${file}.json`), JSON.stringify(items, null, 2) + '\n', 'utf8');
  console.log(`${file}.json: ${items.length} sources`);
}
console.log(`renderer: pele ${peleManifest.version}; written to ${outDir}`);
