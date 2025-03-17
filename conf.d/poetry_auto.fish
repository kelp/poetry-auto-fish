# poetry-auto: Auto-activate Poetry environments when changing directories
#
# Configuration variables (can be set in config.fish):
# - POETRY_AUTO_DISABLE    Set to 1 to disable auto-activation completely
# - POETRY_AUTO_VERBOSE    Set to 1 to enable debug output
# - POETRY_AUTO_CACHE_DIR  Set to override the cache directory

# Skip during non-interactive sessions
status is-interactive; or exit 0

# Set default configuration if not already set
set -q POETRY_AUTO_DISABLE; or set -g POETRY_AUTO_DISABLE 0
set -q POETRY_AUTO_VERBOSE; or set -g POETRY_AUTO_VERBOSE 0
set -q POETRY_AUTO_CACHE_DIR; or set -g POETRY_AUTO_CACHE_DIR "$HOME/.cache/poetry_venv"

# Only register hooks if not disabled
if test "$POETRY_AUTO_DISABLE" != 1
    # Function to run auto_poetry when directory changes (PWD variable)
    function _run_auto_poetry --on-variable PWD
        auto_poetry
    end

    # Run for the current directory on shell startup
    auto_poetry
end
