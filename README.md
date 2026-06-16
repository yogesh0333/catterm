# 🐱 CatTerm

> Your terminal, but with cat sounds.

Plays sounds automatically when commands succeed, fail, or you break things catastrophically — no wrappers, no manual steps. Works in **VS Code** and **any terminal**.

```
    /\_____/\
   (  ^ω^  )   MUHEHEHEHE!!
    )     (    npm install done, human!!
   ( ||||| )
    ‾‾‾‾‾‾‾
```

---

## Platform support

| Platform | Status | Audio |
|---|---|---|
| macOS | ✅ Full support | `afplay` (built-in) |
| Linux | ✅ Full support | `mpg123` / `paplay` / `ffplay` |
| Windows (WSL) | ✅ Works via WSL | WSL + Linux path |
| Windows (native) | ⚠️ Partial | PowerShell fallback |

---

## Install

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/yogesh0333/catterm/main/install.sh | bash
source ~/.zshrc
```

That's it. No dependencies — `afplay` is built into every Mac.

---

### Linux

Install an audio player first (pick one):

```bash
# Ubuntu / Debian
sudo apt install mpg123

# Fedora / RHEL
sudo dnf install mpg123

# Arch
sudo pacman -S mpg123

# or use ffplay (usually already installed)
sudo apt install ffmpeg
```

Then install CatTerm:

```bash
curl -fsSL https://raw.githubusercontent.com/yogesh0333/catterm/main/install.sh | bash
source ~/.zshrc
```

---

### Windows — Option A: WSL (recommended)

1. [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install) if you haven't:
   ```powershell
   wsl --install
   ```
2. Open your WSL terminal and install `mpg123`:
   ```bash
   sudo apt install mpg123
   ```
3. Install CatTerm inside WSL:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/yogesh0333/catterm/main/install.sh | bash
   source ~/.zshrc
   ```

---

### Windows — Option B: Git Bash / native (no WSL)

