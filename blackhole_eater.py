#!/usr/bin/env python3
"""
Black Hole Eater — triggered after 5 consecutive command failures.
The black hole grows from the centre and eats the entire terminal.
"""

import sys, time, math, random, shutil, subprocess, os

RST  = "\033[0m"; BOLD = "\033[1m"
HC   = "\033[?25l"; SC  = "\033[?25h"

def fg(r,g,b): return f"\033[38;2;{r};{g};{b}m"
def bg(r,g,b): return f"\033[48;2;{r};{g};{b}m"
def at(r,c):   return f"\033[{r};{c}H"
def lc(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def cl(v,lo,hi): return max(lo, min(hi, v))

DIR = os.path.join(os.path.expanduser('~'), '.catterm', 'sounds')

def play(f):
    subprocess.Popen(
        ['afplay', os.path.join(DIR, f)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )

EATING_MSGS = [
    "5 FAILURES. REALLY?",
    "ARE BAAP RE...",
    "THE VOID IS HUNGRY",
    "TERMINAL CONSUMED",
    "YOUR CODE IS GONE",
    "NO SURVIVORS",
    "SPAGHETTIFICATION ACTIVE",
    "RIP YOUR CODEBASE",
]

def main():
    sys.stdout.write(HC + "\033[2J")
    sys.stdout.flush()

    W, H = shutil.get_terminal_size((80, 24))
    cx, cy = W // 2, H // 2

    # Max radius needed to cover every corner of the terminal
    max_r = math.sqrt((cx * 0.5) ** 2 + cy ** 2) * 1.6

    # Stars scattered around
    stars = []
    for _ in range(55):
        a  = random.uniform(0, math.tau)
        d  = random.uniform(0.35, 0.95) * min(cx, cy * 1.8)
        stars.append({
            'x':  cx + d * math.cos(a) * 2,
            'y':  cy + d * math.sin(a),
            'ch': random.choice('·∙·•·*·'),
            'tp': random.uniform(0, math.tau),
            'sp': random.uniform(0.05, 0.25),
        })

    play('are-baap-re-yaad-aya.mp3')   # play immediately

    START  = time.time()
    GROW_START = 2.5      # seconds before growth begins
    GROW_END   = 9.5      # fully consumed by here
    MOMENTS_AT = 10.0     # "a few moments later" sound
    END_AT     = 13.0     # total duration

    moments_played = False
    phase = 0.0
    frame = 0

    try:
        while True:
            elapsed = time.time() - START
            if elapsed >= END_AT:
                break

            W, H = shutil.get_terminal_size((80, 24))
            cx, cy = W // 2, H // 2

            # ── Compute how big the black hole is ────────────────────────────
            if elapsed < GROW_START:
                # Normal size — show it appearing
                t_in = elapsed / GROW_START
                Reh = min(cx * 0.45, cy * 0.85) * 0.24 * (0.2 + 0.8 * t_in)
            elif elapsed < GROW_END:
                # EATING — growing exponentially
                t_eat = (elapsed - GROW_START) / (GROW_END - GROW_START)
                t_eat = t_eat ** 0.55  # ease
                base  = min(cx * 0.45, cy * 0.85) * 0.24
                Reh   = base + (max_r - base) * t_eat
            else:
                # Fully consumed — solid black with overlay text
                Reh = max_r * 2

            Risco = Reh * 1.30
            Rdisk = Reh * 3.00
            Rglow = Rdisk * 1.40

            # ── Play "a few moments later" sound ─────────────────────────────
            if elapsed >= MOMENTS_AT and not moments_played:
                moments_played = True
                play('a-few-moments-later-sponge-bob-sfx-fun.mp3')

            # ── Render frame ─────────────────────────────────────────────────
            buf = ["\033[H"]

            for row in range(1, H + 1):
                pfg = pbg = None
                row_buf = []
                for col in range(1, W + 1):
                    ax  = (col - cx) * 0.5
                    ay  = row - cy
                    d   = math.sqrt(ax*ax + ay*ay)
                    ang = math.atan2(ay, ax)
                    rot = ((ang + math.pi) / math.tau + phase * 0.12) % 1.0

                    char = ' '
                    cfr = cfg = cfb = 3
                    cbr = cbg = cbb = 2

                    if d < Reh:
                        cbr = cbg = cbb = cfr = cfg = cfb = 0
                    elif d < Risco:
                        t    = (d - Reh) / (Risco - Reh)
                        beam = 0.55 + 0.45 * math.sin(rot * math.tau - phase * 2.5)
                        hot  = (1 - t) ** 0.5 * beam
                        c    = lc((150, 120, 255), (255, 255, 255), hot)
                        ck   = lc((10, 10, 40), (60, 50, 110), hot)
                        cfr, cfg, cfb = c
                        cbr, cbg, cbb = ck
                        char = '█' if hot > 0.70 else '▓' if hot > 0.45 else '▒'
                    elif d < Rdisk:
                        t     = (d - Risco) / (Rdisk - Risco)
                        beam  = 0.4 + 0.6 * math.sin(rot * math.tau + phase * 1.2)
                        thick = cl(1.0 - t * 0.65, 0.08, 1.0)
                        asn   = abs(math.sin(ang))
                        if asn < thick:
                            br    = beam * (1 - t) ** 0.7
                            swirl = (rot * 5 + t * 3 - phase * 0.2) % 1.0
                            if br > 0.60:
                                c  = lc((255, 190,  50), (255, 255, 200), (br-0.60)/0.40)
                                ck = (35, 15, 3)
                                char = '█' if swirl < 0.55 else '▓'
                            elif br > 0.35:
                                c  = lc((210,  75,  10), (255, 190,  50), (br-0.35)/0.25)
                                ck = (12, 4, 0)
                                char = '▒' if swirl < 0.50 else '░'
                            else:
                                c  = lc(( 50,   6,   2), (210,  75,  10),  br/0.35)
                                ck = (4, 1, 0)
                                char = '░' if swirl < 0.35 else '·'
                            cfr, cfg, cfb = c
                            cbr, cbg, cbb = ck
                        else:
                            sc = (thick / max(asn, 0.01)) * (1 - t) * 0.30
                            if sc > 0.05:
                                cfr, cfg, cfb = int(180*sc), int(65*sc), int(15*sc)
                                char = '·'
                    elif d < Rglow:
                        t     = (d - Rdisk) / (Rglow - Rdisk)
                        pulse = 0.5 + 0.5 * math.sin(phase * 3.5 + d * 0.9)
                        gl    = (1 - t) ** 2.2 * 0.38 * (0.65 + 0.35 * pulse)
                        if gl > 0.04:
                            cfr, cfg, cfb = int(190*gl), int(65*gl), int(18*gl)
                            char = '·'

                    nfg = (cfr, cfg, cfb)
                    nbg = (cbr, cbg, cbb)
                    cell = ""
                    if nfg != pfg: cell += fg(*nfg); pfg = nfg
                    if nbg != pbg: cell += bg(*nbg); pbg = nbg
                    cell += char
                    row_buf.append(cell)

                buf.append(''.join(row_buf) + RST + '\n')

            # ── Stars get sucked in ───────────────────────────────────────────
            for s in stars:
                dx = cx - s['x']; dy = cy - s['y']
                dd = math.sqrt(dx*dx/4 + dy*dy) + 0.1
                pull = s['sp'] * 0.015 * (max(Reh, 5) * 2 / dd) ** 1.5
                s['x'] += (dx/dd/2) * pull
                s['y'] += (dy/dd)   * pull
                sx, sy = int(s['x']), int(s['y'])
                if 1 <= sx <= W and 1 <= sy <= H:
                    tw = 0.5 + 0.5 * math.sin(s['tp'] + phase * 2.5)
                    bv = int(80 + 175 * tw)
                    buf.append(f"{at(sy,sx)}{fg(bv,bv,min(255,bv+30))}{s['ch']}{RST}")

            # ── Eating-phase dramatic text ─────────────────────────────────────
            if GROW_START < elapsed < MOMENTS_AT:
                mi  = int(elapsed * 1.2) % len(EATING_MSGS)
                msg = EATING_MSGS[mi]
                pulse = abs(math.sin(elapsed * 2.5))
                r = int(255 * pulse); g = int(30 * pulse)
                mx = cl(cx - len(msg)//2, 1, max(1, W - len(msg)))
                buf.append(f"{at(cy, mx)}{fg(r,g,0)}{BOLD}{msg}{RST}")

            # ── "A few moments later..." overlay ──────────────────────────────
            if elapsed >= MOMENTS_AT:
                fade  = cl((elapsed - MOMENTS_AT) / 0.6, 0.0, 1.0)
                bv    = int(255 * fade)
                lines = [
                    "✦  A  F E W  M O M E N T S  L A T E R . . .  ✦",
                    "",
                    "     maybe fix your code next time, yeah?",
                ]
                for i, line in enumerate(lines):
                    my = cy - 1 + i
                    mx = cl(cx - len(line)//2, 1, max(1, W - len(line)))
                    color = fg(bv, bv, bv) if i > 0 else fg(bv, int(bv*0.8), 0)
                    buf.append(f"{at(my, mx)}{color}{BOLD}{line}{RST}")

            sys.stdout.write(''.join(buf))
            sys.stdout.flush()

            phase += 0.038
            frame += 1
            time.sleep(1/25)

    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write(f"{SC}\033[2J\033[H{RST}")
        sys.stdout.flush()

if __name__ == '__main__':
    main()
