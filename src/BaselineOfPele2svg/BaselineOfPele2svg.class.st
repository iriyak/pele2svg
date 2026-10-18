Class {
	#name : 'BaselineOfPele2svg',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPele2svg',
	#package : 'BaselineOfPele2svg'
}

{ #category : 'baseline' }
BaselineOfPele2svg >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'Pele2svg'
		]
]
