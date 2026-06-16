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

# ── 1. Detect platform & audio player ─────────────────────────────────────────
OS="$(uname -s)"
AUDIO_PLAYER=""

if [[ "$OS" == "Darwin" ]]; then
  AUDIO_PLAYER="afplay"
  say "Platform: macOS"
elif [[ "$OS" == "Linux" ]]; then
  say "Platform: Linux"
  if command -v mpg123  &>/dev/null; then AUDIO_PLAYER="mpg123 -q"
  elif command -v paplay &>/dev/null; then AUDIO_PLAYER="paplay"
  elif command -v ffplay &>/dev/null; then AUDIO_PLAYER="ffplay -nodisp -autoexit -loglevel quiet"
  elif command -v aplay  &>/dev/null; then AUDIO_PLAYER="aplay -q"
  else
    warn "No audio player found. Install mpg123:  sudo apt install mpg123"
    warn "Continuing install — add mpg123 later and sounds will work."
  fi
elif [[ "$OS" == MINGW* || "$OS" == CYGWIN* || "$OS" == MSYS* ]]; then
  say "Platform: Windows (Git Bash)"
  if command -v ffplay &>/dev/null; then AUDIO_PLAYER="ffplay -nodisp -autoexit -loglevel quiet"
  else
    warn "Install ffmpeg and add it to PATH for sound support."
  fi
else
  warn "Unknown platform: $OS — continuing, but sounds may not work."
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
  "aayein-meme.mp3"
  "mka-ladle-meow-gop.mp3"
  "are-baap-re-yaad-aya.mp3"
  "a-few-moments-later-sponge-bob-sfx-fun.mp3"
  "depression-indian.mp3"
  "abe-sale.mp3"
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

# ── 4a. Create rules file (only if it doesn't exist) ─────────────────────────
if [[ ! -f "$INSTALL_DIR/rules" ]]; then
  if [[ -f "$REPO_DIR/rules.default" ]]; then
    cp "$REPO_DIR/rules.default" "$INSTALL_DIR/rules"
  else
    curl -fsSL "$GITHUB_RAW/rules.default" -o "$INSTALL_DIR/rules" 2>/dev/null
  fi
  say "Created ~/.catterm/rules — add your own triggers with: catrule add"
else
  dim "~/.catterm/rules already exists — keeping your rules"
fi

# ── 4. Create config file (only if it doesn't exist — never overwrite) ────────
if [[ ! -f "$INSTALL_DIR/config" ]]; then
  if [[ -f "$REPO_DIR/config.default" ]]; then
    cp "$REPO_DIR/config.default" "$INSTALL_DIR/config"
  else
    curl -fsSL "$GITHUB_RAW/config.default" -o "$INSTALL_DIR/config" 2>/dev/null
  fi
  say "Created ~/.catterm/config — edit to use your own sounds"
else
  dim "~/.catterm/config already exists — keeping your settings"
fi

# ── 5. Copy Python script ──────────────────────────────────────────────────────
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
  cat >> "$RCFILE" << 'HOOKEOF'

# ── CatTerm hooks ──────────────────────────────────────────────────────────────
_CT_DIR="$HOME/.catterm/sounds"
_CT_CFG="$HOME/.catterm/config"
_CT_RULES="$HOME/.catterm/rules"
_CT_MUTED=0
_CT_LAST=""
_CT_FAIL_STREAK=0
_CT_SAME_FAIL=0
_CT_LAST_FAIL_CMD=""
_CT_SKIP_CMDS="^(cd|ls|ll|la|cat|echo|pwd|which|man|clear|exit|source|.|history|z|j|fg|bg|jobs|type|alias|export|unset|set)"

[[ -f "$_CT_CFG" ]] && source "$_CT_CFG"

_ct_play_file() {
  [[ $_CT_MUTED -eq 1 ]] && return
  local f="$1"; [[ ! -f "$f" ]] && return
  if   command -v afplay &>/dev/null; then afplay "$f" &>/dev/null &
  elif command -v mpg123 &>/dev/null; then mpg123 -q "$f" &>/dev/null &
  elif command -v paplay &>/dev/null; then paplay "$f" &>/dev/null &
  elif command -v ffplay &>/dev/null; then ffplay -nodisp -autoexit -loglevel quiet "$f" &>/dev/null &
  elif command -v aplay  &>/dev/null; then aplay -q "$f" &>/dev/null &
  fi
}

_ct_play() {
  local custom="${(P)1}"
  if [[ -n "$custom" && -f "$custom" ]]; then _ct_play_file "$custom"
  else _ct_play_file "$_CT_DIR/$2"; fi
}

