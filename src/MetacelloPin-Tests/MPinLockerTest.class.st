"
I test `MPinLocker` and `MPinLockfile`: following dependencies of dependencies, conflicts,
the load order, the generated script and writing it to a file. `MPinStubResolver` answers
in place of GitHub.
"
Class {
	#name : #MPinLockerTest,
	#superclass : #TestCase,
	#instVars : [
		'resolver'
	],
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinLockerTest >> lock [

	| occurrences |
	occurrences := MPinScanner new
		               scanMethodSource: MPinTestFixtures baselineBody
		               owner: #BaselineOfSample.
	^ (MPinLocker resolver: resolver) lock: occurrences
]

{ #category : #'tests-locking' }
MPinLockerTest >> testWriteToReplacesFileWithoutLeavingTemporaryFile [

	| root file |
	root := FileSystem memory root.
	file := root / 'metacello.lock.st'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'old' ].
	self lock writeTo: file.
	self assert: file contents equals: self lock script.
	self assert: root children size equals: 1
]

{ #category : #running }
MPinLockerTest >> awsBaseline [

	^ MPinTestFixtures tonelClassNamed: 'BaselineOfAWS' body: 'baseline: spec [
	spec baseline: ''GoogleCloud'' with: [
		spec repository: ''github://newapplesho/google-cloud-smalltalk:v0.0.8/src'' ].
	spec baseline: ''NeoYAML'' with: [
		spec repository: ''github://newapplesho/NeoYAML:main/src'' ]'
]

{ #category : #running }
MPinLockerTest >> setUp [

	super setUp.
	resolver := MPinTestFixtures stubResolver
		            at: 'newapplesho/google-cloud-smalltalk@v0.0.8'
		            sha: MPinTestFixtures shaC;
		            at: 'newapplesho/NeoYAML@main' sha: MPinTestFixtures shaA;
		            baselineNamed: 'AWS' source: self awsBaseline;
		            yourself
]

{ #category : #'tests-locking' }
MPinLockerTest >> testConflictKeepsFirstAndWarns [

	| lockfile |
	lockfile := self lock.
	self assert: (lockfile entryNamed: 'NeoYAML') sha equals: MPinTestFixtures shaB.
	self assert: (lockfile warnings anySatisfy: [ :each |
			 (each beginsWith: 'conflict: NeoYAML') and: [ each includesSubstring: 'AWS' ] ])
]

{ #category : #'tests-locking' }
MPinLockerTest >> testLocksTransitiveDependencies [

	| lockfile entry |
	lockfile := self lock.
	self
		assert: (lockfile entries collect: [ :each | each name ]) asArray
		equals: #( 'GoogleCloud' 'NeoYAML' 'AWS' 'DuckDB' ).
	entry := lockfile entryNamed: 'GoogleCloud'.
	self assert: entry requiredBy equals: 'AWS'.
	self
		assert: entry pinnedUrl
		equals:
		'github://newapplesho/google-cloud-smalltalk:' , MPinTestFixtures shaC , '/src'
]

{ #category : #'tests-locking' }
MPinLockerTest >> testScriptLocksEveryEntry [

	| script |
	script := self lock script.
	self assert: (script occurrencesOf: $.) >= 4.
	self assert: (script includesSubstring: 'baseline: ''GoogleCloud'';').
	self assert: (script includesSubstring: '"v0.0.8, required by AWS";').
	self assert: (script lines count: [ :each | each = '	lock.' ]) equals: 4.
	self assert: (script lines count: [ :each | each = '	load.' ]) equals: 4.
	self
		assert: (script lines indexOf: '	load.')
			> (script lines findLast: [ :each | each = '	lock.' ])
		description: 'every lock comes before the first load'
]

{ #category : #'tests-locking' }
MPinLockerTest >> testScriptIsValidSmalltalk [

	self shouldnt: [ RBParser parseExpression: self lock script ] raise: Error
]

{ #category : #'tests-locking' }
MPinLockerTest >> testWarnsAboutUnreadableAndUnsupported [

	| warnings |
	warnings := self lock warnings.
	self assert:
		(warnings anySatisfy: [ :each | each includesSubstring: 'BaselineOfNeoYAML' ]).
	self assert:
		(warnings anySatisfy: [ :each | each beginsWith: 'not locked: BaselineOfSample' ])
]
