#!/usr/bin/env python3
"""
  /\\_/\\
 ( ●ω●)  CatCompile — your terminal goes MEOW
  > ^ <

Usage:
  python3 catcompile.py npm run dev
  python3 catcompile.py npm run build
  python3 catcompile.py --install     (adds shell aliases)
"""

import sys, os, subprocess, threading, re, time, random, shutil

RST  = "\033[0m";  BOLD = "\033[1m"
def fg(r,g,b): return f"\033[38;2;{r};{g};{b}m"
def cl(v,lo,hi): return max(lo,min(hi,v))

# ── Cat art ────────────────────────────────────────────────────────────────────

CAT_HAPPY = """
    /\\_____/\\
   (  ^ω^  )   MUHEHEHEHE!!
    )     (    IT WORKS, HUMAN!!
   ( ||||| )
    ‾‾‾‾‾‾‾
"""

CAT_FIRE = """
    /\\_____/\\
   (  >_<  )   HISSSSSSSS!!
    ) 🔥🔥 (    BUILD FAILED!!
   ( ||||| )
    ‾‾‾‾‾‾‾
"""

CAT_READY = """
    /\\_____/\\
   (  ≧◡≦  )   PURRRRR!!
    )  🌐  (    SERVER IS ALIVE!!
   ( ||||| )
    ‾‾‾‾‾‾‾
"""

CAT_WAIT = """
    /\\_____/\\
   (  -.- )zzz  watching...
    )      (
   ( ||||| )
    ‾‾‾‾‾‾‾
"""

# ── Sounds (macOS `say` with silly voices) ────────────────────────────────────

SOUNDS = {
    'success': [
        ('Trinoids', 'muhehehehe! It compiled, human! I am so proud!'),
        ('Zarvox',   'meow meow meow! Code works! You are a genius!'),
        ('Cellos',   'purrr purrr! Build success! Give me treats!'),
        ('Bubbles',  'yay yay yay! It actually worked! Amazing!'),
        ('Hysterical', 'oh my gosh it works! muhehehehe!'),
    ],
    'fail': [
        ('Bad News',   'meow of sadness. The build has perished.'),
        ('Trinoids',   'hisssss! You broke it again, human!'),
        ('Cellos',     'the cat is NOT pleased. Fix your code.'),
        ('Zarvox',     'catastrophic meow detected. Errors found.'),
    ],
    'ready': [
        ('Trinoids', 'muhehehehe! Dev server is ALIVE! localhost is ready, human!'),
        ('Zarvox',   'purrr! Your little server is running! Go break things!'),
        ('Cellos',   'meow! Server started! Time to write more bugs!'),
        ('Bubbles',  'yay! localhost is up! You can click things now!'),
    ],
}

SYSTEM_SOUNDS = {
    'success': '/System/Library/Sounds/Glass.aiff',
    'fail':    '/System/Library/Sounds/Basso.aiff',
    'ready':   '/System/Library/Sounds/Hero.aiff',
}

