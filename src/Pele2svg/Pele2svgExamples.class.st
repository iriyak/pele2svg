"
GToolkit examples for Pele2svg. Evaluate `Pele2svgExamples new` and look at the Examples view: it lists all the examples of https://pele.run/examples (featured, documentation and layout examples, read from test/fixtures of the repository), and selecting one renders it through pele2svg as a BlSkiaSvgElement. Requires Node.js (or Bun) and `npm install` in the Iceberg clone of pele2svg.

The sources are those of pele (https://github.com/obsidianmd/pele, MIT License, Copyright (c) 2026 kepano), copied unchanged into test/fixtures/featured.json, docs.json and layout.json by scripts/build-fixtures.mjs. Each example is a Dictionary with the keys 'corpus' (featured, docs or layout), 'type' (the diagram type), 'name' and 'source'. #elementOfExampleNamed: answers the element of one example.

The <gtExample> methods below are short diagrams written for this package (flowchart, sequenceDiagram, ...), a few checks, and one example for each corpus. The featured examples also have a <gtExample> each in Pele2svgFeaturedExamples. The tests of the options are in Pele2svgOptionsTest and Pele2svgExamplesTest (package Pele2svg-Tests).
"
Class {
	#name : 'Pele2svgExamples',
	#superclass : 'Object',
	#category : 'Pele2svg-Examples',
	#package : 'Pele2svg',
	#tag : 'Examples'
}

{ #category : 'fixtures' }
Pele2svgExamples class >> corpusNames [
	"The fixture files that hold the examples of pele.run/examples, in the order they are shown."
	^ #('featured' 'docs' 'layout')
]

{ #category : 'fixtures' }
Pele2svgExamples class >> examplesOfCorpus: aCorpusName [
	"An Array of Dictionaries with the keys 'name' and 'source', read from test/fixtures/<aCorpusName>.json."
	| file |
	file := self fixtureDirectory / (aCorpusName , '.json').
	file exists ifFalse: [ Pele2svgError signal: 'Not found: ' , file fullName ].
	^ NeoJSONReader fromString: (file binaryReadStreamDo: [ :stream | stream upToEnd utf8Decoded ])
]

{ #category : 'gallery' }
Pele2svgExamples class >> exportGalleryPngNamed: aName using: aPele2svg [
	"Draw out/gallery/svg/<aName>.svg with Skia and write out/gallery/skia/<aName>.png at GalleryScale times its size on a white background (Bloc forms are premultiplied, so without a background translucent fills look dark). Answer { name. width. height. share of non-white pixels }, width and height at scale 1."

	| element form bits ink count |
	element := aPele2svg elementFromSvg: (self galleryDirectory / 'svg' / (aName , '.svg')) contents.
	element background: Color white.
	form := BlExporter form element: element; scaled: self galleryScale; export.
	PNGReadWriter putForm: form onFileNamed: (self galleryDirectory / 'skia' / (aName , '.png')) fullName.
	bits := form bits.
	ink := 0.
	count := 0.
	1 to: bits size by: 7 do: [ :i |
		count := count + 1.
		(bits at: i) ~= 16rFFFFFFFF ifTrue: [ ink := ink + 1 ] ].
	^ { aName. form width // self galleryScale. form height // self galleryScale. ink / count asFloat }
]

{ #category : 'gallery' }
Pele2svgExamples class >> exportGalleryPngs [
	"Step 2 of the example gallery (docs/pele-upgrade.md). Run node out/gallery/make-svgs.mjs first. For every example, draw out/gallery/svg/<name>.svg with Skia into out/gallery/skia/<name>.png and write out/gallery/skia-metrics.json, which out/gallery/make-index.mjs reads. Answer the number of examples that failed. It takes about 20 minutes, so run it with [ Pele2svgExamples exportGalleryPngs ] fork if the image should stay usable."

	| pele results errors |
	(self galleryDirectory / 'svg') exists ifFalse: [
		Pele2svgError signal: 'Run node out/gallery/make-svgs.mjs first: ' , (self galleryDirectory / 'svg') fullName , ' does not exist' ].
	(self galleryDirectory / 'skia') ensureCreateDirectory.
	pele := self new renderer.
	results := OrderedCollection new.
	errors := OrderedCollection new.
	self new examples do: [ :each | | name |
		name := each at: 'name'.
		[ results add: (self exportGalleryPngNamed: name using: pele) ]
			on: Error
			do: [ :error | errors add: { name. error messageText asString } ] ].
	(self galleryDirectory / 'skia-metrics.json') ensureDelete.
	(self galleryDirectory / 'skia-metrics.json') writeStreamDo: [ :stream |
		stream nextPutAll: (NeoJSONWriter toString: { 'results' -> results asArray. 'errors' -> errors asArray } asDictionary) ].
	^ errors size
]

{ #category : 'fixtures' }
Pele2svgExamples class >> fixtureDirectory [
	"test/fixtures in the Iceberg clone of the pele2svg repository."
	^ Pele2svg repositoryDirectory / 'test' / 'fixtures'
]

{ #category : 'gallery' }
Pele2svgExamples class >> galleryDirectory [
	"out/gallery in the Iceberg clone of the pele2svg repository (git-ignored)."
	^ Pele2svg repositoryDirectory / 'out' / 'gallery'
]

{ #category : 'gallery' }
Pele2svgExamples class >> galleryScale [
	"The gallery PNGs are written at this multiple of the SVG size, so that they stay sharp on a high-resolution screen."
	^ 2
]

{ #category : 'examples' }
Pele2svgExamples >> architecture [
	<gtExample>
	^ self elementFor: 'architecture-beta
  group api(cloud)[API]
  service db(database)[DB] in api'
]

{ #category : 'examples' }
Pele2svgExamples >> block [
	<gtExample>
	^ self elementFor: 'block-beta
  columns 2
  a b'
]

{ #category : 'examples' }
Pele2svgExamples >> c4Context [
	<gtExample>
	^ self elementFor: 'C4Context
  Person(a, "User")
  System(b, "Sys")
  Rel(a, b, "uses")'
]

{ #category : 'examples' }
Pele2svgExamples >> classDiagram [
	<gtExample>
	^ self elementFor: 'classDiagram
  Animal <|-- Dog
  Animal : +name
  Dog : +bark()'
]

{ #category : 'private' }
Pele2svgExamples >> elementFor: aMermaidString [
	"Answer a BlSkiaSvgElement sized from the SVG viewBox."
	^ self renderer elementFromSvg: (self svgFor: aMermaidString)
]

{ #category : 'accessing' }
Pele2svgExamples >> elementOfExampleNamed: aName [
	"Answer a BlSkiaSvgElement for the example, for instance 'flowchart-1', 'flowchart-01' or 'flowchart-layout-curves-1'."
	^ self elementFor: (self sourceOfExampleNamed: aName)
]

{ #category : 'examples' }
Pele2svgExamples >> erDiagram [
	<gtExample>
	^ self elementFor: 'erDiagram
  CUSTOMER ||--o{ ORDER : places'
]

{ #category : 'examples' }
Pele2svgExamples >> exampleNamesAreUnique [
	<gtExample>
	| names |
	names := self examples collect: [ :each | each at: 'name' ].
	self assert: names isNotEmpty.
	self assert: names asSet size equals: names size.
	^ names
]

{ #category : 'accessing' }
Pele2svgExamples >> examples [
	"All the examples, as Dictionaries with the keys 'corpus', 'type', 'name' and 'source'. The type is the part of the name before the first hyphen."
	^ self class corpusNames flatCollect: [ :corpus |
		(self class examplesOfCorpus: corpus) collect: [ :each |
			Dictionary new
				at: 'corpus' put: corpus;
				at: 'type' put: ((each at: 'name') copyUpTo: $-);
				at: 'name' put: (each at: 'name');
				at: 'source' put: (each at: 'source');
				yourself ] ]
]

{ #category : 'private' }
Pele2svgExamples >> firstElementOfCorpus: aCorpusName [
	^ self elementFor: ((self examples detect: [ :each | (each at: 'corpus') = aCorpusName ]) at: 'source')
]

{ #category : 'examples' }
Pele2svgExamples >> firstOfDocs [
	<gtExample>
	^ self firstElementOfCorpus: 'docs'
]

{ #category : 'examples' }
Pele2svgExamples >> firstOfFeatured [
	<gtExample>
	^ self firstElementOfCorpus: 'featured'
]

{ #category : 'examples' }
Pele2svgExamples >> firstOfLayout [
	<gtExample>
	^ self firstElementOfCorpus: 'layout'
]

{ #category : 'examples' }
Pele2svgExamples >> flowchart [
	<gtExample>
	^ self elementFor: 'flowchart LR
  A[Start] --> B{OK?}
  B -- yes --> C[Done]
  B -- no --> D[Retry]
  D --> B'
]

{ #category : 'examples' }
Pele2svgExamples >> flowchartSubgraph [
	<gtExample>
	^ self elementFor: 'flowchart TB
  subgraph GT
    direction LR
    Coder --> Inspector
  end
  subgraph Pharo
    VM --> Image
  end
  GT --> Pharo'
]

{ #category : 'examples' }
Pele2svgExamples >> gantt [
	<gtExample>
	^ self elementFor: 'gantt
  title Plan
  dateFormat YYYY-MM-DD
  section A
  Task1 :a1, 2026-01-01, 5d'
]

{ #category : 'examples' }
Pele2svgExamples >> gitGraph [
	<gtExample>
	^ self elementFor: 'gitGraph
  commit
  branch dev
  commit
  checkout main
  merge dev'
]

{ #category : 'views' }
Pele2svgExamples >> gtExamplesFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Examples';
		priority: 1;
		items: [ self examples ];
		column: 'Corpus' text: [ :each | each at: 'corpus' ] width: 80;
		column: 'Type' text: [ :each | each at: 'type' ] width: 120;
		column: 'Name' text: [ :each | each at: 'name' ];
		send: [ :each | self elementFor: (each at: 'source') ]
]

{ #category : 'examples' }
Pele2svgExamples >> invalidSourceSignalsError [
	<gtExample>
	| message |
	message := [ self renderer render: 'this is not mermaid(((' . nil ]
		on: Pele2svgError
		do: [ :error | error messageText ].
	self assert: message isNotNil.
	^ message
]

{ #category : 'examples' }
Pele2svgExamples >> japaneseLabels [
	<gtExample>
	^ self elementFor: 'flowchart LR
  A[開始] --> B{判定}
  B -- はい --> C[完了]
  B -- いいえ --> D[再試行]'
]

{ #category : 'examples' }
Pele2svgExamples >> journey [
	<gtExample>
	^ self elementFor: 'journey
  title Day
  section Work
  Code: 5: Me'
]

{ #category : 'examples' }
Pele2svgExamples >> kanban [
	<gtExample>
	^ self elementFor: 'kanban
  todo[Todo]
    t1[Task]'
]

{ #category : 'examples' }
Pele2svgExamples >> mindmap [
	<gtExample>
	^ self elementFor: 'mindmap
  root((GT))
    Pharo
    Skia'
]

{ #category : 'examples' }
Pele2svgExamples >> pieChart [
	<gtExample>
	^ self elementFor: 'pie title Pets
  "Dogs" : 5
  "Cats" : 3'
]

{ #category : 'examples' }
Pele2svgExamples >> quadrantChart [
	<gtExample>
	^ self elementFor: 'quadrantChart
  title T
  x-axis Low --> High
  y-axis Low --> High
  A: [0.3, 0.6]'
]

{ #category : 'private' }
Pele2svgExamples >> renderer [
	"The converter used by all examples. On Windows it applies themes/gt-windows.json, so that the text is drawn with the fonts a browser uses for the raw SVG (Arial) and Consolas."
	| pele theme |
	pele := Pele2svg new.
	theme := Pele2svg repositoryDirectory / 'themes' / 'gt-windows.json'.
	(OSPlatform current isWindows and: [ theme exists ]) ifTrue: [ pele theme: theme fullName ].
	^ pele
]

{ #category : 'examples' }
Pele2svgExamples >> requirementDiagram [
	<gtExample>
	^ self elementFor: 'requirementDiagram
  requirement r1 {
    id: 1
    text: x
    risk: low
    verifymethod: test
  }'
]

{ #category : 'examples' }
Pele2svgExamples >> sankey [
	<gtExample>
	^ self elementFor: 'sankey-beta
A,B,10'
]

{ #category : 'examples' }
Pele2svgExamples >> sequenceDiagram [
	<gtExample>
	^ self elementFor: 'sequenceDiagram
  Alice->>Bob: Hello
  Bob-->>Alice: Hi'
]

{ #category : 'examples' }
Pele2svgExamples >> sequenceLoopAndNote [
	<gtExample>
	^ self elementFor: 'sequenceDiagram
  participant GT
  participant Node
  GT->>Node: run pele2svg
  loop until exit
    Node-->>GT: wait
  end
  Note over GT,Node: timeout 30 s'
]

{ #category : 'accessing' }
Pele2svgExamples >> sourceOfExampleNamed: aName [
	"Answer the Mermaid source of the example. Signal Pele2svgError when there is none of that name."
	^ (self examples
		detect: [ :each | (each at: 'name') = aName ]
		ifNone: [ Pele2svgError signal: 'No example named ' , aName ]) at: 'source'
]

{ #category : 'examples' }
Pele2svgExamples >> stateDiagram [
	<gtExample>
	^ self elementFor: 'stateDiagram-v2
  [*] --> Idle
  Idle --> Running
  Running --> [*]'
]

{ #category : 'private' }
Pele2svgExamples >> svgFor: aMermaidString [
	| svg |
	svg := self renderer render: aMermaidString.
	self assert: (svg beginsWith: '<svg').
	self assert: (svg includesSubstring: 'var(') not.
	self assert: (svg includesSubstring: '<style') not.
	^ svg
]

{ #category : 'examples' }
Pele2svgExamples >> themeFromDictionary [
	<gtExample>
	| svg |
	svg := self renderer
			theme: {'--pele-fg' -> '#abcdef'} asDictionary;
			render: 'sequenceDiagram
  Alice->>Bob: Hello'.
	self assert: (svg includesSubstring: '#abcdef').
	^ self elementFor: 'sequenceDiagram
  Alice->>Bob: Hello'
]

{ #category : 'examples' }
Pele2svgExamples >> timeline [
	<gtExample>
	^ self elementFor: 'timeline
  title History
  2020 : A
  2021 : B'
]

{ #category : 'accessing' }
Pele2svgExamples >> types [
	"The diagram types that have examples, sorted."
	^ (self examples collect: [ :each | each at: 'type' ]) asSet asSortedCollection asArray
]

{ #category : 'examples' }
Pele2svgExamples >> xyChart [
	<gtExample>
	^ self elementFor: 'xychart-beta
  x-axis [a, b, c]
  bar [1, 2, 3]'
]
