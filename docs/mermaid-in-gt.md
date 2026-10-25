# Writing Mermaid for GToolkit with pele2svg

A guide for whoever (a person or Claude) draws a diagram **from scratch** in GToolkit: what Pele can express, what
survives the trip to Skia, and which Pele options reach it. It is based on the Pele release notes (1.0.1 to 1.10.0)
and on checks made with Pele 1.10.0 and `BlSkiaSvgElement` on 2026-10-25. When Pele is upgraded, see
[pele-upgrade.md](pele-upgrade.md) and re-check the sections marked *checked*.

## In short

- **All 33 diagram types of Pele draw in GToolkit.** The 659 official examples were converted and drawn by Skia with no
  failure (see [skia-svg-baseline.md](skia-svg-baseline.md)).
- Pele's releases since 1.0 improved **layout and text**, which reach GToolkit unchanged. The rest (zoom, `mount()`,
  error display, `sanitize`, the `pele/global` script) is for browsers and does not matter here.
- Pele's options reach the diagram through `renderOptions` (`Pele2svg new renderOptions: { #maxWidth -> 360. #math -> true } asDictionary`).
  They are off by default: without them narrow layouts, formulas and Sankey gradients do not appear.
  See [Render options](#render-options).

## Diagram types

`flowchart`, `sequence`, `class`, `state`, `er`, `pie`, `gantt`, `gitGraph`, `mindmap`, `timeline`, `journey`,
`xychart`, `quadrantChart`, `requirement`, `c4`, `sankey`, `block`, `packet`, `kanban`, `architecture`, `radar`,
`treemap`, `info`, `agentflow`, `usecase`, `railroad` (also EBNF, ABNF, PEG), `treeView`, `venn`, `cynefin`, `wardley`,
`swimlane`, `ishikawa`, `eventmodeling`.

Pele targets Mermaid 12.1.0 syntax. Several of these (`agentflow`, `swimlane`, `treeView`, `venn`, `cynefin`, `wardley`,
`ishikawa`, `eventmodeling`, `railroad`, `treemap`, `radar`) are newer than most Mermaid tutorials, so look at the
examples in `test/fixtures/featured.json` before writing the syntax from memory. `Pele2svgFeaturedExamples` has one
method per featured example.

Choosing a type for a Smalltalk or GT subject: `class` (a hierarchy), `sequence` (a message flow), `state`
(a lifecycle), `er` (data), `flowchart` or `swimlane` (a process with roles), `block` or `architecture` (a structure),
`treeView` (a folder or package tree), `mindmap` (a topic map), `sankey` or `treemap` (sizes and flows), `radar`,
`xychart`, `pie` (numbers), `timeline`, `gantt`, `gitGraph` (time), `c4` (system context).

## What the releases added, and what it means in GToolkit

| Pele | Change | In GToolkit |
|---|---|---|
| 1.2.0 | Simpler, better-spaced flowchart and state connections; stepped connections with rounded corners; flowcharts keep the written node order when that does not add crossings | Works with the defaults. Write nodes in reading order and the picture follows it |
| 1.2.0 | `--pele-critical` (critical Gantt tasks, high Kanban priorities); XY chart lines drawn over bars; bar values outside the bars with `showDataLabel` | Works. `--pele-critical` can go into a theme file |
| 1.1.0 | `--pele-radius` for corner radius | Works through a theme file |
| 1.4.0 | Narrow-screen layouts: sequence, journey, event modeling, ishikawa, packet, tree view, swimlane (vertical), railroad (folded rows) | **Needs `maxWidth`** in `renderOptions`. *Checked* with Pele directly: at `maxWidth: 360` the sequence example becomes 309x502 instead of 556x431, the journey 360x624 instead of 808x327, the packet 355x904 instead of 1035x455, and all convert with no warning |
| 1.4.0 | Better swimlane and C4 routing; labels kept beside arrows | Works with the defaults |
| 1.7.0 | Chinese and Japanese labels wrap between characters, closing punctuation stays with the line before it | Works. *Checked*: a long Japanese label wraps in a flowchart box and no line starts with 。 or 、 |
| 1.7.0 | `mermaidType` in `render()` results | Not used by pele2svg (it only needs the SVG) |
| 1.8.0 | `math` option for `$$...$$` labels, given a resolver by the host | **`#math -> true` in `renderOptions`** typesets them with MathJax (see [Formulas](#formulas)). Without it the label shows the TeX source |
| 1.8.0 | Fewer edge crossings in diagrams with subgraphs | Works with the defaults |
| 1.8.0 | HTML5 entity names such as `#lcub;` and `#verbar;`; entities decoded once; bold and italic carry across `<br>` | Works (*checked* `#lcub;` and `#verbar;`) |
| 1.9.0 | More HTML tags in labels: `sub`, `sup`, `code`, `kbd`, `samp`, `tt`, `u`, `ins`, `var`, `cite`, `dfn` | Partly. See [Text in labels](#text-in-labels) |
| 1.9.0 | Wrapping at zero-width spaces and soft hyphens; tighter wrapped lines | Works with the defaults |
| 1.9.0 | Class diagram groups wrap into rows to fit `maxWidth` | Needs `maxWidth` in `renderOptions` |
| 1.9.0 | Sankey: Unicode node names; labels avoid neighbouring columns; **gradient links when `idPrefix` is set** | Names and labels work. Gradients need `idPrefix` in `renderOptions`. *Checked*: Skia draws the gradient, with or without the `#rrggbb` fallback that Pele writes after `url(...)` |
| 1.9.0 | Text that looks like a tag but is not HTML is kept (`List<T>`) | Works (*checked*) |
| 1.9.0 | C4 relation labels no longer cover elements; quadrant point labels stay clear of titles; state transitions follow `flowchart.curve`; only diagrams starting with a C4 keyword are detected as C4 | Works with the defaults |
| 1.0.4, 1.3.0, 1.5.x, 1.6.0 | `maxEdges` (flowcharts are limited to 5,000 edges by default), `links` and `images` switches, `parse()` then `render()` of a model, `mount()` and zoom, error display in place, `onError`, unique SVG IDs | Browser or API matters. Nothing to do in GToolkit, except `maxEdges`, `links` and `images`, which are `renderOptions` keys |
| 1.10.0 | Stricter syntax: `%%` comments no longer delete the character before them, so a line that only parsed because a comment removed a stray `:` or `,` is now a syntax error (Venn, sequence, XY chart, quadrant, gantt, journey, timeline); a Sankey value that does not start with a number is a syntax error; a `title` line without text sets no title; error messages show entity codes as written and count front matter, comments and blank lines in line numbers; Sankey `prefix`/`suffix` entities are decoded; XY chart no longer draws `NaN` when both y-axis bounds clamp to one limit; radar draws very large values in proportion | Works with the defaults. Do not put a stray `:` or `,` before a `%%` comment |

Titles work from frontmatter (`---` / `title: ...` / `---`) and are drawn. *Checked*: the other `config:` keys tried
(`flowchart.curve`) did not change the picture, so do not rely on them.

## Text in labels

*Checked* in Skia with the `gt-windows` theme:

| In the label | Skia draws |
|---|---|
| `<b>`, `<i>`, `<br/>` | as expected |
| `<code>`, `<kbd>` (and the other monospace tags) | monospace font, as expected (Consolas with the theme) |
| `<var>`, `<cite>`, `<dfn>` | italic |
| `<sub>`, `<sup>` | **on the baseline**: `H<sub>2</sub>O` is drawn as `H2O`. Pele writes `baseline-shift`, which Skia ignores. Write `H₂O` and `x²` with Unicode characters instead |
| `<u>`, `<ins>` | **no underline**: Pele writes `text-decoration`, which Skia ignores. Use bold or a different wording |
| `$$...$$` | the TeX source, or the typeset formula with `#math -> true` in `renderOptions` |
| Japanese and Chinese | wrapped between characters, drawn in the first font of the list |
| emoji and symbols | see [skia-svg-baseline.md](skia-svg-baseline.md): an emoji in the middle of a label can become a box; ♥ (U+2665) is safe, ❤ (U+2764) is not |

Colors in `style` or `classDef` should be hex (`#rrggbb`) or the standard names; pele2svg turns names into hex and
Skia understands them. `hsl()`, `oklch()` and 8-digit hex do not work in Skia (see the baseline document).

## Render options

`Pele2svg` gives Pele's `render()` the Dictionary `renderOptions` (a setting like `theme`; on the command line,
`--render-options options.json`). The keys of Pele's `RenderOptions` that JSON can carry are accepted, and `math`. An unknown key
signals `Pele2svgError` and names the known ones. The options apply to Mermaid source, not to `renderSvg:`.

| Key | Effect | Value for GToolkit |
|---|---|---|
| `maxWidth` (with `responsive`, `autoDirection`, `directionBreakpoint`) | lays the diagram out for a given width | narrow layouts of 1.4.0 and the class wrapping of 1.9.0; useful for a narrow pane or a Lepiter page |
| `fontSize`, `fontFamily`, `fontFamilyMono`, `padding` | text size, fonts and margin | sizing a diagram for the view, without a theme file |
| `idPrefix` | unique ids; also switches Sankey links to gradients | Sankey gradients |
| `math` | `true` typesets `$$...$$` labels with MathJax | formulas, see below |
| `links: false`, `images: false` | omit all links and images | should remove the external-image warning of `flowchart-70` (not tried); links are made inert by pele2svg anyway |
| `maxEdges`, `limit`, `outputLimit` | size limits | very large diagrams |

### Formulas

Pele does not typeset formulas itself: the host gives it a resolver that answers an SVG and its size. pele2svg's resolver
(`math.mjs`) uses MathJax 3 (`mathjax-full`, an optional dependency that `Pele2svg installDependencies` installs) with SVG output and no font
cache, so every glyph is an inline path and the picture needs no font. *Checked* in GToolkit (Skia): `$$...$$` is typeset in flowchart, sequence, class,
state, ER, mindmap, kanban, block, requirement, swimlane and use case diagrams (`npm test` has one case for each, and each was drawn once and looked at), and
the formula takes the foreground color of the theme. Pele (1.8.0) lists the same types for `math`.

- `Pele2svgMathExamples` (in the Pharo package) has a `<gtExample>` for each of these types, and `withoutMathOption`; `Pele2svgExamplesTest` runs them.
- MathJax writes each formula with `stroke="currentColor" stroke-width="0"`. Skia draws a stroke of width 0 as 1 px, which made the
  glyphs look bold (next to a browser's drawing); `flatten` now writes `stroke="none"` there (step 13 in development.md).
- KaTeX cannot be used: it answers HTML and MathML, and Pele embeds HTML in a `<foreignObject>`, which Skia does not draw.
  Mermaid itself uses KaTeX and shows MathML in the browser; the MathJax picture is therefore not identical to Mermaid's.
- Mermaid supports `$$...$$` in flowchart and sequence diagrams only; Pele has more.
- MathJax 4 (`@mathjax/src`) was tried and not used: it loads fonts asynchronously, Pele's resolver is synchronous, and a synchronous call
  typeset only the first glyph of `E=mc^2`.
- Cost: MathJax takes about 0.2 s to load. `pele2svg.mjs` loads it only for a source that contains `$$`, so `#math -> true`
  can stay on as a default (README, step 6): a plain diagram took the same time with and without it (about 0.1 s with Node
  and 0.08 s with Bun, measured with the command line on Linux), one with formulas about 0.25 to 0.35 s.
- Bun gives the same SVG as Node for a diagram with formulas (command line, Linux).
- Not checked: a diagram with many formulas was not timed; formulas in the other diagram types of 1.8.0 were not looked for.

## Recipes for a new diagram

1. Pick the type from the list above. For a type you have not drawn before, copy the nearest featured example.
2. Write the source and look at it first with `Pele2svg new asElement: source` (add `renderOptions: { #math -> true } asDictionary` for formulas, `#maxWidth` for a narrow layout). On Windows, `Pele2svgExamples`
   already applies `themes/gt-windows.json`; elsewhere set the theme (see the README, *Fonts in GToolkit*).
3. Keep labels short and in reading order. Use Unicode for sub- and superscripts, or a formula (`$$x^2$$` with `math`). Do not use `<u>`.
4. Put a title in the frontmatter when the diagram stands alone.
5. If the picture is for a README or a document, make a PNG with white background:
   `el background: Color white. BlExporter form element: el; scaled: 2; export` (Bloc forms are premultiplied).
6. Check the converted SVG for warnings. An empty list is the normal result.

## Where each statement comes from

- Release notes: <https://github.com/obsidianmd/pele/releases> (1.0.1 to 1.10.0); the math resolver: [Pele issue 36](https://github.com/obsidianmd/pele/issues/36); Mermaid's math: <https://mermaid.js.org/config/math.html>.
- *Checked*: `render()` calls on the installed Pele 1.10.0, then the pele2svg conversion, then a Skia drawing
  (`BlSkiaSvgElement`) in GToolkit, on 2026-10-25.
- The text-in-labels table and the sankey gradient are small probes, not part of the test suite. If they matter, turn
  them into a gtExample.
