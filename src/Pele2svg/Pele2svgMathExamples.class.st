"
GToolkit examples for formulas: one <gtExample> for each diagram type in which Pele can typeset $$...$$ labels (flowchart, sequence, class, state, ER, mindmap, kanban, block, requirement, swimlane and use case diagrams). Each renders the source through pele2svg with the render option #math -> true, which typesets the formulas with MathJax, and answers a BlSkiaSvgElement. Open the class in the GT Coder and click the example results. Requires Node.js (or Bun) and `npm install` in the Iceberg clone of pele2svg, which also installs mathjax-full, the optional dependency that typesets the formulas.

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
Pele2svgMathExamples >> block [
	<gtExample>
	^ self elementNamed: 'block'
]

{ #category : 'examples' }
Pele2svgMathExamples >> classDiagram [
	<gtExample>
	^ self elementNamed: 'classDiagram'
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

{ #category : 'examples' }
Pele2svgMathExamples >> kanban [
	<gtExample>
	^ self elementNamed: 'kanban'
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
Pele2svgMathExamples >> usecase [
	<gtExample>
	^ self elementNamed: 'usecase'
]

{ #category : 'examples' }
Pele2svgMathExamples >> withoutMathOption [
	"The same kind of label without the render option: Pele leaves the TeX source."

	<gtExample>
	| pele svg |
	pele := Pele2svgExamples new renderer.
	svg := pele render: 'flowchart LR
  A["Energy $$E=mc^2$$"] --> B'.
	self assert: (svg includesSubstring: '$$E=mc^2$$').
	self assert: (svg includesSubstring: 'pele-math') not.
	^ pele elementFromSvg: svg
]
