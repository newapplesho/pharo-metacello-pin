"
I am a Tonel parser that reads metadata with `MPinSafeSTONReader`, so parsing a baseline
fetched from a remote repository cannot instantiate arbitrary classes.
"
Class {
	#name : #MPinSafeTonelParser,
	#superclass : #TonelParser,
	#category : #'MetacelloPin-Core'
}

{ #category : #parsing }
MPinSafeTonelParser >> metadata [

	| result depth char |
	stream peek = ${ ifFalse: [ TonelParseError signal: 'Can''t parse metadata' ].
	result := WriteStream on: String new.
	depth := 0.
	[
		char := stream next.
		result nextPut: char.
		char = ${ ifTrue: [ depth := depth + 1 ].
		char = $} ifTrue: [ depth := depth - 1 ].
		depth = 0 or: [ stream atEnd ] ] whileFalse.
	depth = 0 ifFalse: [ TonelParseError signal: 'Can''t parse metadata' ].
	^ (MPinSafeSTONReader on: result contents readStream) next
]
