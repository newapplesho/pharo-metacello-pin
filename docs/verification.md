# Verification

This page records the checks that we ran by hand against real projects, and what we have
not checked yet. [architecture.md](architecture.md#tests) describes the automated tests.

None of these runs loaded third-party code into the image. `check`, `pin` and `lock` only
read baselines and call the GitHub API.

## pin: branches and tags become commit SHAs

### aws-sdk-smalltalk

We copied the `src/` directory of
[aws-sdk-smalltalk](https://github.com/newapplesho/aws-sdk-smalltalk) and ran `make check`,
`make pin` and then `make check` again on the copy, with `DIR=` pointing to it.
`BaselineOfAWS` gives no ref for NeoJSON, so Metacello uses its default branch. For
XMLParser, it gives the branch `master`.

| Step | Result |
|------|--------|
| `check` before | 2 unpinned, 1 unsupported (Cryptography, smalltalkhub), exit code 1 |
| `pin` | NeoJSON: `master` → `11e274dd96dc9636cab90929937b7cd09719de7c`<br>XMLParser: `master` → `26a888381174c154b02e908f27d9d5eead3d04ec` |
| `check` after | `3 reference(s), no unpinned GitHub baseline`, exit code 0 |

`diff -r` against the original showed that only the two `repository:` strings changed.
Cryptography was not touched:

```smalltalk
with: [ spec repository: 'github://svenvc/NeoJSON:11e274dd96dc9636cab90929937b7cd09719de7c/repository' "master" ].
'github://pharo-contributions/XML-XMLParser:26a888381174c154b02e908f27d9d5eead3d04ec/src' "master" ].
```

The SHAs match what `git ls-remote` reports:

```console
$ git ls-remote --symref https://github.com/svenvc/NeoJSON HEAD
ref: refs/heads/master	HEAD
11e274dd96dc9636cab90929937b7cd09719de7c	HEAD
$ git ls-remote https://github.com/pharo-contributions/XML-XMLParser refs/heads/master
26a888381174c154b02e908f27d9d5eead3d04ec	refs/heads/master
```

### Annotated tags

aws-sdk-smalltalk has no tag references, so we wrote a minimal `BaselineOfMyProject` that
names `github://newapplesho/google-cloud-smalltalk:v0.0.5/src`. `pin` replaced the tag with
`2edbfd56553373665b2796ddc333b43e743f8c8e` and added the comment "v0.0.5":

```console
$ git ls-remote https://github.com/newapplesho/google-cloud-smalltalk 'refs/tags/v0.0.5*'
390c1d92c856499b83f71c55195aedf7b21654b0	refs/tags/v0.0.5
2edbfd56553373665b2796ddc333b43e743f8c8e	refs/tags/v0.0.5^{}
```

`v0.0.5` is an annotated tag. `pin` writes the commit that the tag points to (`^{}`), not
the SHA of the tag object.

## lock

- On aws-sdk-smalltalk, `lock` lists 5 baselines in load order NeoJSON,
  BitmapCharacterSet, OrderPreservingDictionary, XMLWriter, XMLParser. XMLParser's
  dependencies come before it.
- We evaluated a two-step lock script with `CodeImporter evaluateFileNamed:` on Pharo
  12.0, 13.1 and 14.0. It used local Tonel projects: the root requires Mid, Mid requires
  Leaf, and Mid asks for a different Leaf repository (B) than the locked one (A). The
  result was `Leaf=A Mid=true Root=true`: loading the root afterwards did not replace the
  locked Leaf. [architecture.md](architecture.md#lock) compares this with a script that
  only locks and with no lock at all.

## Images

- We downloaded fresh images of Pharo 12.0, 13.1 and 14.0. On each, all 51 tests pass.
  We also ran the CLI on a copy of aws-sdk-smalltalk: `help`, an unknown command, `check`
  before and after `pin`, and `lock --output file`. All three versions gave the same exit
  codes.
- In Pharo 14, every command line goes to Clap, and Pharo no longer calls
  `CommandLineHandler` subclasses. Before we added `MPinClapCommand`, the tests passed on
  14 but Pharo rejected `metacello-pin` as an unknown command. Clap also rejects
  `lock --output=file`. `--output file` works on all three versions.
- On 12.0, 13.1 and 14.0, without a display, we opened the GUI with
  `MPinPresenter new open`, selected a baseline and pressed Lock from code. Save... was
  disabled before Lock and enabled after it, and the label said that the script was not
  saved. The item "Metacello Pin" is in the World menu under Library on all three. In the
  code, this menu is named `#Tools`, but Pharo shows it as "Library".
- On 13.1, without a display, we saved the window as images while we used a temporary
  baseline that names NeoYAML (branch `main`), google-cloud-smalltalk (tag `v0.0.5`) and
  a smalltalkhub project. Before a selection, Pin and Lock were disabled. After the
  selection, the status line said "2 unpinned, 1 unsupported". After Pin, it said
  "2 pinned now, 1 unsupported" and that only the image changed, and Pin was disabled
  again.
- `make load` reports 0 errors and 0 warnings. We check the warnings too, because a Tonel
  parse failure shows up only as a warning, and the method is then missing without any
  error.

## Facts checked in other projects' sources

| Claim | Where it was checked |
|-------|----------------------|
| Zinc resends `Authorization` to another host on redirect; `followRedirects: false` stops it | Two local `ZnServer`s; covered by `MPinGitHubResolverTest` |
| Dependabot updates the `# vX.Y.Z` comment next to a SHA pin | dependabot-core `version_commenter.rb` |
| smalltalkCI accepts `#include : { #packages : [...] }` | smalltalkCI README |
| smalltalkCI downloads a get.pharo.org script and runs it with `bash` | smalltalkCI `pharo/run.sh` |

## Not verified

- We have not loaded a dependency at a pinned SHA, or evaluated a lock script for real
  GitHub dependencies. Metacello accepts a commit SHA as the ref, but none of our runs
  loaded third-party code. To check it yourself:

  ```smalltalk
  Metacello new
  	baseline: 'NeoJSON';
  	repository: 'github://svenvc/NeoJSON:11e274dd96dc9636cab90929937b7cd09719de7c/repository';
  	load
  ```

- The CI workflow has not run on GitHub yet.
- Nobody has used the GUI on screen, including the Save... file dialog.
