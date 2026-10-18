# pele2svg

[pele](https://github.com/obsidianmd/pele)(Mermaid → SVG)が出力する SVG を、**CSS エンジンを持たないレンダラー**
(Skia の SVG モジュール、GToolkit の `BlSkiaSvgElement` など)でも正しく描ける素朴な SVG に変換します。

*Converts pele's CSS-variable-based SVG into plain SVG with presentation attributes only, for renderers without a CSS engine (Skia SVG / GToolkit).*

## なぜ必要か

pele は色やフォントを CSS 変数(`fill="var(--_s)"` など)で書き出します。CSS エンジンのないレンダラーでは
`var()` が解決されず、図形が**すべて黒塗り**になります。`BlSkiaSvgElement` で確かめた範囲では、
`style` 属性の中の宣言は解釈される一方で、`<style>` 要素や `var()` は解釈されませんでした。

## 変換の内容

| 変換前 | 変換後 |
|---|---|
| `var(--x, fallback)` | 実際の値(`--pele-*` はテーマで上書き可) |
| ルート `<svg>` の `style`(`font:` など) | `font-family` / `font-size` 属性 |
| `style="fill:..;stroke:..;rx:.."` | 同名の属性(同名の属性が既にあれば置き換え) |
| `currentColor` | 前景色 |
| `color-mix(in srgb, A p%, B)` | 計算済みの `#rrggbb` |
| 入れ子の `<svg>`(アイコン) | `<g transform="translate() scale()">` |
| `<a href>` | `<g>` |
| 外部 URL の `<image>` | 削除(警告を出力) |
| `font-family="monospace"` など | `--gt-font-mono` などで指定した実フォント名 |

## インストール

```sh
npm install pele2svg        # pele も一緒に入ります (Node.js 18 以上 / bun でも可)
```

リポジトリから直接使う場合:

```sh
git clone <this repo> && cd pele2svg && npm install
```

## 使い方

```sh
# 1 ファイル
npx pele2svg input.mmd output.svg [theme.json]

# まとめて変換: sources.json = [{"name":"flow-1","source":"flowchart LR\n A-->B"}, ...]
npx pele2svg --batch sources.json outdir [theme.json]
```

ライブラリとして:

```js
import { render } from 'pele';
import { flatten } from 'pele2svg';

const { svg } = flatten(render('flowchart LR\n A-->B').svg, { '--gt-font-mono': 'Consolas' });
// flatten は { svg, warnings } を返します
```

### テーマ

`theme.json` で pele の CSS 変数を上書きできます(`themes/` に例があります)。

```json
{"--pele-bg":"#fffcf0","--pele-fg":"#100f0f","--pele-surface":"#f2f0e5","--pele-border":"#cecdc3","--pele-accent":"#205ea6"}
```

### フォント

Skia の SVG は `monospace` のような総称名を実フォントに解決できないことがあります
(GToolkit では `monospace` が効かず、既定フォントで描かれました)。次のキーで実フォント名に置き換えます。

| キー | 置き換える総称名 |
|---|---|
| `--gt-font-mono` | `monospace` |
| `--gt-font-sans` | `sans-serif` |
| `--gt-font-serif` | `serif` |

```json
{"--gt-font-mono":"Consolas"}
```

- `themes/gt-windows.json` は Windows 用の例です。macOS なら `Menlo`、Linux なら `DejaVu Sans Mono` などに変えてください。
- `font-family` は候補リストではなく、**フォント名を 1 つだけ**にしてください。
- 同じテキストでも pele は文字幅を自前で測っています。`sans-serif` を別のフォントにすると、ラベルが枠に収まらなくなることがあります。

## GToolkit で使う

SVG を作ってから、`BlSkiaSvgElement` に渡します。

```smalltalk
svg := (FileLocator home / 'Downloads' / 'eventmodeling-1.svg') contents.
BlSkiaSvgElement new
    svg: svg;
    size: 400 asPoint.
```

Mermaid から直接つなぐ場合は、`pele2svg` を外部プロセスとして呼び、標準出力ではなくファイルに書き出した SVG を読む形が簡単です。

## 確認範囲

pele の例(<https://pele.run/examples>)の 32 種別、トップに並ぶ 58 件と各種別ページの 520 件(計 578 件)で、次を確認しています。

- すべて変換でき、`var()`、`style` 属性、`<style>`、`currentColor`、`color-mix()`、入れ子の `<svg>`、`<a>` が残らないこと
- すべて XML として正しいこと(`xmllint`)
- GToolkit(Skia)と WebView2 の描画を目視で比べ、次が同等に出ること: 色、`tspan` / `text-anchor`、太字・斜体、角丸、矢印、破線、半透明の重なり、回転した文字、アイコン、楕円・多角形、`« »` などの文字、等幅フォント(Consolas に置換)

未確認の点:

- 日本語など全角文字を含む図。pele は文字幅を自前で測るため、全角の幅の見積もりが GT のフォントと合わず、ラベルが枠からずれる可能性があります。
- 外部 URL の `<image>` は削除されます(flowchart の例で 1 件)。

## テスト

```sh
npm test
```

`examples/` に Mermaid のソースと、変換後の SVG(Windows 用フォント置換つき)の例が入っています。

## ライセンス

MIT。pele も MIT ライセンスです。このリポジトリは pele のコードを含まず、pele が出力した SVG を後処理するだけです。
