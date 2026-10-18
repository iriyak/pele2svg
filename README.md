# pele2svg

Draw [pele](https://github.com/obsidianmd/pele) (a fast Mermaid → SVG renderer) diagrams in **GToolkit**.

pele's SVG relies on CSS, which Skia's SVG module (and so GToolkit's `BlSkiaSvgElement`) does not have. `pele2svg`
turns that SVG into **plain SVG that a renderer without a CSS engine can draw**, and the Pharo package in this repository
runs it for you: Mermaid text in, a `BlSkiaSvgElement` out.

This is experimental; the API and options may still change. There are no versioned releases yet.

## Why

pele writes colors and fonts as CSS: custom properties (`fill="var(--_s)"`), `style` attributes, `color-mix()`,
`currentColor`, and so on. Renderers without a CSS engine can't resolve `var()`, so the diagram comes out
**all black** (that is what a renderer with no CSS variable support, resvg, draws for the raw output).
In `BlSkiaSvgElement` a minimal test showed that declarations inside a `style` attribute are honored, while rules in a
`<style>` element are ignored.

`pele2svg` runs pele, then rewrites everything CSS-related as SVG presentation attributes:

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
| `font-family="monospace"` etc. | kept as it is; a theme can map it to another font (see [Fonts in GToolkit](#fonts-in-gtoolkit)) |

## Getting started in GToolkit

You need [Node.js](https://nodejs.org/) 20 or later (pele needs it). [Bun](https://bun.sh/) can run the script too.

1. **Load the Pharo package** in a GToolkit image. Metacello clones the repository with Iceberg
   (under `pharo-local/iceberg/` in the GT directory):

   ```smalltalk
   Metacello new
       repository: 'github://iriyak/pele2svg:main/src';
       baseline: 'Pele2svg';
       load
   ```

2. **Install pele, once.** The Pharo class only calls `pele2svg.mjs`, so pele has to be installed next to it.
   This runs `npm install` in the Iceberg clone (`bun install` if you set `runtime: 'bun'`) and does nothing if pele is
   already there:

   ```smalltalk
   Pele2svg installDependencies
   ```

3. **Try it:**

   ```smalltalk
   Pele2svg new asElement: 'flowchart LR
     A --> B'.
   ```

If you did not get the code through Iceberg — for example, you cloned it with `git` yourself — point `Pele2svg` at the
script in that clone. `installDependencies` then installs pele there, as it does for the Iceberg clone:

```sh
git clone https://github.com/iriyak/pele2svg.git
```

```smalltalk
Pele2svg new
    script: 'C:\...\pele2svg\pele2svg.mjs';
    installDependencies;
    asElement: 'flowchart LR
  A --> B'
```

(Running `npm install` yourself in that directory does the same.)

## Using it

`Pele2svg` turns Mermaid text into an SVG string, or into an element you can show in GToolkit.

### Showing a diagram

| Message | Answers |
|---|---|
| `render:` | the converted SVG, as a string |
| `asElement:` | a `BlSkiaSvgElement` (drawn by Skia) |
| `asWebViewElement:` | a `GtWebViewElement` (drawn by WebView2) |

```smalltalk
Pele2svg new asElement: 'flowchart LR
  A --> B'.

Pele2svg new asWebViewElement: 'flowchart LR
  A --> B'.

Pele2svg new
    theme: { '--pele-surface' -> '#e6e8f0'. '--pele-border' -> '#205ea6' } asDictionary;
    asElement: 'sequenceDiagram
  Alice->>Bob: Hello'.
```

### Settings

Set these on the instance before rendering, as `theme:` is set above.

| Setting | Default | |
|---|---|---|
| `script:` | `pele2svg.mjs` in the Iceberg clone named `pele2svg` | Path of `pele2svg.mjs`. Set it when no Iceberg repository named `pele2svg` exists in the image (the class then signals `Pele2svgError`). |
| `runtime:` | `'node'` | The executable to run. `'bun'` is also possible. |
| `theme:` | none | `nil`, the path of a theme JSON file, or a Dictionary of theme variables. See [Themes](docs/standalone.md#themes). |
| `timeout:` | `30000` | Milliseconds; the process is killed when it is exceeded. |

### What happens when you render

- The class writes the Mermaid source to a temporary file, runs the script as an external process, reads the SVG back,
  and deletes the temporary files.
- A failure signals `Pele2svgError` with a one-line message: invalid Mermaid, a runtime that cannot be started, a
  script that is not found, or a timeout.
- `asWebViewElement:` hands the SVG to `GtWebViewElement>>#html:`, which accepts at most 2 MB.

### Showing an SVG file you already have

Give the file's contents straight to Skia. The repository's [`examples/`](examples) folder has three converted diagrams;
`Pele2svg repositoryDirectory` is the Iceberg clone:

```smalltalk
BlSkiaSvgElement new
	svg: (Pele2svg repositoryDirectory / 'examples' / 'eventmodeling-1.svg') contents.

BlSkiaSvgElement new
	svg: (Pele2svg repositoryDirectory / 'examples' / 'architecture-2.svg') contents.

BlSkiaSvgElement new
	svg: (Pele2svg repositoryDirectory / 'examples' / 'sequence-1.svg') contents.
```

The package also adds an `SvgInWeb` view to `.svg` files in the GT inspector
(`AbstractFileReference>>#gtSvgInWebViewFor:`), which shows the file in WebView2 next to the Skia view. Evaluate
`Pele2svg repositoryDirectory / 'examples' / 'sequence-1.svg'` and look at the result to see both views.

### Examples

The class `Pele2svgExamples` has one `<gtExample>` per diagram — pele's 58 featured examples (`featured…`) and short
examples of the basic diagram types, 82 in all. Each answers a `BlSkiaSvgElement`; open the class in the GT Coder and
look at the results.

### Fonts in GToolkit

Font families are left as pele wrote them: text set in `monospace` stays `monospace`, `sans-serif` stays `sans-serif`.
On Windows, `BlSkiaSvgElement` and WebView2 (Edge) drew `monospace` text with the same font, and the WebView2 inspector
showed that font to be the one `Consolas` gives. Other platforms have not been looked at.

To use another font, map the generic name in the theme (a single font name, not a list):

```smalltalk
Pele2svg new theme: { '--gt-font-mono' -> 'Courier New' } asDictionary; asElement: mmd
```

`--gt-font-sans` and `--gt-font-serif` work the same way. The details are in [docs/standalone.md](docs/standalone.md#fonts).

## What has been checked

- All of pele's published examples (58 featured and 520 documentation examples) convert, and none keeps a `var()`,
  `style` attribute, `<style>` element, `currentColor`, `color-mix()`, nested `<svg>` or `<a>`. The tests in `npm test` repeat
  this for these and 170 more sources from pele's own test corpus.
- Every example of `Pele2svgExamples` (82) was looked at in GToolkit (Skia), including a flowchart with Japanese labels,
  which draws correctly.
- Compared by eye in GToolkit (Skia) and in WebView2 on Windows, the converted SVG matches for: colors, `tspan` /
  `text-anchor`, bold and italic text, rounded corners, arrowheads, dashed lines, translucent overlaps, rotated text,
  icons, ellipses and polygons, and `monospace` text (left as `monospace`).

Not verified: other full-width text than that one flowchart; the converted SVG keeps pele's intrinsic `width`/`height`, so
how it is scaled depends on the viewer; one external `<image>` in a flowchart example is removed. More in
[docs/development.md](docs/development.md).

## More documentation

- [docs/standalone.md](docs/standalone.md) — using `pele2svg` without GToolkit: installing it with npm, the command line,
  the JavaScript API, themes and fonts.
- [docs/development.md](docs/development.md) — what has been checked in detail, and how to run the tests.

## License

MIT. pele is MIT-licensed too; this repository contains no pele code, it only post-processes pele's output.
