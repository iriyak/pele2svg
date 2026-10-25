"
Tests for the fixtures that Pele2svgExamples reads (test/fixtures/featured.json, docs.json and layout.json), for the featured examples of Pele2svgFeaturedExamples, and for the formula examples of Pele2svgMathExamples. The tests of the fixtures and of the example methods do not run pele2svg.mjs. The tests whose names begin with testMath do: they need Node.js (or Bun) and mathjax-full in the Iceberg clone, and are skipped without them. All are skipped when the image has no Iceberg repository named pele2svg, because the fixtures are read from its clone.
"
Class {
	#name : 'Pele2svgExamplesTest',
	#superclass : 'TestCase',
	#category : 'Pele2svg-Tests',
	#package : 'Pele2svg-Tests'
}

{ #category : 'running' }
Pele2svgExamplesTest >> defaultTimeLimit [
	"The math tests start Node.js (or Bun) once for each diagram, which takes about 0.3 s each."

	^ 2 minutes
]

{ #category : 'private' }
Pele2svgExamplesTest >> examples [
	^ Pele2svgExamples new examples
]

{ #category : 'running' }
Pele2svgExamplesTest >> setUp [
	super setUp.
	[ Pele2svgExamples fixtureDirectory ]
		on: Pele2svgError
		do: [ :error | self skip: error messageText ]
]

{ #category : 'private' }
Pele2svgExamplesTest >> skipUnlessMathIsInstalled [
	"The math tests run pele2svg.mjs with MathJax (the optional dependency mathjax-full)."

	(Pele2svg repositoryDirectory / 'node_modules' / 'mathjax-full') exists
		ifFalse: [ self skip: 'mathjax-full is not installed (Pele2svg installDependencies)' ]
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testEveryCorpusHasExamples [
	Pele2svgExamples corpusNames do: [ :corpus |
		self assert: (Pele2svgExamples examplesOfCorpus: corpus) isNotEmpty ]
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testExamplesComeFromEveryCorpus [
	self
		assert: (self examples collect: [ :each | each at: 'corpus' ]) asSet
		equals: Pele2svgExamples corpusNames asSet
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testExamplesHaveANameAndASource [
	self examples do: [ :each |
		self assert: (each at: 'name') isString.
		self assert: (each at: 'name') isNotEmpty.
		self assert: (each at: 'source') isString.
		self assert: (each at: 'source') trimBoth isNotEmpty ]
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testFeaturedMethodsAgreeWithTheFeaturedFixture [
	"Every featured example of the fixture has a method <type><n> (the name without the hyphen) that holds the same source, and the class has no other examples."

	| selectors |
	selectors := Set new.
	(Pele2svgExamples examplesOfCorpus: 'featured') do: [ :each |
		| name selector source |
		name := each at: 'name'.
		selector := (name copyWithout: $-) asSymbol.
		selectors add: selector.
		self assert: (Pele2svgFeaturedExamples includesSelector: selector) description: 'missing ' , selector.
		(Pele2svgFeaturedExamples includesSelector: selector) ifTrue: [
			source := (Pele2svgFeaturedExamples >> selector) literals
				detect: [ :literal | literal isString and: [ literal isSymbol not ] ].
			self assert: source lines = (each at: 'source') lines description: 'different source in ' , selector ] ].
	self
		assert: (Pele2svgFeaturedExamples selectors select: [ :each | (Pele2svgFeaturedExamples >> each) hasPragmaNamed: #gtExample ]) asSet
		equals: selectors
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathExamplesAgreeWithTheSources [
	"Every source of Pele2svgMathExamples has a <gtExample> method of the same name, and the class has no other source-based examples."

	| selectors |
	selectors := Pele2svgMathExamples sourceNames.
	self assert: selectors asSet size equals: selectors size.
	selectors do: [ :each |
		self assert: (Pele2svgMathExamples includesSelector: each asSymbol) description: 'missing ' , each.
		self assert: ((Pele2svgMathExamples >> each asSymbol) hasPragmaNamed: #gtExample) ].
	self
		assert: (Pele2svgMathExamples selectors select: [ :each | (Pele2svgMathExamples >> each) hasPragmaNamed: #gtExample ]) asSet
		equals: (selectors collect: #asSymbol) asSet , #(withoutMathOption texFormula mathmlFormula asciimathFormula displayFormula) asSet
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathExamplesRun [
	"Running the gtExamples checks that each answers a BlSkiaSvgElement."

	| examples |
	self skipUnlessMathIsInstalled.
	examples := Pele2svgMathExamples new.
	Pele2svgMathExamples sourceNames do: [ :each |
		self assert: (examples perform: each asSymbol) class equals: BlSkiaSvgElement ].
	self assert: examples withoutMathOption class equals: BlSkiaSvgElement
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathFormulasOnTheirOwn [
	"A formula without Mermaid: the formula examples answer elements as big as the formula, and the SVG is plain."

	| examples svg |
	self skipUnlessMathIsInstalled.
	examples := Pele2svgMathExamples new.
	#(texFormula mathmlFormula asciimathFormula displayFormula) do: [ :each |
		self assert: (examples perform: each) class equals: BlSkiaSvgElement ].
	svg := Pele2svg new svgFor: 'E=mc^2' format: #tex display: false size: 16 color: '#205ea6'.
	self assert: (svg includesSubstring: 'fill="#205ea6"').
	self assert: (svg includesSubstring: 'currentColor') not.
	self assert: (svg includesSubstring: '<use') not.
	self should: [ Pele2svg new svgForTex: '\frac{' ] raise: Pele2svgError.
	self should: [ Pele2svg new svgFor: 'x' format: #latex ] raise: Pele2svgError
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathLeavesPlainDiagramsAlone [
	"A diagram without $$ is converted in the same way whether or not the math option is given."

	| source |
	self skipUnlessMathIsInstalled.
	source := 'flowchart LR
  A --> B'.
	self
		assert: (Pele2svgExamples new renderer renderOptions: { #math -> true } asDictionary; render: source)
		equals: (Pele2svgExamples new renderer renderOptions: nil; render: source)
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathSourcesAreTypeset [
	self skipUnlessMathIsInstalled.
	Pele2svgMathExamples sources do: [ :each |
		| svg |
		self assert: (each value includesSubstring: '$$') description: each key , ' has no formula'.
		svg := Pele2svgMathExamples new renderer render: each value.
		self assert: (svg includesSubstring: '$$') not description: each key , ': $$ is left'.
		self assert: (svg includesSubstring: 'pele-math') description: each key , ': no formula in the SVG' ]
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testMathWithoutTheOptionLeavesTheTexSource [
	| svg |
	self skipUnlessMathIsInstalled.
	svg := Pele2svgExamples new renderer renderOptions: nil; render: (Pele2svgMathExamples sourceNamed: 'flowchart').
	self assert: (svg includesSubstring: '$$E=mc^2$$').
	self assert: (svg includesSubstring: 'pele-math') not
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testNamesAreUnique [
	| names |
	names := self examples collect: [ :each | each at: 'name' ].
	self assert: names asSet size equals: names size
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testTypeIsTheNameUpToTheFirstHyphen [
	self examples do: [ :each |
		self assert: ((each at: 'name') beginsWith: (each at: 'type') , '-') ]
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testUnknownExampleSignalsAnError [
	self should: [ Pele2svgExamples new sourceOfExampleNamed: 'no-such-example' ] raise: Pele2svgError
]

{ #category : 'tests' }
Pele2svgExamplesTest >> testUnknownRenderOptionSignalsAnError [
	self skipUnlessMathIsInstalled.
	self
		should: [ Pele2svgExamples new renderer renderOptions: { #maxwidth -> 360 } asDictionary; render: 'flowchart LR
  A --> B' ]
		raise: Pele2svgError
]
