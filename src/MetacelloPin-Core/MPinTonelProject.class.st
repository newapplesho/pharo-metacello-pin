"
I am a directory of Tonel packages on disk. I find every `BaselineOf*.class.st` below my
directory and rewrite those files in place when pinning.
"
Class {
	#name : #MPinTonelProject,
	#superclass : #MPinProject,
	#instVars : [
		'directory'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #'instance creation' }
MPinTonelProject class >> on: aFileReference [

	^ self new
		  directory: aFileReference;
		  yourself
]

{ #category : #accessing }
MPinTonelProject >> baselineFiles [

	directory isDirectory ifFalse: [
		^ MPinError signal: 'not a directory: ' , directory fullName ].
	^ (directory allChildrenMatching: 'BaselineOf*.class.st') sorted: [ :a :b |
		  a fullName < b fullName ]
]

{ #category : #accessing }
MPinTonelProject >> directory: aFileReference [

	directory := aFileReference
]

{ #category : #accessing }
MPinTonelProject >> occurrences [

	^ self baselineFiles flatCollect: [ :each |
		  self scanner scanTonelString: each contents ]
]

{ #category : #private }
MPinTonelProject >> bodyOf: aMethodSource in: aFileSource [
	"Tonel stores a method as its selector line followed by the body. The parser answers the
	source with CR line endings, so I rebuild the body with the line endings of the file."

	| lineEnding |
	lineEnding := (aFileSource includesSubstring: String crlf)
		              ifTrue: [ String crlf ]
		              ifFalse: [ String lf ].
	^ lineEnding join: aMethodSource lines allButFirst
]

{ #category : #private }
MPinTonelProject >> pin: aFile with: aPinner [

	| original source occurrences |
	original := aFile contents.
	source := original.
	occurrences := OrderedCollection new.
	(self scanner tonelMethodsIn: original) do: [ :each |
			source := self
				          pinMethod: each
				          in: source
				          with: aPinner
				          into: occurrences ].
	source = original ifFalse: [ self write: source to: aFile ].
	^ occurrences
]

{ #category : #private }
MPinTonelProject >> pinMethod: aDefinition in: aSource with: aPinner into: aCollection [

	| found pinned |
	found := self scanner
		         scanMethodSource: aDefinition source
		         owner: aDefinition className.
	aCollection addAll: found.
	pinned := aPinner pinSource: aDefinition source occurrences: found.
	pinned = aDefinition source ifTrue: [ ^ aSource ].
	^ self
		  replaceBody: (self bodyOf: aDefinition source in: aSource)
		  with: (self bodyOf: pinned in: aSource)
		  in: aSource
		  occurrences: found
]

{ #category : #pinning }
MPinTonelProject >> pinWith: aResolver [

	| pinner |
	pinner := MPinPinner resolver: aResolver.
	^ self baselineFiles flatCollect: [ :each | self pin: each with: pinner ]
]

{ #category : #private }
MPinTonelProject >> replaceBody: anOldBody with: aNewBody in: aSource occurrences: aCollection [
	"When anOldBody occurs more than once in aSource, I do not guess which one to replace. I
	leave aSource unchanged and set an error on the occurrences instead."

	| index |
	index := aSource indexOfSubCollection: anOldBody.
	(index > 0 and: [
		 (aSource indexOfSubCollection: anOldBody startingAt: index + 1) = 0 ]) ifTrue: [
		^ aSource copyReplaceFrom: index to: index + anOldBody size - 1 with: aNewBody ].
	aCollection do: [ :each |
			each resolvedSha ifNotNil: [
				each errorMessage: 'method body is not unique in the file; not rewritten' ] ].
	^ aSource
]

{ #category : #private }
MPinTonelProject >> write: aString to: aFile [
	"I write a temporary file next to aFile first and then move it over aFile, so a failed
	write never leaves a truncated baseline."

	| temporary |
	temporary := aFile parent / (aFile basename , '.metacello-pin.tmp').
	temporary ensureDelete.
	temporary writeStreamDo: [ :stream | stream nextPutAll: aString ].
	aFile ensureDelete.
	temporary moveTo: aFile
]
