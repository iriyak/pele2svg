// math.mjs — typeset $$...$$ labels for Pele with MathJax, for pele2svg.
//
// Pele does not typeset math itself. It calls a resolver given in its `math` option, which answers an SVG
// (or HTML) and its size, and puts that in place of the $$...$$ text. Skia cannot draw HTML, so this resolver
// answers SVG: MathJax 3 (mathjax-full) with SVG output and no font cache, so that every glyph is an inline <path>
// and the SVG has no <use> or <style>. It needs mathjax-full, an optional dependency of pele2svg.
//
// MathJax gives the size in ex. Pele's resolver wants pixels, and pele2svg's conversion of nested <svg> elements
// reads width and height as numbers, so the SVG itself is rewritten in pixels too.
//
// (MathJax 4, @mathjax/src, was tried and not used: it loads its fonts asynchronously, and the resolver has to be
// synchronous. With it, a synchronous call typeset only the first glyph of E=mc^2.)

export async function createMathResolver() {
  let mathjax, TeX, SVG, liteAdaptor, RegisterHTMLHandler, AllPackages;
  try {
    ({ mathjax } = await import('mathjax-full/js/mathjax.js'));
    ({ TeX } = await import('mathjax-full/js/input/tex.js'));
    ({ SVG } = await import('mathjax-full/js/output/svg.js'));
    ({ liteAdaptor } = await import('mathjax-full/js/adaptors/liteAdaptor.js'));
    ({ RegisterHTMLHandler } = await import('mathjax-full/js/handlers/html.js'));
    ({ AllPackages } = await import('mathjax-full/js/input/tex/AllPackages.js'));
  } catch (e) {
    throw new Error('math needs mathjax-full, an optional dependency of pele2svg: run npm install (or bun install) '
      + 'in the directory of pele2svg.mjs without --omit=optional (' + e.message + ')');
  }
  const adaptor = liteAdaptor();
  RegisterHTMLHandler(adaptor);
  const doc = mathjax.document('', {
    InputJax: new TeX({ packages: AllPackages }),
    OutputJax: new SVG({ fontCache: 'none' }),
  });
  // (tex, size) => { svg, width, height } in pixels, or null when MathJax fails (Pele then shows the TeX source)
  return (tex, size) => {
    try {
      const node = adaptor.firstChild(doc.convert(tex, { display: false, em: size, ex: size / 2 }));
      const exToPx = size / 2;
      const width = parseFloat(adaptor.getAttribute(node, 'width')) * exToPx;
      const height = parseFloat(adaptor.getAttribute(node, 'height')) * exToPx;
      if (!(width > 0 && height > 0)) return null;
      const svg = adaptor.outerHTML(node)
        .replace(/ width="[^"]*"/, ` width="${width}"`)
        .replace(/ height="[^"]*"/, ` height="${height}"`)
        .replace(/ style="[^"]*"/, '');
      return { svg, width, height };
    } catch {
      return null;
    }
  };
}
