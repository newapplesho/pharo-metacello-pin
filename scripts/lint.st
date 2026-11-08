"Run Pharo's lint rules (Renraku, the same critiques the System Browser shows under the
 code) on the classes of this project, and print one line per finding.
 Run from the repository root with: make lint
 project is the baseline name: the script checks BaselineOf<project> and every package
 whose name starts with it.

 The rules in ignored below do not fit this project and are skipped for every class.
 The script exits with status 1 when any other rule finds something.
 Run make load first: the rules check the code in the image, not the files in src/."

| project ignored packages findings skipped out |
project := 'MetacelloPin'.
ignored := Dictionary newFrom: {
	'Class not referenced'
		-> 'the entry points (World menu, command line, Metacello) are found by name'.
	'Excessive number of variables'
		-> 'a Spec presenter keeps one variable per widget'.
	'Inconsistent method classification'
		-> 'pin and isPinned override old aliases in Object with protocol #pinning'.
	'Missing super sends in selected methods.'
		-> 'SpPresenter>>initializeWindow: is a Spec 1 helper meant to be replaced'.
	'Method defined in all subclasses, but not in superclass'
		-> 'the subclasses take different arguments, a method or a file' }.

packages := (PackageOrganizer default packages
	select: [ :each | each name beginsWith: project ]) asOrderedCollection.
packages add: (PackageOrganizer default packageNamed: 'BaselineOf' , project).

findings := OrderedCollection new.
skipped := 0.
packages do: [ :package |
	package definedClasses do: [ :class |
		({ class } , class methods , class class methods) do: [ :entity |
			(ReCriticEngine critiquesOf: entity) do: [ :critique |
				(ignored includesKey: critique rule name)
					ifTrue: [ skipped := skipped + 1 ]
					ifFalse: [
						findings add: entity printString , ' | ' , critique rule name ] ] ] ] ].

out := Stdio stdout.
findings do: [ :each | out nextPutAll: each; lf ].
out
	nextPutAll: findings size printString , ' finding(s); ';
	nextPutAll: skipped printString , ' more from ignored rules: ';
	nextPutAll: (', ' join: ignored keys asSortedCollection);
	lf;
	flush.
Smalltalk exit: (findings isEmpty ifTrue: [ 0 ] ifFalse: [ 1 ])