_ct_check_custom_rules() {
  local cmd="$1" code="$2"
  [[ ! -f "$_CT_RULES" ]] && return 1
  while IFS='|' read -r pattern sound; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    pattern="${pattern## }"; pattern="${pattern%% }"
    sound="${sound## }"; sound="${sound%% }"
    [[ -z "$sound" ]] && continue
    if [[ "$pattern" == \!* ]]; then
      [[ $code -eq 0 ]] && continue
      pattern="${pattern#!}"
    else
      [[ $code -ne 0 ]] && continue
    fi
    if [[ "$cmd" =~ $pattern ]]; then
      if [[ -f "$sound" ]]; then _ct_play_file "$sound"
      else _ct_play_file "$_CT_DIR/$sound"; fi
      return 0
    fi
  done < "$_CT_RULES"
  return 1
}

_ct_preexec() { _CT_LAST="$1"; }

_ct_precmd() {
  local code=$? cmd="$_CT_LAST"
  _CT_LAST=""
  [[ -z "$cmd" ]] && return
  [[ "$cmd" =~ $_CT_SKIP_CMDS ]] && return

  if [[ $code -ne 0 ]]; then
    _CT_FAIL_STREAK=$((_CT_FAIL_STREAK + 1))
    if [[ "$cmd" == "$_CT_LAST_FAIL_CMD" ]]; then _CT_SAME_FAIL=$((_CT_SAME_FAIL + 1))
    else _CT_SAME_FAIL=1; _CT_LAST_FAIL_CMD="$cmd"; fi
    if   [[ $_CT_FAIL_STREAK -eq 5 ]]; then python3 "$HOME/.catterm/blackhole_eater.py"
    elif [[ $_CT_FAIL_STREAK -eq 6 ]]; then _ct_play SOUND_DEPRESSION "depression-indian.mp3"
    elif [[ $_CT_FAIL_STREAK -ge 7 ]]; then _ct_play SOUND_MEOW       "mka-ladle-meow-gop.mp3"
    elif [[ $_CT_SAME_FAIL -gt 4 ]];   then _ct_play SOUND_SAME_FAIL  "abe-sale.mp3"
    elif ! _ct_check_custom_rules "$cmd" "$code"; then _ct_play SOUND_FAIL "aayein-meme.mp3"
    fi
  else
    _CT_FAIL_STREAK=0; _CT_SAME_FAIL=0; _CT_LAST_FAIL_CMD=""
    _ct_check_custom_rules "$cmd" "$code" && return
    if   [[ "$cmd" =~ (npm (install|i )|yarn (add|install)|pnpm (add|install)) ]]; then
      _ct_play SOUND_INSTALL "muhehehe.mp3"
    elif [[ "$cmd" =~ (pip3? install|poetry (add|install)|pipenv install|conda install|uv (add|install|sync|pip install)) ]]; then
      _ct_play SOUND_INSTALL "muhehehe.mp3"
    elif [[ "$cmd" =~ (gem install|bundle (install|add)|cargo add|composer (install|require)|dotnet (restore|add package)|flutter pub (get|upgrade)|swift package (resolve|update)|go (get|mod (tidy|download|vendor))|brew (install|upgrade)|apt(-get)? install|dnf install|pacman -S|apk add) ]]; then
      _ct_play SOUND_INSTALL "muhehehe.mp3"
    elif [[ "$cmd" =~ (npm (run )?(build|compile)|yarn (build|compile)|pnpm (run )?(build|compile)|tsc|vite build|esbuild) ]]; then
      _ct_play SOUND_BUILD "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (cargo (build|compile|check)|go build|go install|go generate) ]]; then
      _ct_play SOUND_BUILD "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (mvn (package|compile|install)|gradle (build|assemble)|\.\/gradlew (build|assemble)|dotnet (build|publish)) ]]; then
      _ct_play SOUND_BUILD "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (flutter build|swift build|xcodebuild|docker build|python3? -m build|rake (build|compile)|^make( |$)|cmake|ninja) ]]; then
      _ct_play SOUND_BUILD "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (npm test|yarn test|pnpm test|jest|vitest|pytest|python3? -m pytest) ]]; then
      _ct_play SOUND_TEST "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (cargo test|go test|rspec|phpunit|pest|dotnet test|flutter test|swift test|gradle test|\.\/gradlew test|mvn test) ]]; then
      _ct_play SOUND_TEST "happy-happy-happy-song.mp3"
    elif [[ "$cmd" =~ (git (commit|push|pull|merge|rebase|clone|fetch|stash|tag|cherry-pick)) ]]; then
      _ct_play SOUND_GIT "german-cat.mp3"
    else
      _ct_play SOUND_GIT "german-cat.mp3"
    fi
  fi
}

