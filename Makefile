# Define the Go compiler
GO = go
GOFLAGS = -ldflags="-s -w"

# Define the build directory
BUILD_DIR = ./bin
DIST_DIR = ./dist

# Define the binary name
BINARY = stencil

# Define the source files
SOURCES = ./cmd/stencil/main.go

# Version information (can be overridden by environment variables)
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "1.0.0")
BUILD_TIME = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT = $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Linker flags for version injection
LDFLAGS = -ldflags="-s -w -X 'main.version=$(VERSION)' -X 'main.buildTime=$(BUILD_TIME)' -X 'main.gitCommit=$(GIT_COMMIT)'"

# Go build flags for different platforms
PLATFORMS = linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/386

.PHONY: all init build dev run clean update-deps test build-all release help

# Default target
all: build

# Build for current platform
build:
	$(GO) build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY) $(SOURCES)

# Development target
dev:
	$(GO) run $(SOURCES)

# Run the binary
run: build
	$(BUILD_DIR)/$(BINARY)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)

# Install the dependencies
update-deps:
	$(GO) get -u all
	$(GO) mod tidy

# Test the project
test:
	$(GO) test ./...

# Build for all platforms
build-all:
	@echo "Building for multiple platforms..."
	@mkdir -p $(DIST_DIR)
	@$(foreach PLATFORM,$(PLATFORMS), \
		echo "Building $(PLATFORM)..."; \
		GOOS=$(word 1,$(subst /, ,$(PLATFORM))) \
		GOARCH=$(word 2,$(subst /, ,$(PLATFORM))) \
		$(GO) build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY)_$(subst /,_,$(PLATFORM)) $(SOURCES); \
	)
	@# Add .exe extension to Windows binaries
	@for file in $(DIST_DIR)/stencil_windows_*; do \
		if [ -f "$$file" ] && [ ! -e "$$file.exe" ]; then \
			mv "$$file" "$$file.exe"; \
		fi; \
	done
	@echo "✓ Built binaries:"
	@ls -lh $(DIST_DIR)

# Package release artifacts
release: clean build-all
	@echo "Creating release packages..."
	@mkdir -p $(DIST_DIR)/release
	@for platform in $(PLATFORMS); do \
		platform_us=$$(echo "$$platform" | tr '/' '_'); \
		if echo "$$platform" | grep -q windows; then \
			echo "Packaging $$platform as zip..."; \
			(cd $(DIST_DIR) && zip -q -r release/$(BINARY)_$$platform_us.zip $(BINARY)_$$platform_us.exe); \
		else \
			echo "Packaging $$platform as tar.gz..."; \
			tar -czf $(DIST_DIR)/release/$(BINARY)_$$platform_us.tar.gz -C $(DIST_DIR) $(BINARY)_$$platform_us; \
		fi \
	done
	@echo "✓ Release packages created in $(DIST_DIR)/release:"
	@ls -lh $(DIST_DIR)/release

# Generate checksums for release packages
checksums:
	@echo "Generating checksums..."
	@cd $(DIST_DIR)/release && \
		shasum -a 256 * > SHA256SUMS.txt && \
		echo "✓ Checksums created: SHA256SUMS.txt"

# Help target
help:
	@echo "Stencil Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build       - Build for current platform"
	@echo "  make build-all   - Build for all platforms (linux/darwin/windows amd64/arm64)"
	@echo "  make release     - Build and package release artifacts"
	@echo "  make checksums   - Generate SHA256 checksums for release packages"
	@echo "  make dev         - Run in development mode"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make update-deps - Update dependencies"
	@echo ""
	@echo "Environment variables:"
	@echo "  VERSION         - Override version (default: git describe or 1.0.0)"
	@echo ""
	@echo "Examples:"
	@echo "  make build                    # Build for current platform"
	@echo "  make VERSION=1.2.3 build      # Build with custom version"
	@echo "  make build-all                # Build for all platforms"
	@echo "  make release                  # Create release packages"
