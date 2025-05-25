#!/bin/bash
# Test script to verify platform detection logic

set -e

echo "Testing platform detection logic..."

# Test 1: Linux x86_64
echo "Test 1: Linux x86_64"
OS="linux"
ARCH="x86_64"
VERSION="v1.0.0"

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-linux-amd64" ;;
      aarch64|arm64) BINARY_NAME="mutator-linux-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-macos-amd64" ;;
      arm64) BINARY_NAME="mutator-macos-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

EXPECTED_ARCHIVE="${BINARY_NAME}-${VERSION}.tar.gz"
echo "Expected archive: $EXPECTED_ARCHIVE"
[ "$EXPECTED_ARCHIVE" = "mutator-linux-amd64-v1.0.0.tar.gz" ] && echo "✅ Test 1 passed" || echo "❌ Test 1 failed"

# Test 2: macOS ARM64
echo -e "\nTest 2: macOS ARM64"
OS="darwin"
ARCH="arm64"
VERSION="v2.1.0"

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-linux-amd64" ;;
      aarch64|arm64) BINARY_NAME="mutator-linux-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-macos-amd64" ;;
      arm64) BINARY_NAME="mutator-macos-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

EXPECTED_ARCHIVE="${BINARY_NAME}-${VERSION}.tar.gz"
echo "Expected archive: $EXPECTED_ARCHIVE"
[ "$EXPECTED_ARCHIVE" = "mutator-macos-arm64-v2.1.0.tar.gz" ] && echo "✅ Test 2 passed" || echo "❌ Test 2 failed"

# Test 3: Linux ARM64 (aarch64)
echo -e "\nTest 3: Linux ARM64 (aarch64)"
OS="linux"
ARCH="aarch64"
VERSION="v1.5.2"

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-linux-amd64" ;;
      aarch64|arm64) BINARY_NAME="mutator-linux-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      x86_64) BINARY_NAME="mutator-macos-amd64" ;;
      arm64) BINARY_NAME="mutator-macos-arm64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

EXPECTED_ARCHIVE="${BINARY_NAME}-${VERSION}.tar.gz"
echo "Expected archive: $EXPECTED_ARCHIVE"
[ "$EXPECTED_ARCHIVE" = "mutator-linux-arm64-v1.5.2.tar.gz" ] && echo "✅ Test 3 passed" || echo "❌ Test 3 failed"

echo -e "\nAll platform detection tests completed!" 