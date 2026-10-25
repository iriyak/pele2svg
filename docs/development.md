# Development and verification

## What has been checked

Using Pele's published examples ([pele.run/examples](https://pele.run/examples)) — 32 diagram types, 58 featured examples,
the 520 documentation examples and the 81 layout cases on the per-type pages (659 in total, Pele 1.10.0).

The by-hand checks below (`xmllint`, resvg, GToolkit and WebView2) were made on the 578 featured and documentation
examples, before the layout cases were added. `npm test` covers all 659.

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

- The 81 layout cases in GToolkit and WebView2. `npm test` checks only that they convert cleanly.
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
  58 featured examples, its 520 documentation examples, its 81 layout cases and 170 sources from its own test corpus — and checks that the
  output has no `var()`, `style` attribute, `<style>`, `currentColor`, `color-mix()`, `<a>`, external `<image>` or
  nested `<svg>`, that it is well-formed, and that converting it again changes nothing. It also repeats the featured
  examples with each theme in [`themes/`](../themes) and runs `--batch` on a whole corpus file.

These tests need no GToolkit. What they cannot check is how a renderer draws the result; that was looked at by eye (see above).

The featured, documentation and layout fixtures are generated from a clone of the Pele repository, so they can be
refreshed after a Pele update (see [`test/fixtures/README.md`](../test/fixtures/README.md)):

```sh
node scripts/build-fixtures.mjs --pele <path to the pele clone>
```

[`examples/`](../examples) has Mermaid sources and the converted SVGs. `eventmodeling-1.svg` is made with
[`themes/gt-windows.json`](../themes/gt-windows.json) (`monospace` → `Consolas`); the other two have no `monospace` text.

## Design notes

### What pele2svg is

