"
I lock a whole dependency tree.

I start from the occurrences of the root project. For each GitHub baseline, I get its commit,
read that baseline's own Tonel source at the commit, and continue breadth-first with its
dependencies. When two baselines ask for the same project, I keep the first commit and add
a conflict warning if the other commit is different.

I also record which project requires which. With that, the lock file can load each
dependency before the projects that need it.
"
Class {
	#name : #MPinLocker,
	#superclass : #Object,
	#instVars : [
		'resolver',
		'entries',
		'warnings',
		'queue',
		'maxEntries',
		'dependencies'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #'instance creation' }
MPinLocker class >> resolver: aResolver [

	^ self new
		  resolver: aResolver;
		  yourself
]

{ #category : #private }
MPinLocker >> checkConflict: anOccurrence [

	| entry sha |
	entry := entries at: anOccurrence projectName.
	sha := self shaFor: anOccurrence.
	(sha isNil or: [ sha = entry sha ]) ifTrue: [ ^ self ].
	self warn:
		'conflict: ' , anOccurrence projectName , ' requested at ' , sha , ' by '
		, (anOccurrence requiredBy ifNil: [ 'root' ]) , '; keeping ' , entry sha
]

{ #category : #private }
MPinLocker >> enqueueDependenciesOf: anEntry [

	| source |
	source := [
	          resolver
		          fetch: anEntry reference
		          baselineNamed: anEntry name
		          at: anEntry sha ]
		          on: Error
		          do: [ nil ].
	source ifNil: [
			^ self warn: 'cannot read BaselineOf' , anEntry name
				  , ' (only Tonel layout is supported); its dependencies are not locked' ].
	(self scanRemote: source) do: [ :each | queue add: (each requiredBy: anEntry name) ]
]

{ #category : #private }
MPinLocker >> entryFor: anOccurrence sha: aSha [

	^ MPinLockEntry new
		  name: anOccurrence projectName;
		  reference: anOccurrence reference;
		  sha: aSha;
		  refLabel: (self refLabelFor: anOccurrence);
		  requiredBy: anOccurrence requiredBy;
		  yourself
]

{ #category : #initialization }
MPinLocker >> initialize [

	super initialize.
	entries := OrderedDictionary new.
	warnings := OrderedCollection new.
	queue := OrderedCollection new.
	dependencies := Dictionary new.
	maxEntries := 500
]

{ #category : #private }
MPinLocker >> add: aName inLoadOrderTo: anOrder visited: aSet [
	"Add the entry for aName to anOrder after its dependencies, depth-first. aSet holds the
	names already visited, which also stops dependency cycles."

	(aSet includes: aName) ifTrue: [ ^ self ].
	aSet add: aName.
	(dependencies at: aName ifAbsent: [ #(  ) ]) do: [ :each |
			(entries includesKey: each) ifTrue: [
				self add: each inLoadOrderTo: anOrder visited: aSet ] ].
	anOrder add: (entries at: aName)
]

{ #category : #private }
MPinLocker >> entriesInLoadOrder [

	| order visited |
	order := OrderedCollection new.
	visited := Set new.
	entries keysDo: [ :each | self add: each inLoadOrderTo: order visited: visited ].
	^ order
]

{ #category : #private }
MPinLocker >> recordDependencyOf: anOccurrence [

	| required |
	anOccurrence requiredBy ifNil: [ ^ self ].
	required := dependencies
		            at: anOccurrence requiredBy
		            ifAbsentPut: [ OrderedCollection new ].
	(required includes: anOccurrence projectName) ifFalse: [
		required add: anOccurrence projectName ]
]

{ #category : #accessing }
MPinLocker >> maxEntries: anInteger [
	"Remote baselines are untrusted, so I limit how many projects (and API calls) one lock
	can visit."

	maxEntries := anInteger
]

{ #category : #locking }
MPinLocker >> lock: aCollectionOfOccurrences [

	queue addAll: aCollectionOfOccurrences.
	[ queue isEmpty or: [ entries size >= maxEntries ] ] whileFalse: [
		self visit: queue removeFirst ].
	queue ifNotEmpty: [
			self warn:
				'stopped after ' , maxEntries printString , ' baselines; the rest is not locked' ].
	^ MPinLockfile entries: self entriesInLoadOrder warnings: warnings
]

{ #category : #private }
MPinLocker >> refLabelFor: anOccurrence [

	^ anOccurrence isPinned
		  ifTrue: [ 'pinned' ]
		  ifFalse: [ anOccurrence reference refOrHead ]
]

{ #category : #accessing }
MPinLocker >> resolver: aResolver [

	resolver := aResolver
]

{ #category : #private }
MPinLocker >> scanRemote: aSource [

	^ [ MPinScanner new scanTonelString: aSource ]
		  on: Error
		  do: [ :error |
				  self warn: 'cannot parse remote baseline: ' , error messageText.
				  #(  ) ]
]

{ #category : #private }
MPinLocker >> shaFor: anOccurrence [

	anOccurrence isPinned ifTrue: [ ^ anOccurrence reference ref ].
	^ [ resolver resolve: anOccurrence reference ]
		  on: Error
		  do: [ :error |
				  self warn:
					  'cannot resolve ' , anOccurrence reference url , ': ' , error messageText.
				  nil ]
]

{ #category : #private }
MPinLocker >> visit: anOccurrence [

	| sha entry |
	anOccurrence isPinnable ifFalse: [ ^ self warnUnsupported: anOccurrence ].
	self recordDependencyOf: anOccurrence.
	(entries includesKey: anOccurrence projectName) ifTrue: [
		^ self checkConflict: anOccurrence ].
	sha := self shaFor: anOccurrence.
	sha ifNil: [ ^ self ].
	entry := self entryFor: anOccurrence sha: sha.
	entries at: entry name put: entry.
	self enqueueDependenciesOf: entry
]

{ #category : #private }
MPinLocker >> warn: aString [

	warnings add: aString
]

{ #category : #private }
MPinLocker >> warnUnsupported: anOccurrence [

	self warn: 'not locked: ' , anOccurrence location , ' '
		, (anOccurrence projectName ifNil: [ '-' ]) , ' (' , anOccurrence unsupportedReason
		, ')'
]
