# CLAUDE.md

This file stores frequently used commands, code style preferences, and important information about the codebase structure.

## Build and Test Commands
- `make test` - Run all tests
- `make test-verbose` - Run tests with verbose output
- `cd $(CURDIR) && FUNCTIONS_DIR="$(CURDIR)/functions" fish tests/test_auto_poetry.fish` - Run tests directly
- `make lint` - Run fish_indent to check code style
- `make clean` - Clean up test artifacts
- `make all` - Run both tests and linting

## Code Style Preferences
- Use fish_indent for consistent formatting of fish files
- Functions should have descriptive names and --description comments
- Prefer conditional expressions with `test` instead of `[` or `[[`
- Use $variable for variables and test "$variable" = value for comparisons
- Use `and` and `or` for control flow instead of `&&` and `||`
- Keep indentation consistent with 4 spaces
- Prefer single-quotes for strings without variable interpolation

## Codebase Structure
- `functions/` - Contains fish functions
- `conf.d/` - Fish configuration files, loads on shell start
- `completions/` - Fish command completions
- `tests/` - Test suite