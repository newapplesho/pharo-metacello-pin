"
I load metacello-pin. My groups are Core (the core and the CLI), GUI, Tests and default
(everything). On Pharo 14, Core also loads MetacelloPin-Clap, the command line entry point
for Clap.
"
Class {
	#name : #BaselineOfMetacelloPin,
	#superclass : #BaselineOf,
	#category : #BaselineOfMetacelloPin
}

{ #category : #baselines }
BaselineOfMetacelloPin >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec
				package: 'MetacelloPin-Core';
				package: 'MetacelloPin-CLI' with: [ spec requires: #( 'MetacelloPin-Core' ) ];
				package: 'MetacelloPin-GUI' with: [ spec requires: #( 'MetacelloPin-Core' ) ];
				package: 'MetacelloPin-Tests' with: [ spec requires: #( 'MetacelloPin-Core' ) ].
			spec
				group: 'Core' with: #( 'MetacelloPin-Core' 'MetacelloPin-CLI' );
				group: 'GUI' with: #( 'Core' 'MetacelloPin-GUI' );
				group: 'Tests' with: #( 'Core' 'MetacelloPin-Tests' );
				group: 'default' with: #( 'GUI' 'Tests' ) ].
	spec
		for: #'pharo14.x'
		do: [ "Pharo 14 sends every command line to Clap, so the CLI needs a Clap command too."
				spec
					package: 'MetacelloPin-Clap'
					with: [ spec requires: #( 'MetacelloPin-CLI' ) ].
				spec group: 'Core' with: #( 'MetacelloPin-Clap' ) ]
]