def play_sound(category):
    voice, text = random.choice(SOUNDS[category])
    # play system sound first (instant), then speech
    snd = SYSTEM_SOUNDS.get(category)
    if snd and os.path.exists(snd):
        subprocess.Popen(['afplay', snd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.25)
    try:
        subprocess.Popen(
            ['say', '-v', voice, text],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except FileNotFoundError:
        pass

# ── Rendering ─────────────────────────────────────────────────────────────────

def print_cat(art, color):
    W = shutil.get_terminal_size((80, 24)).columns
    print()
    for line in art.strip('\n').split('\n'):
        pad = max(0, (W - len(line)) // 2)
        print(' ' * pad + fg(*color) + BOLD + line + RST)
    print()

def divider(label='', color=(80,80,80)):
    W = shutil.get_terminal_size((80,24)).columns
    if label:
        side = (W - len(label) - 2) // 2
        line = '─' * side + f' {label} ' + '─' * side
    else:
        line = '─' * W
    print(fg(*color) + line[:W] + RST)

# ── Pattern matching for dev servers ─────────────────────────────────────────

SUCCESS_PATS = [
    r'ready',
    r'compiled successfully',
    r'webpack compiled',
    r'listening on',
    r'server (is )?running',
    r'started server',
    r'local:.*http',
    r'ready in \d+',
    r'vite .* ready',
    r'✓\s*ready',
    r'✔\s*ready',
    r'available on',
    r'app running at',
    r'server started',
]

FAIL_PATS = [
    r'\berror\b(?!.*warning)',
    r'failed to compile',
    r'build failed',
    r'EADDRINUSE',
    r'module not found',
    r'cannot find module',
    r'syntaxerror',
    r'typeerror:',
]

# ── Runners ───────────────────────────────────────────────────────────────────

def run_oneshot(cmd):
    divider(f"CatCompile: {' '.join(cmd)}", (200, 150, 50))
    print_cat(CAT_WAIT, (150, 150, 150))

    t0 = time.time()
    result = subprocess.run(cmd)
    elapsed = time.time() - t0

    print()
    divider(f"done in {elapsed:.1f}s", (80, 80, 80))

    if result.returncode == 0:
        print_cat(CAT_HAPPY, (80, 255, 120))
        play_sound('success')
    else:
        print_cat(CAT_FIRE, (255, 80, 80))
        play_sound('fail')

    return result.returncode


def run_devserver(cmd):
    divider(f"CatCompile: {' '.join(cmd)}", (200, 150, 50))
    print(fg(120,120,120) + "  listening for server ready signal... (Ctrl+C to stop)" + RST + "\n")

    announced = threading.Event()

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    def watch():
        for line in proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()

            if announced.is_set():
                continue

            low = line.lower()

            for pat in FAIL_PATS:
                if re.search(pat, low):
                    announced.set()
                    time.sleep(0.2)
                    print_cat(CAT_FIRE, (255, 80, 80))
                    play_sound('fail')
                    break

            if announced.is_set():
                continue

            for pat in SUCCESS_PATS:
                if re.search(pat, low):
                    announced.set()
                    time.sleep(0.2)
                    print_cat(CAT_READY, (80, 255, 160))
                    play_sound('ready')
                    break

    t = threading.Thread(target=watch, daemon=True)
    t.start()

    try:
        proc.wait()
        t.join(timeout=1)
    except KeyboardInterrupt:
        proc.terminate()
        print(fg(150,150,100) + "\n  server stopped. the cat naps. meow." + RST + "\n")

    return proc.returncode

# ── Installer ─────────────────────────────────────────────────────────────────

ALIAS_BLOCK = """
# ── CatCompile aliases ──────────────────────────────────────────
_catcompile() {{ python3 {script} "$@"; }}
alias nrd='_catcompile npm run dev'
alias nrb='_catcompile npm run build'
alias nrs='_catcompile npm run start'
alias nrt='_catcompile npm test'
alias nrp='_catcompile npm run preview'
alias yrb='_catcompile yarn build'
alias yrd='_catcompile yarn dev'
alias prd='_catcompile pnpm run dev'
alias prb='_catcompile pnpm run build'
catc() {{ python3 {script} "$@"; }}
# ────────────────────────────────────────────────────────────────
"""

def install():
    script = os.path.abspath(__file__)
    rcfile = os.path.expanduser('~/.zshrc')
    if not os.path.exists(rcfile):
        rcfile = os.path.expanduser('~/.bashrc')

    block = ALIAS_BLOCK.format(script=script)
    marker = '# ── CatCompile aliases ──'

    with open(rcfile, 'r') as f:
        content = f.read()

    if marker in content:
        print(fg(255,200,50) + BOLD + "  CatCompile already installed in " + rcfile + RST)
    else:
        with open(rcfile, 'a') as f:
            f.write('\n' + block)
        print(fg(80,255,120) + BOLD + f"  CatCompile aliases added to {rcfile}" + RST)

    print_cat(CAT_HAPPY, (80, 255, 120))
    print(fg(200,200,200) + "  Restart your terminal or run: " + fg(255,255,100) + f"source {rcfile}" + RST)
    print()
    print(fg(180,180,180) + "  New aliases:" + RST)
    aliases = [
        ("nrd",  "npm run dev"),
        ("nrb",  "npm run build"),
        ("nrs",  "npm run start"),
        ("nrt",  "npm test"),
        ("nrp",  "npm run preview"),
        ("yrb",  "yarn build"),
        ("yrd",  "yarn dev"),
        ("prd",  "pnpm run dev"),
        ("prb",  "pnpm run build"),
        ("catc", "catc <any command>"),
    ]
    for alias, desc in aliases:
        print(f"    {fg(255,200,50)+BOLD}{alias:6}{RST}  →  {fg(150,220,255)}{desc}{RST}")
    print()

# ── Dev-server command detection ──────────────────────────────────────────────

DEV_TOKENS = {'dev', 'start', 'serve', 'watch', 'preview', 'develop'}

def is_devserver(cmd):
    return any(t in DEV_TOKENS for t in cmd)

# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    args = sys.argv[1:]

    if not args or args[0] in ('-h', '--help'):
        print(fg(200,100,255) + BOLD + CAT_HAPPY + RST)
        print(fg(255,255,100) + "  Usage:" + RST)
        print(f"    {fg(200,200,200)}python3 catcompile.py npm run dev{RST}")
        print(f"    {fg(200,200,200)}python3 catcompile.py npm run build{RST}")
        print(f"    {fg(200,200,200)}python3 catcompile.py --install{RST}")
        return

    if args[0] == '--install':
        install()
        return

    if is_devserver(args):
        sys.exit(run_devserver(args))
    else:
        sys.exit(run_oneshot(args))

if __name__ == '__main__':
    main()
