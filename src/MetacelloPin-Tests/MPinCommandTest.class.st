"
I test how `MPinCommand` reads its arguments, without touching the network.
"
Class {
	#name : #MPinCommandTest,
	#superclass : #TestCase,
	#category : #'MetacelloPin-Tests'
}

{ #category : #helpers }
MPinCommandTest >> commandOn: anArray [

	^ MPinCommand arguments: anArray stdout: (WriteStream on: String new)
]

{ #category : #tests }
MPinCommandTest >> testHelpSucceeds [

	self assert: (self commandOn: #( 'help' )) run isNil.
	self assert: (self commandOn: #(  )) run isNil
]

{ #category : #tests }
MPinCommandTest >> testMissingDirectoryFailsWithMessage [

	| directory |
	directory := FileLocator imageDirectory / 'metacello-pin-no-such-directory'.
	self deny: directory exists.
	self
		assert: (self commandOn: { 'check'. directory fullName }) run
		equals: 'not a directory: ' , directory resolve fullName
]

{ #category : #tests }
MPinCommandTest >> testOutputPath [

	self assert: (self commandOn: #( 'lock' )) outputPath equals: 'metacello.lock.st'.
	self assert: (self commandOn: #( 'lock' '--output=a.st' )) outputPath equals: 'a.st'.
	self
		assert: (self commandOn: #( 'lock' '--output' 'b.st' )) outputPath
		equals: 'b.st'
]

{ #category : #tests }
MPinCommandTest >> testPositionalArgumentsSkipOutput [

	self
		assert:
		(self commandOn: #( 'lock' '--output' 'b.st' 'src' )) positionalArguments asArray
		equals: #( 'lock' 'src' ).
	self
		assert:
		(self commandOn: #( 'lock' 'src' '--output=a.st' )) positionalArguments asArray
		equals: #( 'lock' 'src' )
]

{ #category : #tests }
MPinCommandTest >> testUnknownCommandFails [

	self
		assert: (self commandOn: #( 'frobnicate' )) run
		equals: 'unknown command: frobnicate'
]
