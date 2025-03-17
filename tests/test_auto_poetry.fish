#!/usr/bin/env fish

# Test auto_poetry functionality

# Initialize variables for testing
set -g POETRY_AUTO_DISABLE 0
set -g POETRY_AUTO_VERBOSE 1
set -g POETRY_AUTO_CACHE_DIR /tmp/poetry_auto_test_cache

# Ensure the cache directory exists
mkdir -p $POETRY_AUTO_CACHE_DIR

# Check if Poetry is available - this is critical for the tests
echo "Checking Poetry installation..."
if command -v poetry >/dev/null 2>&1
    echo "✅ Poetry is installed: "(poetry --version)
else
    echo "❌ ERROR: Poetry is not installed or not in PATH. Tests will fail!"
    echo "Please install Poetry first: https://python-poetry.org/docs/#installation"
    # We continue anyway to see the test output
end

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

# Create a temporary poetry project for testing
function setup_test_poetry_project
    echo "Creating test Poetry project..."
    cd /tmp/test_poetry_project
    
    # Initialize a real Poetry project
    command poetry init --name=test-project --description="Test project" --author="Test <test@example.com>" --no-interaction
    
    # Make sure we have a virtual environment
    command poetry install --no-root --no-ansi
    
    echo "Poetry project created and virtual environment initialized"
end

# Custom wrapper for source to log activations
function source
    echo "Sourcing: $argv[1]"
    
    # Track if we're activating a virtualenv
    if string match -q "*activate.fish" $argv[1]
        echo "Activating virtual environment"
    end
    
    # Use the real source command
    builtin source $argv
end

# Function to check if we're in a virtual environment
function is_in_venv
    if set -q VIRTUAL_ENV
        echo "In virtual environment: $VIRTUAL_ENV"
        return 0
    else
        echo "Not in a virtual environment"
        return 1
    end
end

# Setup real Poetry project
setup_test_poetry_project

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
    
    # Debug information
    echo "- Checking if poetry command is mocked correctly"
    if type -q poetry
        poetry --version
    else
        echo "- Poetry command not available"
    end
    
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

# Make sure we're not in a virtualenv before starting
if set -q VIRTUAL_ENV
    deactivate
end

setup_test
echo "Running auto_poetry in Poetry project directory"
auto_poetry

# Check if auto_poetry activated a virtualenv
if is_in_venv
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

# First, make sure we're in the poetry project with an active venv
cd /tmp/test_poetry_project
setup_test
auto_poetry

# Confirm we're in a virtualenv before leaving
is_in_venv

# Now change to a directory without a poetry project
echo "Changing to non-poetry directory"
cd /tmp/test_regular_dir
setup_test
auto_poetry

# Check if auto_poetry deactivated the virtualenv
if not set -q VIRTUAL_ENV
    echo "✅ Test 4 passed: Virtual environment deactivated"
else
    echo "❌ Test 4 failed: Virtual environment should be deactivated"
    cleanup
    exit 1
end

# Test 5: Disabled functionality
echo "Test 5: Disabled functionality"

# Make sure we're not in a virtualenv
if set -q VIRTUAL_ENV
    deactivate
end

# Disable auto-activation
set -g POETRY_AUTO_DISABLE 1
cd /tmp/test_poetry_project
setup_test
echo "Running auto_poetry with POETRY_AUTO_DISABLE=1"
auto_poetry

# Check that auto_poetry didn't activate the virtualenv
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
