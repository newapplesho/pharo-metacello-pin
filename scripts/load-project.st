"Load (or reload) pharo-metacello-pin into the current Pharo image.
 Run from the repository root with: make load"
Metacello new
	baseline: 'MetacelloPin';
	repository: 'tonel://' , (FileLocator imageDirectory / '..' / 'src') resolve fullName;
	onConflict: [ :ex | ex allow ];
	load.
