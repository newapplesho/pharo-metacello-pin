"
I check that input coming from remote repositories (GitHub API answers, remote baseline
sources, branch and project names) cannot inject code into rewritten baselines or lock
scripts, create instances of classes while parsing, or change where requests are sent.
"
Class {
	#name : #MPinSecurityTest,
	#superclass : #TestCase,
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinSecurityTest >> assertNoInjectedSendIn: anAST [

	self deny: (anAST allChildren anySatisfy: [ :node |
			 node isMessage and: [ #( #beep #runCommand: ) includes: node selector ] ])
]

{ #category : #running }
MPinSecurityTest >> occurrencesIn: aSource [

	^ MPinScanner new scanMethodSource: aSource owner: #BaselineOfSample
]

{ #category : #running }
MPinSecurityTest >> pin: aSource with: aResolver [

	^ (MPinPinner resolver: aResolver)
		  pinSource: aSource
		  occurrences: (self occurrencesIn: aSource)
]

{ #category : #'tests-injection' }
MPinSecurityTest >> testDefaultBranchCannotCloseComment [

	| resolver pinned |
	resolver := MPinTestFixtures stubResolver
		            defaultBranch: 'main" Smalltalk os runCommand: ''x'' "';
		            yourself.
	pinned := self pin: MPinTestFixtures baselineBody with: resolver.
	self assertNoInjectedSendIn: (RBParser parseMethod: pinned).
	self deny: (pinned includesSubstring: 'main" Smalltalk')
]

{ #category : #'tests-injection' }
MPinSecurityTest >> testLockScriptSanitizesRemoteNames [

	| entry script |
	entry := MPinLockEntry new
		         name: 'AWS';
		         reference:
			         (MPinReference fromString: 'github://newapplesho/aws-sdk-smalltalk/src');
		         sha: MPinTestFixtures shaA;
		         refLabel: 'main';
		         requiredBy: 'Evil" Smalltalk beep "';
		         yourself.
	script := String streamContents: [ :stream | entry print: #lock on: stream ].
	self assertNoInjectedSendIn: (RBParser parseExpression: script)
]

{ #category : #'tests-injection' }
MPinSecurityTest >> testNonShaAnswerIsRejected [

	| resolver occurrences |
	resolver := MPinStubResolver new
		            at: 'newapplesho/aws-sdk-smalltalk@HEAD'
		            sha: 'x'' , Smalltalk beep , ''';
		            yourself.
	occurrences := self occurrencesIn: MPinTestFixtures baselineBody.
	(MPinPinner resolver: resolver)
		pinSource: MPinTestFixtures baselineBody
		occurrences: occurrences.
	self assert: occurrences first statusString equals: 'error'.
	self assert: (occurrences first errorMessage includesSubstring: 'not a commit SHA')
]

{ #category : #'tests-parsing' }
MPinSecurityTest >> testRemoteMetadataCannotInstantiateClasses [

	| source |
	source := MPinTestFixtures tonelSample
		          copyReplaceAll: '#category : #BaselineOfSample'
		          with: '#category : Point [ 1, 2 ]'.
	self should: [ MPinScanner new scanTonelString: source ] raise: Error
]

{ #category : #'tests-parsing' }
MPinSecurityTest >> testNonAsciiBaselineNameIsUnsupported [

	| occurrences |
	occurrences := self occurrencesIn: 'baseline: spec
	spec baseline: ''Caf' , (String with: (Character value: 233)) , ''' with: [
		spec repository: ''github://newapplesho/NeoYAML:main/src'' ]'.
	self
		assert: occurrences first unsupportedReason
		equals: 'baseline name must be alphanumeric'
]

{ #category : #'tests-parsing' }
MPinSecurityTest >> testNonAsciiReferencesAreUnsupported [

	| accent |
	accent := String with: (Character value: 233).
	{
		('github://caf' , accent , '/NeoYAML:main/src').
		('github://newapplesho/NeoYAML:v' , accent , '/src') } do: [ :each |
		self deny: (MPinReference fromString: each) isWellFormed description: each ].
	self deny: (MPinReference isAsciiAlphaNumeric: (Character value: 1633)).
	self assert:
		(MPinReference fromString: 'github://new-apple_sho/Neo.YAML:v1.0/src') isWellFormed
]

{ #category : #'tests-parsing' }
MPinSecurityTest >> testUnsafeReferencesAreUnsupported [

	#( 'github://newapplesho/NeoYAML:../../../user/src'
	   'github://newapplesho/NeoYAML:a"b/src' 'github://newapplesho/Neo?YAML:main/src'
	   'github://newapplesho/NeoYAML:main/../x' 'github://newapplesho' ) do: [ :each |
		self deny: (MPinReference fromString: each) isWellFormed description: each ]
]

{ #category : #'tests-parsing' }
MPinSecurityTest >> testUnsafeBaselineNameIsUnsupported [

	| occurrences |
	occurrences := self occurrencesIn: 'baseline: spec
	spec baseline: ''../../x'' with: [
		spec repository: ''github://newapplesho/NeoYAML:main/src'' ]'.
	self
		assert: occurrences first unsupportedReason
		equals: 'baseline name must be alphanumeric'
]

{ #category : #'tests-locking' }
MPinSecurityTest >> testLockStopsAtMaxEntries [

	| lockfile |
	lockfile := (MPinLocker resolver: MPinTestFixtures stubResolver)
		            maxEntries: 1;
		            lock: (self occurrencesIn: MPinTestFixtures baselineBody).
	self assert: lockfile entries size equals: 1.
	self assert:
		(lockfile warnings anySatisfy: [ :each | each beginsWith: 'stopped after 1' ])
]
