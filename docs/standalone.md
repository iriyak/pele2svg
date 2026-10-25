# Using pele2svg without GToolkit

`pele2svg.mjs` is a Node.js script and a small library; GToolkit is only one user of it. This page is for running it
on its own. For GToolkit, see the [README](../README.md).

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

# an SVG that Pele has already produced (Pele itself is not run)
npx pele2svg --svg input.svg output.svg [theme.json]

# options for Pele's render(), as a JSON file; also works with --batch
npx pele2svg --render-options options.json input.mmd output.svg [theme.json]

# one formula on its own (no Pele): --format tex (default), mathml or asciimath
npx pele2svg --math [--format tex] [--display] [--size 16] [--color '#000000'] input.txt output.svg

# many formulas: formulas.json = [{"name":"f1","source":"E=mc^2","format":"tex","display":false,"size":16,"color":"#000000"}, ...]
# (everything but name and source is optional); writes outdir/<name>.svg
npx pele2svg --math-batch formulas.json outdir
```

`options.json` holds the options of Pele's `render()` that JSON can carry (`maxWidth`, `fontSize`, `padding`, `idPrefix`,
`links`, `images`, `maxEdges`, ...; a key that is not one of them is refused), and `"math": true`, which typesets `$$...$$`
labels with MathJax. For example `{"maxWidth":360,"math":true}`. `math` needs `mathjax-full`, an optional dependency that
`npm install` installs unless you pass `--omit=optional`. MathJax takes about 0.2 s to load, so it is loaded only for a
source that contains `$$` (and once per `--batch` run); other diagrams are converted as fast as without `math`.

With `--svg`, an input that has nothing to convert is written unchanged and a note is printed to stderr.
Simple `<style>` rules of the form `.name { declarations }` are turned into attributes of the elements with that class,
so SVGs from other tools can be converted too; other kinds of rules (tag or id selectors, `@media`) are left and reported
as a warning.

As a library:

```js
import { mermaidToSvg } from 'pele2svg';      // from a clone: import { mermaidToSvg } from './pele2svg.mjs';

const { svg, warnings } = await mermaidToSvg('flowchart LR\n A-->B', {
  theme: { '--gt-font-mono': 'Consolas' },          // optional: theme variables, as in a theme.json
  renderOptions: { maxWidth: 360, math: true },     // optional: the JSON of --render-options
});
```

`mermaidToSvg()` is what the command line does for an `.mmd` file: it runs Pele and then `flatten`. It throws when the
Mermaid is invalid or a render option is unknown. MathJax is loaded only for a source that contains `$$`, and Pele is
imported on the first call. To convert an SVG that Pele has already made, call `flatten()` yourself:

```js
import { render } from 'pele';
import { flatten } from 'pele2svg';

const { svg, warnings } = flatten(render('flowchart LR\n A-->B').svg, { '--gt-font-mono': 'Consolas' });
```

With formulas or other render options, `peleOptions()` turns the JSON of `--render-options` into Pele's options
(`math: true` becomes the MathJax resolver of [`math.mjs`](../math.mjs), which answers SVG in pixels); `mermaidToSvg()` calls it for you:

```js
import { peleOptions } from 'pele2svg';

const { svg } = render('flowchart LR\n A["$$E=mc^2$$"] --> B', await peleOptions({ math: true, maxWidth: 360 }));
```

A formula on its own, without Mermaid, is `mathToSvg()`. It typesets with MathJax (`mathjax-full`) and answers plain SVG that Skia can draw,
as large as the formula in pixels (`viewBox="0 0 width height"`):

```js
import { mathToSvg } from 'pele2svg';

