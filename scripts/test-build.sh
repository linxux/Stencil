#!/bin/bash
# Test script to verify the build system works correctly

set -e

echo "=== Stencil Build Test Script ==="
echo ""

# Test 1: Standard build
echo "Test 1: Building for current platform..."
make build
if [ -f "./bin/stencil" ]; then
    echo "✓ Build successful"
    echo "  Version info:"
    ./bin/stencil --version
else
    echo "✗ Build failed"
    exit 1
fi
echo ""

# Test 2: Build for all platforms
echo "Test 2: Building for all platforms..."
make build-all
if [ -d "./dist" ] && [ "$(ls -A ./dist)" ]; then
    echo "✓ Multi-platform build successful"
    echo "  Built binaries:"
    ls -lh ./dist
else
    echo "✗ Multi-platform build failed"
    exit 1
fi
echo ""

# Test 3: Create release packages
echo "Test 3: Creating release packages..."
make release
if [ -d "./dist/release" ] && [ "$(ls -A ./dist/release)" ]; then
    echo "✓ Release packages created"
    echo "  Release artifacts:"
    ls -lh ./dist/release
else
    echo "✗ Release packaging failed"
    exit 1
fi
echo ""

# Test 4: Generate checksums
echo "Test 4: Generating checksums..."
make checksums
if [ -f "./dist/release/SHA256SUMS.txt" ]; then
    echo "✓ Checksums generated"
    echo "  SHA256SUMS.txt contents:"
    cat ./dist/release/SHA256SUMS.txt
else
    echo "✗ Checksum generation failed"
    exit 1
fi
echo ""

# Test 5: Verify binaries
echo "Test 5: Verifying binaries..."
cd ./dist/release
sha256sum -c --ignore-missing SHA256SUMS.txt
cd ../..
echo "✓ All binaries verified"
echo ""

echo "=== All Tests Passed ==="
echo ""
echo "Summary:"
echo "  - Single platform build: ✓"
echo "  - Multi-platform build: ✓"
echo "  - Release packaging: ✓"
echo "  - Checksum generation: ✓"
echo "  - Binary verification: ✓"
echo ""
echo "To clean up, run: make clean"
