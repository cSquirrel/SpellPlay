# SwiftFormat Makefile for SpellPlay
# Usage: make format | make lint | make format-check

.PHONY: format lint format-check format-staged help install-swiftformat

# Default target
help:
	@echo "SwiftFormat Commands:"
	@echo "  make format         - Format all Swift files"
	@echo "  make format-check   - Check formatting without making changes (dry-run)"
	@echo "  make lint           - Lint all Swift files (report issues)"
	@echo "  make format-staged  - Format only git-staged Swift files"
	@echo "  make install        - Install SwiftFormat via Homebrew"
	@echo ""
	@echo "Options:"
	@echo "  VERBOSE=1           - Show detailed output"

# Check if SwiftFormat is installed
SWIFTFORMAT := $(shell command -v swiftformat 2>/dev/null)

ifndef SWIFTFORMAT
$(error SwiftFormat is not installed. Run 'make install' or 'brew install swiftformat')
endif

# Directories to format
SOURCES := SpellPlay SpellPlayUITests

# Common flags
ifdef VERBOSE
VERBOSITY := --verbose
else
VERBOSITY := 
endif

# Format all Swift files
format:
	@echo "Formatting Swift files..."
	@swiftformat $(SOURCES) --config .swiftformat $(VERBOSITY)
	@echo "✅ Formatting complete"

# Check formatting without making changes
format-check:
	@echo "Checking Swift file formatting (dry-run)..."
	@swiftformat $(SOURCES) --config .swiftformat --dryrun $(VERBOSITY)
	@echo "✅ Dry-run complete"

# Lint mode - report issues without fixing
lint:
	@echo "Linting Swift files..."
	@swiftformat $(SOURCES) --config .swiftformat --lint $(VERBOSITY)
	@echo "✅ Lint complete"

# Format only staged files (useful for pre-commit)
format-staged:
	@echo "Formatting staged Swift files..."
	@git diff --cached --name-only --diff-filter=d | grep '\.swift$$' | xargs -I {} swiftformat {} --config .swiftformat $(VERBOSITY)
	@echo "✅ Staged files formatted"

# Install SwiftFormat
install:
	@echo "Installing SwiftFormat via Homebrew..."
	@brew install swiftformat
	@echo "✅ SwiftFormat installed: $$(swiftformat --version)"

