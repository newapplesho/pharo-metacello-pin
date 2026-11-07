"
I am one locked baseline in a lock file: a project name, the repository description pinned
to a commit, the ref it was resolved from and the project that required it.
"
Class {
	#name : #MPinLockEntry,
	#superclass : #Object,
	#instVars : [
		'name',
		'reference',
		'sha',
		'refLabel',
		'requiredBy'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #accessing }
MPinLockEntry >> name [

	^ name
]

{ #category : #accessing }
MPinLockEntry >> name: aString [

	name := aString
]

{ #category : #accessing }
MPinLockEntry >> pinnedUrl [

	^ reference pinnedTo: sha
]

{ #category : #printing }
MPinLockEntry >> print: aCommand on: aStream [
	"Print my Metacello statement on aStream, ending with aCommand (#lock or #load)."

	aStream
		nextPutAll: 'Metacello new';
		lf;
		tab;
		nextPutAll: 'baseline: ';
		print: name;
		nextPut: $;;
		lf.
	self printRepositoryOn: aStream.
	aStream
		tab;
		nextPutAll: aCommand;
		nextPut: $.;
		lf
]

{ #category : #printing }
MPinLockEntry >> printRepositoryOn: aStream [
	"Print my repository: line, with the original ref and the baseline that required me as a
	comment."

	aStream
		tab;
		nextPutAll: 'repository: ';
		print: self pinnedUrl;
		space;
		nextPutAll: (MPinOccurrence commentFor:
					 refLabel , ', required by ' , (requiredBy ifNil: [ 'root' ]));
		nextPut: $;;
		lf
]

{ #category : #accessing }
MPinLockEntry >> refLabel: aString [

	refLabel := aString
]

{ #category : #accessing }
MPinLockEntry >> reference [

	^ reference
]

{ #category : #accessing }
MPinLockEntry >> reference: aReference [

	reference := aReference
]

{ #category : #accessing }
MPinLockEntry >> requiredBy [

	^ requiredBy
]

{ #category : #accessing }
MPinLockEntry >> requiredBy: aString [

	requiredBy := aString
]

{ #category : #accessing }
MPinLockEntry >> sha [

	^ sha
]

{ #category : #accessing }
MPinLockEntry >> sha: aString [

	sha := aString
]
