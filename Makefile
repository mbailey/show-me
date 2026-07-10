.PHONY: test lint release help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  test                       Run tests"
	@echo "  lint                       Run shellcheck on bin/ and tests/"
	@echo "  release BUMP=patch|minor|major|X.Y.Z"
	@echo "                             Atomically bump version in bin/show-me + plugin.json,"
	@echo "                             update CHANGELOG, commit, tag, push (default: patch)"
	@echo "  help                       Show this help"

test:
	@bash tests/test_show.sh

# Lint shell scripts. Treat shellcheck as optional (some environments
# don't have it) but fail the target if it's installed and reports issues.
# bin/show-me and bin/look-at are symlinks -- shellcheck the canonical
# scripts under skills/*/scripts/ they point to. bin/show no longer
# exists (deleted in 97d06f5); bin/release is a real script.
# --severity=warning filters pre-existing SC2016 info-level notices in
# tests/test_show.sh (literal `$var` inside single-quoted grep patterns,
# not real expansion bugs) so the guard only fails on real problems.
lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		shellcheck --severity=warning skills/show-me/scripts/show-me skills/look-at/scripts/look-at bin/release tests/test_show.sh && \
		echo "shellcheck: clean"; \
	else \
		echo "shellcheck not installed — skipping (install with 'brew install shellcheck')"; \
	fi

# Atomic version bump: updates VERSION in bin/show-me AND .version in plugin.json
# in a single commit. See RELEASING.md.
release:
	@bash bin/release $(or $(BUMP),patch)
