"
GToolkit examples for formulas: one <gtExample> for each diagram type in which Pele can typeset $$...$$ labels (flowchart, sequence, class, state, ER, mindmap, kanban, block, requirement, swimlane and use case diagrams). Each renders the source through pele2svg with the render option #math -> true, which typesets the formulas with MathJax, and answers a BlSkiaSvgElement. Open the class in the GT Coder and click the example results. Requires Node.js (or Bun) and `npm install` in the Iceberg clone of pele2svg, which also installs mathjax-full, the optional dependency that typesets the formulas.

#texFormula, #mathmlFormula, #asciimathFormula and #displayFormula typeset a formula on its own, without Mermaid (Pele2svg>>#elementFor:format:); #asciimathSets shows a table of AsciiMath sources for sets next to the formulas they give.

The sources are in Pele2svgMathExamples class >> #sources; Pele2svgExamplesTest checks that each has an example and that its formulas are typeset. #withoutMathOption shows what the same kind of label looks like without the option (the TeX source). See docs/mermaid-in-gt.md.
"
Class {
	#name : 'Pele2svgMathExamples',
	#superclass : 'Object',
	#category : 'Pele2svg-Examples',
	#package : 'Pele2svg',
	#tag : 'Examples'
}

{ #category : 'accessing' }
Pele2svgMathExamples class >> asciimathSetRows [
	"AsciiMath sources for sets and logic that MathJax draws as expected (see #asciimathSets). Not here: emptyset (a word, not the sign: write O/), A \ B (the backslash does not work) and card A (a name, not a function)."

	^ #('A = {x in RR | x > 0}' 'A uu B' 'A nn B' 'A sub B' 'A sube B' 'x notin A' 'NN sub ZZ sub QQ sub RR' 'AA x in A, EE y in B: x < y' 'O/' 'P(A) = {B | B sube A}' 'S := {(x,y) | x^2+y^2 <= 1}' 'f: A -> B' 'x |-> x^2' 'not (A sub B)' '|A|')
]

{ #category : 'accessing' }
Pele2svgMathExamples class >> sourceNamed: aName [
	"The Mermaid source of the example with that name, one of #sourceNames."

	^ (self sources detect: [ :each | each key = aName ] ifNone: [ Pele2svgError signal: 'No math example named ' , aName printString ]) value
]

{ #category : 'accessing' }
Pele2svgMathExamples class >> sourceNames [
	"The names of the examples; each is also the selector of its <gtExample> method."

	^ self sources collect: #key
]

{ #category : 'accessing' }
Pele2svgMathExamples class >> sources [
	"An Array of Associations from the name of an example to a Mermaid source with a $$...$$ formula in a label. There is one for each diagram type in which Pele (1.8.0 and later) typesets math."

	^ {
		'flowchart' -> 'flowchart LR
  A["Energy $$E=mc^2$$"] --> B["$$\int_0^1 x^2\,dx=\frac13$$"]
  B --> C["$$\sum_{i=1}^n i = \frac{n(n+1)}{2}$$"]'.
		'sequence' -> 'sequenceDiagram
  participant A as Customer
  participant B as Billing
  A->>B: Total $$\sum_{i=1}^n p_i q_i$$
  B-->>A: $$\frac{a+b}{2}$$ ok'.
		'classDiagram' -> 'classDiagram
  class Circle["$$\pi r^2$$"]
  Circle : +area()'.
		'stateDiagram' -> 'stateDiagram-v2
  [*] --> S1
  S1: $$\alpha+\beta$$
  S1 --> [*]'.
		'erDiagram' -> 'erDiagram
  A ||--o{ B : "$$n^2$$"'.
		'mindmap' -> 'mindmap
  root(("$$\sqrt{x}$$"))
    child'.
		'kanban' -> 'kanban
  Todo
    t1["$$\frac{a}{b}$$"]'.
		'block' -> 'block-beta
  columns 2
  a["$$x_1$$"] b'.
		'requirement' -> 'requirementDiagram
  requirement r1 {
    id: 1
    text: "$$E=mc^2$$"
    risk: high
    verifymethod: test
  }'.
		'swimlane' -> 'swimlane-beta LR
  subgraph L1
    A["$$a^2$$"]
    B[next]
  end
  A --> B'.
		'usecase' -> 'usecase-beta
direction LR
actor U
C("$$\int f$$")
U --> C'
	}
]

{ #category : 'examples' }
Pele2svgMathExamples >> asciimathFormula [
	"A formula in AsciiMath, on its own."

	<gtExample>
	^ self formulaElement: 'sum_(i=1)^n i^3=((n(n+1))/2)^2' format: #asciimath
]

{ #category : 'examples' }
Pele2svgMathExamples >> asciimathSets [
	"A table of AsciiMath sources for sets and logic (left) and the formulas they give (right), 12 px, black. Each row starts a process, so this takes a few seconds."

	<gtExample>
	| pele table |
	pele := Pele2svg new.
	table := BlElement new
		layout: (BlLinearLayout vertical cellSpacing: 6);
		constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
		padding: (BlInsets all: 12).
	self class asciimathSetRows do: [ :each | | label |
		label := BlTextElement new
			text: (each asRopedText fontName: 'Consolas'; fontSize: 14);
			constraintsDo: [ :c | c horizontal exact: 300. c vertical fitContent ].
		table addChild: (BlElement new
			layout: (BlLinearLayout horizontal alignCenterLeft);
			constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
			addChildren: { label. pele elementFor: each format: #asciimath display: false size: 12 color: '#000000' };
			yourself) ].
	self assert: table children size equals: self class asciimathSetRows size.
	^ table
]

{ #category : 'examples' }
Pele2svgMathExamples >> block [
	<gtExample>
	^ self elementNamed: 'block'
]

{ #category : 'examples' }
Pele2svgMathExamples >> classDiagram [
	<gtExample>
	^ self elementNamed: 'classDiagram'
]

{ #category : 'examples' }
Pele2svgMathExamples >> displayFormula [
	"A TeX formula in the display style, 28 px, in color."

	<gtExample>
	| element |
	element := Pele2svg new
		elementFor: '\int_0^1 x^2\,dx=\frac13'
		format: #tex
		display: true
		size: 28
		color: '#205ea6'.
	self assert: element class equals: BlSkiaSvgElement.
	^ element
]

{ #category : 'private' }
Pele2svgMathExamples >> elementNamed: aName [
	"Answer a BlSkiaSvgElement for the example, with its formulas typeset."

	^ self renderer elementFromSvg: (self svgNamed: aName)
]

{ #category : 'examples' }
Pele2svgMathExamples >> erDiagram [
	<gtExample>
	^ self elementNamed: 'erDiagram'
]

{ #category : 'examples' }
Pele2svgMathExamples >> flowchart [
	<gtExample>
	^ self elementNamed: 'flowchart'
]

{ #category : 'private' }
Pele2svgMathExamples >> formulaElement: aString format: aSymbol [
	| element |
	element := Pele2svg new elementFor: aString format: aSymbol.
	self assert: element class equals: BlSkiaSvgElement.
	^ element
]

{ #category : 'examples' }
Pele2svgMathExamples >> kanban [
	<gtExample>
	^ self elementNamed: 'kanban'
]

{ #category : 'examples' }
Pele2svgMathExamples >> mathmlFormula [
	"A formula in MathML, on its own."

	<gtExample>
	^ self formulaElement: '<math><mfrac><mi>a</mi><mi>b</mi></mfrac><mo>=</mo><msqrt><mi>x</mi></msqrt></math>' format: #mathml
]

{ #category : 'examples' }
Pele2svgMathExamples >> mindmap [
	<gtExample>
	^ self elementNamed: 'mindmap'
]

{ #category : 'private' }
Pele2svgMathExamples >> renderer [
	"The converter of Pele2svgExamples (on Windows with themes/gt-windows.json) with the render option #math -> true."

	^ Pele2svgExamples new renderer
		renderOptions: { #math -> true } asDictionary;
		yourself
]

{ #category : 'examples' }
Pele2svgMathExamples >> requirement [
	<gtExample>
	^ self elementNamed: 'requirement'
]

{ #category : 'examples' }
Pele2svgMathExamples >> sequence [
	<gtExample>
	^ self elementNamed: 'sequence'
]

{ #category : 'examples' }
Pele2svgMathExamples >> stateDiagram [
	<gtExample>
	^ self elementNamed: 'stateDiagram'
]

{ #category : 'private' }
Pele2svgMathExamples >> svgNamed: aName [
	"Answer the converted SVG of the example. Its formulas are typeset: no $$ is left, and they are inside <g class=""pele-math"">."

	| svg |
	svg := self renderer render: (self class sourceNamed: aName).
	self assert: (svg includesSubstring: '$$') not.
	self assert: (svg includesSubstring: 'pele-math').
	self assert: (svg includesSubstring: 'var(') not.
	^ svg
]

{ #category : 'examples' }
Pele2svgMathExamples >> swimlane [
	<gtExample>
	^ self elementNamed: 'swimlane'
]

{ #category : 'examples' }
Pele2svgMathExamples >> texFormula [
	"A TeX formula, on its own."

	<gtExample>
	^ self formulaElement: 'E=mc^2' format: #tex
]

{ #category : 'examples' }
Pele2svgMathExamples >> usecase [
	<gtExample>
	^ self elementNamed: 'usecase'
]

{ #category : 'examples' }
Pele2svgMathExamples >> withoutMathOption [
	"The same kind of label without the render option: Pele leaves the TeX source."

	<gtExample>
	| pele svg |
	pele := Pele2svgExamples new renderer renderOptions: nil; yourself.
	svg := pele render: 'flowchart LR
  A["Energy $$E=mc^2$$"] --> B'.
	self assert: (svg includesSubstring: '$$E=mc^2$$').
	self assert: (svg includesSubstring: 'pele-math') not.
	^ pele elementFromSvg: svg
]
