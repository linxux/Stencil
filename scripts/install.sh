#!/bin/sh
# Stencil Installer
# Adapted from the Deno installer: Copyright 2019 the Deno authors. All rights reserved. MIT license.
# Ref: https://github.com/denoland/deno_install
# Adapted from goose: https://github.com/pressly/goose
#
# This script installs Stencil on Linux and macOS.
# Usage:
#   curl -sSL https://raw.githubusercontent.com/linxux/stencil/master/scripts/install.sh | sh
#   curl -sSL https://raw.githubusercontent.com/linxux/stencil/master/scripts/install.sh | sh -s v1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect operating system
os=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$os" in
  linux|darwin)
    ;;
  *)
    echo "${RED}Error: Unsupported operating system: $os${NC}"
    echo "This installer supports Linux and macOS only."
    echo "For Windows, please download the binary from:"
    echo "https://github.com/linxux/stencil/releases"
    exit 1
    ;;
esac

# Detect architecture
arch=$(uname -m)
case "$arch" in
  x86_64|amd64)
    arch="amd64"
    ;;
  aarch64|arm64)
    arch="arm64"
    ;;
  i386|i686)
    arch="386"
    ;;
  *)
    echo "${RED}Error: Unsupported architecture: $arch${NC}"
    echo "Supported architectures: amd64, arm64, 386"
    exit 1
    ;;
esac

# Version argument (optional)
if [ $# -eq 0 ]; then
  version="latest"
  stencil_uri="https://github.com/linxux/Stencil/releases/latest/download/stencil_${os}_${arch}.tar.gz"
else
  version="$1"
  stencil_uri="https://github.com/linxux/Stencil/releases/download/${version}/stencil_${os}_${arch}.tar.gz"
fi

# Installation directory (default: /usr/local)
stencil_install="${STENCIL_INSTALL:-/usr/local}"
bin_dir="${stencil_install}/bin"
exe="${bin_dir}/stencil"

echo "${GREEN}Stencil Installer${NC}"
echo "==================="
echo "OS: $os"
echo "Architecture: $arch"
echo "Version: $version"
echo "Install directory: ${stencil_install}"
echo ""

# Create bin directory if it doesn't exist
if [ ! -d "${bin_dir}" ]; then
  echo "Creating ${bin_dir}..."
  mkdir -p "${bin_dir}"
  if [ $? -ne 0 ]; then
    echo "${RED}Error: Failed to create ${bin_dir}${NC}"
    echo "Try running with sudo or set STENCIL_INSTALL to a user-writable directory:"
    echo "  curl -sSL https://raw.githubusercontent.com/linxux/stencil/master/scripts/install.sh | STENCIL_INSTALL=~/.local sh"
    exit 1
  fi
fi

# Check if we can write to the bin directory
if [ ! -w "${bin_dir}" ]; then
  echo "${YELLOW}Warning: No write permission for ${bin_dir}${NC}"
  echo "The installer will attempt to use sudo."
  echo "Alternatively, set STENCIL_INSTALL to a user-writable directory:"
  echo "  export STENCIL_INSTALL=~/.local"
  echo ""
fi

# Download and extract
echo "Downloading Stencil from GitHub..."
echo "URL: ${stencil_uri}"

# Create a temporary directory for the download
tmp_dir=$(mktemp -d)
trap "rm -rf ${tmp_dir}" EXIT

if command -v curl >/dev/null 2>&1; then
  curl --silent --show-error --location --fail --output "${tmp_dir}/stencil.tar.gz" "${stencil_uri}"
elif command -v wget >/dev/null 2>&1; then
  wget --quiet --output-document="${tmp_dir}/stencil.tar.gz" "${stencil_uri}"
else
  echo "${RED}Error: Neither curl nor wget is installed${NC}"
  echo "Please install curl or wget to download Stencil."
  exit 1
fi

# Verify the download
if [ ! -f "${tmp_dir}/stencil.tar.gz" ]; then
  echo "${RED}Error: Download failed${NC}"
  echo "Please check your internet connection and try again."
  echo "Visit https://github.com/linxux/stencil/releases for available releases."
  exit 1
fi

# Extract the binary
echo "Extracting binary..."
tar -xzf "${tmp_dir}/stencil.tar.gz" -C "${tmp_dir}"

# Find the extracted binary (handle different archive structures)
binary_path=""
if [ -f "${tmp_dir}/stencil" ]; then
  binary_path="${tmp_dir}/stencil"
elif [ -f "${tmp_dir}/stencil-${os}-${arch}" ]; then
  binary_path="${tmp_dir}/stencil-${os}-${arch}"
else
  # Find any stencil binary in the temp directory
  binary_path=$(find "${tmp_dir}" -type f -name "stencil*" | head -n 1)
fi

if [ -z "${binary_path}" ] || [ ! -f "${binary_path}" ]; then
  echo "${RED}Error: Could not find Stencil binary in archive${NC}"
  echo "Archive contents:"
  tar -tzf "${tmp_dir}/stencil.tar.gz"
  exit 1
fi

# Install the binary
echo "Installing to ${exe}..."
if [ -w "${bin_dir}" ]; then
  cp "${binary_path}" "${exe}"
else
  echo "Using sudo to install to ${bin_dir}..."
  sudo cp "${binary_path}" "${exe}"
fi

# Make executable
chmod +x "${exe}"

# Verify installation
if [ ! -x "${exe}" ]; then
  echo "${RED}Error: Installation failed${NC}"
  echo "The binary was not installed correctly."
  exit 1
fi

echo ""
echo "${GREEN}✓ Stencil was installed successfully!${NC}"
echo ""
echo "Binary location: ${exe}"
echo ""

# Check if the binary is in PATH
if command -v stencil >/dev/null 2>&1; then
  echo "Run 'stencil --version' to verify the installation"
  echo "Run 'stencil --help' to get started"
else
  echo "${YELLOW}Note: ${bin_dir} is not in your PATH${NC}"
  echo ""
  echo "Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
  echo ""
  case $(basename "$SHELL") in
    bash)
      echo "  export PATH=\"${bin_dir}:\$PATH\""
      ;;
    zsh)
      echo "  export PATH=\"${bin_dir}:\$PATH\""
      ;;
    fish)
      echo "  fish_add_path ${bin_dir}"
      ;;
    *)
      echo "  export PATH=\"${bin_dir}:\$PATH\""
      ;;
  esac
  echo ""
  echo "Then restart your shell or run:"
  echo "  source ~/.bashrc  # or ~/.zshrc, etc."
  echo ""
  echo "Or run Stencil directly:"
  echo "  ${exe} --version"
fi

echo ""
echo "For more information, visit: https://github.com/linxux/stencil"
