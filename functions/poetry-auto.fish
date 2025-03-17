function poetry-auto --description "Manage Poetry auto-activation"
    # No arguments shows status
    if test (count $argv) -eq 0
        poetry-auto status
        return
    end

    switch $argv[1]
        case enable
            set -g POETRY_AUTO_DISABLE 0
            echo "Poetry auto-activation enabled"

        case disable
            set -g POETRY_AUTO_DISABLE 1
            if set -q VIRTUAL_ENV
                echo "Deactivating current environment"
                deactivate
            end
            echo "Poetry auto-activation disabled"

        case toggle
            if test "$POETRY_AUTO_DISABLE" = 1
                poetry-auto enable
            else
                poetry-auto disable
            end

        case verbose
            if test "$POETRY_AUTO_VERBOSE" = 1
                set -g POETRY_AUTO_VERBOSE 0
                echo "Verbose mode disabled"
            else
                set -g POETRY_AUTO_VERBOSE 1
                echo "Verbose mode enabled"
            end

        case status
            echo "Poetry auto-activation: "(test "$POETRY_AUTO_DISABLE" = 1 && echo "disabled" || echo "enabled")
            echo "Verbose mode: "(test "$POETRY_AUTO_VERBOSE" = 1 && echo "enabled" || echo "disabled")
            echo "Cache directory: $POETRY_AUTO_CACHE_DIR"
            if set -q VIRTUAL_ENV
                echo "Current environment: $VIRTUAL_ENV"
                if set -q POETRY_PROJECT
                    echo "Poetry project: $POETRY_PROJECT"
                end
            else
                echo "No active environment"
            end

        case cache
            # Handle cache subcommands
            if test (count $argv) -eq 1
                echo "Usage: poetry-auto cache [status|clear]"
                return 1
            end

            switch $argv[2]
                case status
                    echo "Cache directory: $POETRY_AUTO_CACHE_DIR"
                    if test -d "$POETRY_AUTO_CACHE_DIR"
                        echo "Cache entries: "(find "$POETRY_AUTO_CACHE_DIR" -type f | wc -l | string trim)
                        echo "Cache size: "(du -sh "$POETRY_AUTO_CACHE_DIR" | cut -f1)
                    else
                        echo "Cache directory does not exist"
                    end

                case clear
                    if test -d "$POETRY_AUTO_CACHE_DIR"
                        rm -rf "$POETRY_AUTO_CACHE_DIR"/*
                        mkdir -p "$POETRY_AUTO_CACHE_DIR"
                        echo "Cache cleared"
                    else
                        echo "Cache directory does not exist"
                    end

                case '*'
                    echo "Unknown cache subcommand: $argv[2]"
                    echo "Usage: poetry-auto cache [status|clear]"
                    return 1
            end

        case help '*'
            echo "poetry-auto: Manage Poetry environment auto-activation"
            echo
            echo "Usage:"
            echo "  poetry-auto                Show current status"
            echo "  poetry-auto enable         Enable auto-activation"
            echo "  poetry-auto disable        Disable auto-activation"
            echo "  poetry-auto toggle         Toggle auto-activation"
            echo "  poetry-auto verbose        Toggle verbose mode"
            echo "  poetry-auto status         Show detailed status"
            echo "  poetry-auto cache status   Show cache status"
            echo "  poetry-auto cache clear    Clear environment cache"
            echo "  poetry-auto help           Show this help"
    end
end
