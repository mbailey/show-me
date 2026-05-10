.PHONY: test lint release help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  test                       Run tests"
	@echo "  lint                       Run shellcheck on bin/ and tests/"
	@echo "  release BUMP=patch|minor|major|X.Y.Z"
	@echo "                             Atomically bump version in bin/show + plugin.json,"
	@echo "                             update CHANGELOG, commit, tag, push (default: patch)"
	@echo "  help                       Show this help"

test:
	@bash tests/test_show.sh

# Lint shell scripts. Treat shellcheck as optional (some environments
# don't have it) but fail the target if it's installed and reports issues.
lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		shellcheck bin/show bin/look bin/release tests/test_show.sh; \
		echo "shellcheck: clean"; \
	else \
		echo "shellcheck not installed — skipping (install with 'brew install shellcheck')"; \
	fi

# Atomic version bump: updates VERSION in bin/show AND .version in plugin.json
# in a single commit. See RELEASING.md.
release:
	@bash bin/release $(or $(BUMP),patch)
