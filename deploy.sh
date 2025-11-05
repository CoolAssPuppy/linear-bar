#!/bin/bash
# ==============================================================================
# LinearBar Deployment Script
# ==============================================================================
# This script provides an interactive menu for deploying LinearBar to
# TestFlight or the Mac App Store.
#
# Usage:
#   ./deploy.sh                    # Interactive menu
#   ./deploy.sh beta              # Deploy to TestFlight
#   ./deploy.sh release           # Deploy to App Store
#   ./deploy.sh bump-patch        # Bump patch version
#   ./deploy.sh bump-minor        # Bump minor version
#   ./deploy.sh bump-major        # Bump major version
# ==============================================================================

set -e  # Exit on any error

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Emoji for visual appeal
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
ERROR="❌"
INFO="ℹ️"

# Navigate to script directory (project root)
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"

# ==============================================================================
# Helper Functions
# ==============================================================================

print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}  $1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Ruby
    if ! command -v ruby &> /dev/null; then
        print_error "Ruby is not installed"
        echo "Install Ruby from: https://www.ruby-lang.org/"
        exit 1
    fi
    print_success "Ruby installed: $(ruby --version | awk '{print $2}')"

    # Check Bundler
    if ! command -v bundle &> /dev/null; then
        print_error "Bundler is not installed"
        echo "Install with: gem install bundler"
        exit 1
    fi
    print_success "Bundler installed"

    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed"
        exit 1
    fi
    print_success "Xcode installed: $(xcodebuild -version | head -1)"

    # Check .env file
    if [ ! -f .env ]; then
        print_error ".env file not found"
        echo ""
        echo "To create your .env file:"
        echo "  1. cp .env.default .env"
        echo "  2. Edit .env with your Apple Developer credentials"
        echo "  3. Add your App Store Connect API key to fastlane/app_store_connect_api_key.p8"
        echo ""
        echo "See DEPLOY-STEPS.md for detailed setup instructions"
        exit 1
    fi
    print_success ".env file found"

    # Check if gems are installed
    if [ ! -d "vendor/bundle" ]; then
        print_warning "Gems not installed yet"
        echo ""
        read -p "Install dependencies now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bundle install
            print_success "Dependencies installed"
        else
            print_error "Please run 'bundle install' first"
            exit 1
        fi
    else
        print_success "Dependencies installed"
    fi

    echo ""
}

show_menu() {
    print_header "${ROCKET} LinearBar Deployment Menu"

    echo -e "${BOLD}Select deployment type:${NC}"
    echo ""
    echo "  1) ${GREEN}TestFlight${NC} - Deploy beta build for testing"
    echo "  2) ${YELLOW}App Store${NC} - Deploy production build for review"
    echo "  3) ${BLUE}Bump Patch Version${NC} (1.0.0 → 1.0.1)"
    echo "  4) ${BLUE}Bump Minor Version${NC} (1.0.0 → 1.1.0)"
    echo "  5) ${BLUE}Bump Major Version${NC} (1.0.0 → 2.0.0)"
    echo "  6) ${CYAN}Run Tests${NC}"
    echo "  7) ${CYAN}Pre-flight Checks${NC}"
    echo "  q) Quit"
    echo ""
}

deploy_beta() {
    print_header "${ROCKET} Deploying to TestFlight"

    # Get changelog
    echo ""
    read -p "Enter TestFlight changelog (or press Enter for default): " changelog
    if [ -n "$changelog" ]; then
        export TESTFLIGHT_CHANGELOG="$changelog"
    fi

    echo ""
    print_info "Deploying to TestFlight..."
    bundle exec fastlane beta

    echo ""
    print_success "Deployment complete!"
    print_info "Build will appear in TestFlight within 10-15 minutes"
    print_info "Check status at: https://appstoreconnect.apple.com"
}

deploy_release() {
    print_header "${ROCKET} Deploying to App Store"

    echo ""
    echo -e "${RED}${BOLD}⚠️  YOU ARE ABOUT TO DEPLOY TO PRODUCTION! ⚠️${NC}"
    echo ""
    echo "This will:"
    echo "  - Build a production-signed version"
    echo "  - Upload to App Store Connect"
    echo "  - Make the build available for App Store review"
    echo ""
    read -p "Are you ABSOLUTELY SURE you want to continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_warning "Deployment cancelled"
        exit 0
    fi

    # Check git status
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "You have uncommitted changes"
        git status --short
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Deployment cancelled"
            exit 0
        fi
    fi

    echo ""
    print_info "Deploying to App Store..."
    bundle exec fastlane release

    echo ""
    print_success "Deployment complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Go to App Store Connect"
    echo "  2. Fill in version information and 'What's New'"
    echo "  3. Add screenshots if needed"
    echo "  4. Submit for review when ready"
    echo "  5. Push git tags: git push --tags"
}

bump_version() {
    local bump_type=$1
    print_header "Bumping $bump_type version"

    echo ""
    print_info "Bumping $bump_type version..."
    bundle exec fastlane bump_$bump_type

    echo ""
    print_success "Version bumped successfully!"
    print_info "Don't forget to push: git push && git push --tags"
}

run_tests() {
    print_header "Running Tests"

    echo ""
    print_info "Running all tests..."
    bundle exec fastlane test

    echo ""
    print_success "All tests passed!"
}

run_preflight() {
    print_header "Running Pre-flight Checks"

    echo ""
    bundle exec fastlane prep

    echo ""
    print_success "All checks passed! Ready to deploy."
}

# ==============================================================================
# Main Script
# ==============================================================================

# Show current working directory
print_info "Working in: ${PROJECT_ROOT}"

# Handle command line arguments
if [ $# -gt 0 ]; then
    case "$1" in
        beta)
            check_prerequisites
            deploy_beta
            exit 0
            ;;
        release)
            check_prerequisites
            deploy_release
            exit 0
            ;;
        bump-patch)
            check_prerequisites
            bump_version "patch"
            exit 0
            ;;
        bump-minor)
            check_prerequisites
            bump_version "minor"
            exit 0
            ;;
        bump-major)
            check_prerequisites
            bump_version "major"
            exit 0
            ;;
        test)
            check_prerequisites
            run_tests
            exit 0
            ;;
        prep)
            check_prerequisites
            run_preflight
            exit 0
            ;;
        *)
            echo "Unknown command: $1"
            echo ""
            echo "Usage: $0 [beta|release|bump-patch|bump-minor|bump-major|test|prep]"
            exit 1
            ;;
    esac
fi

# Interactive menu
check_prerequisites

while true; do
    show_menu
    read -p "Enter choice: " choice
    echo ""

    case $choice in
        1)
            deploy_beta
            ;;
        2)
            deploy_release
            ;;
        3)
            bump_version "patch"
            ;;
        4)
            bump_version "minor"
            ;;
        5)
            bump_version "major"
            ;;
        6)
            run_tests
            ;;
        7)
            run_preflight
            ;;
        q|Q)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..." -r
    clear
done
