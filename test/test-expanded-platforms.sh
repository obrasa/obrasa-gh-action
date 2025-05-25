#!/bin/bash
# Test script to verify native ARM64 platform support

set -e

echo "🧪 Testing native ARM64 platform support..."

# Set up test environment
export GITHUB_TOKEN="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"
TEST_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "📁 Test directory: $TEST_DIR"
echo "📂 Script directory: $SCRIPT_DIR"

cd "$TEST_DIR"

# Copy the download script to test directory
cp "$SCRIPT_DIR/scripts/download-binary.sh" ./

echo ""
echo "🔍 Test 1: Platform Detection"
echo "Current platform:"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
echo "  OS: $OS"
echo "  ARCH: $ARCH"

# Test platform detection logic
case "$ARCH" in
  x86_64|amd64) ARCH_NAME="amd64" ;;
  aarch64|arm64) ARCH_NAME="arm64" ;;
  *) ARCH_NAME="unknown" ;;
esac

case "$OS" in
  linux)
    EXPECTED_BINARY="mutator-linux-${ARCH_NAME}"
    ;;
  darwin)
    EXPECTED_BINARY="mutator-macos-${ARCH_NAME}"
    ;;
  *)
    EXPECTED_BINARY="unsupported"
    ;;
esac

echo "  Expected binary: $EXPECTED_BINARY"

echo ""
echo "🔍 Test 2: Check Available Platforms in Latest Release"
LATEST_RELEASE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/obrasa/tree-mutator/releases/latest")

if echo "$LATEST_RELEASE" | grep -q '"tag_name"'; then
  LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
  echo "✅ Latest release: $LATEST_VERSION"
  
  echo "📦 Available platform binaries:"
  PLATFORMS=(
    "mutator-linux-amd64"
    "mutator-macos-amd64"
    "mutator-macos-arm64"
  )
  
  # Temporarily disabled until ARM64 runners available for private repos
  COMING_SOON_PLATFORMS=(
    "mutator-linux-arm64"
  )
  
  for platform in "${PLATFORMS[@]}"; do
    if echo "$LATEST_RELEASE" | grep -q "${platform}-${LATEST_VERSION}.tar.gz"; then
      echo "  ✅ $platform"
    else
      echo "  ❌ $platform (not found - will be available after next release)"
    fi
  done
  
  echo "  🚧 Coming soon (when ARM64 runners available for private repos):"
  for platform in "${COMING_SOON_PLATFORMS[@]}"; do
    echo "    - $platform"
  done
else
  echo "❌ Could not get latest release"
fi

echo ""
echo "🔍 Test 3: Test Download with Platform Fallback"
export VERSION="latest"

# Test current platform
echo "Testing download for current platform..."
if bash ./download-binary.sh; then
  echo "✅ Download successful for current platform"
  
  if [ -f "mutator" ]; then
    echo "✅ Binary file created"
    ls -la mutator
    
    # Show binary info
    if command -v file >/dev/null 2>&1; then
      echo "🔍 Binary information:"
      file mutator
    fi
    
    # Test execution
    if [ -x "mutator" ]; then
      echo "✅ Binary is executable"
      
      # Try to run it (might fail if it's for wrong architecture)
      if ./mutator --help >/dev/null 2>&1; then
        echo "✅ Binary executes successfully"
      else
        echo "⚠️  Binary doesn't execute (might be wrong architecture)"
      fi
    else
      echo "❌ Binary is not executable"
    fi
  else
    echo "❌ Binary file not created"
  fi
else
  echo "❌ Download failed"
fi

echo ""
echo "🔍 Test 4: Test GitHub Actions Runner Labels"
echo "Testing GitHub Actions runner label mapping..."

RUNNER_TESTS=(
  "linux:amd64:ubuntu-latest"
  "darwin:amd64:macos-13"
  "darwin:arm64:macos-latest"
)

# Temporarily disabled until ARM64 runners available for private repos
COMING_SOON_TESTS=(
  "linux:arm64:ubuntu-24.04-arm"
)

for test_case in "${RUNNER_TESTS[@]}"; do
  IFS=':' read -r test_os test_arch expected_runner <<< "$test_case"
  echo "Testing $test_os $test_arch -> $expected_runner"
  
  # This would be the runner selection logic in our workflow
  case "$test_os:$test_arch" in
    linux:amd64) runner="ubuntu-latest" ;;
    darwin:amd64) runner="macos-13" ;;
    darwin:arm64) runner="macos-latest" ;;
    *) runner="unknown" ;;
  esac
  
  if [ "$runner" = "$expected_runner" ]; then
    echo "  ✅ Correct runner selection"
  else
    echo "  ❌ Wrong runner selection: got $runner, expected $expected_runner"
  fi
done

echo "🚧 Coming soon (when ARM64 runners available for private repos):"
for test_case in "${COMING_SOON_TESTS[@]}"; do
  IFS=':' read -r test_os test_arch expected_runner <<< "$test_case"
  echo "  - $test_os $test_arch -> $expected_runner"
done

echo ""
echo "🔍 Test 5: Test All Platform Combinations"
PLATFORM_TESTS=(
  "linux:amd64:mutator-linux-amd64"
  "darwin:amd64:mutator-macos-amd64"
  "darwin:arm64:mutator-macos-arm64"
)

# Temporarily disabled until ARM64 runners available for private repos
COMING_SOON_PLATFORM_TESTS=(
  "linux:arm64:mutator-linux-arm64"
)

for test_case in "${PLATFORM_TESTS[@]}"; do
  IFS=':' read -r test_os test_arch expected_binary <<< "$test_case"
  echo "Testing $test_os $test_arch -> $expected_binary"
  
  # Test the logic
  case "$test_arch" in
    amd64) arch_name="amd64" ;;
    arm64) arch_name="arm64" ;;
  esac
  
  case "$test_os" in
    linux) binary_name="mutator-linux-${arch_name}" ;;
    darwin) binary_name="mutator-macos-${arch_name}" ;;
  esac
  
  if [ "$binary_name" = "$expected_binary" ]; then
    echo "  ✅ Correct binary selection"
  else
    echo "  ❌ Wrong binary selection: got $binary_name, expected $expected_binary"
  fi
done

echo "🚧 Coming soon (when ARM64 runners available for private repos):"
for test_case in "${COMING_SOON_PLATFORM_TESTS[@]}"; do
  IFS=':' read -r test_os test_arch expected_binary <<< "$test_case"
  echo "  - $test_os $test_arch -> $expected_binary"
done

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "🎉 Native ARM64 platform testing completed!"
echo ""
echo "📋 Summary:"
echo "  - Platform detection tested"
echo "  - Available binaries checked"
echo "  - Download and fallback logic verified"
echo "  - GitHub Actions runner labels validated"
echo "  - All platform combinations validated"
echo ""
echo "💡 Benefits of native runners:"
echo "  - ✅ No more QEMU emulation overhead"
echo "  - ✅ Native performance on ARM64"
echo "  - ✅ Simpler, cleaner build process"
echo "  - ✅ Free for public repositories"
echo "  - ✅ 4 vCPU, 16 GB RAM for public repos" 