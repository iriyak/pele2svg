# When Pele has a new version

A checklist for refreshing pele2svg after a new release of [pele](https://github.com/obsidianmd/pele). Everything except the last two steps runs in a terminal; GToolkit is needed only for step 6.

Paths below are relative to the pele2svg clone. `<pele>` is your clone of pele.

## 1. Update the renderer

```
npm update
npm ls pele          # note the new version
```

The fixtures are always rendered with the pele in `node_modules`, so this version is the one that counts.

## 2. Update the pele clone

```
git -C <pele> pull
```

The clone is the source of the example diagrams (`website/src/lib/examples.ts`, `layout-cases.ts`, `tests/corpus/*-docs.json`). It is not the renderer.

## 3. Rebuild the fixtures

```
node scripts/build-fixtures.mjs --pele <pele>
```

This rewrites `test/fixtures/featured.json`, `docs.json` and `layout.json`. `reference.json` is never touched. Read the log: the counts of featured, docs and layout examples tell you whether pele added or removed diagrams.

`scripts/export-pele-examples.mjs` is the lower-level step (one `.mmd` file per example into `test/fixtures/pele-examples/`, git-ignored). Run it only when you want to look at the sources as files.

## 4. Run the tests

```
npm test
```

`test/corpus.test.js` converts every example and checks that nothing CSS-dependent is left and that converting twice changes nothing. If a new pele emits a construct that pele2svg does not flatten, it shows up here (a warning or a failed assertion); fix `pele2svg.mjs` and add a case to `test/flatten.test.js`.

## 5. Update what depends on the numbers

- `README.md`, `docs/development.md` and `test/fixtures/README.md` state the number of examples and the pele version.
- `test/fixtures/README.md` says which pele version produced the fixtures.

## 6. Keep the Pharo side in step (needs GToolkit)

- The 58 featured examples of `Pele2svgFeaturedExamples` are methods named `<type><n>`. `Pele2svgExamplesTest` fails when a featured example is added, removed or changed in the fixture, so run it and add or remove the methods it names.
- Run the whole `Pele2svg-Tests` package and all gtExamples.
- Optional: open the examples in the gallery (below).

## 7. Look at the result (optional but cheap)

The gallery shows, for every example, what a browser draws from pele's own SVG next to what Skia draws from the converted SVG. It lives in `out/` (git-ignored) and is rebuilt from the fixtures:

1. `node scripts/gallery-svgs.mjs`: raw and converted SVGs (`out/gallery/raw`, `out/gallery/svg`), converted with `themes/gt-windows.json`.
2. In GToolkit, run `Pele2svgExamples exportGalleryPngs`. It draws every converted SVG with Skia into `out/gallery/skia/<name>.png` at 2x on a white background and writes `out/gallery/skia-metrics.json`; it answers the number of failures and takes about 20 minutes (`[ Pele2svgExamples exportGalleryPngs ] fork` keeps the image usable).
3. `node scripts/gallery-index.mjs`: `index.html` with filters; examples that Skia drew differently (failure, size, nothing drawn) are flagged. Open `out/gallery/index.html`.
4. Optional: `python3 -I scripts/gallery-compare.py` draws every raw SVG in Chromium and compares it with the Skia PNG in 8x8 pixel blocks (it needs numpy, pillow and playwright with Chromium); the result is `out/gallery/compare/compare.json`.

Things that are known to differ and are not bugs of pele2svg: external images are removed, emoji in text may lose bold or shift the following text, and glyphs missing from the font (for example ♥) are drawn as boxes.

## 8. Commit

One commit for the fixtures (they are large and mechanical), one for code changes. The renderer version goes into the message.
