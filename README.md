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
| `integration-screen` | `screen-v5` plus every `fix-*` branch, rebuilt whenever one of them or the base moves; what releases are picked from |
| `release-YYYYMMDD.N` | A tested `integration-screen` commit, picked as a release and pinned by the kit; never moves |
| `github` (default) | This README and the sync workflow, no screen code |

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

Releases are built, tested and published by
[screen-release-kit](https://github.com/congzhangzh/screen-release-kit): it pins a
`release-YYYYMMDD.N` commit of this mirror and turns it into a Debian package and a binary
tarball. This repository keeps only screen itself; the kit's README explains the flow from a
`fix-*` branch to a release.

The first release, [r20261101.1](../../releases/tag/r20261101.1) (`5.0.2+r20261101.1-1`), was
published from here before the kit existed, by a workflow that has since moved to the kit;
its tag and assets stay here.
