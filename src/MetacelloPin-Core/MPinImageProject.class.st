"
I am a baseline class loaded in the image. When I pin, I recompile the changed methods in
the image. Commit the change with Iceberg afterwards.
"
Class {
	#name : #MPinImageProject,
	#superclass : #MPinProject,
	#instVars : [
		'baselineClass'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #'instance creation' }
MPinImageProject class >> on: aBaselineClass [

	^ self new
		  baselineClass: aBaselineClass;
		  yourself
]

{ #category : #accessing }
MPinImageProject >> baselineClass [

	^ baselineClass
]

{ #category : #accessing }
MPinImageProject >> baselineClass: aClass [

	baselineClass := aClass
]

{ #category : #accessing }
MPinImageProject >> occurrences [

	^ self scanner scanClass: baselineClass
]

{ #category : #private }
MPinImageProject >> pin: aMethod with: aPinner [

	| source occurrences newSource |
	source := aMethod sourceCode.
	occurrences := self scanner scanMethodSource: source owner: baselineClass name.
	newSource := aPinner pinSource: source occurrences: occurrences.
	newSource = source ifFalse: [
		baselineClass compile: newSource classified: aMethod protocolName ].
	^ occurrences
]

{ #category : #pinning }
MPinImageProject >> pinWith: aResolver [

	| pinner |
	pinner := MPinPinner resolver: aResolver.
	^ baselineClass methods flatCollect: [ :each | self pin: each with: pinner ]
]
