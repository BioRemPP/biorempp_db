#!/usr/bin/env bash
# ============================================================================
# BioRemPP Database Documentation Build Script
# ============================================================================
# Purpose: Automate documentation generation, build, and serving using MkDocs
# Usage:
#   ./build-docs.sh                # Build documentation
#   ./build-docs.sh serve          # Build and serve locally
#   ./build-docs.sh install        # Install documentation dependencies
#   ./build-docs.sh clean          # Clean build artifacts
#   ./build-docs.sh help           # Show help
# ============================================================================

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
readonly VENV_NAME="venv"
readonly DOCS_DIR="docs"
readonly SITE_DIR="site"
readonly PORT=8002
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${BIODBROOT:-$(dirname "$SCRIPT_DIR")}"

# Required Python packages
readonly REQUIRED_PACKAGES=(
    "mkdocs"
    "mkdocs-material"
    "pymdown-extensions"
    "mkdocs-minify-plugin"
)

# Detect Python command (handles Windows Python Launcher and MS Store aliases)
detect_python_cmd() {
    local python_candidates=()

    # On Windows, try py launcher first (most reliable)
    if command -v py &>/dev/null; then
        # Verify it's not a stub
        if py --version &>/dev/null 2>&1; then
            echo "py"
            return 0
        fi
    fi

    # Try python3 and python, but validate they're real
    for cmd in python3 python; do
        if command -v "$cmd" &>/dev/null; then
            # Test if it's a real Python (not MS Store stub)
            if "$cmd" --version &>/dev/null 2>&1; then
                echo "$cmd"
                return 0
            fi
        fi
    done

    return 1
}

readonly PYTHON_CMD="$(detect_python_cmd || echo "")"

# ============================================================================
# Color Output Functions
# ============================================================================
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_CYAN='\033[0;36m'

