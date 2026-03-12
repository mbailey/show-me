.PHONY: test release help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  test      Run tests"
	@echo "  release   Create a new release (bump version, commit, tag, push)"
	@echo "  help      Show this help"

test:
	@bash tests/test_show.sh

release:
	@claude-plugin-release
