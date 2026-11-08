"
I am the `metacello-pin` command line entry point on Pharo 14. Pharo 14 sends every command
line to Clap and no longer calls `CommandLineHandler` subclasses, so I am a Clap command.
I pass the arguments to `MPinCommand`, which runs the command and lists the usage.
"
Class {
	#name : #MPinClapCommand,
	#superclass : #ClapPharoApplication,
	#category : #'MetacelloPin-Clap'
}

{ #category : #'command line' }
MPinClapCommand class >> commandSpecification [

	<commandline>
	^ (ClapCommandSpec id: #'metacello-pin')
		  description: 'Pin Metacello baseline dependencies to commit SHAs';
		  commandClass: self;
		  addHelp;
		  addPositional: #words spec: [ :positional |
				  positional
					  description: 'check, pin, lock or help, then the directory (default: src)';
					  multiple: true;
					  defaultValue: [ :match | #(  ) ] ];
		  addFlagWithPositional: #output description: 'File written by lock';
		  yourself
]

{ #category : #accessing }
MPinClapCommand >> arguments [

	| result |
	result := OrderedCollection withAll: (self positional: #words).
	(self hasFlag: #output) ifTrue: [
		result add: '--output=' , (self positional: #output) ].
	^ result
]

{ #category : #execution }
MPinClapCommand >> execute [

	(MPinCommand arguments: self arguments stdout: self context stdout) run
		ifNil: [ self exitSuccess ]
		ifNotNil: [ :message | self exitFailure: message ]
]
