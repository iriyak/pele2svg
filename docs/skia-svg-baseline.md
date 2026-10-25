# Skia SVG baseline

What does GToolkit's `BlSkiaSvgElement` actually draw, ignore or get wrong for the CSS and SVG features that
`pele2svg` converts? This page records a first, small set of measurements. It is a **baseline**, not a complete
specification: every row is one minimal SVG, drawn once, with one or two pixels read back.

It was extended on 2026-10-25, after all 659 of Pele's published examples were drawn by Skia and compared with what a
browser draws from Pele's own SVG (see [development.md](development.md) and [pele-upgrade.md](pele-upgrade.md)).
The new measurements are in [Colors](#colors-step-12) and [Text, fonts and emoji](#text-fonts-and-emoji), and
[What turned out differently](#what-turned-out-differently) lists the assumptions that the review corrected.

Why it matters: each step of `flatten` (see [Design notes](development.md#design-notes)) exists because Skia lacks
something. Some of those assumptions can now be checked, and the steps that Skia handles by itself are candidates for
removal; the ones it does not handle are candidates for being supported on the Skia side.

## Environment

| | |
|---|---|
| Date | 2026-10-20 (first measurements), 2026-10-25 (colors, emoji, the 659 examples) |
| Image | Pharo 13.1.0 (64 bit), GToolkit v1.1.624 |
| VM | `v10.3.11-49-gfea30c6` (2026-09-17) |
| OS | Windows 64 bit |
| Renderer | `BlSkiaSvgElement` (`SkiaSvgDom` / `drawSvg:`) |
| Skia version | **not determined** (to be read from the Skia sources GToolkit bundles) |

Not measured: WebView2 (`GtWebViewElement`), other platforms, other GT versions.

## Method

Each case is a small SVG, 20 x 20 user units, with one `<rect>` (or one `<text>`) whose look depends on the feature
under test. The SVG is drawn with `BlSkiaSvgElement`, converted to a `Form` with `asSpartaForm`, and the colors of a few
pixels are read with `colorAt:`. A colored pixel means the feature worked; `#000000` is Skia's default fill and means
"the declaration was ignored"; `none` means a fully transparent pixel.

The reference color is `#00ff00`, so a wrong result shows up as black, red or blue. A sanity case (plain
`fill="#00ff00"`) draws `#00ff00`.

Two cautions for reading pixels back. A `Form` made from a Bloc element is **premultiplied**: a translucent pixel read
with `colorAt:` looks darker than it is (alpha 128 with color 115 for a 50 % green), so give the element
`background: Color white` and `BlExporter form element: ...; scaled: ...; export` before judging translucent fills. And
a case with an unknown value does not fail loudly: Skia ignores the declaration and uses the default (a black fill, no
stroke), so "black" means either "the value was not understood" or "black was meant".

```smalltalk
| head rect render |
head := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="20" height="20"'.
rect := [ :attrs | '<rect x="0" y="0" width="20" height="20" ', attrs, '/>' ].
render := [ :svg :points | | form |
	form := (BlSkiaSvgElement new svg: svg; size: 20 @ 20; yourself) asSpartaForm.
	points collect: [ :p | form colorAt: p ] ].

"example: a CSS variable defined on the root, used with a fallback"
render
	value: head, ' style="--x:#0000ff">', (rect value: 'fill="var(--x, #00ff00)"'), '</svg>'
	value: { 10 @ 10 }
```

Text cases draw ten `i` characters at 20 px and take the right edge of the ink (the largest x with alpha > 0.3).
In a proportional font ten `i` are narrow; in a monospace font they are as wide as ten `W`. The values below are in
pixels for a 200 px wide canvas: **46** is the default font, **108** is Consolas.

## Results

Colors are the sampled pixel at the center (or at the listed point). Rows are grouped by the `flatten` step they bear on.

### `var()` (step 4)

| Case | Observed | Reading |
|---|---|---|
| `fill="var(--x, #00ff00)"`, no definition | `#00ff00` | The fallback is used. |
| same, with `--x:#0000ff` on the root `<svg>` `style` | `#00ff00` | **The definition is ignored; the fallback wins.** |
| same, with `--x:#0000ff` on a `<g>` `style` | `#00ff00` | Same. |
| `fill="var(--x)"`, no fallback, no definition | `#000000` | Falls to the default fill. |
| `fill="var(--x)"` with `--x:#00ff00` on the root | `#000000` | A definition alone is not used. |
| `style="fill:var(--x)"` with `--x:#00ff00` on the root | `#000000` | Same inside a `style` attribute. |
| `style="fill:var(--x, #00ff00)"` | `#00ff00` | Fallback works in `style` too. |
| `var(--a, var(--b, #00ff00))` | `#00ff00` | Nested fallbacks work. |
| `var(--a, rgb(0,255,0))` | `#00ff00` | An `rgb()` fallback works. |

So Skia seems to parse `var()` and take its fallback, but it has no custom-property table. Since Pele *defines* its
variables on the root, the conversion is needed whenever the theme or the root definition is meant to win.

### `currentColor` (step 5)

| Case | Observed | Reading |
|---|---|---|
| `fill="currentColor"`, `color="#00ff00"` on the root | `#00ff00` | Works. |
| `color:#00ff00` in the root `style` | `#00ff00` | Works. |
| `color` on a `<g>`, `fill="currentColor"` on the child | `#00ff00` | Inherited per element. |
| `stroke="currentColor"` with `color` on the root | `#00ff00` | Works for stroke. |
| `fill="currentColor"`, no `color` anywhere | `#000000` | Default text color. |
| `fill="currentcolor"` (lower case), `color="#00ff00"` on the root | `#000000` | **Only the exact spelling `currentColor` is understood** (added 2026-10-25; Pele writes `currentColor`). |

Skia handles `currentColor`, including inheritance. `flatten` replaces it with a single foreground color, which loses
that per-element behavior, so this step is a candidate for removal (to be checked against the corpus; Pele's
`currentColor` may depend on `var()`-defined `color`, which Skia would not resolve).

### Nested `<svg>` (step 6)

| Case | Observed | Reading |
|---|---|---|
| `<svg x=10 width=10 height=20 viewBox="0 0 1 1" preserveAspectRatio="none">` with a 1 x 1 rect | `none` at x=5, `#00ff00` at x=15 | Position and non-uniform scale are right. |
| the same as `<g transform="translate(10 0) scale(10 20)">` | identical | The `<g>` form is equivalent. |
| `viewBox="0 0 1 1"` into 20 x 10, default `preserveAspectRatio` | green only at x=10; `none` at x=2, 18 and at y=15 | `meet` with centering: a 10 x 10 square at x 5..15. |
| `viewBox="1 0 2 2"`, rect at x=1..2 | green at x=5, `none` at x=15 | A non-zero `viewBox` origin is honored. |
| content (20 wide) larger than a 10-wide nested viewport | green at x=15 | **No clipping** of nested-`<svg>` overflow, the same as with `<g>`. |

Skia draws nested `<svg>` correctly for these cases. The `<g transform>` form that `flatten` produces behaves the same
way, including the missing clip, so the step is harmless; it may not be necessary.

### `style` attribute (step 7) and `<style>` (step 3)

| Case | Observed | Reading |
|---|---|---|
| `style="fill:#00ff00"` | `#00ff00` | Declarations in `style` are honored. |
| `fill="#ff0000" style="fill:#00ff00"` | `#00ff00` | `style` beats the attribute, as in CSS. |
| `style="fill:#00ff00"` on a `<g>`, rect without fill | `#00ff00` | Inherited. |
| `style="rx:8"`, `style="rx:8px"` (corner pixel) | `none` | `rx` works, with or without `px`. |
| `style="fill:#00ff00;opacity:0.5"` | green at 50 % alpha | `opacity` works. |
| `fill="#ff0000" style="fill:#00ff00 !important"` | `#ff0000` | **`!important` makes Skia drop the declaration**; the attribute stays. |
| `<style>.a{fill:#00ff00}</style>` + `class="a"` | `#000000` | `<style>` ignored. |
| `<style>rect{fill:#00ff00}</style>` | `#000000` | Tag selectors ignored too. |
| `<style><![CDATA[.a{fill:#00ff00}]]></style>` | `#000000` | CDATA does not help. |

Plain declarations in `style` do not need to be converted to attributes for Skia. What *does* need handling inside
`style`: `!important`, `var()` that depends on a definition, `color-mix()`, and the `font:` shorthand (below).
`<style>` rules are not applied at all, so step 3 is required.

### `color-mix()` (step 8)

| Case | Observed |
|---|---|
| `fill="color-mix(in srgb, #ff0000 50%, #0000ff)"` | `#000000` |
| `style="fill:color-mix(in srgb, #ff0000 50%, #0000ff)"` | `#000000` |

Not supported, in an attribute or in `style`. Step 8 is required.

### `<a>` and external `<image>` (steps 9, 10)

| Case | Observed | Reading |
|---|---|---|
| `<a href="https://example.com">` around a rect | `#00ff00` | Drawn normally; the link is transparent to drawing. |
| `<image href="https://example.invalid/x.png">` followed by a rect | `#00ff00` | Does not stop drawing or hang. Whether the image itself draws anything was **not** checked (the rect covers it). |

### Fonts (step 11, and the root `font-size` of step 2)

Ink right edge of ten `i` at 20 px; 46 = default font, 108 = Consolas.

| `font-family` | Ink edge | Reading |
|---|---|---|
| `monospace`, `sans-serif`, `serif` | 46 (ten `W`: 186) | **All three give the same proportional default font.** Generic names are not resolved. |
| `Consolas` (attribute), `style="font-family:Consolas"` | 108 | Works as attribute and in `style`. |
| `Arial`, `Courier New` | 42, 117 | Named fonts work (ten `W`: 188, 118). |
| `Consolas, monospace`, `Consolas, Nonexistent` | 108 | A list works when the first name exists. |
| `Nonexistent, Consolas`, `ui-monospace, Consolas` | 46 | **Only the first name is tried; there is no fallback to later names.** |
| `'Consolas'` with quotes inside the attribute | 46 | **Quoted names are not matched.** |
| `Nonexistent` | 46 | Unknown name: default font. |
| `style="font:20px Consolas"` | 56 | The `font:` shorthand is **not** honored as written (neither 46 nor 108). |
| `font-family="Consolas"` without `font-size` | 129 | The default `font-size` is larger than 16 (about 24, by proportion with the 20 px case). |

The last row explains why `flatten` writes `font-size="16"` on the root: Skia's default is not 16, so leaving it out
changes the layout Pele computed. The generic-name rows are the reason for the theme mapping (`--gt-font-mono` and
friends), and apply to `sans-serif` and `serif` as well: they all draw the same font.

The default font is **not** Arial: `sans-serif` (46) and `Arial` (42) differ, and Skia's default face is a little
thinner and wider than what a browser on Windows uses for `sans-serif` (Arial). For output that should look like the
browser's, map `sans-serif` to `Arial` too (`--gt-font-sans`; `themes/gt-windows.json` does).

### Colors (step 12)

Added on 2026-10-25 (measured with a 10 x 10 `<rect>`; the center pixel is compared with the CSS value).

**Color keywords.** All 148 CSS color keywords (with both the `gray` and the `grey` spellings, and `rebeccapurple`) were
drawn as `fill="<name>"`. **140 are right; 8 draw black** (`transparent` is separate, below):

| Black (not understood) | Works instead |
|---|---|
| `grey`, `darkgrey`, `dimgrey`, `slategrey`, `darkslategrey`, `lightslategrey` | the `gray` spellings of all of them (`gray`, `darkgray`, ...) |
| `lightgray` | `lightgrey` (the **only** `gray`/`grey` pair where the `grey` spelling works and the `gray` one does not) |
| `rebeccapurple` | `#663399` |

So Skia's color table has some spellings and lacks others (it looks like a table with gaps rather than a rule).
`grey` is the one that matters: Pele's C4 examples can say `$bgColor="grey"` (`c4-layout-narrow-screens-1`).

**Case.** Keywords are case-sensitive: `Purple`, `Gray`, `LIME` and `Lime` draw black. `RGB(0,255,0)` draws black too;
`currentColor` works, `currentcolor` draws black.

**Syntax.**

| Value | Observed |
|---|---|
| `#0f0`, `#00ff00`, `#00FF00` | works |
| `rgb(0,255,0)`, `rgb(0 255 0)`, `rgb(0%,100%,0%)` | works |
| `rgba(0,255,0,0.5)`, `rgba(0,255,0,1)` | works (the alpha is honored) |
| `hsl(120,100%,50%)`, `hsl(120 100% 50%)` | **black** |
| `#0f08`, `#00ff0080` (with alpha) | **black** |
| `color(srgb 0 1 0)`, `oklch(...)` | **black** |
| `transparent` as `fill` | **black** (not "no paint") |
| `transparent` as `stroke` | nothing is drawn (the unknown value is ignored, and the default stroke is none) |
| `none` | no paint (works) |
| `inherit` (`fill`, `style="fill:inherit"`, `stroke`) | works: the parent's value |
| `currentColor` | works (`color` from the root or a parent) |

In Pele's output for the 659 examples the color values are `#rrggbb`, `#rgb`, `none`, two `rgb(r, g, b)` values,
`currentColor`, and keywords (`red`, `blue`, `green`, `white`, `yellow`, `gray`, `grey` and `purple`, from `style`
declarations in the diagram sources). `flatten` writes every keyword as `#rrggbb` (and `transparent` as `none`), which
makes the result independent of this table. `hsl()`, 8-digit hex and `color()` do not occur in the examples and are
**not** converted: a theme or a source that uses them will draw black in Skia.

### Text, fonts and emoji

Added on 2026-10-25 (`font-size="20"`, text drawn with `BlSkiaSvgElement`, looked at in a 2x PNG).

**A missing glyph is replaced, but the replacement font seems to be chosen by the first character of the run.** Skia
does look for another font, but (inferred from the three probes below) only once for a `<text>` or `<tspan>` run, from
its first character:

| Text (`font-family="Arial"`) | Observed |
|---|---|
| `Bold A 🤓 end` (emoji inside) | the emoji is a **box**; the rest is Arial, bold works |
| `🤓 Bold first` (emoji first) | the emoji is drawn (Segoe UI Emoji); the **whole run** is in another face (Segoe UI-like, not Arial) and **bold is nearly lost** (below) |
| `gear ⚙ end`, with the emoji in its own `<tspan font-family="Segoe UI Emoji">` | the emoji is drawn, the rest stays Arial, **bold is kept** |

That is the difference between `treeview-12` (every label starts with an emoji: drawn, but the labels lose bold and
change face) and `mindmap-13` (the emoji comes after the text: a box). Wrapping an emoji in its own
`<tspan font-family="Segoe UI Emoji">` gives the browser-like result; `pele2svg` does not do this yet.

**Variation selector.** `⚙` followed by U+FE0F (written as an emoji, as in `🛠️ utils`, `⚙️ config.yaml`) draws the
emoji and then a wide empty advance: the text after it **shifts right** (`treeview-12`). Under `Arial` the selector
itself is drawn as a box (`♥` + U+FE0F gives `♥` and a box). It is not needed to draw the emoji (`⚙ gear` draws it).

**Glyph coverage of the fonts** (one probe each, Windows):

| Character | Arial | Segoe UI Symbol | Segoe UI Emoji |
|---|---|---|---|
| `♥` U+2665 | drawn | drawn | drawn (red) |
| `❤` U+2764 (`er-05`, `flowchart-03`) | **box** | drawn | drawn (red) |
| `✓` U+2713, `★` U+2605 | **box** | drawn | `✓` drawn, `★` box |
| `🤓` `📁` `😀` `✅` | box (unless first in the run) | not tested | drawn |

Plain `❤` therefore draws as a box under the `Arial` mapping, while the browser (which has per-character fallback)
shows it.

**Font families.** `Arial, Segoe UI Emoji`, `Arial,Segoe UI Emoji` and `Arial, 'Segoe UI Emoji'` all behave like
`Arial`: the later names are not used. Bold and italic (`font-weight="bold"`, `font-style="italic"`) work as attributes
on `<text>` and `<tspan>`. With `Segoe UI Emoji` as the family (a font without a bold face) bold is only synthesized and
barely visible: the ink of `Root` grows by 11 % with bold, against 21 % with `Arial`, even when the text has no emoji
and whether or not `xml:space="preserve"` is set.

### What Pele's output contains

The 659 converted examples use only: `svg`, `g`, `text`, `tspan`, `path`, `rect`, `circle`, `ellipse`, `polygon`,
`title`, `desc`, and the attributes `class`, `x`, `y`, `fill`, `stroke`, `d`, `text-anchor`, `width`, `height`, `rx`,
`ry`, `r`, `cx`, `cy`, `transform`, `font-size`, `font-family`, `font-weight`, `font-style`, `xml:space`, `fill-opacity`,
`opacity`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`, `stroke-dasharray`, `stroke-dashoffset`, `points`, plus
`id`, `role` and `aria-*`, `data-*`, `viewBox`, `xmlns`. No gradients, filters, clip paths, masks, `<use>`, `<symbol>`,
`<marker>` (arrowheads are `<path>`s), `<image>` or `<style>` remain after conversion.

Drawing every one of them with Skia and comparing with Chromium in 8 x 8 pixel blocks (median difference 0.0026, none
failed or came out with another size) is the broad check that the one-pixel cases above could not give: shapes, strokes,
dashed lines, rounded corners, translucent fills, `text-anchor`, multi-line `tspan`, italics, rotation (`transform`) and
the icons all match. The differences that remain are the ones in this page (colors, emoji and missing glyphs, fonts).

## What turned out differently

Assumptions made before the review of 2026-10-25, and what was found:

| Assumed | Found |
|---|---|
| Skia understands CSS color names; at most the case matters (`Purple` came out black) | **Case and spelling both**: `grey`, `lightgray`, `rebeccapurple` and four more `grey` forms draw black, so lower-casing was not enough. `flatten` now writes keywords as hex. |
| `transparent` is "no paint" | As a `fill` it draws **black**; `none` is the no-paint value. (As a `stroke` it is ignored, which looks the same as none.) |
| Skia has no font fallback, so a missing glyph is always a box | It has one, but decided **once per run from its first character**. Text that starts with an emoji draws the emoji and changes the face of the whole run (and loses bold); an emoji later in the text is a box. |
| Bold is lost because of the emoji variation selector (U+FE0F) | Bold is (nearly) lost because the run is drawn in an emoji font that has no bold face; the selector only adds an empty advance that shifts the following text. |
| `♥` is drawn as a box in `er-05` | The character is `❤` (U+2764), which Arial lacks; Arial has `♥` (U+2665). |
| Skia's `sans-serif` is "the same font as the browser's" (README, first text) | It is a different, thinner default face. A browser on Windows uses Arial; map it with `--gt-font-sans` (`themes/gt-windows.json` now does). The numbers were already in the Fonts table (46 vs 42), the reading was missed. |
| A list of fonts could carry an emoji fallback (`Arial, Segoe UI Emoji`) | Only the first name is used (the existing row, confirmed with the emoji case). |
| `currentColor` needs no handling | True for the exact spelling `currentColor` (all of Pele's output); `currentcolor` draws black. |
| `inherit` is not understood (a first probe drew black) | It works; the first probe had no parent value, so black was the inherited value. |
| One-pixel samples are enough to judge a feature | Not for translucent colors (premultiplied reads) and not for text: the 659-example comparison found the color and emoji cases that the baseline rows did not. |

### Stroke width 0 (step 13)

MathJax draws each formula in `<g stroke="currentColor" fill="currentColor" stroke-width="0">`. A browser draws no stroke
for a width of 0. **Skia draws a stroke of about 1 px anyway**, so the glyphs come out visibly bold. For a flowchart with three
formulas, the same SVG with `stroke="none"` instead had 26 % fewer dark pixels in Skia (2.34 % against 3.16 % of the picture)
and looked like Chromium's drawing. `stroke-width="0.5"` was not examined. `flatten` therefore writes `stroke="none"` on every
element that has `stroke-width="0"`.

## Summary: what Skia needs from `flatten`

| Step | Needed for Skia? | Evidence |
|---|---|---|
| 3 `<style>` class rules | **yes** | not applied (class, tag selector, CDATA) |
| 4 `var()` | **yes**, for definitions | only the fallback is used; definitions are ignored |
| 5 `currentColor` | **no**, apparently | works, with inheritance |
| 6 nested `<svg>` | **no**, for the tested cases | position, scale, `meet`, `viewBox` offset are right; no clip either way |
| 7 `style` → attributes | **partly** | plain declarations work; `!important`, `font:`, and anything with `var()`/`color-mix()` do not |
| 8 `color-mix()` | **yes** | not supported |
| 9 `<a>` | **no**, apparently | drawn normally |
| 10 external `<image>` | unclear | does not break drawing; the image itself was not looked at |
| 11 generic font names | **yes** | all generic names draw the default font |
| 2 root `font-size` | **yes** | the default size is not 16 |
| 13 stroke width 0 | **yes** | a stroke of width 0 is drawn as 1 px (bold MathJax glyphs) |
| 12 color keywords (new) | **yes** | 8 of 148 keywords draw black, and case matters; `transparent` draws black |
| 11 `sans-serif` → Arial (theme) | **yes**, for a browser-like look | the default face differs from Arial |
| emoji `<tspan font-family>` | **not done**; would fix `mindmap-13` | emoji inside a run are boxes; text starting with an emoji changes face and loses most of its bold |

## Not covered, and caveats

- One or two pixels per case. A wrong result that happens to hit the same color would not be noticed. Shapes, strokes,
  dashes, translucency, `text-anchor` and `tspan` are covered only by the comparison of the 659 examples (above);
  gradients, filters, markers, clip paths and `<use>` are untested because Pele's output does not use them.
- Only `BlSkiaSvgElement` on Windows. WebView2 was not measured (the README reports that the converted SVGs match there).
- The nested `<svg>` and `<a>` rows used simple inputs; Pele's icon `<svg>` elements are more varied.
- "Needed: no" means "Skia coped with the tested input", not that removing the step is safe. Removing a step should be
  checked against the whole corpus (`npm test`, and the `Pele2svgExamples` in GToolkit).
- The Skia version is unknown. The next step is to obtain the Skia sources that GToolkit bundles (`modules/svg`:
  `SkSVGDOM`, the attribute parser and the presentation-attribute table) and compare the findings above with the
  implementation: this would confirm *why* `var()` takes only its fallback, whether `currentColor` and nested `<svg>`
  are complete, and which other properties and elements are supported but not yet used by Pele2svg.
