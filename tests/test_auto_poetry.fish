#!/usr/bin/env fish

# Test auto_poetry functionality

# Initialize variables for testing
set -g POETRY_AUTO_DISABLE 0
set -g POETRY_AUTO_VERBOSE 1
set -g POETRY_AUTO_CACHE_DIR /tmp/poetry_auto_test_cache

# Setup test environment
mkdir -p /tmp/test_poetry_project /tmp/test_regular_dir "$POETRY_AUTO_CACHE_DIR"

# Create a mock pyproject.toml file
echo "[tool.poetry]
name = \"test-project\"
version = \"0.1.0\"
description = \"Test project for poetry-auto\"
authors = [\"Test <test@example.com>\"]
" >/tmp/test_poetry_project/pyproject.toml

# Clean up function
function cleanup
    rm -rf /tmp/test_poetry_project /tmp/test_regular_dir "$POETRY_AUTO_CACHE_DIR"
    set -e POETRY_AUTO_DISABLE
    set -e POETRY_AUTO_VERBOSE
    set -e POETRY_AUTO_CACHE_DIR
    if set -q VIRTUAL_ENV
        deactivate
    end
end

# Mock deactivate function for tests
function deactivate
    set -e VIRTUAL_ENV
    set -e POETRY_PROJECT
    echo "Mock deactivate called"
end

# Mock poetry command
function poetry
    if test "$argv[1]" = env -a "$argv[2]" = info -a "$argv[3]" = -p
        # Create a mock virtual env structure for testing
        mkdir -p /tmp/mock_poetry_venv/bin
        echo "# Mock activate script" > /tmp/mock_poetry_venv/bin/activate.fish
        echo /tmp/mock_poetry_venv
        return 0
    end
    return 1
end

# Mock source for .venv activation
function source
    if string match -q "*activate.fish" $argv[1]
        set -g VIRTUAL_ENV (dirname (dirname $argv[1]))
        echo "Mock source called with $argv[1]"
        echo "VIRTUAL_ENV set to $VIRTUAL_ENV"
        return 0
    end
    # Otherwise pass to real source
    builtin source $argv
end

# Create test .venv for project directory
mkdir -p /tmp/test_poetry_project/.venv/bin
echo "# Mock activate script" > /tmp/test_poetry_project/.venv/bin/activate.fish

echo "=== Poetry Auto Fish Tests ==="

# Function to set up the test environment
function setup_test
    # Clear any existing state
    if functions -q auto_poetry
        functions -e auto_poetry
    end
    
    # Source the function from the FUNCTIONS_DIR environment variable
    # This is set by the Makefile to point to the correct location
    if not set -q FUNCTIONS_DIR
        echo "ERROR: FUNCTIONS_DIR environment variable not set"
        exit 1
    end
    
    echo "Sourcing from: $FUNCTIONS_DIR/auto_poetry.fish"
    source $FUNCTIONS_DIR/auto_poetry.fish
    
    # Print debug information
    echo "- POETRY_AUTO_CACHE_DIR: $POETRY_AUTO_CACHE_DIR"
    echo "- Current directory: "(pwd)
    if test -f pyproject.toml
        echo "- pyproject.toml exists"
        head -n 3 pyproject.toml
    else
        echo "- No pyproject.toml in current directory"
    end
end

# Test 1: No pyproject.toml
echo "Test 1: Regular directory (no pyproject.toml)"
cd /tmp/test_regular_dir
setup_test
auto_poetry
if set -q VIRTUAL_ENV
    echo "❌ Test 1 failed: Virtual environment should not be activated"
    cleanup
    exit 1
else
    echo "✅ Test 1 passed: No virtual environment activated"
end

# Test 2: With pyproject.toml (Poetry project)
echo "Test 2: Poetry project directory"
cd /tmp/test_poetry_project
setup_test
auto_poetry
if test -n "$VIRTUAL_ENV"
    echo "✅ Test 2 passed: Virtual environment activated"
else
    echo "❌ Test 2 failed: Virtual environment should be activated"
    cleanup
    exit 1
end

# Test 3: Cache functionality
echo "Test 3: Cache functionality"
set -l cache_file "$POETRY_AUTO_CACHE_DIR/path_cache.fish"
if test -f "$cache_file"
    echo "✅ Test 3 passed: Cache file created"
else
    echo "❌ Test 3 failed: Cache file not created"
    cleanup
    exit 1
end

# Test 4: Deactivation when leaving project
echo "Test 4: Deactivation when leaving directory"
cd /tmp/test_regular_dir
setup_test
auto_poetry
if not set -q VIRTUAL_ENV
    echo "✅ Test 4 passed: Virtual environment deactivated"
else
    echo "❌ Test 4 failed: Virtual environment should be deactivated"
    cleanup
    exit 1
end

# Test 5: Disabled functionality
echo "Test 5: Disabled functionality"
set -g POETRY_AUTO_DISABLE 1
cd /tmp/test_poetry_project
setup_test
auto_poetry
if not set -q VIRTUAL_ENV
    echo "✅ Test 5 passed: Auto-activation disabled correctly"
else
    echo "❌ Test 5 failed: Auto-activation should be disabled"
    cleanup
    exit 1
end

# Cleanup
cleanup
echo "All tests completed successfully!"
