// math.mjs — MathJax for pele2svg: typeset $$...$$ labels for Pele, and typeset a formula on its own.
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

// A formula on its own (pele2svg.mjs: mathToSvg, --math) goes through the same engine, in TeX, MathML or AsciiMath.

export const MATH_FORMATS = ['tex', 'mathml', 'asciimath'];

// Answers a synchronous function (source, { display, size }) => { svg, width, height } in pixels, for one input
// format. It throws when MathJax cannot read the source. Each format is loaded only when it is asked for.
export async function createMathEngine(format = 'tex') {
  if (!MATH_FORMATS.includes(format)) {
    throw new Error(`unknown math format: ${format}; known: ${MATH_FORMATS.join(', ')}`);
  }
  let mathjax, input, SVG, liteAdaptor, RegisterHTMLHandler;
  try {
    ({ mathjax } = await import('mathjax-full/js/mathjax.js'));
    ({ SVG } = await import('mathjax-full/js/output/svg.js'));
    ({ liteAdaptor } = await import('mathjax-full/js/adaptors/liteAdaptor.js'));
    ({ RegisterHTMLHandler } = await import('mathjax-full/js/handlers/html.js'));
    if (format === 'tex') {
      const { TeX } = await import('mathjax-full/js/input/tex.js');
      const { AllPackages } = await import('mathjax-full/js/input/tex/AllPackages.js');
      // a TeX error is thrown instead of being drawn as a red message
      input = new TeX({ packages: AllPackages, formatError: (jax, error) => { throw new Error(error.message); } });
    } else if (format === 'mathml') {
      input = new (await import('mathjax-full/js/input/mathml.js')).MathML();
    } else {
      input = new (await import('mathjax-full/js/input/asciimath.js')).AsciiMath();
    }
  } catch (e) {
    throw new Error('math needs mathjax-full, an optional dependency of pele2svg: run npm install (or bun install) '
      + 'in the directory of pele2svg.mjs without --omit=optional (' + e.message + ')');
  }
  const adaptor = liteAdaptor();
  RegisterHTMLHandler(adaptor);
  const doc = mathjax.document('', { InputJax: input, OutputJax: new SVG({ fontCache: 'none' }) });
  return (source, { display = false, size = 16 } = {}) => {
    const node = adaptor.firstChild(doc.convert(source, { display, em: size, ex: size / 2 }));
    const exToPx = size / 2;
    const width = parseFloat(adaptor.getAttribute(node, 'width')) * exToPx;
    const height = parseFloat(adaptor.getAttribute(node, 'height')) * exToPx;
    if (!(width > 0 && height > 0)) throw new Error('MathJax answered an empty formula');
    const svg = adaptor.outerHTML(node)
      .replace(/ width="[^"]*"/, ` width="${width}"`)
      .replace(/ height="[^"]*"/, ` height="${height}"`)
      .replace(/ style="[^"]*"/, '');
    if (svg.includes('data-mml-node="merror"')) {
      throw new Error('MathJax could not read the formula: ' + (/<title[^>]*>([^<]*)/.exec(svg)?.[1] ?? source));
    }
    return { svg, width, height };
  };
}

// For Pele's `math` option: (tex, size) => { svg, width, height } in pixels, or null when MathJax fails
// (Pele then shows the TeX source).
export async function createMathResolver() {
  const engine = await createMathEngine('tex');
  return (tex, size) => {
    try { return engine(tex, { display: false, size }); } catch { return null; }
  };
}
