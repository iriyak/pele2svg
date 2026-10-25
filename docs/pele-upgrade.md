# When Pele has a new version

A checklist for refreshing pele2svg after a new release of [pele](https://github.com/obsidianmd/pele).

| Steps | Where | Takes |
|---|---|---|
| 1 to 5: renderer, fixtures, tests, numbers, `examples/` | a terminal (Node.js or Bun) | minutes |
| 6: the Pharo side | GToolkit | minutes |
| 7: the gallery (look at every example) | terminal and GToolkit, alternately | about 30 minutes, mostly waiting |
| 8: commit | git | |

Paths are relative to the pele2svg clone. `<pele>` is your clone of pele.

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

`test/corpus.test.js` converts every example and checks that nothing CSS-dependent is left and that converting twice changes nothing. If a new pele emits a construct that pele2svg does not flatten, it shows up here (a warning or a failed assertion): fix `pele2svg.mjs` and add a case to `test/flatten.test.js`.

## 5. Update what depends on the numbers and the version

- `README.md`, `docs/development.md` and `test/fixtures/README.md` state the number of examples and the pele version.
- `examples/README.md` states the pele version of the three SVGs. Make them again (the sources do not change; the third argument is the theme):

  ```
  node pele2svg.mjs examples/<name>.mmd examples/<name>.svg themes/gt-windows.json
  ```

  for `eventmodeling-1`, `sequence-1` and `architecture-2`. Compare with the old files: a new pele may change them.

## 6. Keep the Pharo side in step (needs GToolkit)

- The 58 featured examples of `Pele2svgFeaturedExamples` are methods named `<type><n>`. `Pele2svgExamplesTest` fails when a featured example is added, removed or changed in the fixture, so run it and add or remove the methods it names.
- Run the whole `Pele2svg-Tests` package and all gtExamples.

## 7. Look at the result with the gallery

The gallery shows, for every example, what a browser draws from pele's own SVG next to what Skia draws from the converted SVG. It is made in `out/gallery` (git-ignored) from the fixtures. Run the steps in this order; each one needs the output of the one before.

| | Command | Where | Makes |
|---|---|---|---|
| a | `node scripts/gallery-svgs.mjs` | terminal | `raw/` (pele's SVG), `svg/` (converted with `themes/gt-windows.json`), `data.json` |
| b | `Pele2svgExamples exportGalleryPngs` | GToolkit, about 20 minutes (`[ ... ] fork` keeps the image usable) | `skia/<name>.png` at 2x on white, `skia-metrics.json` |
| c | `node scripts/gallery-index.mjs` | terminal | `index.html` |
| d | `Pele2svgExamples openGallery` | GToolkit | opens `index.html` in a WebView2 window |

If you run **d** too early, it tells you what is missing and in which order to run the steps: `Pele2svgExamples galleryUrl` signals `Pele2svgError` listing a, b and c and marking the ones whose output exists. Run **d** by itself when nothing changed and you only want to look again.

Optional: `python3 -I scripts/gallery-compare.py` draws every raw SVG in Chromium and compares it with the Skia PNG in 8x8 pixel blocks (it needs numpy, pillow and playwright with Chromium). The result, `out/gallery/compare/compare.json`, has the difference of every example (`mean` and `bad`, 0 is identical), so sort it by `mean` to see the largest first; with the 659 examples of Pele 1.10.0 the median was 0.0026.

### What to look for

- The flagged examples (use *only flagged*): Skia failed, drew nothing, or the size differs from the viewBox. With 1.10.0 two are flagged and both are expected: `flowchart-70` (the external image is removed) and `gantt-07` (pele draws nothing either).
- Anything that is not in the list below: a color that is black or missing, text that is cut, a shape in the wrong place. Find the construct in the raw SVG, then fix `pele2svg.mjs` and add a test (as was done for color names).

Known differences that are not bugs of pele2svg (details in [development.md](development.md)): emoji in text may lose bold or shift the following text, and an emoji or glyph that the font lacks is drawn as a box (`mindmap-13`, `er-05`, `flowchart-03`).

## 8. Commit

One commit for the fixtures (they are large and mechanical), one for code and documentation changes. The renderer version goes into the message. `out/` is not committed.
