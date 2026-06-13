# 🐱 CatTerm

> Your terminal, but with cat sounds.

Plays sounds automatically when commands succeed or fail — no wrappers, no manual steps.
Works in **VS Code** (watches terminal output) and **any terminal** (zsh hooks on exit code).

```
    /\_____/\
   (  ^ω^  )   MUHEHEHEHE!!
    )     (    npm install done, human!!
   ( ||||| )
    ‾‾‾‾‾‾‾
```

---

## Install (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/yogesh0333/catterm/main/install.sh | bash
```

Then activate:
```bash
source ~/.zshrc
# Reload VS Code → Cmd+Shift+P → "Developer: Reload Window"
```

---

## Sound map

| Sound | When it plays |
|---|---|
| `muhehehe.mp3` | `npm install` done · `npm run dev` server ready · `yarn install` |
| `happy-happy-happy-song.mp3` | `npm run build` success · tests pass · `tsc` done |
| `german-cat.mp3` | `git commit/push/pull` · any other successful command |
| `soulja-boy-saying-huh.mp3` | any command exits with an error |
| `mka-ladle-meow-gop.mp3` | catastrophic failure (TypeError · EADDRINUSE · module not found) |

---

## Use your own sounds

Swap any MP3 in `~/.catterm/sounds/` — filenames must match exactly:

```
~/.catterm/sounds/
├── muhehehe.mp3
├── happy-happy-happy-song.mp3
├── german-cat.mp3
├── soulja-boy-saying-huh.mp3
└── mka-ladle-meow-gop.mp3
```

---

## Commands

```bash
catmute      # silence everything
catunmute    # sounds back on
nrd          # npm run dev (with cat art)
nrb          # npm run build (with cat art)
```

---

## How it works

**VS Code extension** (`~/.vscode/extensions/catterm-sounds-0.0.1/`)
- Registers `onDidWriteTerminalData` — watches every terminal's raw output
- Matches 40+ patterns: "ready in", "added N packages", "npm ERR!", etc.
- Shows cat message in VS Code status bar

**Zsh hooks** (`~/.zshrc`)
- `preexec` records the command, `precmd` checks exit code
- Fires on every command automatically — zero wrappers needed
- Works in Terminal, iTerm2, Warp, anywhere

---

## Requirements

- macOS (uses `afplay` for audio — Linux/Windows PRs welcome!)
- zsh or bash
- VS Code (optional, for the extension)
- Python 3 (optional, for cat-art mode with `nrd`/`nrb`)

---

## Uninstall

```bash
rm -rf ~/.catterm
rm -rf ~/.vscode/extensions/catterm-sounds-0.0.1
# Remove the "CatTerm hooks" block from ~/.zshrc
```

---

Made with 🐱 by [yogesh](https://github.com/yogesh0333)
