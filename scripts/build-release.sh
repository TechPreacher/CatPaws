#!/bin/bash
set -e

# CatPaws Release Build Script
# Builds, signs, notarizes, and packages the app for distribution

# Configuration
TEAM_ID="M9Y77E7ZX5"
SIGNING_IDENTITY="Developer ID Application: Sascha Corti (${TEAM_ID})"
NOTARYTOOL_PROFILE="notarytool-profile"
BUNDLE_ID="com.corti.CatPaws"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT="${PROJECT_ROOT}/CatPaws"
BUILD_DIR="${XCODE_PROJECT}/build"
RELEASE_DIR="${BUILD_DIR}/Build/Products/Release"

echo -e "${GREEN}=== CatPaws Release Build Script ===${NC}"
echo ""

# Prompt for version number
read -p "Enter version number (e.g., 1.0.0): " VERSION
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 1.0.0)${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Building CatPaws v${VERSION}...${NC}"
echo ""

# Step 1: Clean and build
echo -e "${GREEN}[1/6] Building Release configuration...${NC}"
cd "$XCODE_PROJECT"
rm -rf "$BUILD_DIR"
xcodebuild build \
    -scheme CatPaws \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    CODE_SIGN_ENTITLEMENTS=CatPaws/Configuration/CatPaws-Release.entitlements \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    MARKETING_VERSION="$VERSION" \
    | grep -E "(Build|error:|warning:|\*\*)" || true

if [[ ! -d "${RELEASE_DIR}/CatPaws.app" ]]; then
    echo -e "${RED}Error: Build failed - CatPaws.app not found${NC}"
    exit 1
fi
echo -e "${GREEN}Build successful!${NC}"
echo ""

# Step 2: Verify code signing
echo -e "${GREEN}[2/6] Verifying code signature...${NC}"
codesign --verify --deep --strict "${RELEASE_DIR}/CatPaws.app"
echo "Signature verified."

# Check entitlements don't include get-task-allow
if codesign -d --entitlements - "${RELEASE_DIR}/CatPaws.app" 2>&1 | grep -q "get-task-allow"; then
    echo -e "${RED}Error: App contains get-task-allow entitlement (not allowed for distribution)${NC}"
    exit 1
fi
echo "Entitlements verified (no get-task-allow)."
echo ""

# Step 3: Create ZIP for notarization
echo -e "${GREEN}[3/6] Creating ZIP for notarization...${NC}"
cd "$RELEASE_DIR"
rm -f CatPaws-notarize.zip
ditto -c -k --keepParent CatPaws.app CatPaws-notarize.zip
echo "ZIP created."
echo ""

# Step 4: Submit for notarization
echo -e "${GREEN}[4/6] Submitting for notarization (this may take several minutes)...${NC}"
NOTARIZE_OUTPUT=$(xcrun notarytool submit CatPaws-notarize.zip \
    --keychain-profile "$NOTARYTOOL_PROFILE" \
    --wait 2>&1)

echo "$NOTARIZE_OUTPUT"

if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    echo -e "${GREEN}Notarization successful!${NC}"
else
    echo -e "${RED}Notarization failed!${NC}"
    # Extract submission ID and get log
    SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
    if [[ -n "$SUBMISSION_ID" ]]; then
        echo "Fetching notarization log..."
        xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARYTOOL_PROFILE"
    fi
    exit 1
fi
echo ""

# Step 5: Staple the ticket
echo -e "${GREEN}[5/6] Stapling notarization ticket...${NC}"
xcrun stapler staple CatPaws.app
echo ""

# Step 6: Create distribution packages
echo -e "${GREEN}[6/6] Creating distribution packages...${NC}"

# Create DMG
rm -rf dmg_contents "CatPaws-${VERSION}.dmg"
mkdir dmg_contents
cp -R CatPaws.app dmg_contents/
hdiutil create -volname "CatPaws ${VERSION}" -srcfolder dmg_contents -ov -format UDZO "CatPaws-${VERSION}.dmg"
rm -rf dmg_contents
echo "DMG created: CatPaws-${VERSION}.dmg"

# Create ZIP
rm -f "CatPaws-${VERSION}.zip"
ditto -c -k --keepParent CatPaws.app "CatPaws-${VERSION}.zip"
echo "ZIP created: CatPaws-${VERSION}.zip"

# Cleanup
rm -f CatPaws-notarize.zip

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Distribution files created in: ${RELEASE_DIR}"
echo "  - CatPaws-${VERSION}.dmg"
echo "  - CatPaws-${VERSION}.zip"
echo ""
echo "Next steps:"
echo "  1. Create a git tag: git tag -a v${VERSION} -m \"Release ${VERSION}\""
echo "  2. Push the tag: git push origin v${VERSION}"
echo "  3. Create a GitHub release and upload the DMG and ZIP files"
