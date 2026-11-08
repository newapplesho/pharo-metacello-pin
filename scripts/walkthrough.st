"Walkthrough: scan, pin and lock one sample baseline, step by step.

How to use it:
1. Open the image (make ui) and a Playground (Ctrl+O, W), and paste this file.
2. Select everything and choose Debug it (Ctrl+Shift+D).
3. Use Over to go one statement at a time, and Into to enter the method on that line.
   The variables pane of the debugger shows each result.

It uses the test fixtures, so it needs the Tests group (make load loads it). It does not use
the network: MPinStubResolver answers fixed SHAs in place of GitHub. It does not change any
class in the image either; pin only answers a new source string."

| source ast occurrences resolver pinned lockfile |

"1. The sample baseline: method. It names AWS (no ref), NeoYAML (tag v0.1.5), DuckDB (already
   a SHA), a GitLab package and a local package."
source := MPinTestFixtures baselineBody.

"2. The syntax tree of that method. Inspect ast (Ctrl+I) to see the tree. MPinScanner builds
   the same tree in step 3."
ast := RBParser parseMethod: source.

"3. Find every repository: send. Into this line goes to MPinScanner>>scanMethodSource:owner:.
   Each occurrence knows its project name, kind (#baseline or #package) and the position of
   the string in the method. Inspect occurrences now: the statuses are still 'unpinned',
   'pinned' and 'unsupported'."
occurrences := MPinScanner new scanMethodSource: source owner: #BaselineOfSample.

"4. The resolver that pin and lock ask for SHAs. MPinGitHubResolver new would ask GitHub."
resolver := MPinTestFixtures stubResolver.

"5. Pin: replace each unpinned ref with its SHA. Into this line goes to
   MPinPinner>>pinSource:occurrences:. pinned is the new source; compare it with source.
   Pin also records the SHA in each occurrence, so after this line their status is
   'pinned now'."
pinned := (MPinPinner resolver: resolver) pinSource: source occurrences: occurrences.

"6. Lock: resolve every dependency and follow the dependencies of the dependencies. Into this
   line goes to MPinLocker>>lock:. The stub has no remote baselines, so the locker cannot
   follow them and adds warnings. scripts/walkthrough-lock.st shows a deeper tree."
lockfile := (MPinLocker resolver: resolver) lock: occurrences.

"7. The lock script that the CLI writes to metacello.lock.st."
lockfile script
