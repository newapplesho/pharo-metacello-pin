"
I run one `metacello-pin` command: `check`, `pin`, `lock` or `help`. `usage` lists them.

The command line entry points (`MPinCommandLineHandler` on Pharo 12 and 13, `MPinClapCommand`
on Pharo 14) give me the arguments and an output stream. `run` answers nil on success or a
failure message, and the entry point exits with status 0 or 1 accordingly.
"
Class {
	#name : #MPinCommand,
	#superclass : #Object,
	#instVars : [
		'arguments',
		'stdout'
	],
	#category : #'MetacelloPin-CLI'
}

{ #category : #'instance creation' }
MPinCommand class >> arguments: anArray stdout: aStream [

	^ self new setArguments: anArray stdout: aStream
]

{ #category : #commands }
MPinCommand >> check [

	| occurrences unpinned |
	occurrences := self project occurrences.
	self report: occurrences.
	unpinned := occurrences select: [ :each | each needsPin ].
	unpinned ifNotEmpty: [
		^ unpinned size printString , ' unpinned baseline reference(s)' ].
	self printLine:
		occurrences size printString , ' reference(s), no unpinned GitHub baseline'.
	^ nil
]

{ #category : #commands }
MPinCommand >> lock [

	| lockfile output |
	lockfile := self project lockWith: self resolver.
	output := self outputPath asFileReference.
	lockfile writeTo: output.
	lockfile warnings do: [ :each | self printLine: 'WARNING: ' , each ].
	self printLine:
		lockfile entries size printString , ' baseline(s) locked in ' , output fullName.
	^ nil
]

{ #category : #accessing }
MPinCommand >> outputPath [
	"Answer the file given with --output=file or --output file, or metacello.lock.st."

	| index |
	arguments do: [ :each |
		(each beginsWith: '--output=') ifTrue: [ ^ each allButFirst: 9 ] ].
	index := arguments indexOf: '--output'.
	^ (index between: 1 and: arguments size - 1)
		  ifTrue: [ arguments at: index + 1 ]
		  ifFalse: [ 'metacello.lock.st' ]
]

{ #category : #commands }
MPinCommand >> pin [

	| occurrences |
	occurrences := self project pinWith: self resolver.
	self report: occurrences.
	^ (occurrences anySatisfy: [ :each | each errorMessage notNil ])
		  ifTrue: [ 'some references could not be pinned' ]
		  ifFalse: [ nil ]
]

{ #category : #accessing }
MPinCommand >> positionalArguments [
	"Answer the arguments that are not options. The file name after --output is an option
	value, so I skip it too."

	| result skipNext |
	result := OrderedCollection new.
	skipNext := false.
	arguments do: [ :each |
			skipNext
				ifTrue: [ skipNext := false ]
				ifFalse: [
						skipNext := each = '--output'.
						(each beginsWith: '--') ifFalse: [ result add: each ] ] ].
	^ result
]

{ #category : #printing }
MPinCommand >> printLine: aString [

	stdout
		nextPutAll: aString;
		lf;
		flush
]

{ #category : #printing }
MPinCommand >> printUsage [

	self usage lines do: [ :each | self printLine: each ]
]

{ #category : #accessing }
MPinCommand >> project [

	^ MPinTonelProject on:
		  (self positionalArguments at: 2 ifAbsent: [ 'src' ]) asFileReference
]

{ #category : #printing }
MPinCommand >> report: aCollection [

	aCollection do: [ :each |
			self printLine: each printString.
			each note ifNotEmpty: [ :note | self printLine: '    ' , note ] ]
]

{ #category : #accessing }
MPinCommand >> resolver [

	^ MPinGitHubResolver new
]

{ #category : #running }
MPinCommand >> run [
	"Answer nil on success, or the message to fail with."

	| command |
	command := self positionalArguments
		           ifEmpty: [ 'help' ]
		           ifNotEmpty: [ :args | args first ].
	command = 'check' ifTrue: [ ^ self check ].
	command = 'pin' ifTrue: [ ^ self pin ].
	command = 'lock' ifTrue: [ ^ self lock ].
	self printUsage.
	^ command = 'help'
		  ifTrue: [ nil ]
		  ifFalse: [ 'unknown command: ' , command ]
]

{ #category : #initialization }
MPinCommand >> setArguments: anArray stdout: aStream [

	arguments := anArray asArray.
	stdout := aStream
]

{ #category : #printing }
MPinCommand >> usage [

	^ 'Usage:
  metacello-pin check [dir]   list references; exit 1 if a GitHub baseline is unpinned
  metacello-pin pin [dir]     rewrite BaselineOf*/*.class.st to commit SHAs
  metacello-pin lock [dir] [--output file]
                              write a lock script (default: metacello.lock.st)

dir defaults to src.'
]
