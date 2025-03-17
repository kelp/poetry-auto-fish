function __poetry_auto_needs_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

function __poetry_auto_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if test $argv[1] = $cmd[2]
            return 0
        end
    end
    return 1
end

# Define subcommands
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a enable -d 'Enable poetry auto-activation'
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a disable -d 'Disable poetry auto-activation'
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a toggle -d 'Toggle poetry auto-activation'
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a status -d 'Show poetry auto-activation status'
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a verbose -d 'Toggle verbose mode'
complete -f -c poetry-auto -n '__poetry_auto_needs_command' -a cache -d 'Manage environment cache'

# Subcommand options
complete -f -c poetry-auto -n '__poetry_auto_using_command cache' -a clear -d 'Clear environment cache'
complete -f -c poetry-auto -n '__poetry_auto_using_command cache' -a status -d 'Show cache status'