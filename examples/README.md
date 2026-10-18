# Examples

Three diagrams, each as the Mermaid source (`.mmd`) and the SVG that `pele2svg` makes from it (`.svg`):

| Name | Diagram type |
|---|---|
| `eventmodeling-1` | event modeling |
| `sequence-1` | sequence diagram |
| `architecture-2` | architecture diagram |

The `.mmd` sources are examples of [pele](https://github.com/obsidianmd/pele) (MIT License, Copyright (c) 2026 kepano),
copied unchanged from the featured examples on [pele.run/examples](https://pele.run/examples) under the same names;
they are also in `test/fixtures/featured.json`. The `.svg` files are pele's output for them (pele 1.6.0) after
conversion by `pele2svg`: `node pele2svg.mjs examples/<name>.mmd examples/<name>.svg`.
`eventmodeling-1.svg` was made with `themes/gt-windows.json` (`monospace` → `Consolas`), because Skia draws
`monospace` text in a proportional font: `node pele2svg.mjs examples/eventmodeling-1.mmd examples/eventmodeling-1.svg themes/gt-windows.json`.

Try them in GToolkit: see "Showing an SVG file you already have" in the [README](../README.md).
