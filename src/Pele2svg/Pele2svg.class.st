"
I convert Mermaid source to a GToolkit-friendly SVG string by running pele2svg (Node.js or Bun) as an external process.

	Pele2svg installDependencies.	""once, after loading the package""
	Pele2svg new render: mmd.
	Pele2svg new theme: 'path/to/theme.json'; asElement: mmd.
	Pele2svg new renderSvg: peleSvg.	""an SVG that Pele has already produced""
	Pele2svg new asElementFromSvg: peleSvg.

Settings (script, runtime, theme, renderOptions, timeout) are options in the sense of ZnOptions, and an instance works like a ZnClient. What is set on it with #script:, #runtime:, #theme:, #renderOptions: or #timeout: is kept in the instance and applied on top of Pele2svgOptions globalDefault when it renders. The options of an enclosing Pele2svgOptions>>#during: take precedence over both. The getters answer the value that rendering would use now.

	Pele2svgOptions globalDefault at: #runtime put: 'bun'.	""for everything""
	Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ Pele2svg new render: mmd ].	""for this block only""

script: path to pele2svg.mjs (default: the Iceberg clone of pele2svg).
runtime: executable, 'node' by default ('bun' also works).
theme: nil (default), a path to a theme JSON file, or a Dictionary of theme variables. Generic font families such as monospace are left as they are; Skia does not resolve monospace (the text comes out proportional), so map it to a real font name with the theme key --gt-font-mono, e.g. { '--gt-font-mono' -> 'Consolas' } asDictionary on Windows.
renderOptions: nil (default) or a Dictionary of options for Pele's render(), for example { #maxWidth -> 360 } asDictionary for a narrow layout, or { #math -> true } asDictionary to typeset $$...$$ with MathJax (see docs/mermaid-in-gt.md). They apply to Mermaid source, not to #renderSvg:.
timeout: milliseconds, 30000 by default.
installDependencies installs pele and, as an optional dependency, mathjax-full (npm install, or bun install) in the directory of the script, unless both are already there.
Failures signal Pele2svgError.
"
Class {
	#name : 'Pele2svg',
	#superclass : 'Object',
	#instVars : [
		'options'
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

{ #category : 'converting' }
Pele2svg >> asElement: aMermaidString [
	"Answer a BlSkiaSvgElement for the diagram, sized from the viewBox of the SVG so that it takes its own room in a layout."
	^ self elementFromSvg: (self render: aMermaidString)
]

{ #category : 'converting' }
Pele2svg >> asElementFromSvg: anSvgString [
	"Answer a BlSkiaSvgElement for an SVG that Pele has already produced, after converting it like #renderSvg:."
	^ self elementFromSvg: (self renderSvg: anSvgString)
]

{ #category : 'accessing' }
Pele2svg >> asWebViewElement: aMermaidString [
	"Answer a GtWebViewElement (WebView2) that draws the converted SVG. The SVG is handed to the browser as it is. GtWebViewElement>>#html: accepts at most 2 MB."
	^ GtWebViewElement new
		html: (self render: aMermaidString);
		yourself
]

{ #category : 'private' }
Pele2svg >> attribute: aName inTag: aTagString [
	"Answer the value of the attribute, or nil when the tag has none."
	| stream |
	stream := aTagString readStream.
	stream upToAll: ' ', aName, '="'.
	^ stream atEnd ifTrue: [ nil ] ifFalse: [ stream upTo: $" ]
]

{ #category : 'private' }
Pele2svg >> basicConvert: aString extension: anExtension flags: anArray [
	| dir in out process |
	dir := (FileLocator temp / 'pele2svg' / UUID new asString) ensureCreateDirectory.
	^ [ in := dir / ('in.', anExtension).
		out := dir / 'out.svg'.
		in binaryWriteStreamDo: [ :s | s nextPutAll: aString utf8Encoded ].
		process := GtSubprocessWithInMemoryOutput new
			command: self runtime;
			arguments: { self script }, anArray, (anExtension = 'mmd' ifTrue: [ self renderOptionsArgumentIn: dir ] ifFalse: [ #() ]), { in fullName. out fullName }, (self themeArgumentIn: dir);
			yourself.
		self runProcess: process timeout: self timeout description: self runtime.
		(process exitCode = 0 and: [ out exists ]) ifFalse: [
			| message |
			message := process stderr trimBoth.
			Pele2svgError signal: (message first: (message size min: 600)) ].
		out binaryReadStreamDo: [ :s | s upToEnd utf8Decoded ] ]
			ensure: [ dir ensureDeleteAll ]
]

{ #category : 'private' }
Pele2svg >> basicInstallDependencies [
	"Install pele (and mathjax-full, an optional dependency used for $$...$$ math) next to pele2svg.mjs: npm install, or bun install when the runtime is bun. Does nothing when both are already installed there."
	| directory command arguments process message |
	directory := self script asFileReference parent.
	((directory / 'node_modules' / 'pele') exists and: [ (directory / 'node_modules' / 'mathjax-full') exists ]) ifTrue: [ ^ self ].
	self runtime = 'bun'
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
	self runProcess: process timeout: (Pele2svgCurrentOptions at: #installTimeout) description: 'npm install in ', directory fullName.
	process exitCode = 0 ifFalse: [
		message := process stderr trimBoth.
		Pele2svgError signal: 'install failed: ', (message last: (message size min: 600)) ]
]

{ #category : 'converting' }
Pele2svg >> convert: aString extension: anExtension flags: anArray [
	"Write aString to a temporary file, run pele2svg.mjs on it and answer the SVG it wrote."

	^ self withDynamicVariablesDo: [ self basicConvert: aString extension: anExtension flags: anArray ]
]

{ #category : 'private' }
Pele2svg >> elementFromSvg: anSvgString [
	"Answer a BlSkiaSvgElement showing the SVG. Its size is the width and height of the viewBox, or of the root's width and height when there is no viewBox. Skia draws nothing when the root has a viewBox but no width and height, so they are added. Signal Pele2svgError when the SVG has neither."
	| start rootTag extent svg |
	start := anSvgString indexOfSubCollection: '<svg'.
	start = 0 ifTrue: [ Pele2svgError signal: 'Not an SVG: there is no <svg> element' ].
	rootTag := anSvgString readStream position: start - 1; upTo: $>.
	extent := self extentOfSvgRoot: rootTag.
	svg := anSvgString.
	(rootTag includesSubstring: ' width=') ifFalse: [
		svg := (svg first: start + 3), ' width="', extent x printString, '" height="', extent y printString, '"', (svg allButFirst: start + 3) ].
	^ BlSkiaSvgElement new
		svg: svg;
		size: extent;
		yourself
]

{ #category : 'private' }
Pele2svg >> extentOfSvgRoot: aRootTagString [
	"Answer the width@height of the viewBox, or else of the width and height attributes, of the root <svg> tag."
	| numbers width height |
	numbers := (((self attribute: 'viewBox' inTag: aRootTagString) ifNil: [ '' ]) substrings: ', ')
		collect: #asNumber.
	numbers size = 4 ifTrue: [ ^ numbers third @ numbers fourth ].
	width := self attribute: 'width' inTag: aRootTagString.
	height := self attribute: 'height' inTag: aRootTagString.
	(width notNil and: [ height notNil and: [ (width includes: $%) not and: [ (height includes: $%) not ] ] ])
		ifTrue: [ ^ width asNumber @ height asNumber ].
	Pele2svgError signal: 'The SVG has neither a viewBox nor a width and height in pixels'
]

{ #category : 'installing' }
Pele2svg >> installDependencies [
	"Install pele and mathjax-full next to pele2svg.mjs: npm install, or bun install when the runtime is bun. Does nothing when both are already installed there."

	^ self withDynamicVariablesDo: [ self basicInstallDependencies ]
]

{ #category : 'options' }
Pele2svg >> localOptions [
	"The options of this instance: the global default, with what was set on this instance on top."

	| local |
	local := Pele2svgOptions globalDefault clone.
	options ifNotNil: [ options keysAndValuesDo: [ :key :value | local at: key put: value ] ].
	^ local
]

{ #category : 'options' }
Pele2svg >> optionAt: key put: value [
	"Set the option key for this instance only. The key must be one of the options of Pele2svgOptions."

	(Pele2svgOptions globalDefault includesKey: key)
		ifFalse: [ KeyNotFound signalFor: key in: Pele2svgOptions globalDefault ].
	options ifNil: [ options := Dictionary new ].
	options at: key put: value
]

{ #category : 'accessing' }
Pele2svg >> render: aMermaidString [
	"Answer the converted SVG string. Signal Pele2svgError on failure or timeout."
	^ self convert: aMermaidString extension: 'mmd' flags: #()
]

{ #category : 'accessing' }
Pele2svg >> renderOptions [
	"nil, or a Dictionary of options for Pele's render(). See Pele2svgOptions class >> #renderOptions."

	^ self withDynamicVariablesDo: [ Pele2svgCurrentOptions at: #renderOptions ]
]

{ #category : 'accessing' }
Pele2svg >> renderOptions: nilOrDictionary [
	"Options for Pele's render(), for example { #maxWidth -> 360. #math -> true } asDictionary. They apply to Mermaid source (#render:, #asElement:), not to #renderSvg:."

	self optionAt: #renderOptions put: nilOrDictionary
]

{ #category : 'private' }
Pele2svg >> renderOptionsArgumentIn: aDirectory [
	"Answer the command line arguments for the render options: none, or --render-options and the path of a JSON file."
	| file options |
	options := self renderOptions.
	(options isNil or: [ options isEmpty ]) ifTrue: [ ^ #() ].
	file := aDirectory / 'render-options.json'.
	file binaryWriteStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toString: options) utf8Encoded ].
	^ { '--render-options'. file fullName }
]

{ #category : 'accessing' }
Pele2svg >> renderSvg: anSvgString [
	"Answer the converted SVG string for an SVG that Pele has already produced (Pele is not run). Signal Pele2svgError on failure or timeout."
	^ self convert: anSvgString extension: 'svg' flags: #('--svg')
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
	"The executable: 'node' or 'bun'. See Pele2svgOptions."

	^ self withDynamicVariablesDo: [ Pele2svgCurrentOptions at: #runtime ]
]

{ #category : 'accessing' }
Pele2svg >> runtime: anExecutableName [
	self optionAt: #runtime put: anExecutableName
]

{ #category : 'accessing' }
Pele2svg >> script [
	"The path of pele2svg.mjs: the script option, or else the pele2svg.mjs in the Iceberg clone of pele2svg."

	^ (self withDynamicVariablesDo: [ Pele2svgCurrentOptions at: #script ])
		ifNil: [ self class defaultScript ]
]

{ #category : 'accessing' }
Pele2svg >> script: aPathString [
	self optionAt: #script put: aPathString
]

{ #category : 'accessing' }
Pele2svg >> theme [
	"nil, the path of a theme JSON file, or a Dictionary of theme variables. See Pele2svgOptions."

	^ self withDynamicVariablesDo: [ Pele2svgCurrentOptions at: #theme ]
]

{ #category : 'accessing' }
Pele2svg >> theme: nilOrPathOrDictionary [
	"Theme variables for pele2svg: nil, the path of a theme JSON file, or a Dictionary. See docs/standalone.md."

	self optionAt: #theme put: nilOrPathOrDictionary
]

{ #category : 'private' }
Pele2svg >> themeArgumentIn: aDirectory [
	"Answer the theme arguments for the command line: none, or the path of a theme file."
	| file aTheme |
	aTheme := self theme.
	aTheme ifNil: [ ^ #() ].
	aTheme isDictionary ifFalse: [
		file := aTheme asFileReference.
		file exists ifFalse: [ Pele2svgError signal: 'Theme file not found: ', file fullName ].
		^ { file fullName } ].
	file := aDirectory / 'theme.json'.
	file binaryWriteStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toString: aTheme) utf8Encoded ].
	^ { file fullName }
]

{ #category : 'accessing' }
Pele2svg >> timeout [
	"Milliseconds a conversion may take. See Pele2svgOptions."

	^ self withDynamicVariablesDo: [ Pele2svgCurrentOptions at: #timeout ]
]

{ #category : 'accessing' }
Pele2svg >> timeout: milliseconds [
	self optionAt: #timeout put: milliseconds
]

{ #category : 'options' }
Pele2svg >> withDynamicVariablesDo: block [
	"Evaluate block with the options of this instance, unless an enclosing Pele2svgOptions>>#during: has already activated others; those then take precedence."

	^ Pele2svgCurrentOptions value
		ifNil: [ self localOptions during: block ]
		ifNotNil: block
]
