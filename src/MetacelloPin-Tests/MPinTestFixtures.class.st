"
I hold the shared fixtures (SHAs and baseline sources) used by the MetacelloPin tests.
"
Class {
	#name : #MPinTestFixtures,
	#superclass : #Object,
	#category : #'MetacelloPin-Tests'
}

{ #category : #fixtures }
MPinTestFixtures class >> baselineBody [

	^ 'baseline: spec
	<baseline>
	spec for: #common do: [
		spec baseline: ''AWS'' with: [
			spec repository: ''github://newapplesho/aws-sdk-smalltalk/src'' ].
		spec baseline: ''NeoYAML'' with: [
			spec repository: ''github://newapplesho/NeoYAML:v0.1.5/src'' ].
		spec baseline: ''DuckDB'' with: [
			spec repository: ''github://newapplesho/duckdb-smalltalk:' , self shaC
	  , '/src'' ].
		spec package: ''Twilio-Core'' with: [
			spec repository: ''gitlab://newapplesho/twilio-smalltalk:main/src'' ].
		spec package: ''Sample-Core'' ]'
]

{ #category : #fixtures }
MPinTestFixtures class >> shaA [

	^ 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
]

{ #category : #fixtures }
MPinTestFixtures class >> shaB [

	^ 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
]

{ #category : #fixtures }
MPinTestFixtures class >> shaC [

	^ 'cccccccccccccccccccccccccccccccccccccccc'
]

{ #category : #fixtures }
MPinTestFixtures class >> stubResolver [

	^ MPinStubResolver new
		  at: 'newapplesho/aws-sdk-smalltalk@HEAD' sha: self shaA;
		  at: 'newapplesho/NeoYAML@v0.1.5' sha: self shaB;
		  yourself
]

{ #category : #fixtures }
MPinTestFixtures class >> tonelClassNamed: aClassName body: aMethodSource [

	^ 'Class {
	#name : #' , aClassName , ',
	#superclass : #BaselineOf,
	#category : #' , aClassName , '
}

{ #category : #baselines }
' , aClassName , ' >> ' , aMethodSource , '
]
'
]

{ #category : #fixtures }
MPinTestFixtures class >> tonelSample [

	| lines |
	lines := self baselineBody lines.
	^ self
		  tonelClassNamed: 'BaselineOfSample'
		  body: lines first , ' [' , String lf , (String lf join: lines allButFirst)
]
