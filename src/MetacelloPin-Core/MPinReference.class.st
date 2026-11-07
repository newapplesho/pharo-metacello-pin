"
I represent a parsed Metacello repository description, for example
`github://owner/project:ref/path`.

I know whether I am pinned, which means that my ref is a full 40-character hexadecimal
commit SHA. I can also answer a copy of my description with a commit SHA as the ref.
"
Class {
	#name : #MPinReference,
	#superclass : #Object,
	#instVars : [
		'url',
		'scheme',
		'owner',
		'project',
		'ref',
		'path'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #'instance creation' }
MPinReference class >> fromString: aString [

	^ self new
		  parse: aString;
		  yourself
]

{ #category : #testing }
MPinReference class >> isCommitSha: aString [

	^ aString size = 40 and: [
		  aString allSatisfy: [ :each | '0123456789abcdef' includes: each asLowercase ] ]
]

{ #category : #accessing }
MPinReference >> baselineFilePathFor: aProjectName [

	| baselineName |
	baselineName := 'BaselineOf' , aProjectName.
	^ String streamContents: [ :stream |
			  path ifNotEmpty: [
					  stream
						  nextPutAll: path;
						  nextPut: $/ ].
			  stream
				  nextPutAll: baselineName;
				  nextPut: $/;
				  nextPutAll: baselineName;
				  nextPutAll: '.class.st' ]
]

{ #category : #testing }
MPinReference >> hasRef [

	^ ref isEmptyOrNil not
]

{ #category : #testing }
MPinReference class >> isAsciiAlphaNumeric: aCharacter [
	"Answer whether aCharacter is an ASCII letter or digit. isAlphaNumeric alone also accepts
	letters outside ASCII, such as an accented e."

	^ aCharacter asInteger < 128 and: [ aCharacter isAlphaNumeric ]
]

{ #category : #testing }
MPinReference class >> isSafeName: aString [
	"Owner, project and ref names become part of the API and raw URLs, so I allow only ASCII
	letters, ASCII digits, '.', '_' and '-', and never '..'."

	^ aString isEmptyOrNil not and: [
			  (aString includesSubstring: '..') not and: [
					  aString allSatisfy: [ :each |
						  (self isAsciiAlphaNumeric: each) or: [ '._-' includes: each ] ] ] ]
]

{ #category : #testing }
MPinReference class >> isSafePath: aString [

	^ aString isEmpty or: [
		  (aString substrings: '/') allSatisfy: [ :each | self isSafeName: each ] ]
]

{ #category : #testing }
MPinReference >> isGitHub [

	^ scheme = 'github'
]

{ #category : #testing }
MPinReference >> isWellFormed [

	scheme ifNil: [ ^ false ].
	^ (self class isSafeName: owner) and: [
			  (self class isSafeName: project) and: [
					  (self hasRef not or: [ self class isSafeName: ref ]) and: [
						  self class isSafePath: path ] ] ]
]

{ #category : #testing }
MPinReference >> isPinned [

	^ self hasRef and: [ self class isCommitSha: ref ]
]

{ #category : #accessing }
MPinReference >> owner [

	^ owner
]

{ #category : #private }
MPinReference >> parse: aString [

	| rest |
	url := aString.
	(aString includesSubstring: '://') ifFalse: [ ^ self ].
	scheme := aString copyUpToSubstring: '://'.
	rest := aString allButFirst: scheme size + 3.
	owner := rest copyUpTo: $/.
	rest := rest copyAfter: $/.
	self parseProjectAndRef: (rest copyUpTo: $/).
	path := rest copyAfter: $/
]

{ #category : #private }
MPinReference >> parseProjectAndRef: aString [

	project := aString copyUpTo: $:.
	(aString includes: $:) ifTrue: [ ref := aString copyAfter: $: ]
]

{ #category : #accessing }
MPinReference >> path [

	^ path
]

{ #category : #converting }
MPinReference >> pinnedTo: aSha [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: scheme;
				  nextPutAll: '://';
				  nextPutAll: self projectKey;
				  nextPut: $:;
				  nextPutAll: aSha.
			  path ifNotEmpty: [
					  stream
						  nextPut: $/;
						  nextPutAll: path ] ]
]

{ #category : #printing }
MPinReference >> printOn: aStream [

	aStream nextPutAll: url
]

{ #category : #accessing }
MPinReference >> project [

	^ project
]

{ #category : #accessing }
MPinReference >> projectKey [

	^ owner , '/' , project
]

{ #category : #accessing }
MPinReference >> ref [

	^ ref
]

{ #category : #accessing }
MPinReference >> refOrHead [

	^ self hasRef
		  ifTrue: [ ref ]
		  ifFalse: [ 'HEAD' ]
]

{ #category : #accessing }
MPinReference >> scheme [

	^ scheme
]

{ #category : #accessing }
MPinReference >> url [

	^ url
]
