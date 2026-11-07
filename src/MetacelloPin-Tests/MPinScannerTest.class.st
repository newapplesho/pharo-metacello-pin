"
I test how `MPinScanner` finds the `repository:` sends in a baseline method, and what it
records for each of them.
"
Class {
	#name : #MPinScannerTest,
	#superclass : #TestCase,
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinScannerTest >> occurrences [

	^ MPinScanner new
		  scanMethodSource: MPinTestFixtures baselineBody
		  owner: #BaselineOfSample
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testFindsEveryRepositorySend [

	self
		assert: (self occurrences collect: [ :each | each projectName ]) asArray
		equals: #( 'AWS' 'NeoYAML' 'DuckDB' 'Twilio-Core' )
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testKindsAndStatus [

	| occurrences |
	occurrences := self occurrences.
	self
		assert: (occurrences collect: [ :each | each statusString ]) asArray
		equals: #( 'unpinned' 'unpinned' 'pinned' 'unsupported' ).
	self assert: occurrences last kind equals: #package
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testLiteralSourceKeepsQuotes [

	self
		assert: self occurrences first literalSource
		equals: '''github://newapplesho/aws-sdk-smalltalk/src'''
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testLocation [

	self assert: self occurrences first location equals: 'BaselineOfSample>>baseline:'
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testNonLiteralRepository [

	| occurrences |
	occurrences := MPinScanner new
		               scanMethodSource: 'baseline: spec
	spec baseline: ''Foo'' with: [ spec repository: self fooRepository ]'
		               owner: #BaselineOfSample.
	self assert: occurrences size equals: 1.
	self assert: occurrences first statusString equals: 'unsupported'.
	self assert: occurrences first projectName equals: 'Foo'
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testScanTonelString [

	| occurrences |
	occurrences := MPinScanner new scanTonelString: MPinTestFixtures tonelSample.
	self assert: occurrences size equals: 4.
	self assert: occurrences first location equals: 'BaselineOfSample>>baseline:'
]

{ #category : #'tests-scanning' }
MPinScannerTest >> testUnparsableSourceAnswersEmpty [

	self assert: (MPinScanner new scanMethodSource: 'foo [ ' owner: #Foo) isEmpty
]
