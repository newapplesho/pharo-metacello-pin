"
I am a STON reader that refuses class references.

Tonel metadata of a remote baseline is untrusted input. Plain `STON fromString:` would
instantiate any class named in it (`Foo { ... }`); I only materialize literals, lists and
maps, which is all Tonel metadata needs.
"
Class {
	#name : #MPinSafeSTONReader,
	#superclass : #STONReader,
	#category : #'MetacelloPin-Core'
}

{ #category : #private }
MPinSafeSTONReader >> lookupClass: aSymbol [

	^ MPinError signal: 'class reference not allowed in Tonel metadata: ' , aSymbol
]
