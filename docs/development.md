# Development and verification

## What has been checked

Using Pele's published examples ([pele.run/examples](https://pele.run/examples)) — 32 diagram types, 58 featured examples
plus the 520 documentation examples on the per-type pages (578 in total):

- All of them convert, and none keeps a `var()`, `style` attribute, `<style>` element, `currentColor`,
  `color-mix()`, nested `<svg>` or `<a>`. These sources are kept in `test/fixtures/` and checked by `npm test`
  (together with 170 more from Pele's own test corpus).
- All outputs are well-formed XML (`xmllint`; `npm test` has its own, simpler check).
- Rendered with a renderer that has no CSS variable support (resvg): the raw Pele output is all black, the converted output is correct.
- Compared by eye in GToolkit (Skia) and in WebView2 on Windows, they match for: colors, `tspan` / `text-anchor`, bold and
  italic text, rounded corners, arrowheads, dashed lines, translucent overlaps, rotated text, icons, ellipses and polygons,
  characters such as `« »` and `ʻ`, and monospace text (replaced by Consolas).
- Every example of the `Pele2svgExamples` class (82: the 58 featured ones and 24 others) was run through the Pharo class and
  looked at in GToolkit (Skia), including a flowchart with Japanese labels (`japaneseLabels`), which draws correctly.

Not verified:

- Other full-width text than that one flowchart. Pele measures text itself, so label boxes may not fit full-width glyphs
  in every font GT picks.
- One `<image>` with an external URL (a flowchart example) is removed.
- The converted SVG keeps Pele's intrinsic `width`/`height`; how it is scaled depends on the viewer.

## Running the tests

```sh
npm install
npm test
```

`npm test` (Node's built-in test runner, a few seconds) runs:

- [`test/flatten.test.js`](../test/flatten.test.js): small unit tests of `resolveVars` and `flatten`, including the inlining of simple `<style>` class rules.
- [`test/corpus.test.js`](../test/corpus.test.js): converts every source in [`test/fixtures/`](../test/fixtures) — Pele's
  58 featured examples, its 520 documentation examples and 170 sources from its own test corpus — and checks that the
  output has no `var()`, `style` attribute, `<style>`, `currentColor`, `color-mix()`, `<a>`, external `<image>` or
  nested `<svg>`, that it is well-formed, and that converting it again changes nothing. It also repeats the featured
  examples with each theme in [`themes/`](../themes) and runs `--batch` on a whole corpus file.

These tests need no GToolkit. What they cannot check is how a renderer draws the result; that was looked at by eye (see above).

[`examples/`](../examples) has Mermaid sources and the converted SVGs. `eventmodeling-1.svg` is made with
[`themes/gt-windows.json`](../themes/gt-windows.json) (`monospace` → `Consolas`); the other two have no `monospace` text.
