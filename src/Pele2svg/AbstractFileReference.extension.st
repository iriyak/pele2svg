Extension { #name : 'AbstractFileReference' }

{ #category : '*Pele2svg' }
AbstractFileReference >> gtSvgInWebViewFor: aView [
	<gtView>
	(self isFile and: [ self extension asLowercase = 'svg' ])
		ifFalse: [ ^ aView empty ].

	^ aView explicit
		title: 'SvgInWeb';
		priority: 15;
		stencil: [ | urlString |
			urlString := 'file:///' , self pathString.
			GtWebViewElement new url: urlString ]
]
