"
I test how `MPinReference` splits a repository description into its parts, and which
descriptions it accepts.
"
Class {
	#name : #MPinReferenceTest,
	#superclass : #TestCase,
	#category : #'MetacelloPin-Tests'
}

{ #category : #'tests-parsing' }
MPinReferenceTest >> testBaselineFilePath [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/aws-sdk-smalltalk/src'.
	self
		assert: (reference baselineFilePathFor: 'AWS')
		equals: 'src/BaselineOfAWS/BaselineOfAWS.class.st'
]

{ #category : #'tests-parsing' }
MPinReferenceTest >> testBaselineFilePathWithoutPath [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/twilio-smalltalk:main'.
	self
		assert: (reference baselineFilePathFor: 'Twilio')
		equals: 'BaselineOfTwilio/BaselineOfTwilio.class.st'
]

{ #category : #'tests-parsing' }
MPinReferenceTest >> testIsPinned [

	| sha |
	sha := MPinTestFixtures shaA.
	self assert:
		(MPinReference fromString: 'github://newapplesho/NeoYAML:' , sha , '/src') isPinned.
	self deny:
		(MPinReference fromString: 'github://newapplesho/NeoYAML:main/src') isPinned.
	self deny: (MPinReference fromString: 'github://newapplesho/NeoYAML/src') isPinned.
	self deny:
		(MPinReference fromString: 'github://newapplesho/NeoYAML:abc1234/src') isPinned
]

{ #category : #'tests-parsing' }
MPinReferenceTest >> testNonGitHubScheme [

	| reference |
	reference := MPinReference fromString:
		             'gitlab://newapplesho/twilio-smalltalk:main/src'.
	self deny: reference isGitHub.
	reference := MPinReference fromString: 'tonel:///tmp/src'.
	self deny: reference isGitHub
]

{ #category : #'tests-parsing' }
MPinReferenceTest >> testParseWithRefAndPath [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/NeoYAML:v0.1.5/src'.
	self assert: reference isGitHub.
	self assert: reference owner equals: 'newapplesho'.
	self assert: reference project equals: 'NeoYAML'.
	self assert: reference ref equals: 'v0.1.5'.
	self assert: reference path equals: 'src'
]

{ #category : #'tests-parsing' }
MPinReferenceTest >> testParseWithoutRef [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/aws-sdk-smalltalk/src'.
	self deny: reference hasRef.
	self assert: reference refOrHead equals: 'HEAD'.
	self assert: reference path equals: 'src'
]

{ #category : #'tests-converting' }
MPinReferenceTest >> testPinnedTo [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/NeoYAML:v0.1.5/src'.
	self
		assert: (reference pinnedTo: MPinTestFixtures shaB)
		equals: 'github://newapplesho/NeoYAML:' , MPinTestFixtures shaB , '/src'
]

{ #category : #'tests-converting' }
MPinReferenceTest >> testPinnedToWithoutPath [

	| reference |
	reference := MPinReference fromString: 'github://newapplesho/twilio-smalltalk'.
	self
		assert: (reference pinnedTo: MPinTestFixtures shaA)
		equals: 'github://newapplesho/twilio-smalltalk:' , MPinTestFixtures shaA
]
