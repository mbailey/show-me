# Releasing show-me

show-me's version lives in two places that MUST stay in sync:

- `.claude-plugin/plugin.json` -- `.version` (read by Claude Code plugin loader)
- `bin/show` -- `VERSION="X.Y.Z"` constant (printed by `show --version`)

Historically these drifted (see SHOW-64: bin/show was stuck at `1.4.0` from
v2.0.0 through v2.3.0 because plugin.json was bumped automatically while the
shell constant was not). The release flow now updates both atomically.

## Contract

**Do NOT edit `VERSION` in `bin/show` or `.version` in `plugin.json` by hand.**
The `bin/release` script (invoked via `make release`) is the single source of
truth for bumping both files. A drift assertion in `tests/test_show.sh`
backstops this -- `make test` fails fast if the two ever disagree.

## Cutting a release

```bash
make release                  # patch bump (X.Y.Z -> X.Y.Z+1) -- default
make release BUMP=minor       # minor bump
make release BUMP=major       # major bump
make release BUMP=2.4.0       # explicit version
```

The flow:

1. Refuses to run on a dirty working tree.
2. Updates `.claude-plugin/plugin.json` (`jq` -> temp file -> `mv`).
3. Updates `bin/show` `VERSION="..."` line (`sed -i`, BSD-compatible on macOS).
4. Promotes `## [Unreleased]` in `CHANGELOG.md` to `## [X.Y.Z] - YYYY-MM-DD` and
   inserts a fresh `## [Unreleased]` above it.
5. Runs `make test` -- the drift check is one of the assertions, so the release
   cannot ship if the bump didn't take.
6. `git add` plugin.json + bin/show (+ CHANGELOG.md if updated).
7. `git commit -m "Release vX.Y.Z"` -- single atomic commit.
8. `git tag -a vX.Y.Z` and `git push` (commits and tags).

## Dry-run

To validate the bump without committing or pushing:

```bash
bin/release --dry-run 2.4.0
```

This applies the file edits and runs tests, but skips the git commit/tag/push.
Use `git diff` to inspect, then `git checkout -- bin/show .claude-plugin/plugin.json CHANGELOG.md`
to revert.
