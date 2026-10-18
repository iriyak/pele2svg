# Test fixtures

Mermaid sources taken from [pele](https://github.com/obsidianmd/pele) (MIT licensed, see its `LICENSE`),
used by `test/corpus.test.js`. Each file is a JSON array of `{ "name": ..., "source": ... }`, which is also the
input format of `pele2svg --batch`.

| File | Sources | Where they come from |
|---|---|---|
| `featured.json` | 58 | The examples listed on [pele.run/examples](https://pele.run/examples) (named `<type>-<n>`). |
| `docs.json` | 520 | The "Documentation examples" of the per-type pages of pele.run/examples (`<type>-<nn>`). |
| `reference.json` | 170 | The `src` of pele's own conformance corpus (`tests/corpus/*-reference.json`) that is not already in the files above (`<type>-ref-<nnn>`). Sources that pele itself rejects (about 60, deliberately invalid inputs) are left out. |

They were extracted from pele commit `659c3593ce43794dce7ec7ab45d424ad2de182a5`
(`website/src/lib/examples.ts` and `tests/corpus/`), rendered with pele 1.6.0.

To refresh them after a pele update, run the same extraction against a new pele checkout and keep the
`{ name, source }` format. If pele starts rejecting a source, the corpus test names it in its failure message.

## License

The sources are pele's examples and test inputs, copied under its MIT license:

> MIT License — Copyright (c) 2026 kepano
