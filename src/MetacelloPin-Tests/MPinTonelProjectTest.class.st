"
I test `MPinTonelProject` on Tonel files in an in-memory file system: which strings `pin`
rewrites, and that the file is still valid Tonel afterwards.
"
Class {
	#name : #MPinTonelProjectTest,
	#superclass : #TestCase,
	#instVars : [
		'root',
		'file'
	],
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinTonelProjectTest >> project [

	^ MPinTonelProject on: root
]

{ #category : #running }
MPinTonelProjectTest >> setUp [

	super setUp.
	root := FileSystem memory / 'src'.
	(root / 'BaselineOfSample') ensureCreateDirectory.
	file := root / 'BaselineOfSample' / 'BaselineOfSample.class.st'.
	file writeStreamDo: [ :stream | stream nextPutAll: MPinTestFixtures tonelSample ]
]

{ #category : #'tests-files' }
MPinTonelProjectTest >> testOccurrences [

	self assert: self project occurrences size equals: 4
]

{ #category : #'tests-files' }
MPinTonelProjectTest >> testPinRewritesOnlyLiterals [

	| before after |
	before := file contents.
	self project pinWith: MPinTestFixtures stubResolver.
	after := file contents.
	self assert: after lines size equals: before lines size.
	self assert: (after includesSubstring: MPinTestFixtures shaA , '/src'' "main"').
	self assert: (self project occurrences count: [ :each | each needsPin ]) equals: 0
]

{ #category : #'tests-files' }
MPinTonelProjectTest >> testPinnedFileIsStillValidTonel [

	self project pinWith: MPinTestFixtures stubResolver.
	self assert: (MPinScanner new scanTonelString: file contents) size equals: 4
]

{ #category : #'tests-files' }
MPinTonelProjectTest >> testSameUrlInClassCommentIsNotRewritten [

	| comment |
	comment := '"
I load ''github://newapplesho/aws-sdk-smalltalk/src'' by default.
"
'.
	file ensureDelete.
	file writeStreamDo: [ :stream |
		stream nextPutAll: comment , MPinTestFixtures tonelSample ].
	self project pinWith: MPinTestFixtures stubResolver.
	self assert: (file contents beginsWith: comment).
	self assert: (MPinScanner new scanTonelString: file contents) size equals: 4.
	self assert: (self project occurrences count: [ :each | each needsPin ]) equals: 0
]

{ #category : #'tests-files' }
MPinTonelProjectTest >> testNoTemporaryFileIsLeft [

	self project pinWith: MPinTestFixtures stubResolver.
	self assert: (root / 'BaselineOfSample') children size equals: 1
]