log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"; }
log_info() { echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $*"; }
log_warn() { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"; }
log_error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2; }

# ============================================================================
# Banner
# ============================================================================
show_banner() {
    echo ""
    echo -e "${COLOR_CYAN}============================================================${COLOR_RESET}"
    echo -e "${COLOR_CYAN}    BioRemPP Database Documentation Build Tool             ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}                   Version 1.0.0                           ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}============================================================${COLOR_RESET}"
    echo ""
}

# ============================================================================
# Help Message
# ============================================================================
show_help() {
    cat << EOF
${COLOR_YELLOW}Usage:${COLOR_RESET} ./build-docs.sh [COMMAND]

${COLOR_YELLOW}Commands:${COLOR_RESET}
  install       Install documentation dependencies
  serve         Build and serve documentation locally
  clean         Clean build artifacts
  help          Show this help message
  (no args)     Build documentation

${COLOR_YELLOW}Examples:${COLOR_RESET}
  ./build-docs.sh install       # First time setup
  ./build-docs.sh serve         # Develop with live reload
  ./build-docs.sh               # Build static site
  ./build-docs.sh clean         # Clean build artifacts

${COLOR_YELLOW}Environment Variables:${COLOR_RESET}
  BIODBVENV     Path to virtual environment (optional)
  BIODBROOT     Path to project root (optional)

EOF
}

# ============================================================================
# Virtual Environment Resolution
# ============================================================================
resolve_venv() {
    # Allow override via environment variable
    if [[ -n "${BIODBVENV:-}" ]] && [[ -d "$BIODBVENV" ]]; then
        echo "$BIODBVENV"
        return 0
    fi

    # Try multiple candidate locations (check both Unix and Windows paths)
    local candidates=(
        "$PROJECT_ROOT/$VENV_NAME"
        "$SCRIPT_DIR/$VENV_NAME"
        "$SCRIPT_DIR/../$VENV_NAME"
        "$(pwd)/$VENV_NAME"
    )

    for candidate in "${candidates[@]}"; do
        # Check for both Unix (bin/python) and Windows (Scripts/python.exe) structure
        if [[ -d "$candidate" ]]; then
            if [[ -f "$candidate/bin/python" ]] || [[ -f "$candidate/Scripts/python.exe" ]]; then
                echo "$(cd "$candidate" && pwd)"
                return 0
            fi
        fi
    done

    return 1
}

# ============================================================================
# Create Virtual Environment
# ============================================================================
create_venv() {
    local venv_path="$PROJECT_ROOT/$VENV_NAME"

    if [[ -z "$PYTHON_CMD" ]]; then
        log_error "Python not found. Please install Python 3.8+"
        log_info "Download from: https://www.python.org/downloads/"
        log_info "On Windows: Make sure to check 'Add Python to PATH' during installation"
        return 1
    fi

    log_info "Creating virtual environment at: $venv_path"
    log_info "Using Python: $PYTHON_CMD (version: $($PYTHON_CMD --version 2>&1))"

    # Create venv with proper error handling
    if ! $PYTHON_CMD -m venv "$venv_path" >/dev/null 2>&1; then
        log_error "Failed to create virtual environment"
        log_info "Try manually: $PYTHON_CMD -m venv venv"
        return 1
    fi

    log_success "Virtual environment created successfully"
    # Don't echo the path, set it via global variable
    CREATED_VENV_PATH="$venv_path"
    return 0
}

# ============================================================================
# Virtual Environment Check and Activation
# ============================================================================
setup_venv() {
    local venv_path
    local auto_create="${1:-false}"

    # Try to resolve existing venv
    venv_path=$(resolve_venv 2>/dev/null) || true

    if [[ -n "$venv_path" ]]; then
        VENV_PATH="$venv_path"
    else
        if [[ "$auto_create" == "true" ]]; then
            log_warn "Virtual environment not found. Creating one..."
            if ! create_venv; then
                return 1
            fi
            VENV_PATH="$CREATED_VENV_PATH"
        else
            log_error "Virtual environment not found"
            log_info "Run: ./build-docs.sh install (to auto-create)"
            log_info "Or manually: $PYTHON_CMD -m venv venv"
            log_info "Or set BIODBVENV environment variable"
            return 1
        fi
    fi

    # Determine Python executable path (cross-platform)
    # Try Windows path first, then Unix
    local python_exe=""

    if [[ -f "$VENV_PATH/Scripts/python.exe" ]]; then
        python_exe="$VENV_PATH/Scripts/python.exe"
    elif [[ -f "$VENV_PATH/bin/python" ]]; then
        python_exe="$VENV_PATH/bin/python"
    elif [[ -f "$VENV_PATH/bin/python3" ]]; then
        python_exe="$VENV_PATH/bin/python3"
    fi

    if [[ -z "$python_exe" ]]; then
        log_error "Python executable not found in virtual environment: $VENV_PATH"
        return 1
    fi

    PYTHON_EXE="$python_exe"

    PIP_CMD="$PYTHON_EXE -m pip"

    log_info "Using virtual environment: $VENV_PATH"
    log_info "Python executable: $PYTHON_EXE"
    log_success "Virtual environment ready"
    return 0
}

# ============================================================================
# Package Installation Check
# ============================================================================
is_package_installed() {
    local package="$1"
    local pkg_name="${package%%[*}"  # Remove extras like [python]
    $PIP_CMD show "$pkg_name" &>/dev/null
}

# ============================================================================
# Install Documentation Dependencies
# ============================================================================
install_dependencies() {
    log_info "Installing documentation dependencies..."

    # Upgrade pip, setuptools, wheel
    log_info "Upgrading pip, setuptools, and wheel..."
    $PYTHON_EXE -m pip install --upgrade pip setuptools wheel --quiet 2>&1 || true

    # Install all required packages in one go (faster)
    log_info "Installing MkDocs and plugins..."
    if $PIP_CMD install "${REQUIRED_PACKAGES[@]}" --upgrade --quiet 2>&1; then
        log_success "All packages installed successfully"
    else
        log_warn "Batch installation failed. Trying individual package installation..."
        local failed_packages=()

        for package in "${REQUIRED_PACKAGES[@]}"; do
            log_info "Installing $package..."
            if ! $PIP_CMD install "$package" --quiet 2>&1; then
                failed_packages+=("$package")
            fi
        done

        if [[ ${#failed_packages[@]} -gt 0 ]]; then
            log_error "Failed to install packages: ${failed_packages[*]}"
            return 1
        fi
    fi

    # Verify installation
    log_info "Verifying installation..."
    local all_installed=true
    local check_symbol="✓"

    # Use simpler symbols for Windows compatibility
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        check_symbol="+"
    fi

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if is_package_installed "$package"; then
            log_success "  $check_symbol $package installed"
        else
            log_warn "  x $package not found"
            all_installed=false
        fi
    done

    if [[ "$all_installed" == true ]]; then
        log_success "All documentation dependencies installed successfully"
        echo ""
        log_success "Setup complete! Next steps:"
        log_info "  1. Run: ./build-docs.sh serve"
        log_info "  2. Open: http://localhost:$PORT"
        return 0
    else
        log_error "Some packages failed to install"
        return 1
    fi
}

# ============================================================================
# Clean Build Artifacts
# ============================================================================
clean_artifacts() {
    log_info "Cleaning build artifacts..."

    local site_path="$PROJECT_ROOT/$SITE_DIR"

    if [[ -d "$site_path" ]]; then
        rm -rf "$site_path"
        log_success "Removed $SITE_DIR directory"
    else
        log_info "No $SITE_DIR directory to clean"
    fi

    # Clean Python cache files
    log_info "Cleaning Python cache files..."
    find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$PROJECT_ROOT" -type f -name "*.pyc" -delete 2>/dev/null || true

    log_success "Build artifacts cleaned"
}

# ============================================================================
# Install Missing Dependencies
# ============================================================================
ensure_dependencies() {
    local missing_packages=()

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_packages[*]}"
        log_info "Installing missing dependencies..."

        for package in "${missing_packages[@]}"; do
            log_info "  Installing $package..."
            if ! $PIP_CMD install "$package" --quiet; then
                log_error "Failed to install $package"
                return 1
            fi
        done

        log_success "All required dependencies installed"
    fi

    return 0
}

# ============================================================================
# Build Documentation
# ============================================================================
build_documentation() {
    log_info "Building documentation..."

    # Ensure dependencies are installed
    if ! ensure_dependencies; then
        return 1
    fi

    # Verify mkdocs.yml exists
    local mkdocs_config="$PROJECT_ROOT/mkdocs.yml"
    if [[ ! -f "$mkdocs_config" ]]; then
        log_error "mkdocs.yml not found at: $mkdocs_config"
        return 1
    fi

    log_info "Project root: $PROJECT_ROOT"
    log_info "Running mkdocs build..."

    # Build from project root
    if ! (cd "$PROJECT_ROOT" && $PYTHON_EXE -m mkdocs build --clean); then
        log_error "MkDocs build failed"
        return 1
    fi

    # Verify output
    local site_path="$PROJECT_ROOT/$SITE_DIR"
    local index_path="$site_path/index.html"

    if [[ -f "$index_path" ]]; then
        log_success "Documentation built successfully"
        log_info "Output directory: $site_path"

        # Calculate and display size
        if command -v du &>/dev/null; then
            local size_kb=$(du -sk "$site_path" 2>/dev/null | cut -f1)
            local size_mb=$(awk "BEGIN {printf \"%.2f\", $size_kb/1024}")
            log_info "Total size: ${size_mb} MB"
        fi

        echo ""
        log_success "Documentation ready!"
        log_info "Open: $index_path"
        log_info "Or serve with: ./build-docs.sh serve"
        return 0
    else
        log_error "Build completed but output not found at: $site_path"
        return 1
    fi
}

# ============================================================================
# Serve Documentation Locally
# ============================================================================
serve_documentation() {
    log_info "Starting documentation server..."
    log_info "URL: http://localhost:$PORT"
    log_info "Press Ctrl+C to stop"
    echo ""

    # Ensure dependencies are installed
    if ! ensure_dependencies; then
        return 1
    fi

    # Verify mkdocs.yml exists
    if [[ ! -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
        log_error "mkdocs.yml not found at: $PROJECT_ROOT/mkdocs.yml"
        return 1
    fi

    # Serve from project root
    cd "$PROJECT_ROOT"
    $PYTHON_EXE -m mkdocs serve --dev-addr "localhost:$PORT"
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    show_banner

    local command="${1:-build}"

    # Validate Python availability early (except for clean and help commands)
    if [[ "$command" != "clean" ]] && [[ "$command" != "help" ]] && [[ "$command" != "--help" ]] && [[ "$command" != "-h" ]]; then
        if [[ -z "$PYTHON_CMD" ]]; then
            log_error "Python not found in system PATH"
            echo ""
            log_info "Please install Python 3.8+ from: https://www.python.org/downloads/"
            echo ""
            log_info "Windows users:"
            log_info "  1. Download and run Python installer"
            log_info "  2. CHECK 'Add Python to PATH' during installation"
            log_info "  3. Restart Git Bash/terminal"
            log_info "  4. Verify with: py --version"
            echo ""
            log_info "Linux/macOS users:"
            log_info "  Ubuntu/Debian: sudo apt install python3 python3-venv"
            log_info "  macOS: brew install python3"
            exit 1
        fi
        log_info "Python detected: $PYTHON_CMD ($($PYTHON_CMD --version 2>&1))"
    fi

    case "$command" in
        help|--help|-h)
            show_help
            exit 0
            ;;
        install)
            # Auto-create venv if not found
            if ! setup_venv true; then
                log_error "Failed to setup virtual environment"
                exit 1
            fi
            install_dependencies
            exit $?
            ;;
        clean)
            clean_artifacts
            exit 0
            ;;
        serve)
            # Don't auto-create for serve, user should install first
            if ! setup_venv false; then
                log_error "Failed to setup virtual environment"
                exit 1
            fi
            serve_documentation
            exit $?
            ;;
        build|"")
            # Don't auto-create for build, user should install first
            if ! setup_venv false; then
                log_error "Failed to setup virtual environment"
                exit 1
            fi
            build_documentation
            exit $?
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# ============================================================================
# Entry Point
# ============================================================================
main "$@"
