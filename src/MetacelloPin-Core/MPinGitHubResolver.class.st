"
I resolve GitHub references with the GitHub REST API and read baseline sources from
raw.githubusercontent.com.

Set the `GITHUB_TOKEN` environment variable to raise the API rate limit.
"
Class {
	#name : #MPinGitHubResolver,
	#superclass : #MPinResolver,
	#instVars : [
		'token',
		'cache',
		'apiUrl',
		'rawUrl'
	],
	#category : #'MetacelloPin-Core'
}

{ #category : #private }
MPinGitHubResolver >> apiGet: aPath accept: aMimeTypeString [
	"I do not follow redirects, because Zinc sends the Authorization header again to the
	redirect target, even when it is another host."

	| client |
	client := ZnClient new
		          url: apiUrl , aPath;
		          followRedirects: false;
		          headerAt: 'Accept' put: aMimeTypeString;
		          yourself.
	self token ifNotEmpty: [ :value |
		client headerAt: 'Authorization' put: 'Bearer ' , value ].
	^ [ self contentsOf: client for: aPath ] ensure: [ client close ]
]

{ #category : #private }
MPinGitHubResolver >> contentsOf: aClient for: aPath [

	aClient get.
	aClient isSuccess ifFalse: [
			^ MPinError signal:
				  'GitHub API ' , aPath , ' answered ' , aClient response code printString ].
	^ aClient contents
]

{ #category : #resolving }
MPinGitHubResolver >> defaultBranchOf: aReference [

	| json |
	json := self
		        apiGet: '/repos/' , aReference projectKey
		        accept: 'application/vnd.github+json'.
	^ (STONJSON fromString: json) at: 'default_branch'
]

{ #category : #resolving }
MPinGitHubResolver >> fetch: aReference baselineNamed: aProjectName at: aSha [

	| client |
	client := ZnClient new url: rawUrl , '/' , aReference projectKey , '/' , aSha , '/'
		          , (aReference baselineFilePathFor: aProjectName).
	^ [
		  client get.
		  client isSuccess
			  ifTrue: [ client contents ]
			  ifFalse: [ nil ] ] ensure: [ client close ]
]

{ #category : #initialization }
MPinGitHubResolver >> initialize [

	super initialize.
	cache := Dictionary new.
	apiUrl := 'https://api.github.com'.
	rawUrl := 'https://raw.githubusercontent.com'
]

{ #category : #accessing }
MPinGitHubResolver >> apiUrl: aString rawUrl: anotherString [
	"Use other hosts instead of GitHub. The tests use this to point me at a local server."

	apiUrl := aString.
	rawUrl := anotherString
]

{ #category : #resolving }
MPinGitHubResolver >> resolveSha: aReference [

	| key |
	key := aReference projectKey , '/commits/' , aReference refOrHead.
	^ cache
		  at: key
		  ifAbsentPut: [ self apiGet: '/repos/' , key accept: 'application/vnd.github.sha' ]
]

{ #category : #accessing }
MPinGitHubResolver >> token [

	^ token ifNil: [
		  token := Smalltalk os environment at: 'GITHUB_TOKEN' ifAbsent: [ '' ] ]
]

{ #category : #accessing }
MPinGitHubResolver >> token: aString [

	token := aString
]
