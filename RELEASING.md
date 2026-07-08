# Releasing show-me

show-me's version lives in two places that MUST stay in sync:

- `.claude-plugin/plugin.json` -- `.version` (read by Claude Code plugin loader)
- `bin/show-me` -- `VERSION="X.Y.Z"` constant (printed by `show-me --version`)

Historically these drifted (see SHOW-64: the show binary's `VERSION` was stuck
at `1.4.0` from v2.0.0 through v2.3.0 because plugin.json was bumped
automatically while the shell constant was not). The release flow now updates
both atomically. (The binary was `bin/show` until SHOW-58 renamed it to
`bin/show-me`.)

## Contract

**Do NOT edit `VERSION` in `bin/show-me` or `.version` in `plugin.json` by hand.**
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
2. **Minor-bump nudge**: if `## [Unreleased]` has an `### Added` section (i.e.
   features shipped) but you're cutting a *patch*, it stops and asks you to
   confirm -- SemVer wants a minor for new features. Re-run with `BUMP=minor`,
   or pass `--allow-patch` to force the patch. (v3.0.3 shipped features as a
   patch; this guards the next one.)
3. Updates `.claude-plugin/plugin.json` (`jq` -> temp file -> `mv`).
4. Updates the canonical `skills/show-me/scripts/show-me` `VERSION="..."` line.
   `bin/show-me` is a symlink to that script, so the release resolves the
   symlink first and writes the real file (temp file -> `mv`, BSD/macOS-safe) --
   the symlink itself is preserved, never clobbered into a copy.
5. Promotes `## [Unreleased]` in `CHANGELOG.md` to `## [X.Y.Z] - YYYY-MM-DD` and
   inserts a fresh `## [Unreleased]` above it.
6. Runs `make test` -- the drift check is one of the assertions, so the release
   cannot ship if the bump didn't take.
7. `git add` plugin.json + the canonical script (+ CHANGELOG.md if updated).
8. `git commit -m "Release vX.Y.Z"` -- single atomic commit.
9. `git tag -a vX.Y.Z`, `git push` to `origin` (commits + tags), then mirrors the
   branch + tags to the `github` remote if one exists (non-fatal -- a mirror
   failure warns but doesn't fail the release, which is already live on origin).

## Dry-run

To validate the bump without committing or pushing:

```bash
bin/release --dry-run 2.4.0
```

This applies the file edits and runs tests, but skips the git commit/tag/push.
Use `git diff` to inspect, then `git checkout -- bin/show-me .claude-plugin/plugin.json CHANGELOG.md`
to revert.
