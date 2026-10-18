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
```

As a library:

```js
import { render } from 'pele';
import { flatten } from 'pele2svg';      // from a clone: import { flatten } from './pele2svg.mjs';

const { svg, warnings } = flatten(render('flowchart LR\n A-->B').svg, { '--gt-font-mono': 'Consolas' });
```

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
{"--gt-font-mono":"Consolas"}
```

- [`themes/gt-windows.json`](../themes/gt-windows.json) maps `monospace` to `Consolas`, for Skia on Windows. Other platforms have not been looked at.
- Give **a single font name**, not a fallback list: Skia may treat the whole string as one name.
- pele measures text widths itself. Replacing `sans-serif` with a font of different metrics can make labels overflow their boxes, so
  the example theme maps only `monospace`.
- In pele's own examples, `monospace` is used by `eventmodeling` and `railroad`; `sans-serif` is the root font everywhere;
  `serif` is not used.
