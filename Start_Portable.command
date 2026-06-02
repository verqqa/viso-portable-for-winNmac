#!/bin/bash
# ===================================================================
#  VisoMaster Fusion Portable Launcher - macOS
#  Supports: Intel (x86_64) and Apple Silicon (arm64)
#  Requirements: macOS 12+ recommended, internet on first run
# ===================================================================

# Always run from the script's own directory (important for double-click)
cd "$(dirname "$0")"

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${CYAN}>>> $1${NC}"; }

wait_exit() { echo ""; read -rp "Press Enter to close..."; exit "${1:-1}"; }

# --- Paths ---
BASE_DIR="$(pwd)"
PORTABLE_DIR="$BASE_DIR/portable-files"
CONFIG_FILE="$BASE_DIR/portable.cfg"
REPO_URL="https://github.com/VisoMasterFusion/VisoMaster-Fusion.git"
REPO_NAME="VisoMaster-Fusion"
APP_DIR="$BASE_DIR/$REPO_NAME"

UV_DIR="$PORTABLE_DIR/uv-mac"
UV_EXE="$UV_DIR/uv"
export UV_PYTHON_INSTALL_DIR="$PORTABLE_DIR/uv-python"
export UV_CACHE_DIR="$PORTABLE_DIR/uv-cache"

FFMPEG_DIR="$PORTABLE_DIR/ffmpeg-mac"
FFMPEG_BIN_PATH="$FFMPEG_DIR"
PYTHON_VERSION="3.12"
NEEDS_INSTALL=false

mkdir -p "$PORTABLE_DIR"

