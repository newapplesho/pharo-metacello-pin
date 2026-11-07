"
I test `MPinGitHubResolver` offline against local Zinc servers standing in for
api.github.com and raw.githubusercontent.com.
"
Class {
	#name : #MPinGitHubResolverTest,
	#superclass : #TestCase,
	#instVars : [
		'servers',
		'requests'
	],
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinGitHubResolverTest >> reference [

	^ MPinReference fromString: 'github://newapplesho/NeoYAML:v0.1.5/src'
]

{ #category : #running }
MPinGitHubResolverTest >> resolverAnswering: aBlock [

	^ MPinGitHubResolver new
		  token: 'SECRET';
		  apiUrl: (self serverAnswering: aBlock) rawUrl: (self serverAnswering: aBlock);
		  yourself
]

{ #category : #running }
MPinGitHubResolverTest >> serverAnswering: aBlock [

	| server |
	server := (ZnServer on: 0)
		          delegate: (ZnValueDelegate with: [ :request |
						           requests add: request.
						           aBlock value: request ]);
		          start;
		          yourself.
	servers add: server.
	^ 'http://127.0.0.1:' , server serverSocket port printString
]

{ #category : #running }
MPinGitHubResolverTest >> setUp [

	super setUp.
	servers := OrderedCollection new.
	requests := OrderedCollection new
]

{ #category : #running }
MPinGitHubResolverTest >> tearDown [

	servers do: [ :each | each stop ].
	super tearDown
]

{ #category : #'tests-api' }
MPinGitHubResolverTest >> testDoesNotFollowRedirects [

	| elsewhere resolver |
	elsewhere := self serverAnswering: [ :request | ZnResponse ok: (ZnEntity text: 'x') ].
	resolver := self resolverAnswering: [ :request |
		            ZnResponse redirect: elsewhere , '/leak' ].
	self should: [ resolver resolve: self reference ] raise: MPinError.
	self deny: (requests anySatisfy: [ :each | each url path = 'leak' ])
]

{ #category : #'tests-raw' }
MPinGitHubResolverTest >> testFetchMissingBaselineAnswersNil [

	| resolver |
	resolver := self resolverAnswering: [ :request | ZnResponse notFound: request url ].
	self assert:
		(resolver fetch: self reference baselineNamed: 'NeoYAML' at: 'abc') isNil
]

{ #category : #'tests-raw' }
MPinGitHubResolverTest >> testFetchReadsBaselineWithoutToken [

	| resolver |
	resolver := self resolverAnswering: [ :request |
		            ZnResponse ok: (ZnEntity text: 'source') ].
	self
		assert: (resolver fetch: self reference baselineNamed: 'NeoYAML' at: 'abc')
		equals: 'source'.
	self
		assert: requests last url pathPrintString
		equals: '/newapplesho/NeoYAML/abc/src/BaselineOfNeoYAML/BaselineOfNeoYAML.class.st'.
	self deny: (requests last headers includesKey: 'Authorization')
]

{ #category : #'tests-api' }
MPinGitHubResolverTest >> testResolveSendsTokenAndAsksForSha [

	| resolver |
	resolver := self resolverAnswering: [ :request |
		            ZnResponse ok: (ZnEntity text: MPinTestFixtures shaB , String lf) ].
	self assert: (resolver resolve: self reference) equals: MPinTestFixtures shaB.
	self
		assert: requests last url pathPrintString
		equals: '/repos/newapplesho/NeoYAML/commits/v0.1.5'.
	self assert: (requests last headers at: 'Authorization') equals: 'Bearer SECRET'.
	self
		assert: (requests last headers at: 'Accept')
		equals: 'application/vnd.github.sha'
]

{ #category : #'tests-api' }
MPinGitHubResolverTest >> testUnsuccessfulAnswerSignalsError [

	| resolver |
	resolver := self resolverAnswering: [ :request | ZnResponse notFound: request url ].
	self should: [ resolver resolve: self reference ] raise: MPinError
]
