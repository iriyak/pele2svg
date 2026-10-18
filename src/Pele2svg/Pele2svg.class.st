"
I convert Mermaid source to a GToolkit-friendly SVG string by running pele2svg (Node.js or Bun) as an external process.

	Pele2svg new render: mmd.
	Pele2svg new theme: 'path/to/theme.json'; asElement: mmd.

script: path to pele2svg.mjs (default: the Iceberg clone of pele2svg; run npm install there once).
runtime: executable, 'node' by default ('bun' also works).
theme: nil, a path to a theme JSON file, or a Dictionary of theme variables.
timeout: milliseconds, 30000 by default.
"
Class {
	#name : 'Pele2svg',
	#superclass : 'Object',
	#instVars : [
		'script',
		'runtime',
		'theme',
		'timeout'
	],
	#category : 'Pele2svg',
	#package : 'Pele2svg'
}

{ #category : 'defaults' }
Pele2svg class >> defaultScript [
	"The pele2svg.mjs inside the Iceberg clone of the pele2svg repository."
	| repo file |
	repo := IceRepository registry
		detect: [ :each | each name = 'pele2svg' ]
		ifNone: [ Pele2svgError signal: 'No Iceberg repository named pele2svg; set #script: explicitly' ].
	file := repo location / 'pele2svg.mjs'.
	file exists ifFalse: [ Pele2svgError signal: 'Not found: ', file fullName ].
	^ file fullName
]

{ #category : 'accessing' }
Pele2svg >> asElement: aMermaidString [
	^ BlSkiaSvgElement new
		svg: (self render: aMermaidString);
		yourself
]

{ #category : 'accessing' }
Pele2svg >> initialize [
	super initialize.
	runtime := 'node'.
	timeout := 30000
]

{ #category : 'accessing' }
Pele2svg >> render: aMermaidString [
	"Answer the converted SVG string. Signal Pele2svgError on failure or timeout."
	| dir in out process |
	dir := (FileLocator temp / 'pele2svg' / UUID new asString) ensureCreateDirectory.
	^ [ in := dir / 'in.mmd'.
		out := dir / 'out.svg'.
		in binaryWriteStreamDo: [ :s | s nextPutAll: aMermaidString utf8Encoded ].
		process := GtSubprocessWithInMemoryOutput new
			command: runtime;
			arguments: { self script. in fullName. out fullName }, (self themeArgumentIn: dir);
			yourself.
		process runAndSignal.
		(process waitTimeoutMilliseconds: timeout) ifTrue: [
			process kill.
			Pele2svgError signal: 'pele2svg timed out after ', timeout printString, ' ms' ].
		(process exitCode = 0 and: [ out exists ]) ifFalse: [
			| message |
			message := process stderr trimBoth.
			Pele2svgError signal: (message first: (message size min: 600)) ].
		out binaryReadStreamDo: [ :s | s upToEnd utf8Decoded ] ]
			ensure: [ dir ensureDeleteAll ]
]

{ #category : 'accessing' }
Pele2svg >> runtime [
	^ runtime
]

{ #category : 'accessing' }
Pele2svg >> runtime: anExecutableName [
	runtime := anExecutableName
]

{ #category : 'accessing' }
Pele2svg >> script [
	^ script ifNil: [ self class defaultScript ]
]

{ #category : 'accessing' }
Pele2svg >> script: aPathString [
	script := aPathString
]

{ #category : 'accessing' }
Pele2svg >> theme [
	^ theme
]

{ #category : 'accessing' }
Pele2svg >> theme: nilOrPathOrDictionary [
	theme := nilOrPathOrDictionary
]

{ #category : 'accessing' }
Pele2svg >> themeArgumentIn: aDirectory [
	| file |
	theme ifNil: [ ^ #() ].
	theme isDictionary ifFalse: [ ^ { theme asFileReference fullName } ].
	file := aDirectory / 'theme.json'.
	file binaryWriteStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toString: theme) utf8Encoded ].
	^ { file fullName }
]

{ #category : 'accessing' }
Pele2svg >> timeout [
	^ timeout
]

{ #category : 'accessing' }
Pele2svg >> timeout: milliseconds [
	timeout := milliseconds
]
