# Skia in GToolkit: which version, and what its SVG module does

This page records **which Skia GToolkit (GT) draws SVG with**, how that was found, and what the source of that Skia's
SVG module (`modules/svg`) says about the behaviors that [skia-svg-baseline.md](skia-svg-baseline.md) measured. It is a
reference for later work: reading the color table, the font manager GT passes in, and re-measuring on newer GT versions.

Written 2026-11-08. Everything marked **(verified)** was seen directly in a file or a running image; everything marked
**(inferred)** is a reading that has not been tested.

## Summary

| | |
|---|---|
| GT version looked at | v1.1.668 (Windows 64 bit) |
| Native library | `bin\Skia.dll` (27,373,568 bytes), the crate `Skia` of [feenkcom/libskia](https://github.com/feenkcom/libskia) |
| Rust binding | `skia-safe` / `skia-bindings` **0.90.0** (verified: strings in the dll, `Cargo.lock` of libskia) |
| Skia milestone | **m142** (verified: `[package.metadata] skia = "m142-0.89.1"` of `skia-bindings 0.90.0`; `SK_MILESTONE 142` in the `chrome/m142` branch) |
| SVG entry point | `skia_safe::svg::Dom` (`SkSVGDOM`) through six C functions in `libskia/src/svg.rs` |
| Baseline measured with | GT v1.1.624. Its `Skia.dll` has exactly the same size as that of v1.1.668 (27,373,568 bytes, from the Windows file properties of both), which suggests the same Skia; **not** confirmed by a hash (see [Open items](#open-items)). |

## How the version was found

The chain, from the Bloc element down to the Skia source. Each step can be repeated.

1. **The element and its package.** `BlSkiaSvgElement` is in the package `Sparta-Skia`. Following the Iceberg
   repositories from there (done by hand in the image):

   ```smalltalk
   GtGitRepositoryRegistryHistory instance repositoryIncludingPackage: 'BlocPac-Imager'.
   "=> git@github.com:feenkcom/bloc-pac.git, which contains the package Sparta-Skia"
   GtGitRepositoryRegistryHistory instance repositoryIncludingPackage: 'Sparta-Skia'.
   "=> git@github.com:feenkcom/Sparta.git"
   ```

   The README of [Sparta](https://github.com/feenkcom/sparta) says that it needs an extra Skia VM plugin, which is
   downloaded and installed for the current OS and VM.

2. **The plugin is `Skia.dll`.** Its path, from the image (verified):

   ```smalltalk
   SkiaLibrary uniqueInstance win32LibraryName
   "=> '...\GlamorousToolkit-Windows-x86_64-v1.1.668\bin\Skia.dll'"
   ```

   `SkiaLibrary` is a subclass of `FFILibrary`. `SkiaSvgDom` is a `GtBoxerValueBox`, so the library is reached through
   `SkiaLibrary`, not through the class itself.

3. **Strings in the dll.** A Rust library keeps the paths of its sources in its panic messages. Reading `Skia.dll` as
   bytes and searching for `skia-safe-` and `skia-bindings-` (verified) found, among others:

   ```
   ...\skia-safe-0.90.0\src\core\font.rs
   ...\skia-safe-0.90.0\src\modules\paragraph\paragraph_builder.rs
   ...skia-bindings-0.90.0/skia/src/core/SkPath.cpp
   ...skia-bindings-0.90.0/skia/modules/skshaper/src/SkShaper_harfbuzz.cpp
   ```

   ```smalltalk
   | bytes |
   bytes := 'C:\...\bin\Skia.dll' asFileReference binaryReadStreamDo: [ :s | s contents ].
   bytes indexOfSubCollection: 'skia-safe-' asByteArray startingAt: 1
   ```

   (The version string appears in many paths. Take the text up to the next non-printable byte around the hit.)

4. **libskia pins the same version** (verified, clone of the repository): `libskia/Cargo.toml` has
   `skia-safe = "0.90"`, and `Cargo.lock` has `skia-safe 0.90.0` and `skia-bindings 0.90.0`. The crate is named `Skia`
   with `crate-type = ["cdylib", "lib"]`, which is why the file is `Skia.dll`. `default = ["svg", "textlayout"]`.

5. **The milestone.** The published crate `skia-bindings 0.90.0` does not contain Skia's sources, but its `Cargo.toml`
   does:

   ```toml
   [package.metadata]
   skia = "m142-0.89.1"
   ```

   (m142 = the Skia milestone; 0.89.1 = the rust-skia release that first used it.) A `cargo build` in the libskia
   clone downloads the crate into `%USERPROFILE%\.cargo\registry\src\index.crates.io-*\skia-bindings-0.90.0\`; the file
   is there even when the build itself fails (it failed on `Unable to locate LLVM installation`, which does not matter
   for this purpose).

6. **The Skia source.** A sparse clone of the `chrome/m142` branch (verified: `include/core/SkMilestone.h` says
   `#define SK_MILESTONE 142`):

   ```powershell
   git clone --depth 1 --branch chrome/m142 --filter=blob:none --sparse https://skia.googlesource.com/skia skia-m142
   cd skia-m142
   git sparse-checkout set modules/svg include/core
   ```

   `git sparse-checkout set` takes **directories** (cone mode): giving it the file `include/core/SkMilestone.h` fails
   with `'...' is not a directory`, and a second `set` replaces the first list, it does not add to it. Add `src/utils`
   to read the color table (see [Open items](#open-items)).

   The source read for this page is the head of the `chrome/m142` branch on 2026-11-08. `skia-bindings 0.90.0` is built
   from a specific Skia commit (the submodule of rust-skia at the revision `da4579b39b75fa2187c58af5d33d6c1499a2ed42`,
   from the crate's `.cargo_vcs_info.json`, the same hash that appears in the name of the prebuilt-binary archive
   `0.90.0/da4579b39b75fa2187c5-x86_64-pc-windows-msvc-d3d-gl-pdf-svg-textlayout-static`). The branch head may contain
   later fixes. For the questions below this makes no visible difference, but it is a reason to say "m142", not "this
   exact commit".

## What libskia gives GT: six functions

`libskia/src/svg.rs` (verified). All parsing and drawing is done by Skia's `SkSVGDOM`; libskia adds no CSS handling.

| C function | What it does |
|---|---|
| `skia_svg_parse(svg_string, font_mgr)` | `Dom::from_str(svg, font_mgr)`. **The `FontMgr` is chosen by the caller (GT).** |
| `skia_svg_set_container_size(dom, w, h)` | `dom.set_container_size(Size::new(w, h))` |
| `skia_canvas_render_svg(canvas, dom, x, y)` | `translate(x, y)`, `dom.render(canvas)`, `translate(-x, -y)`. No clip. |
| `skia_svg_dom_drop` | drops the DOM |
| `skia_svg_canvas_new/get_canvas/end/drop` | an `SkSVGCanvas`, that is, **writing** SVG from drawing calls (not used for reading SVG) |

The important one is the third: it calls `Dom::render(canvas)`. In Skia that creates an **empty**
`SkSVGPresentationContext`. The other entry point, `renderNode(canvas, pctx, id)`, takes a context from the caller;
libskia does not use it. See `var()` below.

## What the m142 source says (against the baseline)

Files are in `modules/svg/` of the `chrome/m142` branch. "Baseline" is [skia-svg-baseline.md](skia-svg-baseline.md).

### `var()`: parsed, stored, never resolved from the SVG

| Baseline | Source |
|---|---|
| The fallback is used; a definition on the root or a `<g>` is ignored | `SkSVGAttributeParser::parseSVGColor` parses `var(--name, fallback)`: the name (without `--`) is pushed into `SkSVGColor::Vars` and the fallback is parsed recursively (at most 32 names). At draw time `SkSVGRenderContext::resolveSvgColor` looks each name up in `fPresentationContext->fNamedColors`, a `THashMap<SkString, SkSVGColorType>*`. `SkSVGDOM::render` builds `SkSVGPresentationContext pctx;` with `fNamedColors = nullptr`, so no lookup happens and the fallback colour is returned. |
| `var(--x)` without fallback draws black | the no-fallback branch builds `SkSVGColor(SK_ColorBLACK, vars)` |
| `--x:#0000ff` in `style` has no effect | `--x` is neither in the list of presentation attributes nor in `gAttributeParseInfo`, so `set_string_attribute` finds nothing and drops it. Nothing in the module reads custom-property definitions from the document. |

Consequences:

- `var()` works **only for colours** (`fill`, `stroke`, `color`, `stop-color`, ... , everything that is an
  `SkSVGColor` or `SkSVGPaint`). There is no `var()` for lengths or numbers.
- The only way to make a `var()` definition count is to call `renderNode` with a `pctx` whose `fNamedColors` is filled.
  That needs a new C function in libskia and a Pharo binding, that is, a change to GT, not to pele2svg (inferred: whether
  `skia-safe` 0.90.0 exposes `renderNode` with a context was **not** checked). Until then `flatten`'s step 4 is required.

### `<style>` and the cascade

| Baseline | Source |
|---|---|
| `<style>` is ignored (class, tag selector, CDATA) | `gTagFactories` in `SkSVGDOM.cpp` has no `style`. `construct_svg_node` returns `nullptr` for an unknown tag and the node, **with its children**, is dropped. There is no selector code in the module. |
| `style="..."` is honored, beats the attribute | `SetStyleAttributes` splits at `;`, then at the first `:` (`StyleIterator`), trims, and calls `set_string_attribute` for each pair, the same path as an XML attribute. Attributes are applied in the order of the XML attributes, so whether `style` wins over `fill="..."` depends on which comes later. The baseline had `fill` before `style` (`style` won); the reverse order was **not** measured. |
| `!important` drops the declaration | the value `#00ff00 !important` is parsed as a colour and then `parseEOSToken()` finds trailing text, so the parse fails and the property is not set. |
| the `font:` shorthand does nothing | `font` is not in the list of properties. |

### Colours

`parseColorToken` tries, in this order: hex, named colour, `rgba(...)`, `rgb(...)`.

| Baseline | Source |
|---|---|
| `#0f0` and `#00ff00` work; `#0f08` and `#00ff0080` draw black | `parseHexColorToken` accepts only 3 or 6 digits (`default: return false`). |
| `rgb(0,255,0)`, `rgb(0 255 0)`, `rgb(0%,100%,0%)` work | `parseColorComponentToken` takes an integer, an integer with `%`, or a fractional number with `%`; `parseSepToken` accepts a comma or white space. |
| `rgba(...)` honors alpha | `parseRGBAColorToken`: the fourth component is a scalar in 0..1 (`parseColorComponentScalarToken`). |
| `RGB(...)`, `Purple`, `LIME` draw black | the function name and the identifier are compared case-sensitively. |
| `hsl()`, `color()`, `oklch()` draw black | no parser exists for them. |
| `currentColor` works, `currentcolor` draws black | `parseExpectedStringToken("currentColor")`: exact match. Resolved by `resolveSvgColor` to `fInherited.fColor`, which is inherited down the tree. |
| `transparent` as a fill draws black | `transparent` is not a name that the colour parser accepts (it is not in the colour table, see Open items); the failed parse leaves the default fill (black). `none` has its own branch in `parse(SkSVGPaint*)`. |
| `inherit` works | `SkSVGAttributeParser::parseProperty` (header) compares the value with `"inherit"` first and returns `kInherit` for any property. Exact, lower case. |
| 8 of 148 names draw black (`grey`, `lightgray`, `rebeccapurple`, ...) | **not explained yet**: names go to `SkParse::FindNamedColor` (`src/utils/SkParse.cpp`), which is not in this checkout. |

### Text and fonts

| Baseline | Source |
|---|---|
| Default `font-size` is not 16 (about 24) | `SkSVGPresentationAttributes::MakeInitial()`: `fFontSize = SkSVGLength(24)`. The default family is `"Sans"`. |
| Only the first name of a family list is tried | `parse(SkSVGFontFamily*)`: it takes the text up to the first `,`. The comment says "For now, we only use the first entry and rely on the font manager to handle fallback." |
| Quoted names do not match | the quotes are not removed. |
| `monospace`, `sans-serif`, `serif` all draw the same default font | `SkSVGText.cpp` calls `fontMgr()->legacyMakeTypeface(family, style)` with the name as written, and when that answers null, `legacyMakeTypeface(nullptr, style)`. Nothing in the module maps generic names. What `legacyMakeTypeface("sans-serif")` answers is decided by the `FontMgr` that GT gave to `skia_svg_parse` (inferred). |
| A missing glyph is replaced, "chosen once per run from its first character" | `shapePendingBuffer` makes a run iterator with `SkShaper::MakeFontMgrRunIterator(utf8, bytes, font, fontMgr)`, which is meant to switch fonts per character through `matchFamilyStyleCharacter` of the `FontMgr`. The baseline saw something else; the likeliest cause is the `FontMgr` GT passes (inferred; **to be checked**). |
| Bold and italic work as attributes | `font-weight`, `font-style` are in the list; they go into the `SkFontStyle` given to `legacyMakeTypeface`. Whether the face has a real bold is up to the font. |
| `<tspan>` and `text-anchor` work | `tspan`, `textPath`, `text` are registered tags; `text-anchor` is a property. |

### Strokes

| Baseline | Source |
|---|---|
| `stroke-width="0"` is drawn as a stroke of about 1 px | `SkSVGRenderContext::strokePaint()` does `p->setStrokeWidth(resolved width)` with no special case for 0, and an `SkPaint` with stroke width 0 is a hairline (a documented behaviour of `SkPaint`; inferred, not looked up in this checkout). CSS says width 0 draws nothing. |
| `stroke="transparent"` draws nothing | the failed parse leaves the initial `stroke`, which is `none` (`MakeInitial`: `fStroke = SkSVGPaint::Type::kNone`). |
| dashes work | `dash_effect` builds an `SkDashPathEffect`; an odd list is repeated, as in the SVG spec. |

### Structure

| Baseline | Source |
|---|---|
| Nested `<svg>`: position, scale, `meet` and `viewBox` offset are right; no clip | `SkSVGSVG::onPrepareToRender` builds a translate and `ComputeViewboxMatrix(viewBox, viewport, preserveAspectRatio)`, then `canvas()->concat(...)`. There is no `clipRect` and no `overflow` handling. `ComputeViewboxMatrix` implements `meet`, `slice` and `none`, and all nine alignments. |
| `<a>` is drawn like a `<g>` | the tag `a` is registered with `SkSVGG::Make()`. |
| external `<image>` | `image` is registered; whether an external `href` is fetched depends on the `ResourceProvider`. `SkSVGDOM` uses a `NullResourceProvider` when none is given (inferred from the source; not run). |

## What Skia's SVG module can and cannot read

### Elements (the table `gTagFactories`, plus `svg`)

`a`, `circle`, `clipPath`, `defs`, `ellipse`, `filter` and the filter primitives (`feBlend`, `feColorMatrix`,
`feComponentTransfer`, `feComposite`, `feDiffuseLighting`, `feDisplacementMap`, `feDistantLight`, `feFlood`, `feFuncA/B/G/R`,
`feGaussianBlur`, `feImage`, `feMerge`, `feMergeNode`, `feMorphology`, `feOffset`, `fePointLight`, `feSpecularLighting`,
`feSpotLight`, `feTurbulence`), `g`, `image`, `line`, `linearGradient`, `mask`, `path`, `pattern`, `polygon`, `polyline`,
`radialGradient`, `rect`, `stop`, `svg`, `text`, `textPath`, `tspan`, `use`.

**Not present:** `style`, `symbol`, `marker`, `switch`, `foreignObject`, `title`, `desc`, `metadata`. An unknown element is
dropped together with its children.

### Presentation properties (`SkSVGNode::parseAndSetAttribute`, 30 names)

`clip-path`, `clip-rule`, `color`, `color-interpolation`, `color-interpolation-filters`, `display`, `fill`,
`fill-opacity`, `fill-rule`, `filter`, `flood-color`, `flood-opacity`, `font-family`, `font-size`, `font-style`,
`font-weight`, `lighting-color`, `mask`, `opacity`, `stop-color`, `stop-opacity`, `stroke`, `stroke-dasharray`,
`stroke-dashoffset`, `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-opacity`, `stroke-width`,
`text-anchor`, `visibility`.

Other attributes that are read (`gAttributeParseInfo`): `cx`, `cy`, `fx`, `fy`, `r`, `rx`, `ry`, `x`, `y`, `x1`, `x2`,
`y1`, `y2`, `width`, `height`, `viewBox`, `preserveAspectRatio`, `transform`, `filterUnits`, `text`, `xlink:href`, and
`style`. (More are set by the element classes themselves, for example `d`, `points`, `offset`.)

**Not read** (so CSS or attributes using them are ignored, **inferred** from their absence in these lists):
`font:` shorthand, `text-decoration`, `letter-spacing`, `font-variant`, `dominant-baseline`, `paint-order`,
`vector-effect`, `mix-blend-mode`, `overflow`, `marker-*`, `shape-rendering`, and `href` without the `xlink:` prefix
(**to be checked** in the element classes: only `xlink:href` is in `gAttributeParseInfo`).

## What this means for `flatten`

| Step | Reading |
|---|---|
| 3 `<style>` | **Required.** No `<style>` and no selectors in Skia. |
| 4 `var()` | **Required** while GT draws with `Dom::render`. Skia can resolve `var()` only for colours and only from a table that the caller supplies. |
| 5 `currentColor` | **Probably removable.** Skia resolves it by inheritance. Caveat: if `color` itself is given as `var()`, step 4 must run first. Check with the corpus before removing. |
| 6 nested `<svg>` | **Probably removable** for `xMidYMid meet` and other `preserveAspectRatio` values; Skia implements all of them, and the `<g transform>` form has the same missing clip. Check with the corpus. |
| 7 `style` to attributes | **Partly required**: for `!important`, the `font:` shorthand, `var()` and `color-mix()` values. Plain declarations are honored. |
| 8 `color-mix()` | **Required.** Not implemented. |
| 9 `<a>` | **Removable.** Registered as `SkSVGG`. |
| 10 external `<image>` | Unclear. Depends on the `ResourceProvider`. |
| 11 generic font names | **Required**, as long as GT's `FontMgr` does not map them (to be checked, see below). |
| 12 colour keywords | **Required.** The colour table has gaps (reason not yet read), `transparent`, `hsl()` and 8-digit hex are not parsed. |
| 13 `stroke-width="0"` | **Required.** No special case for 0 in the SVG module. |
| 2 root `font-size` | **Required.** The default is 24. |

"Removable" means that Skia handles the case by itself; it does not mean that the step is safe to delete.
Run `npm test` and the examples in GToolkit (see [development.md](development.md)).

## Open items

1. **The colour table.** Add `src/utils` to the sparse checkout and read `SkParse.cpp` (`FindNamedColor`). It should
   explain why `grey`, `darkgrey`, `dimgrey`, `slategrey`, `darkslategrey`, `lightslategrey`, `lightgray` and
   `rebeccapurple` draw black and why `transparent` does not parse.
2. **The `FontMgr` that GT passes to `skia_svg_parse`.** Find where `SkiaSvgDom` is created in the image (the senders of
   the Pharo side of `skia_svg_parse`, likely in `Sparta-Skia`) and see which font manager that is (DirectWrite, GDI,
   fontconfig, ...). This decides what `legacyMakeTypeface("sans-serif")` returns, and whether a missing glyph gets a
   per-character fallback (the emoji cases in the baseline). A test: the same SVGs drawn with `skia-safe` directly from a
   small Rust program with each `FontMgr`.
3. **Which Skia did v1.1.624 use?** The baseline was measured with v1.1.624; the Skia checked here is the one of v1.1.668.
   The file properties of the two `Skia.dll` (2026-11-08) show the **same size, 27,373,568 bytes**, while the dates differ
   (v1.1.624: created and modified 2026-10-17; v1.1.668: created 2026-11-07, modified 2026-11-08; GT is built each time).
   Equal size to the byte is a strong hint that it is the same build, but not a proof. To settle it, compare the hashes
   (`Get-FileHash -Algorithm SHA256 <path>\bin\Skia.dll` for both installs), or run the same string search for
   `skia-safe-` on the older dll. If they are the same, the baseline rows hold for m142 as measured.
4. **`renderNode` and `fNamedColors`.** Is `renderNode(canvas, pctx, id)` reachable from `skia-safe` 0.90.0 with a
   `fNamedColors` table? If yes, a `var()` definition could be honoured by a small addition to libskia and to the Pharo
   binding (a change in GT, not in pele2svg).
5. **Re-measure** the rows of the baseline that depend on the Skia version, once 3 is answered.

## Sources

- [feenkcom/libskia](https://github.com/feenkcom/libskia): `Cargo.toml`, `Cargo.lock`, `libskia/src/svg.rs`.
- [feenkcom/Sparta](https://github.com/feenkcom/sparta): the Skia VM plugin.
- `skia-bindings 0.90.0` on crates.io: `Cargo.toml` (`[package.metadata] skia = "m142-0.89.1"`) and `.cargo_vcs_info.json`.
- Skia, branch `chrome/m142` (<https://skia.googlesource.com/skia>): `include/core/SkMilestone.h`; in `modules/svg`:
  `src/SkSVGAttributeParser.cpp`, `src/SkSVGDOM.cpp`, `src/SkSVGNode.cpp`, `src/SkSVGAttribute.cpp`,
  `src/SkSVGRenderContext.cpp`, `src/SkSVGSVG.cpp`, `src/SkSVGText.cpp`, `include/SkSVGAttributeParser.h`,
  `include/SkSVGRenderContext.h`, `include/SkSVGTypes.h`, `include/SkSVGNode.h`.
