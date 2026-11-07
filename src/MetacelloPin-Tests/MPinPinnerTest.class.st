"
I test `MPinPinner`: which references it pins, the comments it adds, and that pinning a
second time changes nothing.
"
Class {
	#name : #MPinPinnerTest,
	#superclass : #TestCase,
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinPinnerTest >> pin: aSource with: aResolver [

	| occurrences |
	occurrences := MPinScanner new scanMethodSource: aSource owner: #BaselineOfSample.
	^ (MPinPinner resolver: aResolver) pinSource: aSource occurrences: occurrences
]

{ #category : #'tests-pinning' }
MPinPinnerTest >> testKeepsUnsupportedAndPinnedReferences [

	| pinned |
	pinned := self
		          pin: MPinTestFixtures baselineBody
		          with: MPinTestFixtures stubResolver.
	self assert:
		(pinned includesSubstring: '''gitlab://newapplesho/twilio-smalltalk:main/src''').
	self assert: (pinned includesSubstring:
			 '''github://newapplesho/duckdb-smalltalk:' , MPinTestFixtures shaC , '/src'' ]')
]

{ #category : #'tests-pinning' }
MPinPinnerTest >> testPinIsIdempotent [

	| once twice |
	once := self pin: MPinTestFixtures baselineBody with: MPinTestFixtures stubResolver.
	twice := self pin: once with: MPinStubResolver new.
	self assert: twice equals: once
]

{ #category : #'tests-pinning' }
MPinPinnerTest >> testPinsBranchlessReferenceWithDefaultBranchComment [

	| pinned |
	pinned := self
		          pin: MPinTestFixtures baselineBody
		          with: MPinTestFixtures stubResolver.
	self assert: (pinned includesSubstring:
			 '''github://newapplesho/aws-sdk-smalltalk:' , MPinTestFixtures shaA
			 , '/src'' "main"')
]

{ #category : #'tests-pinning' }
MPinPinnerTest >> testPinsTagReferenceWithTagComment [

	| pinned |
	pinned := self
		          pin: MPinTestFixtures baselineBody
		          with: MPinTestFixtures stubResolver.
	self assert: (pinned includesSubstring:
			 '''github://newapplesho/NeoYAML:' , MPinTestFixtures shaB , '/src'' "v0.1.5"')
]

{ #category : #'tests-pinning' }
MPinPinnerTest >> testUnresolvableReferenceIsReported [

	| source occurrences pinned |
	source := MPinTestFixtures baselineBody.
	occurrences := MPinScanner new scanMethodSource: source owner: #BaselineOfSample.
	pinned := (MPinPinner resolver: MPinStubResolver new)
		          pinSource: source
		          occurrences: occurrences.
	self assert: pinned equals: source.
	self assert: occurrences first statusString equals: 'error'.
	self assert: (occurrences first errorMessage includesSubstring: 'unknown ref')
]
