# poetry-auto-fish 🐟+📜

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI Status](https://github.com/kelp/poetry-auto-fish/actions/workflows/test.yml/badge.svg)](https://github.com/kelp/poetry-auto-fish/actions)
[![Fisher Plugin](https://img.shields.io/badge/Fisher-Plugin-00AEEF.svg)](https://github.com/jorgebucaran/fisher)

> Automatically activate Poetry environments when changing directories in fish shell

This plugin automatically detects and activates Poetry virtual environments when you change into a Poetry project directory, and deactivates them when you leave. It's fast, efficient, and configurable.

## Features

- **Automatic activation/deactivation** of Poetry environments
- **Smart caching** to avoid slow `poetry env info` calls
- **Compatible** with direnv and other environment managers
- **Customizable** with options to disable or enable verbose mode
- **CLI management tool** to control all aspects of auto-activation

## Installation

### Using [Fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher install kelp/poetry-auto-fish
```

### Manually

```fish
git clone https://github.com/kelp/poetry-auto-fish.git
cp -r poetry-auto-fish/functions/ ~/.config/fish/functions/
cp -r poetry-auto-fish/conf.d/ ~/.config/fish/conf.d/
cp -r poetry-auto-fish/completions/ ~/.config/fish/completions/
```

## Usage

Once installed, poetry-auto-fish works immediately without any configuration. It will:

1. Automatically detect Poetry projects (directories with `pyproject.toml` and `[tool.poetry]` section)
2. Activate the appropriate virtual environment when you enter a project directory
3. Deactivate the environment when you leave the project directory

### CLI Commands

The plugin provides a `poetry-auto` command for control:

```fish
# Show current status
poetry-auto status

# Disable auto-activation
poetry-auto disable

# Enable auto-activation
poetry-auto enable

# Toggle verbose output (for debugging)
poetry-auto verbose

# Clear the environment cache
poetry-auto cache clear
```

## Configuration

You can configure the plugin by setting these variables in your `config.fish`:

```fish
# Disable auto-activation
set -g POETRY_AUTO_DISABLE 1

# Enable verbose output
set -g POETRY_AUTO_VERBOSE 1

# Change cache directory
set -g POETRY_AUTO_CACHE_DIR "$HOME/.cache/custom-poetry-path"
```

## Prompt Integration

poetry-auto-fish sets a `POETRY_PROJECT` global variable with the active project name. You can use this in your prompt:

```fish
function fish_prompt
    # Your existing prompt code
    
    if set -q POETRY_PROJECT
        echo -n " 📜($POETRY_PROJECT)"
    end
    
    # Rest of your prompt
end
```

## Performance

The plugin uses smart caching to avoid repeated slow calls to `poetry env info`. Once a virtual environment is activated, its path is cached using a directory hash, making future activations nearly instantaneous.

## Development

### Running Tests

The plugin includes a test suite that can be run using the Makefile:

```fish
make test      # Run tests
make lint      # Check code style
make all       # Run both tests and linting
make clean     # Clean up test artifacts
```

The tests are automatically run on GitHub Actions for all pull requests and pushes to the main branch.

## License

MIT © Travis Cole

---

> **Note:** This plugin was largely developed with assistance from [Claude Code](https://claude.ai/code), Anthropic's AI coding assistant.