const { svg, width, height } = await mathToSvg('E=mc^2', { format: 'tex', display: false, size: 16, color: '#000000' });
```

`format` is `'tex'`, `'mathml'` or `'asciimath'`; it throws when MathJax cannot read the formula. The engine of each format is
loaded once, when it is first used, so the second formula costs almost nothing.

## Themes

A theme is a JSON object that overrides pele's CSS variables (examples in [`themes/`](../themes)):

```json
{"--pele-bg":"#fffcf0","--pele-fg":"#100f0f","--pele-surface":"#f2f0e5","--pele-border":"#cecdc3","--pele-accent":"#205ea6"}
```

Not every variable shows up in every diagram. Changing each one in turn and comparing the output for pele's 58 featured
examples: `--pele-fg`, `--pele-surface` and `--pele-border` changed the sequence diagram and the flowchart;
`--pele-bg` changed neither (the SVG has no background of its own); `--pele-accent` changed only 5 of the 58
(`gantt-1`, `gantt-2`, `kanban-2`, `treeview-2`, `wardley-1`).

## Fonts

Font families are left as pele wrote them (`monospace`, `sans-serif`). A renderer such as WebView2 resolves the
generic names itself; Skia (`BlSkiaSvgElement`) does not resolve `monospace` (on Windows the text came out
proportional). To get a monospace font there, or to use another font, map the generic names to real font names with
these keys in a theme:

| Key | Replaces |
|---|---|
| `--gt-font-mono` | `monospace` |
| `--gt-font-sans` | `sans-serif` |
| `--gt-font-serif` | `serif` |

```json
{"--gt-font-mono":"Consolas","--gt-font-sans":"Arial"}
```

- [`themes/gt-windows.json`](../themes/gt-windows.json) maps `monospace` to `Consolas` and `sans-serif` to `Arial`, for Skia on Windows. Other platforms have not been looked at. Without the `sans-serif` mapping Skia draws the root font in another, thinner face than a browser on Windows does.
- Give **a single font name**, not a fallback list: Skia may treat the whole string as one name.
- pele measures text widths itself. Replacing `sans-serif` with a font of different metrics can make labels overflow their boxes.
  Arial is the font a browser on Windows uses for `sans-serif`, so it suits pele's measurements; use another font with care.
- In pele's own examples, `monospace` is used by `eventmodeling` and `railroad`; `sans-serif` is the root font everywhere;
  `serif` is not used.

### Japanese text in a browser

When the SVG is shown in a browser (an HTML page, or a screenshot made with Chromium), give the converter an empty theme
(`{}`), so that `monospace` and `sans-serif` stay as they are, and let the page choose the Japanese font. A browser picks a CJK
font for `sans-serif` by itself, and that can be a Chinese one: in Chromium on a Linux machine it was WenQuanYi Zen Hei, and
characters such as 令 and 直 were drawn in the Chinese shapes. `lang="ja"` on the `<svg>` or on `<html>` made no difference.
A CSS rule beats the `font-family` attribute of the SVG, so this rule in the page is enough:

```css
svg { font-family: Arial, "Hiragino Sans", "Yu Gothic", "Meiryo", "Noto Sans CJK JP", sans-serif; }
```

Arial comes first so that Latin text keeps the metrics pele measured with; the kanji and kana come from the first Japanese font
that exists. In the check, Liberation Sans stood in for Arial and Noto Sans CJK JP drew the Japanese (`fc-list :lang=ja family`
lists the Japanese fonts of a Linux machine). This is for browsers; Skia in GToolkit is described above.

## Using it from an MCP server

An MCP server needs only `pele2svg` as a dependency: `npm install github:iriyak/pele2svg` (it brings in pele, and `mathjax-full`
as an optional dependency). The author's own server, `local-mcp-server`, has a tool named `pele2svg` made this way. It maps its
`input_format` argument to the functions above:

| `input_format` | Call |
|---|---|
| `mermaid` | `mermaidToSvg(source, { theme, renderOptions })` |
| `svg` | `flatten(source, theme)` |
| `tex`, `mathml`, `asciimath` | `mathToSvg(source, { format, display, size, color })` |

- The tool answers the SVG as text, with the warnings (and the size of a formula) as a second text item. An invalid Mermaid source,
  a formula MathJax cannot read and an unknown render option come back as an error result with the one-line message. The
  `output_path` argument writes the SVG to a file and answers only the path and the size, which keeps a large SVG out of the conversation.
- When no theme is given, the tool uses [`themes/gt-windows.json`](../themes/gt-windows.json), which was made for Skia on Windows. For
  a browser, an HTML page or a PNG, pass `{}` (see [Japanese text in a browser](#japanese-text-in-a-browser)).
- `themes/` is in the `files` of the package, but `exports` has only `"."`, so find the folder from the main file:

  ```js
  import { createRequire } from 'node:module';
  import { dirname, join } from 'node:path';

  const themeDir = join(dirname(createRequire(import.meta.url).resolve('pele2svg')), 'themes');
  ```

- A server that talks over stdio must keep stdout for the protocol. pele2svg writes its warnings with `console.error`, so it is safe
  to call from a handler.
- `github:` is pinned to a commit by `package-lock.json`. After a new commit of pele2svg is pushed, run `npm update pele2svg` in the
  server's folder, then restart the MCP client.
- Checked: Mermaid (with and without `math`), a TeX formula, an SVG to convert, a file written with `output_path`, an unknown option
  and invalid Mermaid, each called through the MCP protocol over stdio. For one flowchart with formulas, with the same theme and options,
  the tool's SVG was identical to the string that `Pele2svg>>#render:` answers in GToolkit.