autoload -Uz add-zsh-hook 2>/dev/null
add-zsh-hook preexec _ct_preexec 2>/dev/null
add-zsh-hook precmd  _ct_precmd  2>/dev/null

catmute()   { _CT_MUTED=1; echo "🔇 CatTerm muted"; }
catunmute() { _CT_MUTED=0; echo "🐱 CatTerm sounds ON!"; }
catstreak() { echo "💀 Current fail streak: $_CT_FAIL_STREAK"; }
catconfig() { ${EDITOR:-nano} "$HOME/.catterm/config" && source "$HOME/.catterm/config" && echo "🐱 Config reloaded!"; }

catrule() {
  local rules="$HOME/.catterm/rules"
  case "$1" in
    add)
      [[ -z "$2" || -z "$3" ]] && echo "Usage: catrule add <pattern> <sound>" && return 1
      echo "${2}|${3}" >> "$rules" && echo "  ✓ Rule added: $2 → $3"
      ;;
    list)
      echo "Custom rules (from ~/.catterm/rules):"
      local n=0
      while IFS='|' read -r pat snd; do
        [[ -z "$pat" || "$pat" == \#* ]] && continue
        n=$(( n + 1 ))
        local type="success"
        [[ "$pat" == \!* ]] && type="fail   " && pat="${pat#!}"
        printf "  %2d  [%s]  %-30s →  %s\n" $n $type "$pat" "$snd"
      done < "$rules"
      [[ $n -eq 0 ]] && echo "  (no rules yet — run: catrule add <pattern> <sound>)"
      ;;
    remove)
      [[ -z "$2" ]] && echo "Usage: catrule remove <number>" && return 1
      local tmpf=$(mktemp) n=0 target=$2
      while IFS='|' read -r pat snd; do
        if [[ -z "$pat" || "$pat" == \#* ]]; then echo "$pat${snd:+|$snd}" >> "$tmpf"; continue; fi
        n=$(( n + 1 ))
        [[ $n -ne $target ]] && echo "$pat|$snd" >> "$tmpf"
      done < "$rules"
      mv "$tmpf" "$rules" && echo "  ✓ Rule $2 removed"
      ;;
    *)
      echo "Usage:"
      echo "  catrule add <pattern> <sound>   # sound = filename or full path"
      echo "  catrule list                    # show all custom rules"
      echo "  catrule remove <n>              # remove rule by number"
      echo ""
      echo "Examples:"
      echo "  catrule add 'docker build'     german-cat.mp3"
      echo "  catrule add 'terraform apply'  muhehehe.mp3"
      echo "  catrule add '!git push'        mka-ladle-meow-gop.mp3"
      ;;
  esac
}

catupdate() {
  echo "🐱 Updating CatTerm..."
  local RCFILE="${ZDOTDIR:-$HOME}/.zshrc"
  [[ ! -f "$RCFILE" ]] && RCFILE="$HOME/.bashrc"
  local RAW="https://raw.githubusercontent.com/yogesh0333/catterm/main"
  local SOUNDS=(muhehehe.mp3 happy-happy-happy-song.mp3 german-cat.mp3
    soulja-boy-saying-huh.mp3 aayein-meme.mp3 mka-ladle-meow-gop.mp3
    are-baap-re-yaad-aya.mp3 "a-few-moments-later-sponge-bob-sfx-fun.mp3"
    depression-indian.mp3 abe-sale.mp3)
  for s in "${SOUNDS[@]}"; do
    curl -fsSL "$RAW/sounds/$s" -o "$HOME/.catterm/sounds/$s" 2>/dev/null && echo "  ✓ $s"
  done
  curl -fsSL "$RAW/blackhole_eater.py" -o "$HOME/.catterm/blackhole_eater.py" 2>/dev/null && echo "  ✓ blackhole_eater.py"
  curl -fsSL "$RAW/catcompile.py"      -o "$HOME/.catterm/catcompile.py"      2>/dev/null && echo "  ✓ catcompile.py"
  [[ ! -f "$HOME/.catterm/rules" ]] && curl -fsSL "$RAW/rules.default" -o "$HOME/.catterm/rules" 2>/dev/null && echo "  ✓ rules (new)"
  local EXT="$HOME/.vscode/extensions/catterm-sounds-0.0.1"
  [[ -d "$EXT" ]] && curl -fsSL "$RAW/vscode-extension/extension.js" -o "$EXT/extension.js" 2>/dev/null && echo "  ✓ VS Code extension"
  sed -i '' '/# ── CatTerm hooks/,/# ─────────────────/d' "$RCFILE" 2>/dev/null
  curl -fsSL "$RAW/install.sh" | bash
  echo "🐱 Done! Run: source $RCFILE"
}
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
