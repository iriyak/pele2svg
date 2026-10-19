# pele2svg

Draw [Pele](https://github.com/obsidianmd/pele) (a fast Mermaid → SVG renderer) diagrams in **GToolkit**.

Pele's SVG relies on CSS, which Skia's SVG module (and so GToolkit's `BlSkiaSvgElement`) does not have. `pele2svg`
turns that SVG into **plain SVG that a renderer without a CSS engine can draw**, and the Pharo package in this repository
runs it for you: Mermaid text in, a `BlSkiaSvgElement` out.

This is experimental; the API and options may still change. There are no versioned releases yet.

## Why

Pele writes colors and fonts as CSS: custom properties (`fill="var(--_s)"`), `style` attributes, `color-mix()`,
`currentColor`, and so on. Renderers without a CSS engine can't resolve `var()`, so the diagram comes out
**all black** (that is what a renderer with no CSS variable support, resvg, draws for the raw output).
In `BlSkiaSvgElement` a minimal test showed that declarations inside a `style` attribute are honored, while rules in a
`<style>` element are ignored.

`pele2svg` runs Pele, then rewrites everything CSS-related as SVG presentation attributes:

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
| `font-family="monospace"` etc. | kept as it is; map it to a real font with a theme (see [Fonts in GToolkit](#fonts-in-gtoolkit)) |

## Getting started in GToolkit

You need [Node.js](https://nodejs.org/) 20 or later (Pele needs it). [Bun](https://bun.sh/) can run the script too.

1. **Load the Pharo package** in a GToolkit image. Metacello clones the repository with Iceberg
   (under `pharo-local/iceberg/` in the GT directory):

   ```smalltalk
   Metacello new
       repository: 'github://iriyak/pele2svg:main/src';
       baseline: 'Pele2svg';
       load
   ```

2. **Install Pele, once.** The Pharo class only calls `pele2svg.mjs`, so Pele has to be installed next to it.
   This runs `npm install` in the Iceberg clone (`bun install` if you set `runtime: 'bun'`) and does nothing if Pele is
   already there:

   ```smalltalk
   Pele2svg installDependencies
   ```

3. **Add the Lepiter notebook, once.** The repository has a Lepiter database with a *Getting started* page.
   This registers it with Lepiter:

   ```smalltalk
   #BaselineOfPele2svg asClass loadLepiter
   ```

4. **Open the Getting started page.** Evaluate this and look at the page that comes back:

   ```smalltalk
   aDatabaseName := 'iriyak/pele2svg/lepiter'.
   aDatabase := LeDatabasesRegistry defaultLogicalDatabase databases
       detect: [ :each | (each databaseName copyReplaceAll: '\' with: '/') = aDatabaseName ].
   aPage := aDatabase pageNamed: 'Getting started with pele2svg in GT'
   ```

5. **Try it**, here or with the snippets on that page:

   ```smalltalk
   Pele2svg new asElement: 'flowchart LR
     A --> B'.
   ```

If you did not get the code through Iceberg — for example, you cloned it with `git` yourself — point `Pele2svg` at the
script in that clone. `installDependencies` then installs Pele there, as it does for the Iceberg clone:

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

The Lepiter notebook (steps 3 and 4) is registered from the Iceberg clone, so it is available only with the Iceberg route.

## Using it

`Pele2svg` turns Mermaid text into an SVG string, or into an element you can show in GToolkit.

### Showing a diagram

| Message | Answers |
|---|---|
| `render:` | the converted SVG, as a string |
| `asElement:` | a `BlSkiaSvgElement` (drawn by Skia) |
| `asWebViewElement:` | a `GtWebViewElement` (drawn by WebView2) |

For an SVG that Pele has already made, give the SVG instead of the Mermaid source
(see [Showing an SVG file you already have](#showing-an-svg-file-you-already-have)):

| Message | Answers |
|---|---|
| `renderSvg:` | the converted SVG, as a string |
| `asElementFromSvg:` | a `BlSkiaSvgElement` (drawn by Skia) |

```smalltalk
Pele2svg new asElement: 'flowchart LR
  A --> B'.

Pele2svg new asWebViewElement: 'flowchart LR
  A --> B'.
```

The same diagram without and with a theme, side by side:

```smalltalk
element1 := Pele2svg new asElement: 'sequenceDiagram
  Alice->>Bob: Hello'.
element2 := Pele2svg new
    theme: { '--pele-surface' -> '#e6e8f0'. '--pele-border' -> '#205ea6' } asDictionary;
    asElement: 'sequenceDiagram
  Alice->>Bob: Hello'.
BrHorizontalPane new
    matchParent;
    addChildren: { element1. element2 }
```

The element that `asElement:` answers has the size of the diagram (the width and height of the SVG's `viewBox`), so
it takes its own room in a layout. Elements placed side by side, for example in a `BrHorizontalPane`, do not overlap.
`width` and `height` answer that size once the element has been laid out.

### Showing an SVG file you already have

`asElementFromSvg:` takes the contents of an SVG file, converts it if it needs it, and answers a `BlSkiaSvgElement`
sized from the `viewBox`. It works for the diagrams in [`examples/`](examples) (already converted, so nothing changes),
for a file straight from Pele (the CSS is converted, and Pele itself is not run), and for SVGs from other tools.
`Pele2svg repositoryDirectory` is the Iceberg clone:

```smalltalk
Pele2svg new
	asElementFromSvg: (Pele2svg repositoryDirectory / 'examples' / 'eventmodeling-1.svg') contents.

Pele2svg new
	asElementFromSvg: (Pele2svg repositoryDirectory / 'examples' / 'architecture-2.svg') contents.

Pele2svg new
	asElementFromSvg: (Pele2svg repositoryDirectory / 'examples' / 'sequence-1.svg') contents.
```

For your own file, use its path (a `theme:` and the other settings work as before):

```smalltalk
| svg |
svg := 'path/to/diagram.svg' asFileReference contents.
Pele2svg new renderSvg: svg.            "the converted SVG string"
Pele2svg new asElementFromSvg: svg.     "a BlSkiaSvgElement"
```

What is converted is what Skia cannot draw: CSS variables, `style` attributes, `color-mix()` and so on (see the table
at the top). Simple `<style>` rules such as `.a { fill: red }` are turned into attributes too, so SVGs from other tools
often draw correctly; an SVG with nothing to convert comes back unchanged. The element is sized from the `viewBox` (or from `width` and `height` when there is no `viewBox`); when the root has a
`viewBox` but no `width` and `height`, they are added (Skia draws nothing without them). An SVG with neither signals
`Pele2svgError`. The command line does the same with
`pele2svg --svg input.svg output.svg` (see [docs/standalone.md](docs/standalone.md)).

The package also adds an `SvgInWeb` view to `.svg` files in the GT inspector
(`AbstractFileReference>>#gtSvgInWebViewFor:`), which shows the file in WebView2 next to the Skia view. Evaluate
`Pele2svg repositoryDirectory / 'examples' / 'sequence-1.svg'` and look at the result to see both views.

### Examples

The class `Pele2svgExamples` has one `<gtExample>` per diagram — Pele's 58 featured examples (`featured…`, with their sources copied from Pele) and short
examples of the basic diagram types, 82 in all. Each answers a `BlSkiaSvgElement`; open the class in the GT Coder and
look at the results.

### Settings

Set these on the instance before rendering, as `theme:` is set above.

| Setting | Default | |
|---|---|---|
| `script:` | `pele2svg.mjs` in the Iceberg clone named `pele2svg` | Path of `pele2svg.mjs`. Set it when no Iceberg repository named `pele2svg` exists in the image (the class then signals `Pele2svgError`). |
| `runtime:` | `'node'` | The executable to run. `'bun'` is also possible. Give the full path if `node` is not on the PATH that GToolkit sees (for example, an app started from the macOS Finder does not use your shell's PATH; not tried). |
| `theme:` | none | `nil`, the path of a theme JSON file, or a Dictionary of theme variables. See [Themes](docs/standalone.md#themes). |
| `timeout:` | `30000` | Milliseconds; the process is killed when it is exceeded. |

### Fonts in GToolkit

Font families are left as Pele wrote them: `monospace` stays `monospace`, `sans-serif` stays `sans-serif`.
WebView2 draws `monospace` text in a monospace font, but `BlSkiaSvgElement` does not: on Windows the text came out
proportional. To get monospace text in Skia, map `monospace` to a real font name in the theme (`Consolas` on Windows;
the other platforms have not been looked at). Only some diagram types use `monospace`, such as event modeling; a
flowchart is all `sans-serif`.

To use another font, map the generic name in the theme (a single font name, not a list):

```smalltalk
Pele2svg new theme: { '--gt-font-mono' -> 'Courier New' } asDictionary; asElement: mmd
```

`--gt-font-sans` and `--gt-font-serif` work the same way. The details are in [docs/standalone.md](docs/standalone.md#fonts).

### What happens when you render

- The class writes the Mermaid source to a temporary file, runs the script as an external process, reads the SVG back,
  and deletes the temporary files.
- A failure signals `Pele2svgError` with a one-line message: invalid Mermaid, a runtime that cannot be started, a
  script that is not found, or a timeout.
- `asWebViewElement:` hands the SVG to `GtWebViewElement>>#html:`, which accepts at most 2 MB.

## What has been checked

Every one of Pele's published examples (578) converts cleanly, and the converted SVGs match in GToolkit (Skia) and in
WebView2 on Windows. The details, what is not verified, and how to run the tests are in
[docs/development.md](docs/development.md).

## More documentation

- [docs/standalone.md](docs/standalone.md) — using `pele2svg` without GToolkit: installing it with npm, the command line,
  the JavaScript API, themes and fonts.
- [docs/development.md](docs/development.md) — what has been checked, what has not, and how to run the tests.

## License

MIT License.
```
Copyright (c) 2026 kepano (pele)
Copyright (c) 2026 Kazunori Iriya (pele2svg post-processing and GToolkit adaptation)
```
[Pele](https://github.com/obsidianmd/pele) is the work of its original author and is MIT-licensed
([its LICENSE](https://github.com/obsidianmd/pele/blob/main/LICENSE)). This repository contains no Pele code: it
post-processes Pele's output, and Pele is installed with npm. The example diagram sources in `examples`,
`test/fixtures` and the `featured…` methods of `Pele2svgExamples` are taken from Pele, and Pele itself is run by the
tests and the examples. Each of these says so where it is used: `examples/README.md`, `test/fixtures/README.md`, the
header of `test/corpus.test.js` and the class comment of `Pele2svgExamples`.

See [LICENSE](LICENSE) for the full text.
