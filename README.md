# pele2svg

Turn the SVG produced by [pele](https://github.com/obsidianmd/pele) (a fast Mermaid → SVG renderer) into **plain SVG
that renderers without a CSS engine can draw** — Skia's SVG module, and with it GToolkit's `BlSkiaSvgElement`.

## Why

pele writes colors and fonts as CSS: custom properties (`fill="var(--_s)"`), `style` attributes, `color-mix()`,
`currentColor`, and so on. Renderers without a CSS engine can't resolve `var()`, so the diagram comes out
**all black** (that is what a renderer with no CSS variable support, resvg, draws for the raw output).
In `BlSkiaSvgElement` (Glamorous Toolkit) a minimal test showed that declarations inside a `style` attribute are
honored, while rules in a `<style>` element are ignored.

`pele2svg` runs pele, then rewrites everything CSS-related as SVG presentation attributes.

## What it converts

| Before | After |
|---|---|
| `var(--x, fallback)` | the actual value (`--pele-*` can be overridden with a theme) |
| `style` on the root `<svg>` (`font:` …) | `font-family` / `font-size` attributes |
| `style="fill:..;stroke:..;rx:.."` | attributes of the same name (existing ones are replaced, as in CSS) |
| `currentColor` | the foreground color |
| `color-mix(in srgb, A p%, B)` | a computed `#rrggbb` |
| nested `<svg>` (icons) | `<g transform="translate() scale()">` |
| `<a href>` | `<g>` |
| `<image>` with an external URL | removed (a warning is printed) |
| `font-family="monospace"` etc. | the font name you give in the theme (see [Fonts](#fonts)) |

## Install

Requires [Node.js](https://nodejs.org/) 20 or later (pele itself needs it).
[Bun](https://bun.sh/) can run `pele2svg.mjs` too: with Bun 1.4.3 on Windows the output was identical to Node's and each
run was faster. Installing with `bun install` / `bunx` has not been tried.

pele2svg is **not on the npm registry yet** and has no versioned releases; the API and options may still change.
Install it straight from GitHub. (npm records the exact commit in `package-lock.json`, so a project that uses it stays reproducible.)

Run it once, without installing anything:

```sh
npx github:iriyak/pele2svg input.mmd output.svg
```

Add it to a project (this also installs pele):

```sh
npm install github:iriyak/pele2svg
npx pele2svg input.mmd output.svg
```

Or work from a clone — for development, or to run the tests:

```sh
git clone https://github.com/iriyak/pele2svg.git
cd pele2svg
npm install
node pele2svg.mjs input.mmd output.svg
```

If `github:` fails because SSH is not set up, use the HTTPS form: `npm install git+https://github.com/iriyak/pele2svg.git`.

## Usage

In the commands below, write `npx github:iriyak/pele2svg` instead of `npx pele2svg` if you have not installed it,
or `node pele2svg.mjs` if you work from a clone.

```sh
# one file
npx pele2svg input.mmd output.svg [theme.json]

# many at once: sources.json = [{"name":"flow-1","source":"flowchart LR\n A-->B"}, ...]
npx pele2svg --batch sources.json outdir [theme.json]
```

As a library:

```js
import { render } from 'pele';
import { flatten } from 'pele2svg';      // from a clone: import { flatten } from './pele2svg.mjs';

const { svg, warnings } = flatten(render('flowchart LR\n A-->B').svg, { '--gt-font-mono': 'Consolas' });
```

### Themes

A theme is a JSON object that overrides pele's CSS variables (examples in [`themes/`](themes)):

```json
{"--pele-bg":"#fffcf0","--pele-fg":"#100f0f","--pele-surface":"#f2f0e5","--pele-border":"#cecdc3","--pele-accent":"#205ea6"}
```

### Fonts

Skia's SVG module could not resolve the generic family name `monospace` (in GToolkit, text set in
`monospace` was drawn in the default font). Map generic names to real font names with these keys:

| Key | Replaces |
|---|---|
| `--gt-font-mono` | `monospace` |
| `--gt-font-sans` | `sans-serif` |
| `--gt-font-serif` | `serif` |

```json
{"--gt-font-mono":"Consolas"}
```

- [`themes/gt-windows.json`](themes/gt-windows.json) is a Windows example. Use `Menlo` on macOS or `DejaVu Sans Mono` on most Linux systems.
- Give **a single font name**, not a fallback list: Skia may treat the whole string as one name.
- pele measures text widths itself. Replacing `sans-serif` with a font of different metrics can make labels overflow their boxes, so
  only `monospace` is mapped in the example theme.
- In pele's own examples, `monospace` is used by `eventmodeling` and `railroad`; `sans-serif` is the root font everywhere;
  `serif` is not used.

## Using it from GToolkit

### From a file

Generate the SVG on the command line, then hand it to `BlSkiaSvgElement`:

```smalltalk
svg := (FileLocator home / 'Downloads' / 'eventmodeling-1.svg') contents.
BlSkiaSvgElement new
    svg: svg;
    size: 400 asPoint.
```

### From Mermaid text, inside GToolkit

The Pharo package `Pele2svg` has a class `Pele2svg` that runs `pele2svg.mjs` as an external process
(it writes the source to a temporary file, reads the SVG back, and deletes the temporary files):

```smalltalk
Pele2svg new render: 'flowchart LR
  A --> B'.                                  "an SVG string"

Pele2svg new asElement: 'flowchart LR
  A --> B'.                                  "a BlSkiaSvgElement"

Pele2svg new
    theme: { '--gt-font-mono' -> 'Consolas' } asDictionary;   "or the path of a theme JSON file"
    asElement: 'sequenceDiagram
  Alice->>Bob: Hello'.
```

| Setting | Default | |
|---|---|---|
| `script:` | `pele2svg.mjs` in the Iceberg clone named `pele2svg` | Path of `pele2svg.mjs`. Set it when no Iceberg repository named `pele2svg` exists in the image (the class then signals `Pele2svgError`). |
| `runtime:` | `'node'` | The executable to run. `'bun'` is also possible; see [Install](#install). |
| `theme:` | none | `nil`, the path of a theme JSON file, or a Dictionary of theme variables. |
| `timeout:` | `30000` | Milliseconds; the process is killed when it is exceeded. |

A failure (invalid Mermaid, a missing runtime, a timeout) signals `Pele2svgError` with a one-line message.

Load the package with Metacello:

```smalltalk
Metacello new
    repository: 'github://iriyak/pele2svg:main/src';
    baseline: 'Pele2svg';
    load
```

The class only calls the script, so `npm install` must have been run in the directory that holds `pele2svg.mjs`
(pele is installed there). The class `Pele2svgExamples` has one `<gtExample>` per diagram — the 58 featured
examples of pele (`featured…`) and short examples of the basic diagram types; each answers a `BlSkiaSvgElement`.

## What has been checked

Using pele's published examples ([pele.run/examples](https://pele.run/examples)) — 32 diagram types, 58 featured examples
plus the 520 documentation examples on the per-type pages (578 in total):

- All of them convert, and none keeps a `var()`, `style` attribute, `<style>` element, `currentColor`,
  `color-mix()`, nested `<svg>` or `<a>`. These sources are kept in `test/fixtures/` and checked by `npm test`
  (together with 170 more from pele's own test corpus).
- All outputs are well-formed XML (`xmllint`; `npm test` has its own, simpler check).
- Rendered with a renderer that has no CSS variable support (resvg): the raw pele output is all black, the converted output is correct.
- Compared by eye in GToolkit (Skia) and in WebView2 on Windows, they match for: colors, `tspan` / `text-anchor`, bold and
  italic text, rounded corners, arrowheads, dashed lines, translucent overlaps, rotated text, icons, ellipses and polygons,
  characters such as `« »` and `ʻ`, and monospace text (replaced by Consolas).
- Every example of the `Pele2svgExamples` class (82: the 58 featured ones and 24 others) was run through the Pharo class and
  looked at in GToolkit (Skia), including a flowchart with Japanese labels (`japaneseLabels`), which draws correctly.

Not verified:

- Other full-width text than that one flowchart. pele measures text itself, so label boxes may not fit full-width glyphs
  in every font GT picks.
- One `<image>` with an external URL (a flowchart example) is removed.
- The converted SVG keeps pele's intrinsic `width`/`height`; how it is scaled depends on the viewer.

## Development

```sh
npm install
npm test
```

`npm test` (Node's built-in test runner, a few seconds) runs:

- [`test/flatten.test.js`](test/flatten.test.js): small unit tests of `resolveVars` and `flatten`.
- [`test/corpus.test.js`](test/corpus.test.js): converts every source in [`test/fixtures/`](test/fixtures) — pele's
  58 featured examples, its 520 documentation examples and 170 sources from its own test corpus — and checks that the
  output has no `var()`, `style` attribute, `<style>`, `currentColor`, `color-mix()`, `<a>`, external `<image>` or
  nested `<svg>`, that it is well-formed, and that converting it again changes nothing. It also repeats the featured
  examples with each theme in [`themes/`](themes) and runs `--batch` on a whole corpus file.

These tests need no GToolkit. What they cannot check is how a renderer draws the result; that was looked at by eye (see above).

[`examples/`](examples) has Mermaid sources and the converted SVGs (with the Consolas font mapping).

## License

MIT. pele is MIT-licensed too; this repository contains no pele code, it only post-processes pele's output.
