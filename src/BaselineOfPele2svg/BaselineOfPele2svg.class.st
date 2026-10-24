"
Metacello baseline of Pele2svg. The default group loads the package Pele2svg; the group Tests also loads Pele2svg-Tests. Run Pele2svg installDependencies once afterwards to install Pele next to pele2svg.mjs.
"
Class {
	#name : 'BaselineOfPele2svg',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPele2svg',
	#package : 'BaselineOfPele2svg'
}

{ #category : 'lepiter' }
BaselineOfPele2svg class >> loadLepiter [
	"Register the lepiter/ folder of this repository with the default logical Lepiter database and reload it,
	 so that the 'Getting started with pele2svg in GT' page shows up in Lepiter. Requires the repository to be
	 loaded into Iceberg (as 'pele2svg'), which Metacello does."

	IceRepository registry
		detect: [ :aRepository | aRepository name = 'pele2svg' ]
		ifFound: [ :aRepository |
			| defaultDatabase |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			defaultDatabase properties
				addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [ self inform: 'Repository pele2svg not found in Iceberg.' ]
]

{ #category : 'accessing' }
BaselineOfPele2svg >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec
				package: 'Pele2svg';
				package: 'Pele2svg-Tests' with: [ spec requires: #('Pele2svg') ].
			spec
				group: 'default' with: #('Pele2svg');
				group: 'Tests' with: #('Pele2svg' 'Pele2svg-Tests') ]
]
