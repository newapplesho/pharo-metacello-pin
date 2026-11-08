"
I am an offline resolver for tests. I answer SHAs and remote baseline sources from
dictionaries filled by the test.
"
Class {
	#name : #MPinStubResolver,
	#superclass : #MPinResolver,
	#instVars : [
		'shas',
		'sources',
		'defaultBranch'
	],
	#category : #'MetacelloPin-Tests'
}

{ #category : #accessing }
MPinStubResolver >> at: aKey sha: aSha [
	"Make me answer aSha for the reference aKey, which has the form 'owner/project@ref'."

	shas at: aKey put: aSha
]

{ #category : #accessing }
MPinStubResolver >> baselineNamed: aProjectName source: aString [

	sources at: aProjectName put: aString
]

{ #category : #resolving }
MPinStubResolver >> defaultBranch: aString [

	defaultBranch := aString
]

{ #category : #resolving }
MPinStubResolver >> defaultBranchOf: aReference [

	^ defaultBranch
]

{ #category : #resolving }
MPinStubResolver >> fetch: aReference baselineNamed: aProjectName at: aSha [

	^ sources at: aProjectName ifAbsent: [ nil ]
]

{ #category : #initialization }
MPinStubResolver >> initialize [

	super initialize.
	shas := Dictionary new.
	sources := Dictionary new.
	defaultBranch := 'main'
]

{ #category : #resolving }
MPinStubResolver >> resolveSha: aReference [

	^ shas
		  at: aReference projectKey , '@' , aReference refOrHead
		  ifAbsent: [ MPinError signal: 'unknown ref ' , aReference url ]
]
