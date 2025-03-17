function auto_poetry --description "Auto-activate Poetry environments"
    # Skip during fish initialization to avoid messing up the prompt
    status --is-command-substitution; and return

    # Return if disabled
    if test "$POETRY_AUTO_DISABLE" = 1
        return
    end

    # Define cache file path
    set -l cache_dir "$POETRY_AUTO_CACHE_DIR"
    set -l cache_file "$cache_dir/path_cache.fish"

    # Check if Poetry is installed
    if not command -sq poetry
        test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Poetry not installed"
        return
    end

    # Make sure the POETRY_AUTO_CACHE_DIR exists
    if not set -q POETRY_AUTO_CACHE_DIR
        set -g POETRY_AUTO_CACHE_DIR "$HOME/.cache/poetry_auto"
    end
    mkdir -p "$cache_dir" 2>/dev/null

    # Check for direnv managed environment
    if set -q DIRENV_DIR; and test -f .envrc
        # Skip if direnv is managing a Poetry environment
        if grep -q poetry .envrc 2>/dev/null
            test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Direnv is managing this environment"
            return
        end
    end

    # Check if we're already in a virtual environment
    if set -q VIRTUAL_ENV
        # If we moved out of the project directory, deactivate
        if not test -f pyproject.toml
            test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Leaving Poetry project, deactivating"
            deactivate
            # Clear cache for this path when deactivating
            if test -f "$cache_file"
                rm "$cache_file" 2>/dev/null
            end
        end
        return
    end

    # Return if no pyproject.toml exists
    if not test -f pyproject.toml
        return
    end

    # Get directory hash for caching
    set -l dir_hash (pwd | shasum -a 256 | string split ' ' | head -n1)

    # Check if we have a cache for this directory
    if test -f "$cache_file"
        set -l cached_hash (head -n1 "$cache_file")
        set -l cached_path (tail -n1 "$cache_file")

        if test "$cached_hash" = "$dir_hash"; and test -f "$cached_path/bin/activate.fish"
            # Use cached virtual environment path
            test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Using cached environment at $cached_path"
            source "$cached_path/bin/activate.fish"

            # Set poetry project name for prompt customization
            set -l project_name (grep "name = " pyproject.toml | head -n 1 | sed -E 's/name = "([^"]*)"/\1/g' 2>/dev/null)
            set -g POETRY_PROJECT "$project_name"
            return
        end
    end

    # Optimize Poetry project detection with caching
    if test -f pyproject.toml
        if not set -q __fish_poetry_detected
            if grep -q "\[tool.poetry\]" pyproject.toml 2>/dev/null
                set -g __fish_poetry_detected 1
            else
                test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Not a Poetry project"
                set -g __fish_poetry_detected 0
                return
            end
        else if test "$__fish_poetry_detected" = 0
            return
        end
    end

    # Make sure we don't show output during activation
    set -l old_value $VIRTUAL_ENV_DISABLE_PROMPT
    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

    # First check for .venv in project directory
    if test -d .venv -a -f .venv/bin/activate.fish
        # Activate the virtual environment - this sets VIRTUAL_ENV
        test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Activating local .venv"
        source .venv/bin/activate.fish

        # Save to cache
        mkdir -p "$cache_dir"
        echo -e "$dir_hash\n"(pwd)"/.venv" >"$cache_file"

        # Set poetry project name for prompt customization
        set -l project_name (grep "name = " pyproject.toml | head -n 1 | sed -E 's/name = "([^"]*)"/\1/g' 2>/dev/null)
        set -g POETRY_PROJECT "$project_name"

        # Restore original setting
        if set -q old_value
            set -gx VIRTUAL_ENV_DISABLE_PROMPT $old_value
        else
            set -e VIRTUAL_ENV_DISABLE_PROMPT
        end
        return
    end

    # Try to get the project name if not in the project dir
    set -l project_name (grep "name = " pyproject.toml | head -n 1 | sed -E 's/name = "([^"]*)"/\1/g' 2>/dev/null)
    if test -z "$project_name"
        test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Could not determine project name"
        # Restore original setting
        if set -q old_value
            set -gx VIRTUAL_ENV_DISABLE_PROMPT $old_value
        else
            set -e VIRTUAL_ENV_DISABLE_PROMPT
        end
        return
    end

    # Then try `poetry env info` to locate the virtualenv
    test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Looking up Poetry environment"
    set -l poetry_env_path (poetry env info -p 2>/dev/null)
    if test -n "$poetry_env_path" -a -f "$poetry_env_path/bin/activate.fish"
        # Activate the virtual environment - this sets VIRTUAL_ENV
        test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: Activating Poetry environment at $poetry_env_path"
        source "$poetry_env_path/bin/activate.fish"

        # Save to cache
        mkdir -p "$cache_dir"
        echo -e "$dir_hash\n$poetry_env_path" >"$cache_file"

        # Set poetry project name for prompt customization
        set -g POETRY_PROJECT "$project_name"

        # Restore original setting
        if set -q old_value
            set -gx VIRTUAL_ENV_DISABLE_PROMPT $old_value
        else
            set -e VIRTUAL_ENV_DISABLE_PROMPT
        end
        return
    end

    test "$POETRY_AUTO_VERBOSE" = 1; and echo "poetry-auto: No Poetry environment found"

    # Restore original setting if we didn't return earlier
    if set -q old_value
        set -gx VIRTUAL_ENV_DISABLE_PROMPT $old_value
    else
        set -e VIRTUAL_ENV_DISABLE_PROMPT
    end
end