1. Install [Git for Windows](https://gitforwindows.org/) (includes Git Bash)
2. Install [ffmpeg](https://ffmpeg.org/download.html) and add it to your PATH
3. Run in **Git Bash**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/yogesh0333/catterm/main/install.sh | bash
   source ~/.bashrc
   ```

> **Note:** VS Code extension works on all platforms once CatTerm is installed.

---

## Update (already installed)

```bash
catupdate
source ~/.zshrc
```

Re-downloads everything — sounds, scripts, VS Code extension, and replaces zsh hooks with the latest version.

---

## Sound map

| Sound | When it plays |
|---|---|
| `muhehehe.mp3` | package install done — npm/yarn/pnpm/pip/cargo/gem/composer/brew/apt/go mod… |
| `happy-happy-happy-song.mp3` | build or tests pass — tsc/cargo/go/mvn/gradle/dotnet/flutter/xcodebuild/pytest/jest… |
| `german-cat.mp3` | `git commit/push/pull/merge/fetch` · any other successful command |
| `aayein-meme.mp3` | command fails (1st–4th time) |
| `abe-sale.mp3` | **same command fails 5+ times** in a row |
| `are-baap-re-yaad-aya.mp3` | **5 consecutive failures** — triggers black hole |
| `a-few-moments-later...mp3` | 10 seconds into the black hole animation |
| `depression-indian.mp3` | 6th consecutive failure — depression mode |
| `mka-ladle-meow-gop.mp3` | 7th+ consecutive failure — the meow returns |

### Built-in language support

CatTerm understands tools from every major ecosystem out of the box:

| Stack | Install trigger | Build trigger | Test trigger |
|---|---|---|---|
| **JS/TS** | npm i, yarn add, pnpm add | tsc, vite build, esbuild | jest, vitest, npm test |
| **Python** | pip install, poetry, pipenv, uv, conda | python -m build, pyinstaller | pytest |
| **Rust** | cargo add, cargo fetch | cargo build/check | cargo test |
| **Go** | go get, go mod tidy | go build, go install | go test |
| **Java/Kotlin** | mvn dependency, gradle deps | mvn package, gradle build | mvn test, gradle test |
| **Ruby** | gem install, bundle install | rake build, assets:precompile | rspec, rake test |
| **PHP** | composer install/require | — | phpunit, pest |
| **.NET** | dotnet restore, nuget | dotnet build/publish | dotnet test |
| **Flutter/Dart** | flutter pub get | flutter build | flutter test |
| **Swift/iOS** | swift package resolve | swift build, xcodebuild | swift test |
| **Docker** | docker pull | docker build | — |
| **System** | brew, apt, dnf, pacman, apk | make, cmake, ninja | — |

---

## The black hole

Fail 5 commands in a row and your terminal gets eaten:

```
    /\_____/\
   (  >_<  )   ARE BAAP RE...
    ) 🔥🔥 (    TERMINAL CONSUMED
   ( ||||| )
```

The black hole grows from the centre and swallows the entire screen.
After 10 seconds: *"✦ A F E W M O M E N T S L A T E R . . . ✦"*
Then your terminal comes back. Hopefully.

---

## Commands

```bash
catupdate        # pull latest version from GitHub
catmute          # silence all sounds
catunmute        # sounds back on
catstreak        # show current consecutive fail count
catconfig        # edit sound config in your $EDITOR
catrule add      # add a custom trigger rule
catrule list     # show your custom rules
catrule remove   # remove a rule by number
nrd              # npm run dev (with cat art)
nrb              # npm run build (with cat art)
```

---

## Custom rules

Add your own command → sound triggers with `catrule`:

```bash
# Trigger on success
catrule add 'docker build'      german-cat.mp3
catrule add 'terraform apply'   muhehehe.mp3
catrule add 'ansible-playbook'  /path/to/boom.mp3

# Trigger on failure (prefix with !)
catrule add '!git push'         mka-ladle-meow-gop.mp3

# List all rules
catrule list

# Remove rule #2
catrule remove 2
```

Rules are stored in `~/.catterm/rules` — one per line, `pattern|sound`.
Custom rules are checked **first** and override built-in patterns when matched.

---

## Use your own sounds

Swap any MP3 in `~/.catterm/sounds/` — filenames must match exactly:

```
~/.catterm/sounds/
├── muhehehe.mp3
├── happy-happy-happy-song.mp3
├── german-cat.mp3
├── mka-ladle-meow-gop.mp3
├── abe-sale.mp3
├── are-baap-re-yaad-aya.mp3
├── a-few-moments-later-sponge-bob-sfx-fun.mp3
└── depression-indian.mp3
```

---

## How it works

**VS Code extension** (`~/.vscode/extensions/catterm-sounds-0.0.1/`)
- Watches every terminal's raw output via `onDidWriteTerminalData`
- Matches 40+ patterns: "ready in", "added N packages", "npm ERR!", etc.
- Shows cat status in the VS Code status bar
- Click `🐱 catterm` in status bar to mute/unmute

**Zsh / Bash hooks** (in `~/.zshrc` or `~/.bashrc`)
- `preexec` records each command before it runs
- `precmd` checks exit code after it finishes
- Tracks consecutive failure streaks and same-command repeats
- Fires on every command — zero wrappers needed

---

## Requirements

| | macOS | Linux | Windows (WSL) |
|---|---|---|---|
| Shell | zsh / bash | zsh / bash | zsh / bash |
| Audio | built-in `afplay` | `mpg123` / `paplay` / `ffplay` | `mpg123` |
| Python 3 | optional (cat art) | optional (cat art) | optional (cat art) |
| VS Code | optional | optional | optional |

---

## Uninstall

```bash
rm -rf ~/.catterm
rm -rf ~/.vscode/extensions/catterm-sounds-0.0.1
# open ~/.zshrc and delete the block between:
# "# ── CatTerm hooks" and "# ────────────────"
```

---

## Contributing

PRs welcome! Especially:
- 🐧 Linux audio improvements
- 🪟 Better Windows native support
- 🔊 New sound scenarios
- 🐱 More cat art

---

Made with 🐱 by [yogesh](https://github.com/yogesh0333)
