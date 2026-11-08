"
I am the `metacello-pin` command line entry point on Pharo 12 and 13. I pass the arguments to
`MPinCommand`, which runs the command and lists the usage.
"
Class {
	#name : #MPinCommandLineHandler,
	#superclass : #CommandLineHandler,
	#category : #'MetacelloPin-CLI'
}

{ #category : #accessing }
MPinCommandLineHandler class >> commandName [

	^ 'metacello-pin'
]

{ #category : #accessing }
MPinCommandLineHandler class >> description [

	^ 'Pin Metacello baseline dependencies to commit SHAs'
]

{ #category : #'handler selection' }
MPinCommandLineHandler class >> priority [
	"STCommandLineHandler also claims any argument ending in .st, such as the file after
	--output. My higher priority makes Pharo choose me instead. Pharo considers me only when
	the command line starts with my command name."

	^ 1
]

{ #category : #activation }
MPinCommandLineHandler >> activate [

	(MPinCommand arguments: self arguments stdout: self stdout) run
		ifNil: [ self exitSuccess ]
		ifNotNil: [ :message | self exitFailure: message ]
]
