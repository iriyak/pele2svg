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

Requires [Node.js](https://nodejs.org/) 20 or later (pele itself needs it). Bun has not been tested.

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

Generate the SVG, then hand it to `BlSkiaSvgElement`:

```smalltalk
svg := (FileLocator home / 'Downloads' / 'eventmodeling-1.svg') contents.
BlSkiaSvgElement new
    svg: svg;
    size: 400 asPoint.
```

To go from Mermaid text to a view, run `pele2svg` as an external process and read back the file it writes.

## What has been checked

Using pele's published examples ([pele.run/examples](https://pele.run/examples)) — 32 diagram types, 58 featured examples
plus the 520 documentation examples on the per-type pages (578 in total):

- All of them convert, and none keeps a `var()`, `style` attribute, `<style>` element, `currentColor`,
  `color-mix()`, nested `<svg>` or `<a>`.
- All outputs are well-formed XML (`xmllint`).
- Rendered with a renderer that has no CSS variable support (resvg): the raw pele output is all black, the converted output is correct.
- Compared by eye in GToolkit (Skia) and in WebView2 on Windows, they match for: colors, `tspan` / `text-anchor`, bold and
  italic text, rounded corners, arrowheads, dashed lines, translucent overlaps, rotated text, icons, ellipses and polygons,
  characters such as `« »` and `ʻ`, and monospace text (replaced by Consolas).

Not verified:

- Diagrams with Japanese or other full-width text. pele measures text itself, so label boxes may not fit full-width glyphs
  in the font GT picks.
- One `<image>` with an external URL (a flowchart example) is removed.
- The converted SVG keeps pele's intrinsic `width`/`height`; how it is scaled depends on the viewer.

## Development

```sh
npm install
npm test
```

[`examples/`](examples) has Mermaid sources and the converted SVGs (with the Consolas font mapping).

## License

MIT. pele is MIT-licensed too; this repository contains no pele code, it only post-processes pele's output.
