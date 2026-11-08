# Development

This page is for people who work on `pharo-metacello-pin` itself. Users of the tool do not
need it.

## Local setup

```sh
make setup   # download Pharo 13 into pharo-local/
make load    # load src/ into the image
make test
make lint
make check DIR=../src
```

`make setup PHARO_VERSION=140` downloads Pharo 14 instead. `make load` should report no
warnings: a Tonel parse failure shows up only as a warning, and the method is then missing
without any error.

`make lint` runs the lint rules that the System Browser shows under the code (Renraku) on
every class of this project, in the image. Run `make load` first. `scripts/lint.st` skips
a few rules that do not fit this project, each with its reason, and exits with status 1
when any other rule finds something.

## Following the code in the debugger

Two Playground scripts run the code on sample data, without the network and without
changing any class in the image. Paste one into a Playground (`make ui`, then Ctrl+O, W),
select everything and choose Debug it (Ctrl+Shift+D) to step through it, or Print it
(Ctrl+P) to see the result.

- `scripts/walkthrough.st` scans, pins and locks one sample baseline. The comments say which
  line to step Into to reach `MPinScanner`, `MPinPinner` and `MPinLocker`.
- `scripts/walkthrough-lock.st` builds a small dependency tree and shows how `lock` follows
  it: dependencies of dependencies, a version conflict, a baseline it cannot read, the load
  order, and a dependency that only GemStone needs.

## CI

The CI workflow (`.github/workflows/ci.yml`) has two jobs:

- `build` runs the tests with smalltalkCI on Pharo 12, 13 and 14.
- `cli` runs `metacello-pin help` and `metacello-pin check` on this repository with Pharo
  13 and 14, the same way users run them.

The workflow runs code from outside this repository: the GitHub Actions it uses and the
Pharo download script. This repository applies the same rule to its CI that
`metacello-pin` applies to Metacello baselines: depend on fixed commits, not on refs that
can move.

- Every action is pinned to a commit SHA, with the version as a comment
  (`actions/checkout@3d3c42e5… # v7.0.1`). Dependabot updates the SHA and the comment
  together.
- The workflow sets `permissions: {}`, and each job asks only for `contents: read`. The
  checkout does not keep the token (`persist-credentials: false`).

One gap remains (see [ROADMAP.md](../ROADMAP.md)). `make setup` runs
`curl https://get.pharo.org/64/130+vm | bash`, and smalltalkCI downloads the same kind of
get.pharo.org script and runs it with `bash` (`pharo/run.sh`). Neither download is pinned
or checked against a checksum.
