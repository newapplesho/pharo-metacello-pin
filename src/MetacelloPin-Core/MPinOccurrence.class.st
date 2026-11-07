"
I am one `spec repository: ...` send found in a baseline method.

I remember where I was found, which project the repository belongs to, the exact literal
token in the source (so it can be replaced in place) and, after pinning, the commit SHA I
was resolved to or the error that prevented it.
"
Class {
	#name : #MPinOccurrence,
	#superclass : #Object,
	#instVars : [
		'reference',
		'literalSource',
		'projectName',
		'kind',
		'ownerName',
		'selector',
		'requiredBy',
		'resolvedSha',
		'refLabel',
		'errorMessage',
		'sourceStart',
		'sourceStop'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #printing }
MPinOccurrence class >> commentFor: aString [
	"Answer aString as a Smalltalk comment. Double quotes are replaced so that text coming
	from remote sources (branch or project names) cannot close the comment and inject code."

	^ '"' , (aString copyReplaceAll: '"' with: '''') , '"'
]

{ #category : #accessing }
MPinOccurrence >> errorMessage [

	^ errorMessage
]

{ #category : #accessing }
MPinOccurrence >> errorMessage: aString [

	errorMessage := aString
]

{ #category : #testing }
MPinOccurrence >> isPinnable [

	^ self unsupportedReason isNil
]

{ #category : #testing }
MPinOccurrence >> isPinned [

	^ reference notNil and: [ reference isPinned ]
]

{ #category : #accessing }
MPinOccurrence >> kind [

	^ kind
]

{ #category : #accessing }
MPinOccurrence >> kind: aSymbol [

	kind := aSymbol
]

{ #category : #accessing }
MPinOccurrence >> literalSource [

	^ literalSource
]

{ #category : #accessing }
MPinOccurrence >> literalSource: aString [

	literalSource := aString
]

{ #category : #accessing }
MPinOccurrence >> location [

	^ ownerName asString , '>>' , selector asString
]

{ #category : #testing }
MPinOccurrence >> needsPin [

	^ self isPinnable and: [ self isPinned not ]
]

{ #category : #accessing }
MPinOccurrence >> note [

	errorMessage ifNotNil: [ ^ errorMessage ].
	self unsupportedReason ifNotNil: [ :reason | ^ reason ].
	resolvedSha ifNotNil: [ ^ refLabel , ' -> ' , resolvedSha ].
	^ ''
]

{ #category : #accessing }
MPinOccurrence >> ownerName: aString [

	ownerName := aString
]

{ #category : #accessing }
MPinOccurrence >> pinnedLiteral [

	^ (reference pinnedTo: resolvedSha) printString , ' '
	  , (self class commentFor: refLabel)
]

{ #category : #printing }
MPinOccurrence >> printOn: aStream [

	aStream
		nextPutAll: '[';
		nextPutAll: self statusString;
		nextPutAll: '] ';
		nextPutAll: self location;
		space;
		nextPutAll: (projectName ifNil: [ '-' ]);
		space;
		nextPutAll: (reference ifNil: [ literalSource ] ifNotNil: [ :r | r url ])
]

{ #category : #accessing }
MPinOccurrence >> projectName [

	^ projectName
]

{ #category : #accessing }
MPinOccurrence >> projectName: aString [

	projectName := aString
]

{ #category : #accessing }
MPinOccurrence >> refLabel [

	^ refLabel
]

{ #category : #accessing }
MPinOccurrence >> refLabel: aString [

	refLabel := aString
]

{ #category : #accessing }
MPinOccurrence >> reference [

	^ reference
]

{ #category : #accessing }
MPinOccurrence >> reference: aReference [

	reference := aReference
]

{ #category : #accessing }
MPinOccurrence >> requiredBy [

	^ requiredBy
]

{ #category : #accessing }
MPinOccurrence >> requiredBy: aString [

	requiredBy := aString
]

{ #category : #accessing }
MPinOccurrence >> resolvedSha [

	^ resolvedSha
]

{ #category : #accessing }
MPinOccurrence >> resolvedSha: aString [

	resolvedSha := aString
]

{ #category : #accessing }
MPinOccurrence >> selector: aSymbol [

	selector := aSymbol
]

{ #category : #accessing }
MPinOccurrence >> sourceStart [

	^ sourceStart
]

{ #category : #accessing }
MPinOccurrence >> sourceStart: aStart stop: aStop [

	sourceStart := aStart.
	sourceStop := aStop
]

{ #category : #accessing }
MPinOccurrence >> sourceStop [

	^ sourceStop
]

{ #category : #accessing }
MPinOccurrence >> statusString [

	errorMessage ifNotNil: [ ^ 'error' ].
	resolvedSha ifNotNil: [ ^ 'pinned now' ].
	self isPinnable ifFalse: [ ^ 'unsupported' ].
	^ self isPinned
		  ifTrue: [ 'pinned' ]
		  ifFalse: [ 'unpinned' ]
]

{ #category : #accessing }
MPinOccurrence >> unsupportedReason [

	reference ifNil: [ ^ 'repository is not a string literal' ].
	reference isGitHub ifFalse: [ ^ 'repository scheme not supported: ' , reference url ].
	reference isWellFormed ifFalse: [ ^ 'malformed repository description' ].
	kind = #baseline ifFalse: [ ^ 'only spec baseline:with: is supported' ].
	(projectName notNil and: [
		 projectName allSatisfy: [ :each | MPinReference isAsciiAlphaNumeric: each ] ])
		ifFalse: [ ^ 'baseline name must be alphanumeric' ].
	^ nil
]
