#!/usr/bin/env bash
# Mirror upstream GNU screen's branches and tags into this repo, and leave our own
# branches (github, fix-*) alone.
#
# Usage: sync.sh <upstream url> <destination url>
# PUSH_TOKEN, when set, authenticates the push to github.com (the workflow passes
# GITHUB_TOKEN). Upstream branches and tags are force-updated, as a mirror should be;
# a branch that upstream deletes is reported, not deleted here.
set -euo pipefail
src=$1 dst=$2

# Branch names that belong to this repo; an upstream branch of the same name is skipped.
ours() { [[ $1 == github || $1 == fix-* ]]; }

GIT_DIR=$(mktemp -d)
export GIT_DIR
git init -q --bare "$GIT_DIR"
if [ -n "${PUSH_TOKEN:-}" ]; then
	git config http.https://github.com/.extraheader \
		"AUTHORIZATION: basic $(printf 'x-access-token:%s' "$PUSH_TOKEN" | base64 -w0)"
fi

# Savannah's git server sometimes answers 500; retry with a growing pause.
for try in 1 2 3 4 5; do
	git fetch -q "$src" '+refs/heads/*:refs/up/*' '+refs/tags/*:refs/tags/*' && break
	if [ "$try" = 5 ]; then
		echo "::error::fetching $src failed 5 times"
		exit 1
	fi
	echo "fetch failed (try $try), retrying in $((try * 30)) s"
	sleep $((try * 30))
done

specs=()
while read -r ref; do
	b=${ref#refs/up/}
	if ours "$b"; then
		echo "::warning::upstream has a branch '$b', a name this repo keeps for its own; not mirrored"
		continue
	fi
	specs+=("+$ref:refs/heads/$b")
done < <(git for-each-ref --format='%(refname)' refs/up/)
specs+=('+refs/tags/*:refs/tags/*')

echo "upstream: $(git for-each-ref refs/up/ | wc -l) branches, $(git for-each-ref refs/tags/ | wc -l) tags"
git push --porcelain "$dst" "${specs[@]}"

git ls-remote --heads "$dst" | while read -r _ ref; do
	b=${ref#refs/heads/}
	ours "$b" && continue
	git show-ref -q --verify "refs/up/$b" || echo "::notice::branch '$b' is gone upstream; kept here"
done
