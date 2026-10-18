"
I convert Mermaid source to a GToolkit-friendly SVG string by running pele2svg (Node.js or Bun) as an external process.

	Pele2svg installDependencies.	""once, after loading the package""
	Pele2svg new render: mmd.
	Pele2svg new theme: 'path/to/theme.json'; asElement: mmd.

script: path to pele2svg.mjs (default: the Iceberg clone of pele2svg).
runtime: executable, 'node' by default ('bun' also works).
theme: nil (default), a path to a theme JSON file, or a Dictionary of theme variables. Generic font families such as monospace are left as they are.
timeout: milliseconds, 30000 by default.
installDependencies installs pele (npm install, or bun install) in the directory of the script, unless it is already there.
Failures signal Pele2svgError.
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
	| file |
	file := self repositoryDirectory / 'pele2svg.mjs'.
	file exists ifFalse: [ Pele2svgError signal: 'Not found: ', file fullName ].
	^ file fullName
]

{ #category : 'installing' }
Pele2svg class >> installDependencies [
	"Install pele (npm install) in the directory of pele2svg.mjs. Run it once after loading the package."
	^ self new installDependencies
]

{ #category : 'defaults' }
Pele2svg class >> repositoryDirectory [
	"The directory of the Iceberg clone of the pele2svg repository."
	| repository |
	repository := IceRepository registry
		detect: [ :each | each name = 'pele2svg' ]
		ifNone: [ Pele2svgError signal: 'No Iceberg repository named pele2svg; set #script: explicitly' ].
	^ repository location
]

{ #category : 'accessing' }
Pele2svg >> asElement: aMermaidString [
	^ BlSkiaSvgElement new
		svg: (self render: aMermaidString);
		yourself
]

{ #category : 'accessing' }
Pele2svg >> asWebViewElement: aMermaidString [
	"Answer a GtWebViewElement (WebView2) that draws the converted SVG. The SVG is handed to the browser as it is. GtWebViewElement>>#html: accepts at most 2 MB."
	^ GtWebViewElement new
		html: (self render: aMermaidString);
		yourself
]

{ #category : 'accessing' }
Pele2svg >> initialize [
	super initialize.
	runtime := 'node'.
	timeout := 30000
]

{ #category : 'installing' }
Pele2svg >> installDependencies [
	"Install pele next to pele2svg.mjs: npm install, or bun install when the runtime is bun. Does nothing when pele is already installed there."
	| directory command arguments process message |
	directory := self script asFileReference parent.
	(directory / 'node_modules' / 'pele') exists ifTrue: [ ^ self ].
	runtime = 'bun'
		ifTrue: [ command := 'bun'. arguments := #('install') ]
		ifFalse: [
			OSPlatform current isWindows
				ifTrue: [ command := 'cmd'. arguments := #('/c' 'npm' 'install') ]
				ifFalse: [ command := 'npm'. arguments := #('install') ] ].
	process := GtSubprocessWithInMemoryOutput new
		command: command;
		arguments: arguments;
		workingDirectory: directory;
		yourself.
	self runProcess: process timeout: 300000 description: 'npm install in ', directory fullName.
	process exitCode = 0 ifFalse: [
		message := process stderr trimBoth.
		Pele2svgError signal: 'install failed: ', (message last: (message size min: 600)) ]
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
		self runProcess: process timeout: timeout description: runtime.
		(process exitCode = 0 and: [ out exists ]) ifFalse: [
			| message |
			message := process stderr trimBoth.
			Pele2svgError signal: (message first: (message size min: 600)) ].
		out binaryReadStreamDo: [ :s | s upToEnd utf8Decoded ] ]
			ensure: [ dir ensureDeleteAll ]
]

{ #category : 'private' }
Pele2svg >> runProcess: aProcess timeout: milliseconds description: aString [
	"Run aProcess to completion. Signal Pele2svgError when it cannot be started or does not finish in time."
	| timedOut |
	timedOut := false.
	[ aProcess runAndSignal.
	  timedOut := aProcess waitTimeoutMilliseconds: milliseconds.
	  "stderr signals an error when the process could not be started"
	  timedOut ifFalse: [ aProcess stderr ] ]
		on: Error
		do: [ :error | Pele2svgError signal: 'cannot run ', aString, ': ', error messageText ].
	timedOut ifTrue: [
		aProcess kill.
		Pele2svgError signal: aString, ' timed out after ', milliseconds printString, ' ms' ]
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
	"Theme variables for pele2svg: nil, the path of a theme JSON file, or a Dictionary. See docs/standalone.md."
	theme := nilOrPathOrDictionary
]

{ #category : 'private' }
Pele2svg >> themeArgumentIn: aDirectory [
	"Answer the theme arguments for the command line: none, or the path of a theme file."
	| file |
	theme ifNil: [ ^ #() ].
	theme isDictionary ifFalse: [
		file := theme asFileReference.
		file exists ifFalse: [ Pele2svgError signal: 'Theme file not found: ', file fullName ].
		^ { file fullName } ].
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
