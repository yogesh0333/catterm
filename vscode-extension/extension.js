const vscode = require('vscode');
const { exec }  = require('child_process');
const path      = require('path');
const os        = require('os');

// ── Sound files ───────────────────────────────────────────────────────────────
const DL = path.join(os.homedir(), '.catterm', 'sounds');
const SOUNDS = {
  server:  path.join(DL, 'muhehehe.mp3'),          // dev server alive
  install: path.join(DL, 'muhehehe.mp3'),          // npm/yarn/pip install done
  build:   path.join(DL, 'happy-happy-happy-song.mp3'), // build success
  test:    path.join(DL, 'happy-happy-happy-song.mp3'), // tests pass
  git:     path.join(DL, 'german-cat.mp3'),        // git ops / general win
  general: path.join(DL, 'german-cat.mp3'),        // catch-all success
  fail:    path.join(DL, 'mka-ladle-meow-gop.mp3'),   // anything breaks
};

// ── Cat art for status bar ─────────────────────────────────────────────────────
const CAT_MSGS = {
  server:  '🐱 ( ≧◡≦) purrr~ server is alive!',
  install: '🐱 ( ^ω^) MUHEHEHEHE!! packages installed!',
  build:   '🐱 ( ^ω^) IT WORKS, HUMAN!!',
  test:    '🐱 ( ≧◡≦) tests passing — give me treats!',
  git:     '🐱 (=^･ω･^=) git says yes!',
  general: '🐱 ( ^ω^) command success, meow!',
  fail:    '🐱 ( >_<) 🔥 HISSSSSS!! something broke!!',
};

// ── Pattern triggers ──────────────────────────────────────────────────────────
const TRIGGERS = [
  // Server/dev started → muhehehe
  { key: 'server', patterns: [
    /ready in \d+/i,
    /local:\s+http/i,
    /compiled successfully/i,
    /listening on port/i,
    /server (is )?running/i,
    /ready - started server/i,
    /vite .* ready/i,
    /webpack compiled/i,
    /app running at/i,
    /✓\s*ready/i,
    /started on.*:\d{4}/i,
    /now serving/i,
    /development server/i,
  ]},

  // Package install done → muhehehe
  { key: 'install', patterns: [
    /added \d+ packages?/i,
    /\d+ packages? installed/i,
    /successfully installed/i,
    /packages? up to date/i,
    /already up.to.date/i,
    /installed \d+ package/i,
    /resolving packages/i,           // yarn finish signal
    /done in \d+\.\d+s/i,           // yarn done
  ]},

  // Build success → happy song
  { key: 'build', patterns: [
    /build succeeded/i,
    /compiled \d+ files/i,
    /✓ built in \d+/i,
    /build finished/i,
    /successfully compiled/i,
    /webpack .* compiled/i,
    /tsc: done/i,
    /\bbuilt\b.*\d+ modules/i,
  ]},

  // Tests pass → happy song
  { key: 'test', patterns: [
    /tests? passed/i,
    /all tests? pass/i,
    /✓ \d+ passing/i,
    /\d+ passed.*\d+ failed.*0/i,
    /test suites.*passed/i,
    /ok - all tests passed/i,
    /pass\s+\d+/i,
  ]},

  // Git → german cat
  { key: 'git', patterns: [
    /branch .* set up to track/i,
    /your branch is up to date/i,
    /\[.*\] .* commit/i,
    /fast-forward/i,
    /merge made/i,
    /switched to (a new )?branch/i,
    /origin\/.*done/i,
  ]},

  // Failure → soulja boy HUH (check last so successes win if both match)
  { key: 'fail', patterns: [
    /npm ERR!/i,
    /\berror\b(?!s found)/i,
    /ENOENT/i,
    /EADDRINUSE/i,
    /command not found/i,
    /failed to compile/i,
    /build failed/i,
    /error TS\d+:/i,
    /SyntaxError:/i,
    /TypeError:/i,
    /\bfailed\b/i,
    /FAILED/,
    /✗\s/,
    /exit code [^0]/i,
    /\d+ failed/i,
    /cannot find module/i,
    /module not found/i,
    /permission denied/i,
  ]},
];

// ── Helpers ───────────────────────────────────────────────────────────────────
let muted = false;
const cooldown = new Map();
const COOLDOWN_MS = 6000;

function play(key) {
  if (muted) return;
  const now = Date.now();
  if ((now - (cooldown.get(key) || 0)) < COOLDOWN_MS) return;
  cooldown.set(key, now);
  exec(`afplay "${SOUNDS[key]}" 2>/dev/null`, () => {});
}

function showCat(key, bar) {
  const msg = CAT_MSGS[key] || '🐱 meow!';
  bar.text = msg;
  bar.backgroundColor = key === 'fail'
    ? new vscode.ThemeColor('statusBarItem.errorBackground')
    : undefined;
  setTimeout(() => {
    bar.text = '🐱 catterm: watching...';
    bar.backgroundColor = undefined;
  }, 5000);
}

// ── Activation ────────────────────────────────────────────────────────────────
function activate(context) {
  // Status bar
  const bar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 200);
  bar.text = '🐱 catterm: watching...';
  bar.tooltip = 'CatTerm Sounds — click to toggle mute';
  bar.command = 'catterm.toggle';
  bar.show();
  context.subscriptions.push(bar);

  // Toggle command
  context.subscriptions.push(
    vscode.commands.registerCommand('catterm.toggle', () => {
      muted = !muted;
      bar.text = muted ? '🔇 catterm: muted' : '🐱 catterm: watching...';
      vscode.window.showInformationMessage(muted ? '🐱 CatTerm muted. Boring.' : '🐱 CatTerm unmuted. Sounds ON!');
    })
  );

  // Watch terminal output
  context.subscriptions.push(
    vscode.window.onDidWriteTerminalData(event => {
      const data = event.data;

      // Check success patterns first (order matters — fail is last)
      for (const trigger of TRIGGERS) {
        for (const pat of trigger.patterns) {
          if (pat.test(data)) {
            play(trigger.key);
            showCat(trigger.key, bar);
            return; // first match wins per chunk
          }
        }
      }
    })
  );

  // Also watch for terminal exit (process done)
  context.subscriptions.push(
    vscode.window.onDidCloseTerminal(terminal => {
      const code = terminal.exitStatus?.code;
      if (code === undefined || code === null) return;
      if (code === 0) {
        play('general');
        showCat('general', bar);
      } else {
        play('fail');
        showCat('fail', bar);
      }
    })
  );

  console.log('🐱 CatTerm Sounds is watching your terminal...');
}

function deactivate() {}

module.exports = { activate, deactivate };
