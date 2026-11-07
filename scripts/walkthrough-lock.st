"Walkthrough: how lock follows a dependency tree.

Paste this file into a Playground and choose Print it (Ctrl+P) to see the lock script, or
Debug it (Ctrl+Shift+D) and step Into the lock: line. Useful places to stop:
- MPinLocker>>lock: takes one occurrence after another from a queue.
- MPinLocker>>enqueueDependenciesOf: reads a dependency's baseline and adds its references
  to the queue.
- MPinLocker>>checkConflict: warns when a project is requested at another commit.
- MPinLocker>>entriesInLoadOrder puts dependencies before the baselines that need them.

It does not use the network. MPinStubResolver answers made-up SHAs (1111..., 2222...) and
baseline sources for made-up projects under github://example/.

The tree:
  Root -+- Mid v1.0 (1111...)
        |    +- Leaf v1.0 (3333...)     another version of Leaf than Root asks for
        |    +- NoTonel main (4444...)  no baseline source, like a FileTree repository
        |    +- GsOnly main (5555...)   only inside spec for: #gemstone do: [ ... ]
        +- Leaf v2.0 (2222...)

What to look for in the result:
- NoTonel and GsOnly are locked: lock follows the dependencies of Mid.
- Leaf stays at 2222... (the one closest to Root), with a conflict warning.
- NoTonel is locked, but lock cannot read its baseline, so it warns and stops there.
- The load order is Leaf, NoTonel, GsOnly, Mid: dependencies first.
- GsOnly is locked and loaded even though only GemStone needs it. The scanner reads every
  spec for: block, whatever the platform (see ROADMAP.md)."

| sha root mid leaf resolver occurrences lockfile |
sha := [ :digit | String new: 40 withAll: digit ].

"The root baseline, as the source of its baseline: method."
root := 'baseline: spec
	<baseline>
	spec for: #common do: [
		spec baseline: ''Mid'' with: [ spec repository: ''github://example/Mid:v1.0/src'' ].
		spec baseline: ''Leaf'' with: [ spec repository: ''github://example/Leaf:v2.0/src'' ] ]'.

"Remote baselines are Tonel files. tonelClassNamed:body: wraps a method body, which starts
 with 'baseline: spec [' as in a Tonel file."
mid := 'baseline: spec [
	<baseline>
	spec for: #common do: [
		spec baseline: ''Leaf'' with: [ spec repository: ''github://example/Leaf:v1.0/src'' ].
		spec baseline: ''NoTonel'' with: [
			spec repository: ''github://example/NoTonel:main/src'' ] ].
	spec for: #gemstone do: [
		spec baseline: ''GsOnly'' with: [
			spec repository: ''github://example/GsOnly:main/src'' ] ]'.
leaf := 'baseline: spec [
	<baseline>'.

resolver := MPinStubResolver new
	at: 'example/Mid@v1.0' sha: (sha value: $1);
	at: 'example/Leaf@v2.0' sha: (sha value: $2);
	at: 'example/Leaf@v1.0' sha: (sha value: $3);
	at: 'example/NoTonel@main' sha: (sha value: $4);
	at: 'example/GsOnly@main' sha: (sha value: $5);
	baselineNamed: 'Mid' source: (MPinTestFixtures tonelClassNamed: 'BaselineOfMid' body: mid);
	baselineNamed: 'Leaf' source: (MPinTestFixtures tonelClassNamed: 'BaselineOfLeaf' body: leaf);
	baselineNamed: 'GsOnly'
		source: (MPinTestFixtures tonelClassNamed: 'BaselineOfGsOnly' body: leaf);
	yourself.

occurrences := MPinScanner new scanMethodSource: root owner: #BaselineOfRoot.
lockfile := (MPinLocker resolver: resolver) lock: occurrences.
lockfile script
