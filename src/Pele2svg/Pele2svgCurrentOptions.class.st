"
I am Pele2svgCurrentOptions. I am a DynamicVariable and a ProcessSpecificVariable.

I provide access to the current Pele2svgOptions instance: the options activated by an enclosing Pele2svgOptions>>#during:, or else Pele2svgOptions globalDefault.

	Pele2svgCurrentOptions at: #runtime
"
Class {
	#name : 'Pele2svgCurrentOptions',
	#superclass : 'DynamicVariable',
	#category : 'Pele2svg',
	#package : 'Pele2svg'
}

{ #category : 'accessing' }
Pele2svgCurrentOptions class >> at: key [
	^ self value
		ifNil: [ Pele2svgOptions globalDefault at: key ]
		ifNotNil: [ :options | options at: key ]
]
