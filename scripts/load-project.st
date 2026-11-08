"Load (or reload) pharo-metacello-pin into the current Pharo image.
 Run from the repository root with: make load
 get reloads BaselineOfMetacelloPin first: load alone keeps the copy already in the image,
 so a change to the baseline (even to its class comment) would be missed."
| repository |
repository := 'tonel://' , (FileLocator imageDirectory / '..' / 'src') resolve fullName.
Metacello new
	baseline: 'MetacelloPin';
	repository: repository;
	get.
Metacello new
	baseline: 'MetacelloPin';
	repository: repository;
	onConflict: [ :ex | ex allow ];
	load.
