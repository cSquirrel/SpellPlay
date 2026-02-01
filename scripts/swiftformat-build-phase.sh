#!/bin/bash
# SwiftFormat Build Phase Script for SpellPlay
# Add this as a "Run Script" build phase in Xcode (before "Compile Sources")
#
# To add in Xcode:
# 1. Select the SpellPlay target
# 2. Go to "Build Phases" tab
# 3. Click "+" and select "New Run Script Phase"
# 4. Drag the new phase BEFORE "Compile Sources"
# 5. Paste the contents of this script (or reference it)
# 6. Set Shell to: /bin/bash
# 7. Uncheck "Based on dependency analysis" for consistent formatting
#
# Script Build Phase Settings:
#   Shell: /bin/bash
#   Script: "${SRCROOT}/scripts/swiftformat-build-phase.sh"

set -e

# Check if we should skip formatting (useful for CI or quick builds)
if [ "${SKIP_SWIFTFORMAT}" = "1" ]; then
    echo "Skipping SwiftFormat (SKIP_SWIFTFORMAT=1)"
    exit 0
fi

# Only format on Debug builds to speed up Release builds
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "Skipping SwiftFormat for Release build"
    exit 0
fi

# Find SwiftFormat
if command -v swiftformat &> /dev/null; then
    SWIFTFORMAT_PATH="swiftformat"
elif [ -f "/opt/homebrew/bin/swiftformat" ]; then
    SWIFTFORMAT_PATH="/opt/homebrew/bin/swiftformat"
elif [ -f "/usr/local/bin/swiftformat" ]; then
    SWIFTFORMAT_PATH="/usr/local/bin/swiftformat"
else
    echo "warning: SwiftFormat not found. Install via: brew install swiftformat"
    exit 0
fi

echo "Running SwiftFormat..."

# Format only changed files for speed (if git is available)
if command -v git &> /dev/null && [ -d "${SRCROOT}/.git" ]; then
    # Get modified and staged Swift files
    CHANGED_FILES=$(cd "${SRCROOT}" && git diff --name-only --diff-filter=d HEAD 2>/dev/null | grep '\.swift$' || true)
    STAGED_FILES=$(cd "${SRCROOT}" && git diff --cached --name-only --diff-filter=d 2>/dev/null | grep '\.swift$' || true)
    
    # Combine unique files
    ALL_FILES=$(echo -e "${CHANGED_FILES}\n${STAGED_FILES}" | sort -u | grep -v '^$' || true)
    
    if [ -n "${ALL_FILES}" ]; then
        echo "Formatting $(echo "${ALL_FILES}" | wc -l | tr -d ' ') changed file(s)..."
        echo "${ALL_FILES}" | while read -r file; do
            if [ -f "${SRCROOT}/${file}" ]; then
                "${SWIFTFORMAT_PATH}" "${SRCROOT}/${file}" --config "${SRCROOT}/.swiftformat" --quiet
            fi
        done
    else
        echo "No changed Swift files to format"
    fi
else
    # Fallback: format all Swift files in the SpellPlay directory
    echo "Formatting all Swift files in SpellPlay..."
    "${SWIFTFORMAT_PATH}" "${SRCROOT}/SpellPlay" --config "${SRCROOT}/.swiftformat" --quiet
fi

echo "SwiftFormat completed"

