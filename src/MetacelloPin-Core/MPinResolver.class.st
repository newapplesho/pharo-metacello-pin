"
I am the abstract interface used to turn a `MPinReference` into a commit SHA and to read a
baseline source from a remote repository at a given commit.
"
Class {
	#name : #MPinResolver,
	#superclass : #Object,
	#category : #'MetacelloPin-Core'
}

{ #category : #resolving }
MPinResolver >> defaultBranchOf: aReference [

	self subclassResponsibility
]

{ #category : #resolving }
MPinResolver >> fetch: aReference baselineNamed: aProjectName at: aSha [
	"Answer the Tonel source of BaselineOf<aProjectName> at aSha, or nil if it cannot be read."

	self subclassResponsibility
]

{ #category : #resolving }
MPinResolver >> refLabelFor: aReference [

	^ aReference hasRef
		  ifTrue: [ aReference ref ]
		  ifFalse: [ self defaultBranchOf: aReference ]
]

{ #category : #resolving }
MPinResolver >> resolve: aReference [
	"Answer the commit SHA of aReference. The answer is validated because it is written into
	baseline sources and lock scripts."

	| sha |
	sha := (self resolveSha: aReference) asString trimBoth asLowercase.
	(MPinReference isCommitSha: sha) ifFalse: [
		^ MPinError signal: 'not a commit SHA for ' , aReference url ].
	^ sha
]

{ #category : #resolving }
MPinResolver >> resolveSha: aReference [

	self subclassResponsibility
]
