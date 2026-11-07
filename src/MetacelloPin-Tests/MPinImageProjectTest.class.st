"
I test `MPinImageProject` on an anonymous `BaselineOf` subclass, so that pinning never
changes a real class in the image.
"
Class {
	#name : #MPinImageProjectTest,
	#superclass : #TestCase,
	#instVars : [
		'baselineClass'
	],
	#category : #'MetacelloPin-Tests'
}

{ #category : #running }
MPinImageProjectTest >> setUp [

	super setUp.
	baselineClass := BaselineOf newAnonymousSubclass.
	baselineClass compile: MPinTestFixtures baselineBody classified: 'baselines'
]

{ #category : #'tests-image' }
MPinImageProjectTest >> testPinRecompilesMethod [

	(MPinImageProject on: baselineClass) pinWith: MPinTestFixtures stubResolver.
	self assert: ((baselineClass >> #baseline:) sourceCode includesSubstring:
			 MPinTestFixtures shaB , '/src'' "v0.1.5"').
	self assert: (baselineClass >> #baseline:) protocolName equals: 'baselines'
]

{ #category : #'tests-image' }
MPinImageProjectTest >> testOccurrences [

	self assert: (MPinImageProject on: baselineClass) occurrences size equals: 4
]
