"
I am Pele2svgOptions, an object that holds key/value options for configuration, parameterization and settings of Pele2svg. I follow the design of ZnOptions.

Option objects contain key/value pairs and inherit from a parent. They can be writable or read-only.

Clients typically refer to an option using the Pele2svgCurrentOptions dynamic variable.

	Pele2svgCurrentOptions at: #runtime

The top level, global default is defined on my class side by the <pele2svgOption> pragma: the method selector is the key and the value it answers is the default value. I hold the #globalDefault options. They are writable, so the default for everything can be changed:

	Pele2svgOptions globalDefault at: #runtime put: 'bun'.

Options can be cloned to make a local, writable copy that inherits from the original. Use #during: to activate a copy for a block only:

	Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ Pele2svg new render: aMermaidString ].

An instance of Pele2svg keeps the options set on it with #runtime:, #script:, #theme: or #timeout: (as ZnClient does) and applies them with #conditionallyDuring:. So the options of an enclosing #during: take precedence over what was set on the instance, and what was set on the instance takes precedence over the global default.

Options: #runtime (executable, 'node' or 'bun'), #script (path of pele2svg.mjs; nil means the Iceberg clone of pele2svg), #theme (nil, a path to a theme JSON file or a Dictionary of theme variables), #timeout (milliseconds for one conversion), #installTimeout (milliseconds for installDependencies).
"
Class {
	#name : 'Pele2svgOptions',
	#superclass : 'Object',
	#instVars : [
		'options',
		'parent',
		'writable'
	],
	#classVars : [
		'globalDefault'
	],
	#category : 'Pele2svg-Options',
	#package : 'Pele2svg',
	#tag : 'Options'
}

{ #category : 'utilities' }
Pele2svgOptions class >> definitionOf: key [
	"Answer the class-side method that defines the option key."

	| options |
	options := key implementors select: [ :method |
		method methodClass = self class and: [ method method pragmas anySatisfy: [ :pragma | pragma selector = #pele2svgOption ] ] ].
	options ifEmpty: [ self error: 'No option definition found for ', key printString ].
	options size > 1 ifTrue: [ self error: 'Multiple conflicting option definitions found for ', key printString ].
	^ options first method
]

{ #category : 'accessing' }
Pele2svgOptions class >> globalDefault [
	"The writable options that are used when no other options are active."

	^ globalDefault ifNil: [ globalDefault := self root clone ]
]

{ #category : 'class initialization' }
Pele2svgOptions class >> initialize [
	self resetGlobalDefault
]

{ #category : 'options' }
Pele2svgOptions class >> installTimeout [
	"Milliseconds installDependencies may take before it is stopped."

	<pele2svgOption>
	^ 300000
]

{ #category : 'instance creation' }
Pele2svgOptions class >> onClass: targetClass [
	"Answer read-only options holding the defaults defined by the <pele2svgOption> methods on the class side of targetClass."

	| dictionary |
	dictionary := Dictionary new.
	(Pragma allNamed: #pele2svgOption in: targetClass class) do: [ :each |
		dictionary
			at: each method selector
			put: (each method methodClass instanceSide perform: each method selector) ].
	^ self new
		options: dictionary;
		writable: false;
		yourself
]

{ #category : 'class initialization' }
Pele2svgOptions class >> resetGlobalDefault [
	globalDefault := nil
]

{ #category : 'private' }
Pele2svgOptions class >> root [
	^ self onClass: self
]

{ #category : 'options' }
Pele2svgOptions class >> runtime [
	"The executable that runs pele2svg.mjs: 'node' or 'bun'."

	<pele2svgOption>
	^ 'node'
]

{ #category : 'options' }
Pele2svgOptions class >> script [
	"The path of pele2svg.mjs. nil means the pele2svg.mjs in the Iceberg clone of the pele2svg repository."

	<pele2svgOption>
	^ nil
]

{ #category : 'options' }
Pele2svgOptions class >> theme [
	"Theme variables for pele2svg: nil, the path of a theme JSON file, or a Dictionary. See docs/standalone.md."

	<pele2svgOption>
	^ nil
]

{ #category : 'options' }
Pele2svgOptions class >> timeout [
	"Milliseconds a conversion may take before it is stopped."

	<pele2svgOption>
	^ 30000
]

{ #category : 'accessing' }
Pele2svgOptions >> at: key [
	options ifNotNil: [ options at: key ifPresent: [ :value | ^ value ] ].
	^ parent
		ifNil: [ KeyNotFound signalFor: key in: self ]
		ifNotNil: [ parent at: key ]
]

{ #category : 'accessing' }
Pele2svgOptions >> at: key put: value [
	writable ifFalse: [
		(ModificationForbidden for: self at: key with: value retrySelector: #at:put:) signal ].
	(parent notNil and: [ parent includesKey: key ])
		ifFalse: [ KeyNotFound signalFor: key in: self ].
	options ifNil: [ options := Dictionary new ].
	^ options at: key put: value
]

{ #category : 'copying' }
Pele2svgOptions >> clone [
	"Answer writable options that inherit from the receiver."

	^ self class new
		parent: self;
		writable: true;
		yourself
]

{ #category : 'execution' }
Pele2svgOptions >> conditionallyDuring: block [
	"Evaluate block with the receiver as the current options, unless an enclosing #during: has already activated other options."

	^ Pele2svgCurrentOptions value
		ifNil: [ Pele2svgCurrentOptions value: self during: block ]
		ifNotNil: block
]

{ #category : 'execution' }
Pele2svgOptions >> during: block [
	"Evaluate block with the receiver as the current options."

	^ Pele2svgCurrentOptions value: self during: block
]

{ #category : 'testing' }
Pele2svgOptions >> includesKey: key [
	^ (options notNil and: [ options includesKey: key ])
		or: [ parent notNil and: [ parent includesKey: key ] ]
]

{ #category : 'private' }
Pele2svgOptions >> options: aDictionary [
	options := aDictionary
]

{ #category : 'private' }
Pele2svgOptions >> parent: otherOptions [
	parent ifNotNil: [
		(ModificationForbidden for: self at: nil with: otherOptions retrySelector: #parent:) signal ].
	parent := otherOptions
]

{ #category : 'private' }
Pele2svgOptions >> writable: boolean [
	writable ifNotNil: [
		(ModificationForbidden for: self at: nil with: boolean retrySelector: #writable:) signal ].
	writable := boolean
]
