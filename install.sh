#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║   CatTerm Installer — makes your terminal go MEOW       ║
# ║   Usage: curl -fsSL <raw-url>/install.sh | bash         ║
# ╚══════════════════════════════════════════════════════════╝

set -e

RST="\033[0m"; BOLD="\033[1m"
GRN="\033[38;2;80;255;120m"; YLW="\033[38;2;255;220;50m"
RED="\033[38;2;255;80;80m";  PRP="\033[38;2;160;40;255m"
GRY="\033[38;2;130;130;130m"

say()  { echo -e "${GRN}${BOLD}  ✓ $1${RST}"; }
info() { echo -e "${YLW}  → $1${RST}"; }
warn() { echo -e "${RED}  ✗ $1${RST}"; }
dim()  { echo -e "${GRY}    $1${RST}"; }

# ── Detect repo location (works both from curl | bash and direct run) ─────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$PWD")"

# If piped from curl, we need to clone or download
if [[ "$REPO_DIR" == "/" || ! -f "$REPO_DIR/sounds/muhehehe.mp3" ]]; then
  REPO_DIR="$HOME/.catterm"
fi

SOUNDS_DIR="$REPO_DIR/sounds"
INSTALL_DIR="$HOME/.catterm"
EXT_DIR="$HOME/.vscode/extensions/catterm-sounds-0.0.1"
RCFILE="$HOME/.zshrc"
[[ ! -f "$RCFILE" ]] && RCFILE="$HOME/.bashrc"

GITHUB_RAW="https://raw.githubusercontent.com/yogesh0333/catterm/main"

# ── Banner ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${PRP}${BOLD}"
echo "    /\\_____/\\"
echo "   (  ^ω^  )   CatTerm Installer"
echo "    )     (    your terminal is about to get WEIRD"
echo "   ( ||||| )"
echo "    ‾‾‾‾‾‾‾"
echo -e "${RST}"

# ── 1. Check macOS ─────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  warn "CatTerm currently supports macOS only (uses afplay for audio)"
  warn "Linux/Windows support coming soon — PR welcome!"
  exit 1
fi

# ── 2. Create install directory ────────────────────────────────────────────────
info "Setting up ~/.catterm ..."
mkdir -p "$INSTALL_DIR/sounds"
say "Created $INSTALL_DIR"

# ── 3. Copy/download sounds ────────────────────────────────────────────────────
info "Installing sounds ..."

SOUNDS=(
  "muhehehe.mp3"
  "happy-happy-happy-song.mp3"
  "german-cat.mp3"
  "soulja-boy-saying-huh.mp3"
  "mka-ladle-meow-gop.mp3"
  "are-baap-re-yaad-aya.mp3"
  "a-few-moments-later-sponge-bob-sfx-fun.mp3"
  "depression-indian.mp3"
)

for sound in "${SOUNDS[@]}"; do
  if [[ -f "$SOUNDS_DIR/$sound" ]]; then
    cp "$SOUNDS_DIR/$sound" "$INSTALL_DIR/sounds/$sound"
    say "Copied $sound"
  else
    # Try downloading from GitHub
    if curl -fsSL "$GITHUB_RAW/sounds/$sound" -o "$INSTALL_DIR/sounds/$sound" 2>/dev/null; then
      say "Downloaded $sound"
    else
      warn "Could not find $sound — add your own to ~/.catterm/sounds/$sound"
    fi
  fi
done

# ── 4. Copy Python script ──────────────────────────────────────────────────────
info "Installing catcompile.py ..."
if [[ -f "$REPO_DIR/catcompile.py" ]]; then
  cp "$REPO_DIR/catcompile.py" "$INSTALL_DIR/catcompile.py"
else
  curl -fsSL "$GITHUB_RAW/catcompile.py" -o "$INSTALL_DIR/catcompile.py"
fi
chmod +x "$INSTALL_DIR/catcompile.py"
say "catcompile.py installed"

# ── 5. Install VS Code extension ───────────────────────────────────────────────
if command -v code &>/dev/null; then
  info "Installing VS Code extension ..."
  mkdir -p "$EXT_DIR"
  if [[ -f "$REPO_DIR/vscode-extension/extension.js" ]]; then
    cp "$REPO_DIR/vscode-extension/extension.js" "$EXT_DIR/"
    cp "$REPO_DIR/vscode-extension/package.json"  "$EXT_DIR/"
  else
    curl -fsSL "$GITHUB_RAW/vscode-extension/extension.js" -o "$EXT_DIR/extension.js"
    curl -fsSL "$GITHUB_RAW/vscode-extension/package.json"  -o "$EXT_DIR/package.json"
  fi
  # Patch sound paths to use ~/.catterm/sounds/
  sed -i '' "s|path.join(os.homedir(), 'Downloads')|require('path').join(require('os').homedir(), '.catterm', 'sounds')|g" "$EXT_DIR/extension.js" 2>/dev/null || true
  say "VS Code extension installed → reload VS Code to activate"
