"
Tests for the fixtures that Pele2svgExamples reads (test/fixtures/featured.json, docs.json and layout.json) and for the featured examples of Pele2svgFeaturedExamples. They do not run pele2svg.mjs. They are skipped when the image has no Iceberg repository named pele2svg, because the fixtures are read from its clone.
"
Class {
	#name : 'Pele2svgExamplesTest',
	#superclass : 'TestCase',
	#category : 'Pele2svg-Tests',
	#package : 'Pele2svg-Tests'
}

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
