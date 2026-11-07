"
I find `spec repository: ...` sends in baseline sources.

I work on a single method source, on a whole Tonel class file, or on a class loaded in the
image. For each send I answer an `MPinOccurrence` with the enclosing project name taken
from the surrounding `spec baseline: 'Name' with: [ ... ]`.
"
Class {
	#name : #MPinScanner,
	#superclass : #Object,
	#category : #'MetacelloPin-Core'
}

{ #category : #accessing }
MPinScanner class >> kinds [

	^ Dictionary new
		  at: #baseline:with: put: #baseline;
		  at: #project:with: put: #project;
		  at: #package:with: put: #package;
		  yourself
]

{ #category : #private }
MPinScanner >> assignProjectOf: aNode to: anOccurrence [

	| spec name |
	spec := self enclosingSpecOf: aNode.
	spec ifNil: [ ^ self ].
	anOccurrence kind: (self class kinds at: spec selector).
	name := spec arguments first.
	name isLiteralNode ifTrue: [ anOccurrence projectName: name value asString ]
]

{ #category : #private }
MPinScanner >> enclosingSpecOf: aNode [

	| current kinds |
	kinds := self class kinds.
	current := aNode parent.
	[
	current isNil or: [ current isMessage and: [ kinds includesKey: current selector ] ] ]
		whileFalse: [ current := current parent ].
	^ current
]

{ #category : #private }
MPinScanner >> isRepositorySend: aNode [

	^ aNode isMessage and: [ aNode selector = #repository: ]
]

{ #category : #private }
MPinScanner >> occurrenceFor: aNode owner: anOwnerName selector: aSelector [

	| argument occurrence |
	argument := aNode arguments first.
	occurrence := MPinOccurrence new
		              ownerName: anOwnerName;
		              selector: aSelector;
		              yourself.
	(argument isLiteralNode and: [ argument value isString ]) ifTrue: [
			occurrence
				reference: (MPinReference fromString: argument value);
				literalSource: argument sourceCode;
				sourceStart: argument start stop: argument stop ].
	self assignProjectOf: aNode to: occurrence.
	^ occurrence
]

{ #category : #scanning }
MPinScanner >> scanClass: aClass [

	^ aClass methods flatCollect: [ :method |
		  self scanMethodSource: method sourceCode owner: aClass name ]
]

{ #category : #scanning }
MPinScanner >> scanMethodSource: aString owner: anOwnerName [

	| ast |
	ast := [ RBParser parseMethod: aString ]
		       on: Error
		       do: [ :error | nil ].
	ast ifNil: [ ^ #(  ) ].
	^ (ast allChildren select: [ :node | self isRepositorySend: node ]) collect: [ :node |
		  self occurrenceFor: node owner: anOwnerName selector: ast selector ]
]

{ #category : #scanning }
MPinScanner >> scanTonelString: aString [

	^ (self tonelMethodsIn: aString) flatCollect: [ :each |
		  self scanMethodSource: each source owner: each className ]
]

{ #category : #scanning }
MPinScanner >> tonelMethodsIn: aString [
	"Tonel sources may come from remote repositories, so I parse them with
	MPinSafeTonelParser."

	^ (MPinSafeTonelParser parseString: aString) select: [ :each |
		  each isMethodDefinition ]
]
