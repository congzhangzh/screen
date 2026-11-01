# GNU Screen, mirrored on GitHub

This repository is a mirror of [GNU Screen](https://www.gnu.org/software/screen/), whose
canonical home is Savannah: <https://git.savannah.gnu.org/git/screen.git>. GitHub can only
fork repositories hosted on GitHub, so this is a mirror rather than a fork. It works the same
way otherwise: branches, compare views and pull requests between its own branches.

Bugs and patches for screen go upstream, to the
[Savannah bug tracker](https://savannah.gnu.org/bugs/?group=screen) or the
`screen-devel@gnu.org` mailing list. Pull requests here never reach the maintainers.

## Branches

| Branch | What it is |
|---|---|
| `screen-v5` | Upstream's development branch, with the 5.x releases |
| `master`, `screen-v4`, `next`, … | Upstream's other branches, as Savannah has them |
| tags `v.4.2.0` … `v.5.0.2` | Upstream's release tags |
| `fix-*` | Our fixes, each one topic on top of `screen-v5`, also reported upstream |
| `integration-screen` | `screen-v5` plus every `fix-*` branch, rebuilt whenever one of them or the base moves; what releases are built from |
| `release-YYYYMMDD.N` | A tested `integration-screen` commit, picked as a release; never moves |
| `github` (default) | This README, the workflows and the build scripts, no screen code |

Our fix branches:

| Branch | Base | Upstream report |
|---|---|---|
| `fix-addwindows-killed-window` | `screen-v5` | [bug #67589](https://savannah.gnu.org/bugs/?67589), probably also [#68648](https://savannah.gnu.org/bugs/?68648): crash when a window shown on two attached displays exits while `%-Lw`/`%+Lw` is in the hardstatus or caption |

## How the mirror stays current

[`.github/workflows/sync.yml`](.github/workflows/sync.yml) runs every six hours, and on
demand from the Actions tab. It runs [`.github/sync.sh`](.github/sync.sh), which:

1. fetches every branch and tag from Savannah, retrying when Savannah's server answers an
   error (it does now and then);
2. force-updates the same branches and tags here, so upstream's branches stay identical to
   Savannah's;
3. never touches `github`, `fix-*`, `integration-*` or `release-*`, even if upstream ever
   creates a branch of that name (the run logs a warning instead);
4. reports a branch that upstream deleted, but keeps it here.

Scheduled workflows run only from a repository's default branch. That is why the default
branch is `github` and not one of upstream's, whose history stays untouched.

Limits:
- Pushes made with the workflow's own token may not change files under `.github/workflows/`.
  Upstream has no such files today; if it ever adds some, the sync fails, and needs a token
  with the `workflow` scope.
- GitHub disables scheduled workflows in a public repository after 60 days without activity.
  If that happens, the Actions tab offers to enable it again.

## Releases

[Releases](../../releases) carry screen built for Debian testing/unstable (amd64), in two forms
from one build:

- `screen_<version>_amd64.deb`, which replaces Debian's package: `sudo apt install ./screen_….deb`;
- `screen-<version>-linux-amd64.tar.gz`, the same binary with its man page and encodings, for
  a prefix such as `~/.local` beside Debian's package (the release notes give the commands).

The version is `<upstream>+r<YYYYMMDD>.<N>-1`, e.g. `5.0.2+r20261101.1-1`: newer than Debian's
`5.0.2-1`, older than a future `5.0.3`, so apt replaces it once Debian ships a newer release.
The release tag is `r<YYYYMMDD>.<N>`; the branch `release-<YYYYMMDD>.<N>` points at the same
commit.

[`.github/workflows/release.yml`](.github/workflows/release.yml), started by hand from the
Actions tab (or `gh workflow run release.yml -f pick=true`), runs
[`ci/run.sh`](ci/run.sh) in a `debian:testing` container:

1. [`ci/build.sh`](ci/build.sh) builds the commit with Debian's packaging and flags (PAM,
   `/run/screen`, `/etc/screenrc`) and makes the tarball from the same build;
2. [`ci/build-control.sh`](ci/build-control.sh) builds plain upstream (`screen-v5`, without our
   fixes) as a control;
3. [`ci/test.sh`](ci/test.sh) runs [`ci/repro.py`](ci/repro.py) as a normal user: the build
   must survive 10 runs with two displays and 3 with one, and the control must crash at least
   once, or the test no longer reproduces the bug;
4. with `pick`, and only when every test passed,
   [`ci/publish-release.py`](ci/publish-release.py) makes a draft release with the assets,
   pushes `release-<YYYYMMDD>.<N>`, then publishes the release (which creates its tag), so a
   failure leaves at most a draft. Without `pick` the build is kept as a workflow artifact.

The packaging in [`packaging/debian`](packaging/debian) is Debian's screen 5.0.2-1
(<https://tracker.debian.org/pkg/screen>), unchanged except that its patch series drops the
five patches upstream `screen-v5` already has (91, 95, 98, 99, 100). The other 16 apply as
they are.
