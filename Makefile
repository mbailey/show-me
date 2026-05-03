.PHONY: test release help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  test                       Run tests"
	@echo "  release BUMP=patch|minor|major|X.Y.Z"
	@echo "                             Atomically bump version in bin/show + plugin.json,"
	@echo "                             update CHANGELOG, commit, tag, push (default: patch)"
	@echo "  help                       Show this help"

test:
	@bash tests/test_show.sh

# Atomic version bump: updates VERSION in bin/show AND .version in plugin.json
# in a single commit. See RELEASING.md.
release:
	@bash bin/release $(or $(BUMP),patch)
