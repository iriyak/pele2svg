"
Tests for Pele2svgOptions and Pele2svgCurrentOptions: the defaults, #during:, the precedence of values set on a Pele2svg instance, and the read-only root. They do not run pele2svg.mjs.
"
Class {
	#name : 'Pele2svgOptionsTest',
	#superclass : 'TestCase',
	#category : 'Pele2svg-Tests',
	#package : 'Pele2svg-Tests'
}

{ #category : 'running' }
Pele2svgOptionsTest >> tearDown [
	Pele2svgOptions resetGlobalDefault.
	super tearDown
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testConditionallyDuringKeepsEnclosingOptions [
	| inner |
	inner := Pele2svgOptions globalDefault clone at: #runtime put: 'x'; yourself.
	Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ inner conditionallyDuring: [ self assert: (Pele2svgCurrentOptions at: #runtime) equals: 'bun' ] ].
	inner conditionallyDuring: [ self assert: (Pele2svgCurrentOptions at: #runtime) equals: 'x' ]
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testDefaults [
	self assert: (Pele2svgCurrentOptions at: #runtime) equals: 'node'.
	self assert: (Pele2svgCurrentOptions at: #timeout) equals: 30000.
	self assert: (Pele2svgCurrentOptions at: #installTimeout) equals: 300000.
	self assert: (Pele2svgCurrentOptions at: #theme) isNil.
	self assert: (Pele2svgCurrentOptions at: #script) isNil
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testDuringIsLocal [
	Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ self assert: Pele2svg new runtime equals: 'bun' ].
	self assert: Pele2svg new runtime equals: 'node'.
	self assert: (Pele2svgOptions globalDefault includesKey: #runtime)
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testDuringIsNotVisibleAfterAnError [
	[ Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ self error: 'expected' ] ] on: Error do: [ :error | error return ].
	self assert: Pele2svg new runtime equals: 'node'
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testEnclosingDuringTakesPrecedenceOverInstanceValue [
	"As with ZnClient, the options of an enclosing #during: win over what was set on the instance."

	| pele |
	pele := Pele2svg new runtime: '/path/to/node'; yourself.
	Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ self assert: pele runtime equals: 'bun' ].
	self assert: pele runtime equals: '/path/to/node'
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testEveryOptionHasOneDefinition [
	#(#runtime #script #theme #timeout #installTimeout) do: [ :key |
		self assert: (Pele2svgOptions definitionOf: key) methodClass equals: Pele2svgOptions class ]
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testGlobalDefaultIsWritable [
	Pele2svgOptions globalDefault at: #runtime put: 'bun'.
	self assert: (Pele2svgCurrentOptions at: #runtime) equals: 'bun'.
	self assert: Pele2svg new runtime equals: 'bun'.
	Pele2svgOptions resetGlobalDefault.
	self assert: Pele2svg new runtime equals: 'node'
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testInstanceSeesALaterGlobalDefaultAndAReset [
	| pele |
	pele := Pele2svg new.
	Pele2svgOptions globalDefault at: #runtime put: 'bun'.
	self assert: pele runtime equals: 'bun'.
	Pele2svgOptions resetGlobalDefault.
	self assert: pele runtime equals: 'node'
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testInstanceValueIsLocalToTheInstance [
	Pele2svg new runtime: '/path/to/node'.
	self assert: Pele2svg new runtime equals: 'node'
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testInstanceValueIsUsedWithoutDuring [
	| pele |
	Pele2svgOptions globalDefault at: #timeout put: 10.
	pele := Pele2svg new runtime: '/path/to/node'; timeout: 5; yourself.
	self assert: pele runtime equals: '/path/to/node'.
	self assert: pele timeout equals: 5.
	"what was not set on the instance comes from the global default"
	self assert: pele theme isNil.
	self assert: Pele2svg new timeout equals: 10
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testRenderUsesTheInstanceRuntime [
	"A runtime that cannot be started is reported as Pele2svgError: the instance value reaches the process."

	self
		should: [ Pele2svg new runtime: 'no-such-runtime-for-pele2svg'; render: 'flowchart LR
  A --> B' ]
		raise: Pele2svgError
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testRenderUsesTheRuntimeOption [
	"A runtime that cannot be started is reported as Pele2svgError, which shows that the option reaches the process."

	Pele2svgOptions globalDefault clone
		at: #runtime put: 'no-such-runtime-for-pele2svg';
		during: [ self should: [ Pele2svg new render: 'flowchart LR
  A --> B' ] raise: Pele2svgError ]
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testRootIsReadOnly [
	self should: [ Pele2svgOptions root at: #runtime put: 'bun' ] raise: ModificationForbidden
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testUnknownKeyIsRejected [
	self should: [ Pele2svgOptions globalDefault at: #nope put: 1 ] raise: KeyNotFound.
	self should: [ Pele2svgCurrentOptions at: #nope ] raise: KeyNotFound
]

{ #category : 'tests' }
Pele2svgOptionsTest >> testUnknownKeyIsRejectedOnTheInstance [
	self should: [ Pele2svg new optionAt: #nope put: 1 ] raise: KeyNotFound
]
