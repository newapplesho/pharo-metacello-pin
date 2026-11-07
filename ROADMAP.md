# Roadmap

This page lists what `pharo-metacello-pin` does and what it does not do yet. A checked item
is covered by the tests in `src/MetacelloPin-Tests`, or we checked it by hand.
[docs/verification.md](docs/verification.md) lists the checks by hand, and what we have not
checked yet.

## Core
- [x] Parse repository descriptions such as `github://owner/project:ref/path`
      (`MPinReference`). Descriptions with characters outside `[A-Za-z0-9._-]` are rejected.
- [x] Treat everything from the network as untrusted (`docs/security.md`): parse Tonel
      without creating classes, accept only SHAs from the API, escape `"` in generated
      comments, never follow a redirect with the token, and stop `lock` after 500
      baselines.
- [x] Find each `spec repository: '...'` by parsing the method (`RBParser`), and take the
      project name from the enclosing `spec baseline: 'Name' with: [ ... ]`
      (`MPinScanner`).
- [x] Treat a reference as pinned only if its ref is a full 40-character commit SHA.
- [x] Get the commit SHA of a branch, a tag, or the default branch (when there is no ref)
      from the GitHub REST API, using `GITHUB_TOKEN` when it is set (`MPinGitHubResolver`).
- [x] Replace only the string, found by its position in the parsed method, and keep the
      original ref as a comment, e.g. `'github://o/p:<sha>/src' "v1.2.0"`. Running `pin`
      again changes nothing (`MPinPinner`).

## pin: rewriting baselines
- [x] Tonel files on disk: every `BaselineOf*.class.st` below a directory
      (`MPinTonelProject`).
- [x] Classes loaded in the image: `pin` recompiles each changed method in its protocol
      (`MPinImageProject`).

## lock: the whole dependency tree
- [x] Walk the dependency tree breadth-first: get each dependency's SHA, download its
      `BaselineOf<Name>` Tonel source at that SHA from `raw.githubusercontent.com`, and scan
      it for further dependencies (`MPinLocker`).
- [x] When two baselines ask for the same project, keep the first SHA (the one closest to
      the root) and report a different SHA as a `conflict:` warning.
- [x] Write a Metacello script that first locks every project, then loads them,
      dependencies first (`MPinLockfile`). Metacello skips a project that is only locked,
      so the script needs both steps.

## Interfaces
- [x] CLI: `metacello-pin check|pin|lock [dir] [--output file]` (`MPinCommand`, entry
      points `MPinCommandLineHandler` on Pharo 12/13 and `MPinClapCommand` on Pharo 14).
      `check` exits with status 1 when a reference is not pinned.
- [x] CI: smalltalkCI on Pharo 12, 13 and 14, and a CLI smoke test on Pharo 13 and 14
      (docs/development.md).
- [x] GUI: a Spec2 window with Refresh, Pin, Lock and Save... buttons, opened from the
      World menu (`Library > Metacello Pin`, `MPinPresenter`).
- [x] Pharo 12.0, 13.1 and 14.0.

## Repository kinds
- [ ] `gitlab://` and `bitbucket://`. `metacello-pin` parses them but reports them as
      `unsupported`.

## Spec forms
- [ ] `spec package: 'X' with: [ spec repository: ... ]`. `metacello-pin` reports it as
      `unsupported`.
- [ ] Platform blocks (`spec for: #gemstone do: [...]`). `metacello-pin` scans them like
      `#common` and does not filter by platform. As a result, `lock` also locks a
      dependency that only GemStone needs, and the lock script loads it on Pharo
      (`scripts/walkthrough-lock.st` shows this).

## Remote baselines (lock)
- [ ] Dependencies in private repositories. `lock` sends `GITHUB_TOKEN` only to the GitHub
      API, not to `raw.githubusercontent.com`. With a token, `lock` gets the SHA of a
      private dependency but cannot download its baseline, so it does not lock the
      dependency's own dependencies. The warning then says "only Tonel layout is
      supported", which is misleading.
- [ ] Dependencies stored in the FileTree layout (`BaselineOfX.package/.../baseline..st`).
      `lock` does not lock their own dependencies, and prints a warning instead.
- [ ] Find a dependency's source directory from its `.properties` or `.project` file,
      instead of relying on the path in the repository description.
- [ ] More choices when two baselines ask for different SHAs of the same project: prefer
      the newest, or fail (`--strict`).

## Pinning
- [ ] `--update`: move each pin to the latest tag.
- [ ] Put the matching tag in the comment when the ref is a branch or already a SHA. The
      comment is currently the branch name, or nothing for an existing pin.
- [ ] Short SHAs (`:abc1234`): treat them as pinned, or expand them to full SHAs.
- [ ] A verify mode that checks whether the ref in each comment still points to the
      pinned SHA.
- [ ] `--diff` or a dry run for `pin`, to show the changes without writing them.

## Lock file
- [ ] Load only what the root needs. The script loads each dependency's default group,
      even when the baseline that requires it uses `loads:`.

## GUI
- [ ] Call GitHub in a background process and show progress. The window currently stops
      responding until the calls finish.
- [ ] Pin only the selected rows.
- [ ] Save the lock script into the Iceberg repository of the baseline.
- [ ] Show the changes before recompiling.

## Security (see docs/security.md and docs/development.md)
- [ ] Download Pharo in `make setup` / CI from a pinned URL with a checksum instead of
      `curl https://get.pharo.org/... | bash`.
- [x] Write the lock file through a temporary file (`MPinLockfile>>writeTo:`), in the CLI
      and the GUI.

## Project
- [ ] A reusable GitHub Action (`uses: .../metacello-pin@<sha>`), so that other projects
      can run `metacello-pin check` without a Makefile.
