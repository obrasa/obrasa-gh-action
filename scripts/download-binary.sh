#!/bin/bash
set -e

echo "Downloading tree-mutator binary release..."

# Determine the version to download
if [ "$VERSION" = "latest" ]; then
  echo "Fetching latest release..."
  RELEASE_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/obrasa/tree-mutator/releases/latest")
  VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
  echo "Latest version: $VERSION"
fi

# Get release assets to find the binary
echo "Getting release assets for version $VERSION..."
ASSETS_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/obrasa/tree-mutator/releases/tags/$VERSION")

# Determine platform-specific binary name (matching our build matrix)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64|amd64) ARCH_NAME="amd64" ;;
  aarch64|arm64) ARCH_NAME="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

case "$OS" in
  linux)
    BINARY_NAME="mutator-linux-${ARCH_NAME}"
    ;;
  darwin)
    BINARY_NAME="mutator-macos-${ARCH_NAME}"
    ;;
  *)
    echo "Unsupported operating system: $OS"
    exit 1
    ;;
esac

echo "Detected platform: $OS $ARCH_NAME"

# Function to get asset download URL and download via API (for private repos)
download_asset() {
  local asset_name="$1"
  local output_file="$2"
  
  echo "Looking for asset: $asset_name"
  
  # Get the asset URL from the API response - need to be more specific
  ASSET_URL=$(echo "$ASSETS_INFO" | grep -B 5 -A 20 "\"name\": \"$asset_name\"" | grep '"url": "https://api.github.com/repos/obrasa/tree-mutator/releases/assets/' | head -1 | sed -E 's/.*"url": "([^"]+)".*/\1/')
  
  if [ -z "$ASSET_URL" ]; then
    return 1
  fi
  
  echo "Downloading via GitHub API: $ASSET_URL"
  
  # Download using the API with proper headers for private repos
  if curl -L -H "Authorization: token $GITHUB_TOKEN" \
          -H "Accept: application/octet-stream" \
          "$ASSET_URL" \
          -o "$output_file"; then
    return 0
  else
    return 1
  fi
}

# Try to download the native binary first
ARCHIVE_NAME="${BINARY_NAME}-${VERSION}.tar.gz"
echo "Looking for binary archive: $ARCHIVE_NAME"

# Debug: Show all available assets
echo "📋 Available assets in release $VERSION:"
echo "$ASSETS_INFO" | grep '"name":' | sed 's/.*"name": "\([^"]*\)".*/  - \1/' | head -10

if download_asset "$ARCHIVE_NAME" "$ARCHIVE_NAME"; then
  echo "✅ Downloaded native binary: $ARCHIVE_NAME"
else
  # Try fallback to x86_64 if ARM64 not available
  if [ "$ARCH_NAME" = "arm64" ]; then
    FALLBACK_BINARY="mutator-${OS}-amd64"
    FALLBACK_ARCHIVE="${FALLBACK_BINARY}-${VERSION}.tar.gz"
    echo "Native arm64 binary not found, trying amd64 binary (compatibility mode)..."
    
    if download_asset "$FALLBACK_ARCHIVE" "$FALLBACK_ARCHIVE"; then
      echo "✅ Downloaded fallback binary: $FALLBACK_ARCHIVE"
      ARCHIVE_NAME="$FALLBACK_ARCHIVE"
    else
      echo "❌ No compatible binary found for $OS $ARCH_NAME"
      echo "Available assets:"
      echo "$ASSETS_INFO" | grep '"name":' | grep -E '\.(tar\.gz|zip)' | sed 's/.*"name": "\([^"]*\)".*/  - \1/'
      
      # Debug: Show raw API response if no assets found
      echo "🔍 Raw API response for debugging:"
      echo "$ASSETS_INFO" | head -50
      exit 1
    fi
  else
    echo "❌ Binary not found: $ARCHIVE_NAME"
    echo "Available assets:"
    echo "$ASSETS_INFO" | grep '"name":' | grep -E '\.(tar\.gz|zip)' | sed 's/.*"name": "\([^"]*\)".*/  - \1/'
    
    # Debug: Show raw API response if no assets found
    echo "🔍 Raw API response for debugging:"
    echo "$ASSETS_INFO" | head -50
    exit 1
  fi
fi

# Extract the binary
echo "Extracting binary from $ARCHIVE_NAME..."

# Remove any existing mutator binary to avoid conflicts
if [ -f "mutator" ]; then
  echo "🧹 Removing existing mutator binary..."
  rm -f mutator
fi

if tar -xzf "$ARCHIVE_NAME"; then
  echo "✅ Binary extracted successfully"
  
  # The extracted binary is named 'mutator' - rename it to avoid conflicts with source directory
  if [ -f "mutator" ] && [ -d "mutator" ]; then
    echo "🔄 Renaming binary to avoid conflict with mutator source directory..."
    mv mutator mutator-bin
    BINARY_NAME="mutator-bin"
  else
    BINARY_NAME="mutator"
  fi
  
  # Make sure it's executable
  chmod +x "$BINARY_NAME"
  
  # Show binary info
  echo "📦 Binary information:"
  ls -la "$BINARY_NAME"
  if command -v file >/dev/null 2>&1; then
    file "$BINARY_NAME"
  fi
  
  echo "✅ Download and extraction completed successfully"
  echo "🎯 Binary available as: $BINARY_NAME"
else
  echo "❌ Failed to extract binary from $ARCHIVE_NAME"
  exit 1
fi 