`pele2svg` is a pre-processor that evaluates CSS features ahead of time, so that Skia's SVG module does not have to. It
was written on the assumption that Skia lacks those features; the [Skia SVG baseline](skia-svg-baseline.md) later
measured that assumption, and it holds only in part (see
[Which steps does Skia really need?](#which-steps-does-skia-really-need)). It is not a general CSS engine. Pele writes its SVG as if a browser were going to draw it, so colors, fonts and some geometry are expressed with
CSS features: custom properties, `style` attributes, `color-mix()`, `currentColor`, nested `<svg>` elements. `flatten`
evaluates those features *once, ahead of time*, and writes the result back as plain SVG presentation attributes. After
that, the renderer has nothing left to evaluate.

Seen this way, each conversion step does one of four kinds of work:

| Kind | What it means here | Steps |
|---|---|---|
| **Evaluation** | Compute a value from an expression and an environment. | `var()`, `currentColor`, `color-mix()` |
| **Cascade** | Decide which of several competing declarations wins. | `<style>` class rules, `style` → attributes |
| **Structural rewrite** | Change the shape of the SVG tree, not its values. | nested `<svg>` → `<g>`, `<a>` → `<g>`, external `<image>` removal |
| **Name resolution** | Map a name to something the renderer knows. | generic font families → real font names |

The last step is not a conversion but a check: it looks for anything the earlier steps should have removed.

### The steps, in the order `flatten` runs them

The order is part of the design (see [Ordering constraints](#ordering-constraints)). It differs slightly from the
numbering in the header comment of `pele2svg.mjs` and in the README table, which group steps by topic.

| # | Step | What it actually does | Example | CSS / SVG concept |
|---|---|---|---|---|
| 1 | Read the root `style` | **Builds the environment.** Collects the custom properties (`--pele-*` …) from the root `<svg>`'s `style`. Theme values are put into the table first and are not overwritten; each collected value is itself passed through `var()` resolution, so variables may refer to variables. | `--_s:#f3f3f3;--_fg:…` → variable table | scope, environment |
| 2 | Root `font-family` | **Lowers an inherited property to an attribute.** The root `style` is removed; `font-family` becomes an attribute, `font-size` is fixed at 16 (the `font:` shorthand is not interpreted as a whole). Skia's own default size is not 16 (about 24 in the [baseline](skia-svg-baseline.md)), so leaving it out would change the layout Pele computed. | `style="font-family:…"` → `font-family="…" font-size="16"` | inheritance (approximated) |
| 3 | `<style>` class rules | **Selector evaluation.** For rules of the form `.name { … }` (also `.a, .b { … }`), the declarations are prepended to the `style` attribute of every element that has the class, so an element's own `style` is later and wins. The `<style>` element is removed only if all its rules were of this simple form. | `.a{fill:red}` + `<g class="a">` → `<g style="fill:red">` | cascade, a minimal selector subset |
| 4 | `var()` | **Expression evaluation.** Looks the name up in the variable table; if it is missing, uses the fallback; repeats while the result still changes (at most 20 rounds), so nested `var()` and variables whose values contain `var()` are resolved. | `var(--a, var(--x, #fff))` → `#205ea6` or `#fff` | custom properties |
| 5 | `currentColor` | **Resolves an inherited color.** Replaced by the foreground color (`--_fg`, else `--pele-fg`, else black). Per-element `color` is *not* tracked. | `currentColor` → `#1f1f1f` | `color` inheritance (approximated) |
| 6 | Nested `<svg>` | **Coordinate-system change.** From `x`, `y`, `width`, `height`, `viewBox` it computes the scale and offset equivalent to `preserveAspectRatio="xMidYMid meet"` and emits a `<g transform>`. `</svg>` closers are paired with their openers by a depth counter. | `<svg x y width height viewBox>` → `<g transform="translate() scale()">` | `viewBox`, `preserveAspectRatio` |
| 7 | `style` → attributes | **Reproduces cascade precedence.** Each declaration becomes an attribute of the same name; an existing attribute of that name is replaced, because in CSS a `style` declaration beats a presentation attribute. `rx`/`ry` lose a trailing `px`. `!important` is dropped (Skia discards a declaration that has it, so the attribute underneath would win). | `style="fill:#f00;rx:4px"` → `fill="#f00" rx="4"` | cascade order, units |
| 8 | `color-mix()` | **Function evaluation.** Linear interpolation in sRGB, written as `#rrggbb`. Only opaque colors given as `#rgb`, `#rrggbb`, `rgb()`, `white` or `black` are understood; otherwise a warning is recorded and the text is left alone. | `color-mix(in srgb,#000 50%,#fff)` → `#808080` | color functions |
| 9 | `<a>` | **Element rewrite.** Links are useless in a Skia view, so `<a …>` becomes a bare `<g>` and its attributes are discarded. | `<a href="…">` → `<g>` | — |
| 10 | External `<image>` | **Removal of what cannot be fetched.** An `<image>` whose `href` starts with `http:` or `https:` is deleted and a warning is recorded. | `<image href="https://…"/>` → (nothing) | external resources |
| 11 | Generic font names | **Name resolution.** `monospace`, `sans-serif`, `serif` are replaced by `--gt-font-mono`, `--gt-font-sans`, `--gt-font-serif` from the theme, if given. In Skia all three generic names draw the same default font, only the first name of a family list is tried, and quoted names do not match. | `font-family="monospace"` → `font-family="Consolas"` | font matching |
| 12 | Final check | **Verification only.** Adds a warning if `var(`, `<style` or `color-mix(` is still in the output. | — | — |

`asElementFromSvg:` and `--svg` run exactly the same `flatten` on an SVG that already exists; only the Pele rendering
step is skipped.

### Which steps does Skia really need?

The design above was written on the assumption that Skia lacks the CSS features Pele uses. The
[Skia SVG baseline](skia-svg-baseline.md) measured it with minimal SVGs drawn by `BlSkiaSvgElement` (GToolkit v1.1.624,
Windows). The assumption holds for some steps and not for others:

| Step | Measured in Skia | Status in `flatten` |
|---|---|---|
| 3 `<style>` class rules | not applied (class, tag selector, CDATA) | required |
| 4 `var()` | the fallback is used; definitions are ignored | required |
| 5 `currentColor` | honored, including per-element inheritance | kept as a precaution |
| 6 nested `<svg>` | position, scale, `meet` and `viewBox` origin are right; overflow is not clipped (same as `<g>`) | kept as a precaution |
| 7 `style` → attributes | plain declarations are honored; `!important`, the `font:` shorthand, and values with `var()` / `color-mix()` are not | partly required |
| 8 `color-mix()` | not supported | required |
| 9 `<a>` | drawn normally | kept as a precaution |
| 10 external `<image>` | does not stop drawing; the image itself was not examined | unclear |
| 11 generic font names | all draw the same default font | required |
| 2 root `font-size` | Skia's default is not 16 | required |

"Kept as a precaution" means that Skia coped with the inputs used in the baseline, not that the step may be removed.
Pele's own SVG is more varied than those inputs. For example, step 5 as implemented replaces `currentColor` with one
foreground color, which discards the per-element `color` that Skia would honor; but if Pele defines `color` through a
`var()`, Skia could not resolve it without that step. Removing or narrowing a step should be checked against the whole
corpus (`npm test`) and the examples in GToolkit.

### Ordering constraints

Several steps depend on an earlier one having run:

- **1 before 4.** `var()` needs the variable table.
- **3 before 4 and 7.** The declarations that step 3 copies into `style` may contain `var()` or `currentColor`; they
  must be inside the SVG text before those are resolved, and must be in `style` before step 7 moves them to attributes.
- **4 and 5 before 7 and 8.** Step 7 should move *values*, not expressions, and step 8 needs concrete colors to mix.
  `color-mix(in srgb, var(--a) 40%, var(--b))` is only a valid input for step 8 after `var()` is gone.
- **12 last.** It is a check on everything above.

Steps 6 to 11 do not depend on each other in the same way; their order in the code is a convention, not a requirement.

### Deliberate simplifications

`flatten` knows what Pele writes, and does not claim to implement CSS. The known gaps are:

- `currentColor` is a single foreground color; `color` is not inherited per element. (Skia itself honors per-element `color`; see the baseline.)
- `font-size` of the root is fixed at 16 and the `font:` shorthand is not parsed.
- `<style>` support covers `.class` selectors only. Tag, id, attribute, descendant selectors and `@` rules are left in
  place, and the final check reports the remaining `<style>`.
- `color-mix()` supports opaque sRGB only, with the color syntaxes listed above.
- `style` is split on `;` and `:` without understanding CSS strings or `url(…)`.
- Nested `<svg>` is converted with `xMidYMid meet` only; other `preserveAspectRatio` values and `overflow` are ignored.

These are enough for the 659 published examples (see [What has been checked](#what-has-been-checked)). For SVGs from
other tools they are the first places to look when a drawing is wrong.

### Text processing, not a tree

`flatten` works on the SVG as a string, with regular expressions (`TAG_RE`, `ATTR_RE`, `VAR_RE`, …). That is simple and
has no dependency, and it is safe for Pele's output because the output is regular, but it relies on assumptions:

- attribute values are written in double quotes and do not contain `>`;
- tags carry no unusual whitespace between name and attributes;
- `<style>` and `<svg>` tags are distinguishable by a simple pattern, with nesting recovered by counting.

SVG from other tools may break these. The test suite includes a second pass over the output ("converting it again
changes nothing") to catch some of that; it does not prove that the regexes are right for arbitrary input.

### Exploration: the same conversion as tree rewrites with SmaCC

The steps above can also be read as rewrite rules over a parse tree. An experiment in a GToolkit image
(GT v1.1.624; the code is not part of this repository) tried this for step 4, `var()`, using the `CSSParser` and
`SmaCCRewriteEngine` that ship with GT. It worked:

```smalltalk
| engine rule |
engine := SmaCCRewriteEngine new.
engine propertyAt: #theme put: { '--x' -> '#205ea6' } asDictionary.
rule := SmaCCRewriteRuleFileParser parse: 'Parser: CSSParser
CSSFunctionNode
->
>>>``match name value = ''var(''
	ifTrue: [ (self rewriteEngine propertyAt: #theme)
		at: (self sourceFor: match items first)
		ifAbsent: [ self rewrite: (match items at: 3) ] ]
	ifFalse: [ self sourceFor: match ]``<<<'.
engine rewriteRule: rule.
engine rewriteTree: (CSSParser parse:
	'a { fill: var(--a, var(--x, #fff)); stroke: var(--a, var(--b, #123456)); width: 3px }')
"=> 'a { fill: #205ea6; stroke: #123456; width: 3px }'"
```

What this showed:

- The variable table maps to an engine property, the fixed-point loop of `resolveVars` maps to recursion with
  `self rewrite:` on the fallback, and everything outside the matched nodes is left byte for byte as it was.
- Tree patterns with `` `name` `` placeholders (`var(`n`, `f`) -> `f``) did **not** work with `CSSParser`: its scanner
  treats the backtick as an ordinary delimiter, so the pattern is parsed as a literal CSS function with extra tokens and
  never matches. Matching on the node type (`CSSFunctionNode`) and doing the work in a code block is the form that
  worked. A declarative pattern form would need a CSS grammar that supports pattern tokens.
- Inside a code block, `self replace:with:` and `insert:before:` + `delete:` gave an empty result in this image. Returning the new text as the value of the block did work.
- There is no SmaCC parser for SVG/XML in the image, so the structural steps (6, 9, 10) cannot be tried until one exists.

How well each step would map:

| Step | Fit for tree rewriting | Why |
|---|---|---|
| 4 `var()`, 5 `currentColor`, 11 fonts | good | local replacement of one node by a value computed from a table |
| 8 `color-mix()` | fair | the matching is local, but the arithmetic is code anyway |
| 7 `style` → attributes | fair | needs the CSS declaration grammar *and* a condition ("replace an existing attribute of that name") |
| 1 variable table, 3 class rules | poor | they need whole-document information (all variable definitions; all rules matched against all classes); this is a pass that gathers facts, not a local rewrite |
| 6, 9, 10 structural | good, once an XML grammar exists | pairing `<svg>` with `</svg>` is trivial on a tree |
| 12 final check | not a rewrite | a traversal that reports |

A practical split would be: gather the environment with a visitor, apply the local rewrites as rules, and keep
verification as a separate traversal. The 659-example corpus and `test/corpus.test.js` would serve as the oracle for such
an implementation, comparing canonicalized XML rather than bytes, because attribute order is not preserved identically
by both approaches.