# --- Config helpers ---
cfg_get() {
    grep -i "^${1}=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2- | tr -d '[:space:]'
}
cfg_set() {
    local key="$1" val="$2"
    if grep -qi "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i '' "s|^${key}=.*|${key}=${val}|i" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

echo ""
echo "==================================================================="
echo "  VisoMaster Fusion Portable Launcher - macOS"
echo "==================================================================="

# --- Fast-launch check (already installed) ---
LAUNCHER_ENABLED=$(cfg_get LAUNCHER_ENABLED)
if [ "$LAUNCHER_ENABLED" = "1" ]; then
    PYTHON_EXE=$("$UV_EXE" python find "$PYTHON_VERSION" 2>/dev/null)
    if [ -n "$PYTHON_EXE" ] && [ -d "$APP_DIR/.git" ]; then
        log_info "Existing installation detected. Launching..."
        export PATH="$FFMPEG_BIN_PATH:$PATH"
        cd "$APP_DIR"
        "$PYTHON_EXE" -m app.ui.launcher
        EXIT=$?
        cd "$BASE_DIR"
        wait_exit $EXIT
    fi
fi

log_step "Entering setup / update mode..."

# --- Detect architecture ---
ARCH=$(uname -m)
log_info "Architecture: $ARCH (macOS $(sw_vers -productVersion))"

if [ "$ARCH" = "arm64" ]; then
    UV_URL="https://github.com/astral-sh/uv/releases/download/0.8.22/uv-aarch64-apple-darwin.tar.gz"
    FFMPEG_ZIP_URL="https://www.osxexperts.net/ffmpeg711ARM.zip"
else
    UV_URL="https://github.com/astral-sh/uv/releases/download/0.8.22/uv-x86_64-apple-darwin.tar.gz"
    FFMPEG_ZIP_URL="https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
fi

# ===================================================================
# Step 1: Verify Git is available
# ===================================================================
log_step "Step 1: Checking Git..."
if ! command -v git &>/dev/null; then
    log_warn "Git not found. Triggering Xcode Command Line Tools installer..."
    xcode-select --install 2>/dev/null || true
    log_error "Please complete the Xcode CLT install popup, then re-run this script."
    wait_exit 1
fi
GIT_EXE=$(command -v git)
log_info "Git: $GIT_EXE"

# ===================================================================
# Step 2: Determine branch
# ===================================================================
log_step "Step 2: Determining branch..."
BRANCH=$(cfg_get BRANCH)
if [ -z "$BRANCH" ]; then
    if [ "${1:-}" = "dev" ]; then
        BRANCH="dev"
        log_info "Dev argument detected. Using branch: dev"
    else
        BRANCH="main"
        log_info "Defaulting to branch: main"
    fi
    cfg_set BRANCH "$BRANCH"
fi
log_info "Branch: $BRANCH"

# ===================================================================
# Step 3: Clone or update repository
# ===================================================================
log_step "Step 3: Repository..."
if [ ! -d "$APP_DIR/.git" ]; then
    [ -d "$APP_DIR" ] && rm -rf "$APP_DIR"
    log_info "Cloning repository (branch: $BRANCH)..."
    "$GIT_EXE" clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR" \
        || { log_error "Clone failed. Check internet connection."; wait_exit 1; }
    NEEDS_INSTALL=true
else
    log_info "Repository found. Checking for updates..."
    cd "$APP_DIR"
    "$GIT_EXE" checkout "$BRANCH" --quiet 2>/dev/null

    if "$GIT_EXE" fetch --quiet 2>/dev/null; then
        LOCAL=$("$GIT_EXE" rev-parse HEAD)
        REMOTE=$("$GIT_EXE" rev-parse "origin/$BRANCH" 2>/dev/null)
        if [ "$LOCAL" != "$REMOTE" ]; then
            echo ""
            log_warn "Updates are available on branch '$BRANCH'."
            read -rp "Update now? This discards local changes. [y/N]: " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                "$GIT_EXE" reset --hard "origin/$BRANCH" \
                    || { log_error "Reset failed."; cd "$BASE_DIR"; wait_exit 1; }
                log_info "Repository updated."
                cfg_set DOWNLOAD_RUN false
                NEEDS_INSTALL=true
            fi
        else
            log_info "Repository is up to date."
        fi
    else
        log_warn "Offline or GitHub unreachable — skipping update check."
    fi
    cd "$BASE_DIR"
fi

# ===================================================================
# Step 4: Install UV (package + Python manager)
# ===================================================================
log_step "Step 4: UV package manager..."
if [ ! -f "$UV_EXE" ]; then
    log_info "Downloading UV..."
    mkdir -p "$UV_DIR"
    curl -fsSL "$UV_URL" -o "$PORTABLE_DIR/uv-mac.tar.gz" \
        || { log_error "Failed to download UV."; wait_exit 1; }
    tar -xzf "$PORTABLE_DIR/uv-mac.tar.gz" -C "$UV_DIR" --strip-components=1 2>/dev/null \
        || tar -xzf "$PORTABLE_DIR/uv-mac.tar.gz" -C "$UV_DIR"
    # Locate uv in case strip-components changed path
    if [ ! -f "$UV_EXE" ]; then
        FOUND=$(find "$UV_DIR" -name "uv" -type f 2>/dev/null | head -1)
        [ -n "$FOUND" ] && ln -sf "$FOUND" "$UV_EXE"
    fi
    chmod +x "$UV_EXE" 2>/dev/null
    rm -f "$PORTABLE_DIR/uv-mac.tar.gz"
fi
log_info "UV: $UV_EXE"

# ===================================================================
# Step 5: Install Python 3.12 via UV
# ===================================================================
log_step "Step 5: Python $PYTHON_VERSION..."
if ! "$UV_EXE" python find "$PYTHON_VERSION" &>/dev/null; then
    log_info "Installing Python $PYTHON_VERSION (this is a one-time download)..."
    "$UV_EXE" python install "$PYTHON_VERSION" \
        || { log_error "Python install failed."; wait_exit 1; }
    NEEDS_INSTALL=true
fi
PYTHON_EXE=$("$UV_EXE" python find "$PYTHON_VERSION")
log_info "Python: $PYTHON_EXE"

# ===================================================================
# Step 6: Check if dependencies need installing
# ===================================================================
if [ "$NEEDS_INSTALL" = "false" ]; then
    if ! "$PYTHON_EXE" -c "import PySide6" 2>/dev/null; then
        log_info "Missing packages detected — forcing reinstall..."
        NEEDS_INSTALL=true
    fi
fi

# ===================================================================
# Step 7: Install Python dependencies
# ===================================================================
log_step "Step 7: Python dependencies..."
REQUIREMENTS="$APP_DIR/requirements_mac.txt"
[ ! -f "$REQUIREMENTS" ] && REQUIREMENTS="$APP_DIR/requirements.txt"
if [ "$NEEDS_INSTALL" = "true" ]; then
    log_info "Installing from: $(basename "$REQUIREMENTS")"
    log_info "This may take 10-30 minutes on first run..."
    "$UV_EXE" pip install -r "$REQUIREMENTS" --python "$PYTHON_EXE" \
        || { log_error "Dependency install failed."; wait_exit 1; }
    log_info "Cleaning UV cache..."
    "$UV_EXE" cache clean
fi

# ===================================================================
# Step 8: Install FFmpeg
# ===================================================================
log_step "Step 8: FFmpeg..."
if command -v ffmpeg &>/dev/null; then
    FFMPEG_BIN_PATH="$(dirname "$(command -v ffmpeg)")"
    log_info "FFmpeg found on PATH: $FFMPEG_BIN_PATH"
elif [ -f "$FFMPEG_DIR/ffmpeg" ]; then
    log_info "FFmpeg already downloaded."
elif command -v brew &>/dev/null; then
    log_info "Installing FFmpeg via Homebrew (handles Intel + Apple Silicon automatically)..."
    brew install ffmpeg
    FFMPEG_BIN_PATH="$(brew --prefix)/bin"
else
    log_info "Downloading static FFmpeg binary for $ARCH..."
    mkdir -p "$FFMPEG_DIR"
    curl -fsSL "$FFMPEG_ZIP_URL" -o "$PORTABLE_DIR/ffmpeg-mac.zip" \
        || { log_warn "FFmpeg download failed — app may not handle video. Continuing..."; }
    if [ -f "$PORTABLE_DIR/ffmpeg-mac.zip" ]; then
        unzip -o -q "$PORTABLE_DIR/ffmpeg-mac.zip" -d "$FFMPEG_DIR"
        rm -f "$PORTABLE_DIR/ffmpeg-mac.zip"
        # Find and move binaries to top of FFMPEG_DIR
        for tool in ffmpeg ffprobe ffplay; do
            BIN=$(find "$FFMPEG_DIR" -name "$tool" -type f 2>/dev/null | head -1)
            if [ -n "$BIN" ] && [ "$BIN" != "$FFMPEG_DIR/$tool" ]; then
                mv "$BIN" "$FFMPEG_DIR/$tool"
            fi
            [ -f "$FFMPEG_DIR/$tool" ] && chmod +x "$FFMPEG_DIR/$tool"
        done
        # Remove macOS quarantine so binaries run without Gatekeeper block
        xattr -dr com.apple.quarantine "$FFMPEG_DIR" 2>/dev/null || true
    fi
fi
log_info "FFmpeg: $FFMPEG_BIN_PATH"

# ===================================================================
# Step 9: Download models
# ===================================================================
log_step "Step 9: AI models..."
DOWNLOAD_RUN=$(cfg_get DOWNLOAD_RUN)
[ "$NEEDS_INSTALL" = "true" ] && DOWNLOAD_RUN="false"

if [ "$DOWNLOAD_RUN" != "true" ]; then
    echo ""
    echo "  Model downloader will run next."
    echo "  If you already have the models, copy them to:"
    echo "  $APP_DIR/model_assets"
    echo "  then press Enter to skip the download."
    echo ""
    read -rp "Press Enter to continue..."
    cd "$APP_DIR"
    "$PYTHON_EXE" download_models.py
    MODEL_EXIT=$?
    cd "$BASE_DIR"
    [ $MODEL_EXIT -eq 0 ] && cfg_set DOWNLOAD_RUN true
fi

# ===================================================================
# Finalise config
# ===================================================================
if [ "$(cfg_get LAUNCHER_ENABLED)" != "1" ]; then
    cfg_set LAUNCHER_ENABLED 1
fi

# ===================================================================
# Step 10: Launch application
# ===================================================================
log_step "Step 10: Launching VisoMaster Fusion..."
export PATH="$FFMPEG_BIN_PATH:$PATH"
cd "$APP_DIR"

LAUNCHER_ENABLED=$(cfg_get LAUNCHER_ENABLED)
if [ "$LAUNCHER_ENABLED" = "1" ]; then
    "$PYTHON_EXE" -m app.ui.launcher
    EXIT=$?
else
    PYTHONPATH="$APP_DIR" "$PYTHON_EXE" main.py
    EXIT=$?
fi

cd "$BASE_DIR"
echo ""
echo "Application closed."
wait_exit $EXIT
