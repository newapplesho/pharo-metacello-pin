# Security

`metacello-pin` writes code. It rewrites baselines and generates a script that users
evaluate, and part of that code comes from outside: GitHub API answers, and the baselines
of other projects that `lock` downloads. This page lists which inputs `metacello-pin`
trusts, the threats from the others, and what the code does about each threat. A ✓ means
that `MPinSecurityTest` or `MPinTonelProjectTest` tests the countermeasure.

## Trust boundaries

| Input | Trusted? | What `metacello-pin` does with it |
|-------|----------|-----------------------------------|
| Your own `BaselineOf*` sources | yes | Scans them and rewrites them |
| GitHub API answers (SHA, default branch) | no | Writes them into your sources and the lock script |
| Remote `BaselineOf*.class.st` (during `lock`) | no | Parses them, follows their references and writes those into the lock script |
| `GITHUB_TOKEN` | secret | Sends it to `api.github.com` and nowhere else |

## Threats and countermeasures

| Threat | Countermeasure | Where | Test |
|--------|----------------|-------|------|
| Remote Tonel metadata creates instances of any class it names (`STON fromString:` resolves any class name) | `metacello-pin` parses Tonel with `MPinSafeTonelParser`. Its `MPinSafeSTONReader` refuses class references | `MPinSafeSTONReader>>lookupClass:` | ✓ |
| A branch or project name containing `"` closes the generated comment and injects code into the baseline or lock script | `MPinOccurrence class>>commentFor:` replaces `"` in every comment that `metacello-pin` writes | `MPinOccurrence>>pinnedLiteral`, `MPinLockEntry>>print:on:`, `MPinLockfile>>script` | ✓ |
| An API answer that is not a SHA ends up in a string literal | `MPinResolver>>resolve:` accepts only 40-character hex SHAs. `metacello-pin` writes URLs with `printString`, which escapes quotes | `MPinResolver>>resolve:` | ✓ |
| The owner, project, ref or path in a remote baseline changes the authenticated API request (with `..`, `?`, `#` or `%`) | `isWellFormed` accepts only parts made of `[A-Za-z0-9._-]` without `..`, and `unsupportedReason` accepts only baseline names made of `[A-Za-z0-9]`. Letters outside ASCII, such as `é`, are rejected too. `metacello-pin` reports anything else as unsupported and never requests it | `MPinReference>>isWellFormed`, `MPinOccurrence>>unsupportedReason` | ✓ |
| Zinc resends `Authorization` when following a redirect, even to another host (tested: a local server on another port received `Bearer …`) | The resolver does not follow redirects on authenticated API requests | `MPinGitHubResolver>>apiGet:accept:` | ✓ |
| A remote dependency tree makes `lock` send an unlimited number of requests | The locker stops after 500 baselines and prints a warning | `MPinLocker>>maxEntries:` | ✓ |
| `pin` also rewrites the same URL in a comment or another string (and a `"` inserted into a Tonel comment breaks the file) | The pinner replaces each string at its position in the parsed method. `MPinTonelProject` replaces a method body in the file only when the body occurs exactly once | `MPinPinner`, `MPinTonelProject>>replaceBody:with:in:occurrences:` | ✓ |
| A failed write leaves a truncated baseline or lock file | `metacello-pin` writes `<file>.metacello-pin.tmp` first, then moves it over the original | `MPinTonelProject>>write:to:`, `MPinLockfile>>writeTo:` | Partly: the test checks only that no temporary file is left |

`metacello-pin` never evaluates code that it downloads. It only parses remote sources, with
`RBParser` and the safe Tonel parser.

## What you still need to do

- Review the lock script and pinned diffs like any other code change before you evaluate
  or merge them. A pin records whatever the ref pointed to at that moment.
- A pinned SHA always gives you the same code, but it says nothing about whether that code
  is safe.
- `GITHUB_TOKEN` only needs read access. Do not save an image after setting a token with
  `MPinGitHubResolver>>token:`: the token stays in the image file, and anyone who gets the
  file can read it. Prefer the `GITHUB_TOKEN` environment variable.

This page is about using `metacello-pin`. [development.md](development.md#ci) describes
how the CI of this repository is protected.
