package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/linxux/stencil/config"
	"github.com/linxux/stencil/internal/generator"
	"github.com/linxux/stencil/internal/interactive"
)

var (
	// Version information (injected via ldflags during build)
	version   = "1.0.0"
	buildTime = "unknown"
	gitCommit = "unknown"
)

var (
	// Command-line flags
	templateDir     string
	outputDir       string
	configFile      string
	variables       string
	interactiveMode bool
	dryRun          bool
	skipConfirm     bool
	showVersion     bool
	showHelp        bool
)

func init() {
	// Define command-line flags
	flag.StringVar(&templateDir, "t", "./template", "Template directory path")
	flag.StringVar(&templateDir, "template", "./template", "Template directory path")

	flag.StringVar(&outputDir, "o", "./output", "Output directory path")
	flag.StringVar(&outputDir, "output", "./output", "Output directory path")

	flag.StringVar(&configFile, "c", "", "Configuration file path (JSON)")
	flag.StringVar(&configFile, "config", "", "Configuration file path (JSON)")

	flag.StringVar(&variables, "v", "", "Variables in format 'key1=value1,key2=value2'")
	flag.StringVar(&variables, "vars", "", "Variables in format 'key1=value1,key2=value2'")

	flag.BoolVar(&interactiveMode, "i", false, "Interactive mode")
	flag.BoolVar(&interactiveMode, "interactive", false, "Interactive mode")

	flag.BoolVar(&dryRun, "dry-run", false, "Dry run (show what would be generated without creating files)")

	flag.BoolVar(&skipConfirm, "y", false, "Skip confirmation in interactive mode")
	flag.BoolVar(&skipConfirm, "yes", false, "Skip confirmation in interactive mode")

	flag.BoolVar(&showVersion, "version", false, "Show version information")

	flag.BoolVar(&showHelp, "h", false, "Show help information")
	flag.BoolVar(&showHelp, "help", false, "Show help information")
}

