"
I am a Spec2 window for pinning the baselines loaded in the image.

Select a baseline on the left to see its repository references. The line under the table
counts them by status and says what to do next. `Pin` rewrites the selected baseline in the
image (commit it with Iceberg afterwards). `Lock` resolves the whole dependency tree and
shows the lock script below. `Lock` does not write a file: `Save...` writes the script to a
file that you choose, and the label above the script says whether it has been saved. `Pin`
and `Lock` stay disabled until they have something to do.

Open me from the World menu (Library > Metacello Pin) or with `MPinPresenter new open`.
"
Class {
	#name : #MPinPresenter,
	#superclass : #SpPresenter,
	#instVars : [
		'baselineList',
		'occurrenceTable',
		'lockText',
		'refreshButton',
		'pinButton',
		'lockButton',
		'lockLabel',
		'saveButton',
		'lockfile',
		'guideLabel',
		'statusLabel'
	],
	#category : #'MetacelloPin-GUI'
}

{ #category : #'world menu' }
MPinPresenter class >> menuCommandOn: aBuilder [
	"Pharo shows the menu named #Tools as Library."

	<worldMenu>
	(aBuilder item: 'Metacello Pin')
		parent: #Tools;
		help: 'Pin Metacello baseline dependencies to commit SHAs';
		action: [ self new open ]
]

{ #category : #accessing }
MPinPresenter >> baselineClasses [

	^ BaselineOf allSubclasses sorted: [ :a :b | a name < b name ]
]

{ #category : #initialization }
MPinPresenter >> connectPresenters [

	baselineList whenSelectionChangedDo: [ :selection |
			self refresh.
			self resetLockPane ].
	refreshButton action: [ self refresh ].
	pinButton action: [ self pin ].
	lockButton action: [ self lock ].
	saveButton action: [ self save ]
]

{ #category : #layout }
MPinPresenter >> buttonsLayout [

	^ SpBoxLayout newLeftToRight
		  add: refreshButton expand: false;
		  add: pinButton expand: false;
		  add: lockButton expand: false;
		  add: guideLabel;
		  yourself
]

{ #category : #layout }
MPinPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: self buttonsLayout expand: false;
		  add: (SpPanedLayout newTopToBottom
				   add: (SpPanedLayout newLeftToRight
						    positionOfSlider: 30 percent;
						    add: baselineList;
						    add: (SpBoxLayout newTopToBottom
								     add: occurrenceTable;
								     add: statusLabel expand: false;
								     yourself);
						    yourself);
				   add: self lockLayout;
				   yourself);
		  yourself
]

{ #category : #initialization }
MPinPresenter >> initializeOccurrenceTable [

	occurrenceTable := self newTable.
	{
		('Status' -> [ :each | each statusString ]).
		('Project' -> [ :each | each projectName ifNil: [ '-' ] ]).
		('Repository' -> [ :each | self repositoryLabelOf: each ]).
		('Note' -> [ :each | each note ]) } do: [ :column |
			occurrenceTable addColumn:
				(SpStringTableColumn title: column key evaluated: column value) ]
]

{ #category : #initialization }
MPinPresenter >> initializePresenters [

	baselineList := self newFilteringList
		                items: self baselineClasses;
		                display: [ :each | each name ];
		                yourself.
	self initializeOccurrenceTable.
	self initializeLockPane.
	self initializeButtons.
	guideLabel := self newLabel
		              label: 'Select a baseline, then Pin it (in this image) or Lock it.';
		              yourself.
	statusLabel := self newLabel
		               label: 'Select a baseline on the left.';
		               yourself
]

{ #category : #initialization }
MPinPresenter >> initializeButtons [

	refreshButton := self newButton
		                 label: 'Refresh';
		                 help: 'Scan the selected baseline again';
		                 yourself.
	pinButton := self newButton
		             label: 'Pin';
		             help: 'Replace unpinned refs with commit SHAs in this image';
		             enabled: false;
		             yourself.
	lockButton := self newButton
		              label: 'Lock';
		              help: 'Show the lock script below. It is not saved to a file.';
		              enabled: false;
		              yourself
]

{ #category : #initialization }
MPinPresenter >> initializeLockPane [

	lockText := self newText.
	lockLabel := self newLabel.
	saveButton := self newButton
		              label: 'Save...';
		              help: 'Write the lock script to a file';
		              yourself.
	self resetLockPane
]

{ #category : #initialization }
MPinPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Metacello Pin';
		initialExtent: 1000 @ 650
]

{ #category : #actions }
MPinPresenter >> lock [

	self selectedProject ifNil: [ ^ self ].
	lockfile := self selectedProject lockWith: self resolver.
	lockText text: lockfile script.
	lockLabel label:
		'Lock script for ' , baselineList selectedItem name , ': not saved to a file yet.'.
	saveButton enabled: true
]

{ #category : #layout }
MPinPresenter >> lockLayout [

	^ SpBoxLayout newTopToBottom
		  add: (SpBoxLayout newLeftToRight
				   add: lockLabel;
				   add: saveButton expand: false;
				   yourself)
		  expand: false;
		  add: lockText;
		  yourself
]

{ #category : #actions }
MPinPresenter >> pin [

	| occurrences |
	self selectedProject ifNil: [ ^ self ].
	occurrences := self selectedProject pinWith: self resolver.
	self show: occurrences.
	(occurrences anySatisfy: [ :each | each resolvedSha notNil ]) ifTrue: [
			statusLabel label:
				statusLabel label , ' Changed in this image only: commit it with Iceberg.' ]
]

{ #category : #actions }
MPinPresenter >> refresh [

	self show:
		(self selectedProject ifNil: [ #(  ) ] ifNotNil: [ :project | project occurrences ])
]

{ #category : #private }
MPinPresenter >> resetLockPane [

	lockfile := nil.
	lockText text: ''.
	lockLabel label: 'Lock script: press Lock to create it. It is not saved to a file.'.
	saveButton enabled: false
]

{ #category : #private }
MPinPresenter >> show: aCollectionOfOccurrences [
	"Show the occurrences in the table, summarize them in the status line, and enable only
	the buttons that have something to do."

	occurrenceTable items: aCollectionOfOccurrences.
	statusLabel label: (self summaryOf: aCollectionOfOccurrences).
	lockButton enabled: aCollectionOfOccurrences notEmpty.
	pinButton enabled:
		(aCollectionOfOccurrences anySatisfy: [ :each | self waitsForPin: each ])
]

{ #category : #private }
MPinPresenter >> waitsForPin: anOccurrence [
	"Answer whether Pin would still change anOccurrence. After a pin, the occurrence keeps
	its old reference, so needsPin alone is still true for it."

	^ anOccurrence needsPin and: [ anOccurrence resolvedSha isNil ]
]

{ #category : #private }
MPinPresenter >> summaryOf: aCollectionOfOccurrences [
	"Answer the status line: how many references the selected baseline has in each status,
	and what to do next."

	| baseline |
	baseline := baselineList selectedItem ifNil: [ ^ 'Select a baseline on the left.' ].
	aCollectionOfOccurrences ifEmpty: [
			^ baseline name asString
			  , ' has no spec repository: references, so there is nothing to pin or lock.' ].
	^ baseline name asString , ': ' , (self countsOf: aCollectionOfOccurrences)
	  , ((aCollectionOfOccurrences anySatisfy: [ :each | self waitsForPin: each ])
			   ifTrue: [ ' Press Pin to replace the unpinned refs with commit SHAs.' ]
			   ifFalse: [ '' ])
]

{ #category : #private }
MPinPresenter >> countsOf: aCollectionOfOccurrences [
	"Answer a text such as '2 unpinned, 1 unsupported.'"

	| counts |
	counts := (aCollectionOfOccurrences collect: [ :each | each statusString ]) asBag.
	^ (', ' join: (counts asSet sorted collect: [ :status |
			    (counts occurrencesOf: status) printString , ' ' , status ])) , '.'
]

{ #category : #private }
MPinPresenter >> repositoryLabelOf: anOccurrence [

	^ anOccurrence reference
		  ifNil: [ anOccurrence literalSource ]
		  ifNotNil: [ :reference | reference url ]
]

{ #category : #accessing }
MPinPresenter >> resolver [

	^ MPinGitHubResolver new
]

{ #category : #actions }
MPinPresenter >> save [
	"Write the script that Lock created. I do not save the text in the pane, because the
	user may have edited it."

	| file |
	lockfile ifNil: [ ^ self ].
	file := UIManager default
		        chooseForSaveFileReference: 'Save lock script'
		        extensions: #( 'st' )
		        path: FileSystem workingDirectory / 'metacello.lock.st'.
	file ifNil: [ ^ self ].
	lockfile writeTo: file.
	lockLabel label: 'Lock script saved to ' , file fullName
]

{ #category : #accessing }
MPinPresenter >> selectedProject [

	^ baselineList selectedItem ifNotNil: [ :class | MPinImageProject on: class ]
]
