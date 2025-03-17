.PHONY: test test-verbose lint all clean

all: lint test

test:
	@echo "Running tests..."
	@cd $(CURDIR) && FUNCTIONS_DIR="$(CURDIR)/functions" fish tests/test_auto_poetry.fish

test-verbose:
	@echo "Running tests with verbose output..."
	@cd $(CURDIR) && FUNCTIONS_DIR="$(CURDIR)/functions" fish tests/test_auto_poetry.fish

lint:
	@echo "Linting fish files..."
	@if command -v fish_indent >/dev/null; then \
		echo "Checking files with fish_indent"; \
		fish_indent -c functions/*.fish conf.d/*.fish completions/*.fish || exit 1; \
	else \
		echo "fish_indent not found, skipping lint"; \
	fi

clean:
	@echo "Cleaning up test artifacts..."
	@rm -rf /tmp/test_poetry_project /tmp/test_regular_dir /tmp/poetry_auto_test_cache

help:
	@echo "Available targets:"
	@echo "  make test         - Run tests (quietly)"
	@echo "  make test-verbose - Run tests with all output"
	@echo "  make lint         - Lint fish files"
	@echo "  make clean        - Clean up test artifacts"
	@echo "  make all          - Run all checks (default)"
	@echo "  make help         - Show this help"