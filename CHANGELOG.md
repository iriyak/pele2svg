# Changelog

## Unreleased

### Added

- **A formula on its own.** `mathToSvg(source, { format, display, size, color })` typesets one formula with MathJax and answers plain SVG, as large as the formula in pixels. The format is TeX, MathML or AsciiMath. On the command line: `--math` and `--math-batch`. In Pharo: `elementFor:format:`, `svgFor:format:`, `elementForTex:`, `svgForTex:`, and the longer `elementFor:format:display:size:color:` and `svgFor:format:display:size:color:`. Five new gtExamples in `Pele2svgMathExamples` (the fifth, `asciimathSets`, is a table of AsciiMath sources for sets and logic), `test/math.test.js` and a new test.

- **`mermaidToSvg(source, { theme, renderOptions })`**, the library form of what the command line does for an `.mmd` file: it runs Pele, then `flatten`, and answers `{ svg, warnings }`. MathJax is still loaded only for a source that contains `$$`. The command line (`input.mmd`, `--batch`) now calls it. New file `test/mermaid-to-svg.test.js`.

### Changed

- A TeX error in a `$$...$$` label now shows the TeX source (as when MathJax is not available) instead of MathJax's red error message.
- The tests that need the math option off set `renderOptions: nil` explicitly, so they no longer fail when the global default has `math` on.

## 0.3.0 (pre-release)

Formulas, render options, and a pele 1.10 baseline.

### Added

- **Formulas.** `$$...$$` in a Mermaid label is typeset with MathJax 3 (`mathjax-full`, SVG output, no font cache) when the `math` render option is on. It works in the 11 diagram types that pele supports formulas in. The result is plain paths, which Skia draws. `mathjax-full` is an optional dependency and is loaded only when the source contains `$$` (about 0.2 s more for that conversion). New file `math.mjs`.
- **Render options.** `--render-options file.json` on the command line and `peleOptions(json)` in the API pass pele's render options (`maxWidth`, `fontSize`, `padding`, `math`, ...). Unknown keys are refused with the list of known ones.
- **Pharo.** The `renderOptions` setting (`Pele2svgOptions`, and `renderOptions:` on `Pele2svg`), for example `{ #maxWidth -> 360. #math -> true } asDictionary`. `installDependencies` also installs `mathjax-full`.
- **Examples and tests.** `Pele2svgMathExamples` (11 gtExamples with formulas), six new tests in `Pele2svgExamplesTest`, `Pele2svgOptionsTest>>testRenderOptions`, and `test/options.test.js`.
- **Docs.** `docs/mermaid-in-gt.md` (what pele 1.0.1 to 1.10.0 brought to GT, text in labels, render options, formulas); a section in the README on formulas and the width of a diagram; Lepiter page sections for the same.

### Changed

- The Metacello baseline `default` group now loads `Pele2svg` and `Pele2svg-Tests`; the group `Core` loads `Pele2svg` only. The group `Tests` is gone.
- `pele` dependency is `^1.10.0` (tested with 1.10.0).

### Fixed

- Skia draws `stroke-width="0"` as a stroke of about one pixel, which made formulas look bold. New step 13 rewrites such elements to `stroke="none"` (26 % fewer dark pixels in the test case; see `docs/skia-svg-baseline.md`).

### Known limits

- `<sub>`, `<sup>` and `<u>` are ignored by Skia; emoji can render with the wrong font.
- Skia does not resolve the `monospace` family; a theme key maps it to a real font.
- Only Windows has been checked (GToolkit and WebView2); macOS and Linux have not been tried.
- Images with external URLs are removed.
- Converted SVGs keep pele's intrinsic size, so scaling depends on the viewer.
- Only simple class rules are converted; other rules are left in place with a warning.
- Not yet on the npm registry.

## 0.2.0 (2026-10-19, pre-release)

- Convert existing SVG files without running pele: a command-line option and GToolkit methods.
- Simple CSS class rules are turned into plain SVG attributes, so more SVG files render in Skia.
- Elements are sized from the viewBox or from width and height; an SVG with neither is an error.
- README shortened; the details of what was checked moved to a development doc.
- Known limits: Skia does not resolve the `monospace` font family; only Windows has been checked; external `<image>` URLs are removed; not on npm yet. Only simple class-based CSS rules are converted (tag or id selectors and `@media` are left in place with a warning).

## 0.1.0 (2026-10-18, pre-release)

First tagged version, experimental.

- Command-line tool and JavaScript API that convert pele's SVG output into plain SVG for renderers without CSS support.
- Pharo package for GToolkit: rendering methods, dependency installation, example methods, and a Lepiter getting-started page.
- Test suite of 14 tests over 748 pele source files.
