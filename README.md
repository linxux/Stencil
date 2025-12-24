# Stencil

A fast and flexible project scaffolding generator written in Go. Stencil allows you to create project templates with variable substitution for any programming language.

## Features

- **Template-based Generation**: Use any folder as a template
- **Variable Substitution**: Replace keywords in files, filenames, and directory names
- **Multiple Variable Formats**: Supports `{{var}}`, `<<var>>`, `__var__`, and `%var%` syntax
- **Interactive Mode**: Prompt for variables interactively during generation
- **Dry Run**: Preview what would be generated without creating files
- **Config File Support**: Use JSON files for reusable configurations
- **Binary File Detection**: Automatically detects and copies binary files without modification
- **Language Agnostic**: Works with any programming language or project type

## Installation

### Quick Install (Linux & macOS)

The easiest way to install Stencil is using the installation script:

```bash
# Install the latest version
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | sh

# Install a specific version
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | sh -s v1.0.0

# Install to a custom directory (e.g., user home)
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | STENCIL_INSTALL=~/.local sh
```

The installer will:
- Detect your operating system and architecture
- Download the latest Stencil binary from GitHub releases
- Install it to `/usr/local/bin` (or `STENCIL_INSTALL` directory)
- Set up executable permissions

### Manual Installation

#### Linux & macOS

Download the binary for your platform from [Releases](https://github.com/linxux/Stencil/releases):

```bash
# Example: Linux amd64
wget https://github.com/linxux/Stencil/releases/latest/download/stencil_linux_amd64.tar.gz
tar -xzf stencil_linux_amd64.tar.gz
chmod +x stencil_linux_amd64
sudo mv stencil_linux_amd64 /usr/local/bin/stencil

# Verify installation
stencil --version
```

#### Windows

Download the `.zip` file from [Releases](https://github.com/linxux/Stencil/releases), extract it, and add the binary to your PATH.

#### Using Homebrew (macOS)

Coming soon! We're working on a Homebrew tap.

#### Using Scoop (Windows)

Coming soon! We're working on a Scoop bucket.

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/linxux/Stencil.git
cd Stencil

# Build
make build

# The binary will be created in ./bin/stencil
sudo mv ./bin/stencil /usr/local/bin/
```

## Usage

### Basic Usage

```bash
# Auto-detects stencil.json config file in current directory
./bin/stencil

# Generate a project with variables (overrides config)
./bin/stencil -t ./template -o ./output -v "project_name=MyApp,author=John"

# Interactive mode
./bin/stencil -t ./template -o ./output -i

# Using a specific configuration file
./bin/stencil -c config.json

# Dry run to preview changes
./bin/stencil -t ./template -o ./output --dry-run
```

### Command-Line Options

```
  -t, --template <dir>      Template directory path
  -o, --output <dir>        Output directory path
  -c, --config <file>       Configuration file path (JSON)
  -v, --vars <vars>         Variables in format 'key1=value1,key2=value2'
  -i, --interactive         Interactive mode
  --dry-run                 Dry run (show what would be generated)
  -y, --yes                 Skip confirmation in interactive mode
  --version                 Show version information
  -h, --help                Show help message
```

## Template Syntax

Variables can be specified in multiple formats:

- `{{variable}}` - Double curly braces
- `<<variable>>` - Double angle brackets
- `__variable__` - Double underscores (great for filenames)
- `%variable%` - Percent signs

These will be replaced in:
- File contents
- File names
- Directory names

### Example Template Structure

```
template/
├── README.md
├── go.mod
├── cmd/
│   └── __project_name__/
│       └── main.go
└── internal/
    └── __project_name__/
        └── app.go
```

### Example Template File (README.md)

```markdown
# {{project_name}}

{{description}}

## Author
{{author}}

## Installation
```bash
go get {{module_path}}
```

## Configuration File

Stencil automatically detects configuration files in the current directory (in order of priority):
- `stencil.json` (recommended)
- `.stencil.json` (hidden file)
- `stencil.config.json`

Create a `stencil.json` file for reusable settings:

```json
{
  "templateDir": "./template",
  "outputDir": "./my-project",
  "variables": {
    "project_name": "myapp",
    "module_path": "github.com/example/myapp",
    "author": "Your Name",
    "description": "An awesome application",
    "version": "1.0.0"
  },
  "interactive": false,
  "dryRun": false
}
```

**Priority order** (higher priority overrides lower):
1. Command-line flags (`-t`, `-o`, `-v`, etc.)
2. Config file specified with `-c`
3. Auto-detected config file (`stencil.json`, etc.)
4. Built-in defaults (`./template`, `./output`)

## Examples

See the `examples/` directory for sample templates:

- `template-go-basic`: A basic Go project template

### Running the Example

```bash
# From the project root
cd examples

# Interactive mode
../bin/stencil -t ./template-go-basic -o ./my-project -i

# Using config file
../bin/stencil -c config.json
```

## How It Works

1. **Template Scanning**: Stencil scans your template directory for variables
2. **Variable Collection**: It collects all variables from filenames, directory names, and file contents
3. **Interactive Mode** (optional): If enabled, prompts you for values
4. **Generation**: Creates the output directory with all variables replaced
5. **Binary Handling**: Detects binary files and copies them without modification

## Development

```bash
# Run in development mode
make dev

# Run tests
make test

# Build the binary
make build

# Clean build artifacts
make clean
```

## Tips

1. **Create a `stencil.json`** in your project root for quick access - just run `./bin/stencil`
2. **Use `__variable__` format** for filenames and directory names (e.g., `__project_name__`)
3. **Organize templates** with clear directory structures
4. **Use dry-run mode** to preview changes before generating
5. **Create config files** for frequently-used templates
6. **Binary files** (images, compiled assets) are automatically detected and copied as-is
7. **Command-line flags override config** - great for one-off changes

## License

MIT License - see [LICENSE](LICENSE) file for details