func main() {
	flag.Parse()

	if showVersion {
		fmt.Printf("Stencil v%s\n", version)
		fmt.Printf("Build: %s\n", buildTime)
		fmt.Printf("Commit: %s\n", gitCommit)
		fmt.Println("A project scaffolding generator")
		os.Exit(0)
	}

	if showHelp {
		printHelp()
		os.Exit(0)
	}

	// Load configuration
	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading configuration: %v\n", err)
		os.Exit(1)
	}

	// Validate template directory exists and provide helpful message
	if _, err := os.Stat(cfg.TemplateDir); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Error: Template directory does not exist: %s\n\n", cfg.TemplateDir)
		printGettingStarted()
		os.Exit(1)
	}

	// Create generator
	gen := generator.NewGenerator(cfg)

	// Interactive mode
	if cfg.Interactive {
		if err := runInteractiveMode(gen); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	// Generate project
	if err := gen.Generate(); err != nil {
		fmt.Fprintf(os.Stderr, "Error generating project: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("\n✓ Project generated successfully!")
	if cfg.DryRun {
		fmt.Println("  (This was a dry run - no files were actually created)")
	}
}

func loadConfig() (*config.Config, error) {
	var cfg *config.Config
	var configUsed bool

	// Auto-detect config file if not specified
	if configFile == "" {
		// Check for common config file names
		candidates := []string{"stencil.json", ".stencil.json", "stencil.config.json"}
		for _, candidate := range candidates {
			if _, err := os.Stat(candidate); err == nil {
				configFile = candidate
				break
			}
		}
	}

	// Load from config file if specified or auto-detected
	if configFile != "" {
		var err error
		cfg, err = config.LoadConfig(configFile)
		if err != nil {
			return nil, fmt.Errorf("failed to load config file '%s': %w", configFile, err)
		}
		configUsed = true
	} else {
		cfg = config.DefaultConfig()
	}

	// Override with command-line flags (flags take precedence)
	if templateDir != "" {
		cfg.TemplateDir = templateDir
	}
	if outputDir != "" {
		cfg.OutputDir = outputDir
	}
	if interactiveMode {
		cfg.Interactive = true
	}
	if dryRun {
		cfg.DryRun = true
	}
	if skipConfirm {
		cfg.SkipConfirm = true
	}

	// Parse variables from command line (merge with config variables)
	if variables != "" {
		if cfg.Variables == nil {
			cfg.Variables = make(map[string]string)
		}
		vars := strings.Split(variables, ",")
		for _, v := range vars {
			parts := strings.SplitN(v, "=", 2)
			if len(parts) == 2 {
				cfg.Variables[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
			}
		}
	}

	// Show which config was used
	if configUsed {
		fmt.Printf("Using config file: %s\n", configFile)
	}

	return cfg, nil
}

func runInteractiveMode(gen *generator.Generator) error {
	prompter := interactive.NewPrompter()

	fmt.Println("=== Stencil - Interactive Mode ===")
	fmt.Println("Scanning template for variables...")

	// Extract variables from template
	variables, err := gen.ExtractVariables()
	if err != nil {
		return fmt.Errorf("failed to extract variables: %w", err)
	}

	if len(variables) == 0 {
		fmt.Println("No variables found in template.")
		fmt.Println("Generating project...")
		return gen.Generate()
	}

	fmt.Printf("Found %d variables in template.\n", len(variables))

	// Prompt for values
	values, err := prompter.PromptForValues(variables)
	if err != nil {
		return err
	}

	// Display summary
	fmt.Println("\n=== Summary ===")
	fmt.Printf("Template: %s\n", gen.TemplateDir())
	fmt.Printf("Output: %s\n", gen.OutputDir())
	fmt.Println("\nVariables:")
	for key, value := range values {
		fmt.Printf("  %s = %s\n", key, value)
	}

	// Confirmation
	if !gen.SkipConfirm() {
		confirmed, err := prompter.PromptForConfirmation("Proceed with generation?")
		if err != nil {
			return err
		}
		if !confirmed {
			fmt.Println("Generation cancelled.")
			return nil
		}
	}

	// Update generator with values
	gen.SetVariables(values)

	// Generate
	fmt.Println("\nGenerating project...")
	return gen.Generate()
}

func printHelp() {
	fmt.Printf(`Stencil v%s - Project Scaffolding Generator

USAGE:
  stencil [OPTIONS]

OPTIONS:
  -t, --template <dir>      Template directory path (default: ./template)
  -o, --output <dir>        Output directory path (default: ./output)
  -c, --config <file>       Configuration file path (JSON)
  -v, --vars <vars>         Variables in format 'key1=value1,key2=value2'
  -i, --interactive         Interactive mode
  --dry-run                 Dry run (show what would be generated)
  -y, --yes                 Skip confirmation in interactive mode
  --version                 Show version information
  -h, --help                Show this help message

AUTO-DETECTION:
  Stencil automatically detects config files (in order):
  - stencil.json (recommended)
  - .stencil.json
  - stencil.config.json

  Command-line flags override config file values.

EXAMPLES:
  # Auto-detect stencil.json and run
  stencil

  # Basic usage with variables
  stencil -t ./template -o ./output -v "project_name=MyApp,author=John"

  # Interactive mode
  stencil -t ./template -o ./output -i

  # Using configuration file
  stencil -c config.json

  # Dry run to preview changes
  stencil -t ./template -o ./output --dry-run

TEMPLATE SYNTAX:
  Variables can be specified in multiple formats:
  - {{variable}}
  - <<variable>>
  - __variable__
  - %%variable%%

  These will be replaced in:
  - File contents
  - File names
  - Directory names

CONFIG FILE FORMAT (JSON):
  {
    "templateDir": "./template",
    "outputDir": "./output",
    "variables": {
      "project_name": "MyApp",
      "author": "John"
    },
    "interactive": false,
    "dryRun": false
  }

`, version)
}

func printGettingStarted() {
	fmt.Print(`GETTING STARTED:

  Option 1: Use a config file (recommended)
    1. Create a stencil.json file:
       {
         "templateDir": "./path/to/your/template",
         "outputDir": "./output",
         "variables": {
           "project_name": "myproject"
         }
       }

    2. Run: ./bin/stencil

  Option 2: Use command-line flags
    ./bin/stencil -t ./path/to/template -o ./output

  Option 3: Try the example template
    ./bin/stencil -t ./examples/template-go-basic -o ./myproject -i

  For more information, run: ./bin/stencil --help
`)
}
