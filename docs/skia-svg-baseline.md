# Skia SVG baseline

What does GToolkit's `BlSkiaSvgElement` actually draw, ignore or get wrong for the CSS and SVG features that
`pele2svg` converts? This page records a first, small set of measurements. It is a **baseline**, not a complete
specification: every row is one minimal SVG, drawn once, with one or two pixels read back.

Why it matters: each step of `flatten` (see [Design notes](development.md#design-notes)) exists because Skia lacks
something. Some of those assumptions can now be checked, and the steps that Skia handles by itself are candidates for
removal; the ones it does not handle are candidates for being supported on the Skia side.

## Environment

| | |
|---|---|
| Date | 2026-10-20 |
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

## Not covered, and caveats

- One or two pixels per case. A wrong result that happens to hit the same color would not be noticed; shapes, strokes,
  gradients, filters, markers, clip paths and text layout (`text-anchor`, `tspan`) are untested.
- Only `BlSkiaSvgElement` on Windows. WebView2 was not measured (the README reports that the converted SVGs match there).
- The nested `<svg>` and `<a>` rows used simple inputs; Pele's icon `<svg>` elements are more varied.
- "Needed: no" means "Skia coped with the tested input", not that removing the step is safe. Removing a step should be
  checked against the whole corpus (`npm test`, and the `Pele2svgExamples` in GToolkit).
- The Skia version is unknown. The next step is to obtain the Skia sources that GToolkit bundles (`modules/svg`:
  `SkSVGDOM`, the attribute parser and the presentation-attribute table) and compare the findings above with the
  implementation: this would confirm *why* `var()` takes only its fallback, whether `currentColor` and nested `<svg>`
  are complete, and which other properties and elements are supported but not yet used by Pele2svg.