else
  dim "VS Code not found — skipping extension (install code CLI to enable it)"
fi

# ── 6. Add zsh hooks ───────────────────────────────────────────────────────────
info "Adding shell hooks to $RCFILE ..."

MARKER="# ── CatTerm hooks ──"

if grep -q "$MARKER" "$RCFILE" 2>/dev/null; then
  dim "Shell hooks already present — skipping"
else
  cat >> "$RCFILE" << HOOKEOF

# ── CatTerm hooks ──────────────────────────────────────────────────────────────
_CT_DIR="\$HOME/.catterm/sounds"
_CT_MUTED=0
_CT_LAST=""
_CT_FAIL_STREAK=0
_CT_SKIP="^(cd|ls|ll|la|cat|echo|pwd|which|man|clear|exit|source|history|z|j)"

_ct_play() { [[ \$_CT_MUTED -eq 1 ]] && return; afplay "\$_CT_DIR/\$1" &>/dev/null & }

_ct_preexec() { _CT_LAST="\$1"; }

_ct_precmd() {
  local code=\$? cmd="\$_CT_LAST"
  _CT_LAST=""
  [[ -z "\$cmd" || "\$cmd" =~ \$_CT_SKIP ]] && return
  if [[ \$code -ne 0 ]]; then
    _CT_FAIL_STREAK=\$((_CT_FAIL_STREAK + 1))
    if [[ \$_CT_FAIL_STREAK -eq 5 ]]; then
      python3 "\$HOME/.catterm/blackhole_eater.py"
    elif [[ \$_CT_FAIL_STREAK -gt 5 ]]; then
      _ct_play "depression-indian.mp3"
    else
      _ct_play "mka-ladle-meow-gop.mp3"
    fi
  else
    _CT_FAIL_STREAK=0
    if [[ "\$cmd" =~ (npm install|npm i |yarn (add|install)|pip install|brew install|pnpm (add|install)) ]]; then
      _ct_play "muhehehe.mp3"
    elif [[ "\$cmd" =~ (npm (run )?(build|compile)|yarn build|tsc|cargo build|go build|make|pytest|jest|npm test) ]]; then
      _ct_play "happy-happy-happy-song.mp3"
    elif [[ "\$cmd" =~ (git (commit|push|pull|merge|rebase|clone)) ]]; then
      _ct_play "german-cat.mp3"
    else
      _ct_play "german-cat.mp3"
    fi
  fi
}

autoload -Uz add-zsh-hook 2>/dev/null
add-zsh-hook preexec _ct_preexec 2>/dev/null
add-zsh-hook precmd  _ct_precmd  2>/dev/null

catmute()   { _CT_MUTED=1; echo "🔇 CatTerm muted"; }
catunmute() { _CT_MUTED=0; echo "🐱 CatTerm sounds ON!"; }
catstreak() { echo "💀 Current fail streak: \$_CT_FAIL_STREAK"; }
alias nrd='python3 \$HOME/.catterm/catcompile.py npm run dev'
alias nrb='python3 \$HOME/.catterm/catcompile.py npm run build'
# ──────────────────────────────────────────────────────────────────────────────
HOOKEOF
  say "Shell hooks added to $RCFILE"
fi

# ── 7. Done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}${BOLD}"
echo "    /\\_____/\\"
echo "   (  ^ω^  )   MUHEHEHEHE!! Installation complete!!"
echo "    )     (  "
echo "   ( ||||| )"
echo "    ‾‾‾‾‾‾‾"
echo -e "${RST}"
echo -e "${YLW}${BOLD}  Next steps:${RST}"
echo -e "${GRY}  1. source $RCFILE"
echo -e "  2. Reload VS Code  →  Cmd+Shift+P → 'Developer: Reload Window'"
echo -e "  3. Run any command and listen 👂${RST}"
echo ""
echo -e "${GRY}  Sounds live in  ~/.catterm/sounds/  — swap any MP3 to customise"
echo -e "  Toggle:          catmute  /  catunmute${RST}"
echo ""
