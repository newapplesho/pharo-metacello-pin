"
I rewrite baseline sources so that every unpinned GitHub baseline reference points to a
commit SHA, keeping the original ref as a trailing comment:

```
spec repository: 'github://owner/project:<sha>/src' ""v1.2.0""
```

I replace only the string literal, by its position in the parsed method, so the rest of
the source (including identical text in comments) is left untouched.
"
Class {
	#name : #MPinPinner,
	#superclass : #Object,
	#instVars : [
		'resolver'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #'instance creation' }
MPinPinner class >> resolver: aResolver [

	^ self new
		  resolver: aResolver;
		  yourself
]

{ #category : #pinning }
MPinPinner >> pin: anOccurrence in: aSource [

	self resolve: anOccurrence.
	anOccurrence resolvedSha ifNil: [ ^ aSource ].
	^ aSource
		  copyReplaceFrom: anOccurrence sourceStart
		  to: anOccurrence sourceStop
		  with: anOccurrence pinnedLiteral
]

{ #category : #pinning }
MPinPinner >> pinSource: aSource occurrences: aCollection [
	"I rewrite from the end of the source to the start, so the positions of the earlier
	literals stay valid."

	| pending |
	pending := (aCollection select: [ :each | each needsPin ]) sorted: [ :a :b |
		           a sourceStart > b sourceStart ].
	^ pending inject: aSource into: [ :source :each | self pin: each in: source ]
]

{ #category : #private }
MPinPinner >> resolve: anOccurrence [

	[
		anOccurrence refLabel: (resolver refLabelFor: anOccurrence reference).
		anOccurrence resolvedSha: (resolver resolve: anOccurrence reference) ]
		on: Error
		do: [ :error | anOccurrence errorMessage: error messageText ]
]

{ #category : #accessing }
MPinPinner >> resolver: aResolver [

	resolver := aResolver
]
