"
I am the abstract source of baseline code to check, pin and lock. My subclasses read
baselines from Tonel files on disk (`MPinTonelProject`, used by the CLI) or from classes
loaded in the image (`MPinImageProject`, used by the GUI).
"
Class {
	#name : #MPinProject,
	#superclass : #Object,
	#category : #'MetacelloPin-Core'
}

{ #category : #locking }
MPinProject >> lockWith: aResolver [

	^ (MPinLocker resolver: aResolver) lock: self occurrences
]

{ #category : #accessing }
MPinProject >> occurrences [

	self subclassResponsibility
]

{ #category : #pinning }
MPinProject >> pinWith: aResolver [
	"Rewrite my baselines and answer the occurrences annotated with the outcome."

	self subclassResponsibility
]

{ #category : #accessing }
MPinProject >> scanner [

	^ MPinScanner new
]
