#!/bin/bash
# ==============================================================================
# LinearBar Quick Test Script
# ==============================================================================
# Quickly run tests without the full deployment workflow.
# Useful for local development and CI/CD pipelines.
#
# Usage: ./quick-test.sh
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Navigate to script directory (project root)
cd "$(dirname "$0")"

echo ""
echo "🧪 Running LinearBar tests..."
echo ""

if [ ! -d "vendor/bundle" ]; then
    echo "Installing dependencies first..."
    bundle install
    echo ""
fi

bundle exec fastlane test

echo ""
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
