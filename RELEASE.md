# Build and Release Guide

This guide explains how to build Stencil for multiple platforms and create releases in GitHub and GitLab.

## Table of Contents

- [Local Builds](#local-builds)
- [GitHub Actions](#github-actions)
- [GitLab CI/CD](#gitlab-cicd)
- [Creating Releases](#creating-releases)
- [GoReleaser (Alternative)](#goreleaser-alternative)
- [Version Management](#version-management)

## Local Builds

### Build for Current Platform

```bash
make build
```

This creates `./bin/stencil` with version information injected from git.

### Build for All Platforms

```bash
make build-all
```

This creates binaries in `./dist/` for:
- Linux (amd64, arm64)
- macOS (amd64, arm64)
- Windows (amd64, 386)

### Create Release Packages

```bash
make release
```

This builds for all platforms and packages them into `./dist/release/`:
- **Linux/macOS**: `.tar.gz` files
- **Windows**: `.zip` files

### Generate Checksums

```bash
make checksums
```

Creates `SHA256SUMS.txt` in `./dist/release/`.

### Custom Version

```bash
make VERSION=2.0.0 build
make VERSION=2.0.0 release
```

## GitHub Actions

The `.github/workflows/` directory contains two workflows:

### CI Workflow (`.github/workflows/ci.yml`)

Runs on every push and pull request:

- **Test**: Runs tests on Ubuntu, macOS, and Windows with multiple Go versions
- **Lint**: Runs golangci-lint for code quality
- **Build**: Verifies the project builds on all platforms
- **Security**: Runs Gosec security scanner
- **Check**: Ensures code is formatted and dependencies are up to date

### Release Workflow (`.github/workflows/release.yml`)

Runs on tag pushes and manual workflow dispatch:

#### Stages

1. **Test**: Runs tests with coverage
2. **Build**: Builds binaries for multiple platforms in parallel
3. **Package**: Creates release packages and generates checksums
4. **Release**: Creates GitHub release with all artifacts
5. **GoReleaser**: Optionally runs GoReleaser for additional packaging

#### Workflow Diagram

```
┌──────────┐     ┌──────────┐     ┌────────────┐     ┌───────────┐     ┌─────────┐
│   Test   │ ──> │  Build   │ ──> │  Package   │ ──> │  Release  │ ──> │ GitHub  │
│ (all)    │     │ (matrix) │     │  (tags)    │     │  (tags)   │     │ Release │
└──────────┘     └──────────┘     └────────────┘     └───────────┘     └─────────┘
                      │
                      ├─> linux/amd64
                      ├─> linux/arm64
                      ├─> darwin/amd64
                      ├─> darwin/arm64
                      └─> windows/amd64
```

### Manual Trigger

You can manually trigger the release workflow from GitHub Actions:
1. Go to Actions → Release
2. Click "Run workflow"
3. Enter version (e.g., `v1.0.0`)
4. Click "Run workflow"

## GitLab CI/CD

The `.gitlab-ci.yml` file defines three stages: **test**, **build**, and **release**.

### Pipeline Stages

#### 1. Test Stage

Runs tests on merge requests and master branches:

```yaml
test:go
  - go test -v -race -coverprofile=coverage.out ./...
  - Generates coverage report
```

#### 2. Build Stage

Builds binaries for multiple platforms on tags and master branches:

- `build:linux-amd64`
- `build:linux-arm64`
- `build:darwin-amd64` (macOS Intel)
- `build:darwin-arm64` (macOS Apple Silicon)
- `build:windows-amd64`

#### 3. Release Stage

- **package:release**: Packages binaries into tar.gz/zip files and generates checksums
- **create:release**: Creates a GitLab release with download links

## Creating Releases

### GitHub Releases

#### Method 1: Git Tag (Recommended)

1. **Tag your release:**

```bash
# Create an annotated tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Or create a tag with a message
git tag -a v1.0.0 -m "Release v1.0.0

- Add new feature X
- Fix bug Y
- Update documentation"

# Push the tag to GitHub
git push origin v1.0.0
```

2. **GitHub Actions automatically:**
   - Runs tests
   - Builds for all platforms
   - Packages binaries
   - Creates a GitHub release with download links

3. **Download the artifacts from the release:**
   - Go to your GitHub repo → Releases
   - Find your release tag
   - Download the binaries for your platform

#### Method 2: Manual Workflow Dispatch

1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Enter version (e.g., `v1.0.0`)
4. Click "Run workflow"

### GitLab Releases

1. **Tag your release:**

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

2. **GitLab CI/CD automatically:**
   - Runs tests
   - Builds for all platforms
   - Packages binaries
   - Creates a GitLab release with download links

### GoReleaser (Local)

For more control, use GoReleaser locally:

#### Install GoReleaser

```bash
# macOS
brew install goreleaser

# Linux
curl -sL https://git.io/goreleaser | bash

# Or from GitHub releases
# https://github.com/goreleaser/goreleaser/releases
```

#### Test Build (Dry Run)

```bash
goreleaser release --snapshot --skip-publish --clean
```

#### Create Release

```bash
# Tag the commit
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Build and publish
goreleaser release
```

This will:
- Build for all platforms
- Create packages (tar.gz, zip, deb, rpm, apk)
- Generate checksums
- Sign binaries (if GPG key is configured)
- Create release on GitHub
- Update Homebrew tap (if configured)
- Update Scoop bucket (if configured)

## Version Management

### Version Variables

The build system uses several variables for versioning:

| Variable | Source | Description |
|----------|--------|-------------|
| `version` | Git tag or hardcoded | Semantic version |
| `buildTime` | Build timestamp | ISO 8601 UTC timestamp |
| `gitCommit` | Git commit hash | Short commit SHA |

### Display Version

```bash
./bin/stencil --version
# Output:
# Stencil v1.0.0
# Build: 2024-01-15T10:30:00Z
# Commit: abc1234
```

### Tag Naming Convention

Use semantic versioning:

```bash
# Major release (breaking changes)
v2.0.0

# Minor release (new features, backward compatible)
v1.2.0

# Patch release (bug fixes)
v1.2.1

# Pre-release
v1.3.0-rc.1
v1.3.0-beta.1
v1.3.0-alpha.1
```

**Note:** Pre-release tags (containing `-`) will be marked as pre-releases in GitHub/GitLab.

## Platform Support Matrix

| Platform | Architecture | Status | Binary Name |
|----------|--------------|--------|-------------|
| Linux | amd64 (x86_64) | ✅ | `stencil_linux_amd64` |
| Linux | arm64 (aarch64) | ✅ | `stencil_linux_arm64` |
| macOS | amd64 (Intel) | ✅ | `stencil_darwin_amd64` |
| macOS | arm64 (Apple Silicon) | ✅ | `stencil_darwin_arm64` |
| Windows | amd64 (x86_64) | ✅ | `stencil_windows_amd64.exe` |
| Windows | 386 (x86) | ✅ | `stencil_windows_386.exe` |

## Artifacts

Each release produces:

### Binaries

```
stencil_linux_amd64.tar.gz
stencil_linux_arm64.tar.gz
stencil_darwin_amd64.tar.gz
stencil_darwin_arm64.tar.gz
stencil_windows_amd64.zip
```

### Checksums

```
SHA256SUMS.txt
```

### Optional (with GoReleaser)

- Debian packages: `.deb`
- RPM packages: `.rpm`
- Alpine packages: `.apk`
- Homebrew bottle (macOS)
- Scoop manifest (Windows)
- Snap package (Linux)

## Installation Script

The `scripts/install.sh` script provides an easy way for users to install Stencil on Linux and macOS.

### Usage

```bash
# Install latest version
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | sh

# Install specific version
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | sh -s v1.0.0

# Install to custom directory
curl -sSL https://raw.githubusercontent.com/linxux/Stencil/master/scripts/install.sh | STENCIL_INSTALL=~/.local sh

# Install from local copy
./scripts/install.sh
./scripts/install.sh v1.0.0
```

### Features

- **Auto-detection**: Detects OS (Linux/macOS) and architecture (amd64/arm64/386)
- **Latest version**: Downloads the latest release by default
- **Specific version**: Optional version argument to install a specific release
- **Custom install location**: Uses `STENCIL_INSTALL` environment variable (default: `/usr/local`)
- **Error handling**: Clear error messages for unsupported platforms or download failures
- **PATH setup**: Provides instructions for adding to PATH if needed

### Script Flow

1. Detect operating system and architecture
2. Determine version (latest or specified)
3. Create installation directory (with sudo if needed)
4. Download release from GitHub
5. Extract binary
6. Install to target location
7. Set executable permissions
8. Provide usage instructions

### URL Patterns

The script expects binaries to follow this naming convention in GitHub releases:

```
https://github.com/linxux/Stencil/releases/latest/download/stencil_{os}_{arch}.tar.gz
```

Examples:
- `stencil_linux_amd64.tar.gz`
- `stencil_linux_arm64.tar.gz`
- `stencil_darwin_amd64.tar.gz`
- `stencil_darwin_arm64.tar.gz`
- `stencil_windows_amd64.zip`

### Verification

After installation, users can verify:

```bash
stencil --version
# Output: Stencil v1.0.0
#          Build: 2024-01-15T10:30:00Z
#          Commit: abc1234
```

## Verification

Always verify downloaded binaries:

```bash
# Download checksums (GitHub)
curl -sL https://github.com/linxux/Stencil/releases/download/v1.0.0/SHA256SUMS.txt -o SHA256SUMS.txt

# Download checksums (GitLab)
curl -sL https://gitlab.com/linxux/stencil/-/releases/v1.0.0/downloads/assets/SHA256SUMS.txt -o SHA256SUMS.txt

# Download binary
curl -sL https://github.com/linxux/Stencil/releases/download/v1.0.0/stencil_linux_amd64.tar.gz -o stencil.tar.gz

# Verify checksum
sha256sum -c --ignore-missing SHA256SUMS.txt
# Output: stencil_linux_amd64.tar.gz: OK
```

## Environment Variables

### GitHub Actions

Automatically available in GitHub Actions:

- `GITHUB_TOKEN`: Authentication token (auto-provided)
- `GITHUB_REF`: The tag being built
- `GITHUB_SHA`: Commit SHA
- `CI`: Always set to `true`

### GitLab CI/CD Variables

Automatically available in GitLab CI/CD:

- `CI_COMMIT_TAG`: The tag being built
- `CI_COMMIT_SHORT_SHA`: Short commit SHA
- `CI_PIPELINE_CREATED_AT`: Pipeline creation timestamp
- `CI_PROJECT_URL`: Project URL

### GoReleaser Variables

Optional variables for GoReleaser:

- `GITHUB_TOKEN`: For GitHub releases (required)
- `GITLAB_TOKEN`: For GitLab releases (if using GitLab)
- `GPG_FINGERPRINT`: For signing binaries (optional)

## CI/CD Best Practices

1. **Always tag releases** - Don't create releases manually, use tags
2. **Test before release** - Ensure all tests pass on master branch
3. **Use semantic versioning** - Follow SemVer (MAJOR.MINOR.PATCH)
4. **Write changelogs** - Document changes in CHANGELOG.md
5. **Verify checksums** - Always verify downloaded binaries
6. **Keep tags clean** - Don't modify tags after pushing them

## Troubleshooting

### Build Failures

**Problem**: Build fails with "go: module ... not found"

**Solution**:
```bash
go mod download
go mod tidy
```

**Problem**: Cross-compilation fails for arm64

**Solution**: Ensure you're using Go 1.16+ with better cross-compilation support:
```bash
go version  # Should be 1.16+
```

### Release Failures

**Problem**: Release not created in GitHub

**Solution**:
- Ensure tag format is `vX.Y.Z` (e.g., `v1.0.0`)
- Check GitHub Actions logs for errors
- Verify `.github/workflows/release.yml` syntax is correct
- Ensure `GITHUB_TOKEN` has write permissions

**Problem**: Artifacts not attached to release

**Solution**:
- Check workflow logs for errors
- Ensure build jobs completed successfully
- Verify artifact paths in workflow file

**Problem**: Pre-release marked as full release

**Solution**:
- Use semantic versioning with pre-release identifiers:
  - `v1.0.0-alpha.1`
  - `v1.0.0-beta.1`
  - `v1.0.0-rc.1`
- GitHub Actions automatically detects pre-releases by `-` in tag

## Quick Reference

```bash
# Local development
make build              # Build for current platform
make dev                # Run directly
make test               # Run tests
make clean              # Clean build artifacts

# Release preparation
make build-all          # Build for all platforms
make release            # Build and package
make checksums          # Generate checksums

# GitHub releases
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# GitLab releases
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# GoReleaser (alternative)
goreleaser release --snapshot --skip-publish
goreleaser release
```

## Repository Management

### GitHub vs GitLab

This repository is set up to work with both GitHub and GitLab:

- **GitHub Actions**: `.github/workflows/` - Primary CI/CD
- **GitLab CI/CD**: `.gitlab-ci.yml` - Alternative CI/CD for GitLab
- **GoReleaser**: `.goreleaser.yml` - Works with both platforms

When pushing to both platforms:

```bash
# Add both remotes
git remote add github https://github.com/linxux/Stencil.git
git remote add gitlab https://gitlab.com/linxux/stencil.git

# Push to both
git push github master
git push gitlab master

# Push tags to both
git push github v1.0.0
git push gitlab v1.0.0
```

Both platforms will trigger their respective CI/CD pipelines automatically.

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GoReleaser Documentation](https://goreleaser.com/)
- [Semantic Versioning](https://semver.org/)
- [Go Build Documentation](https://golang.org/doc/install/source#environment)
