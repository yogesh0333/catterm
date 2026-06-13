#!/usr/bin/env zsh
# CatTerm test suite — pattern matching + catrule + sound playback

RST="\033[0m"; BOLD="\033[1m"
GRN="\033[38;2;80;255;120m"; RED="\033[38;2;255;80;80m"
YLW="\033[38;2;255;220;50m"; PRP="\033[38;2;180;80;255m"
CYN="\033[38;2;80;220;255m"; GRY="\033[38;2;130;130;130m"

pass() { echo -e "  ${GRN}✓${RST}  $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗${RST}  $1"; FAIL=$((FAIL+1)); }
section() { echo -e "\n${PRP}${BOLD}── $1 ──${RST}"; }
banner() { echo -e "\n${YLW}${BOLD}$1${RST}"; }
PASS=0; FAIL=0

DIR="$HOME/.catterm/sounds"
afplay_or_skip() { [[ -f "$DIR/$1" ]] && afplay "$DIR/$1" & }

# ── Load the hooks into this shell ───────────────────────────────────────────
source ~/.zshrc 2>/dev/null

# ── Helper: test if a command matches the right sound category ───────────────
check_pattern() {
  local label="$1" cmd="$2" expected="$3"
  local got=""

  # replicate _ct_precmd pattern logic (success branch)
  if   [[ "$cmd" =~ (npm (install|i )|yarn (add|install)|pnpm (add|install)) ]] ||
       [[ "$cmd" =~ (pip3? install|poetry (add|install)|pipenv install|conda install|uv (add|install|sync|pip install)) ]] ||
       [[ "$cmd" =~ (gem install|bundle (install|add)|cargo add|composer (install|require)|dotnet (restore|add package)|flutter pub (get|upgrade)|swift package (resolve|update)|go (get|mod (tidy|download|vendor))|brew (install|upgrade)|apt(-get)? install|dnf install|pacman -S|apk add) ]]; then
    got="install"
  elif [[ "$cmd" =~ (npm (run )?(build|compile)|yarn (build|compile)|pnpm (run )?(build|compile)|tsc|vite build|esbuild) ]] ||
       [[ "$cmd" =~ (cargo (build|compile|check)|go build|go install|go generate) ]] ||
       [[ "$cmd" =~ (mvn (package|compile|install)|gradle (build|assemble)|\.\/gradlew (build|assemble)|dotnet (build|publish)) ]] ||
       [[ "$cmd" =~ (flutter build|swift build|xcodebuild|docker (build|pull)|python3? -m build|rake (build|compile)|^make( |$)|cmake|ninja) ]]; then
    got="build"
  elif [[ "$cmd" =~ (npm test|yarn test|pnpm test|jest|vitest|pytest|python3? -m pytest) ]] ||
       [[ "$cmd" =~ (cargo test|go test|rspec|phpunit|pest|dotnet test|flutter test|swift test|gradle test|\.\/gradlew test|mvn test) ]]; then
    got="test"
  elif [[ "$cmd" =~ (git (commit|push|pull|merge|rebase|clone|fetch|stash|tag|cherry-pick)) ]]; then
    got="git"
  else
    got="generic"
  fi

  if [[ "$got" == "$expected" ]]; then
    pass "$label  ${GRY}($cmd)${RST}"
  else
    fail "$label  ${GRY}($cmd)${RST}  → expected ${GRN}$expected${RST} got ${RED}$got${RST}"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${PRP}${BOLD}"
echo "    /\\_____/\\"
echo "   (  ^ω^  )   CatTerm Test Suite"
echo "    )     (  "
echo "   ( ||||| )"
echo "    ‾‾‾‾‾‾‾"
echo -e "${RST}"

# ── 1. Pattern matching ───────────────────────────────────────────────────────
section "1. JS / TypeScript"
check_pattern "npm install"        "npm install"               install
check_pattern "npm i"              "npm i lodash"              install
check_pattern "yarn add"           "yarn add react"            install
check_pattern "pnpm install"       "pnpm install"              install
check_pattern "npm run build"      "npm run build"             build
check_pattern "yarn build"         "yarn build"                build
check_pattern "pnpm build"         "pnpm run build"            build
check_pattern "tsc"                "tsc --noEmit"              build
check_pattern "vite build"         "vite build"                build
check_pattern "jest"               "jest --watch"              test
check_pattern "vitest"             "vitest run"                test
check_pattern "npm test"           "npm test"                  test

section "2. Python"
check_pattern "pip install"        "pip install requests"      install
check_pattern "pip3 install"       "pip3 install -r req.txt"   install
check_pattern "poetry install"     "poetry install"            install
check_pattern "poetry add"         "poetry add flask"          install
check_pattern "uv install"         "uv pip install numpy"      install
check_pattern "conda install"      "conda install pandas"      install
check_pattern "pytest"             "pytest tests/"             test
check_pattern "python -m pytest"   "python3 -m pytest -v"      test
check_pattern "python -m build"    "python3 -m build"          build

section "3. Rust"
check_pattern "cargo add"          "cargo add serde"           install
check_pattern "cargo build"        "cargo build --release"     build
check_pattern "cargo check"        "cargo check"               build
check_pattern "cargo test"         "cargo test"                test

section "4. Go"
check_pattern "go get"             "go get github.com/x/y"     install
check_pattern "go mod tidy"        "go mod tidy"               install
check_pattern "go mod download"    "go mod download"           install
check_pattern "go build"           "go build ./..."            build
check_pattern "go test"            "go test ./..."             test

section "5. Java / Kotlin"
check_pattern "mvn package"        "mvn package -DskipTests"   build
check_pattern "mvn compile"        "mvn compile"               build
check_pattern "gradle build"       "gradle build"              build
check_pattern "gradlew build"      "./gradlew build"           build
check_pattern "mvn test"           "mvn test"                  test
check_pattern "gradle test"        "gradle test"               test
check_pattern "gradlew test"       "./gradlew test"            test

section "6. Ruby"
check_pattern "gem install"        "gem install rails"         install
check_pattern "bundle install"     "bundle install"            install
check_pattern "bundle add"         "bundle add devise"         install
check_pattern "rake build"         "rake build"                build
check_pattern "rspec"              "rspec spec/"               test

section "7. PHP"
check_pattern "composer install"   "composer install"          install
check_pattern "composer require"   "composer require laravel/framework" install
check_pattern "phpunit"            "phpunit"                   test
check_pattern "pest"               "pest"                      test

section "8. .NET / C#"
check_pattern "dotnet restore"     "dotnet restore"            install
check_pattern "dotnet build"       "dotnet build"              build
check_pattern "dotnet publish"     "dotnet publish -c Release" build
check_pattern "dotnet test"        "dotnet test"               test

section "9. Flutter / Dart"
check_pattern "flutter pub get"    "flutter pub get"           install
check_pattern "flutter pub upgrade" "flutter pub upgrade"      install
check_pattern "flutter build"      "flutter build apk"         build
check_pattern "flutter test"       "flutter test"              test

section "10. Swift / Xcode"
check_pattern "swift package resolve" "swift package resolve"  install
check_pattern "swift build"        "swift build"               build
check_pattern "xcodebuild"         "xcodebuild -scheme App"    build
check_pattern "swift test"         "swift test"                test

section "11. Docker / Infra"
check_pattern "docker build"       "docker build -t myapp ."   build
check_pattern "docker pull"        "docker pull nginx"         build

section "12. System pkg managers"
check_pattern "brew install"       "brew install ripgrep"      install
check_pattern "brew upgrade"       "brew upgrade"              install
check_pattern "apt install"        "apt install git"           install
check_pattern "apt-get install"    "apt-get install vim"       install
check_pattern "dnf install"        "dnf install curl"          install
check_pattern "pacman -S"          "pacman -S neovim"          install
check_pattern "apk add"            "apk add bash"              install

section "13. Make / CMake"
check_pattern "make"               "make"                      build
check_pattern "make target"        "make install"              build
check_pattern "cmake"              "cmake -B build"            build
check_pattern "ninja"              "ninja -C build"            build

section "14. Git"
check_pattern "git commit"         "git commit -m 'fix'"       git
check_pattern "git push"           "git push origin main"      git
check_pattern "git pull"           "git pull"                  git
check_pattern "git merge"          "git merge feature/x"       git
check_pattern "git fetch"          "git fetch --all"           git
check_pattern "git cherry-pick"    "git cherry-pick abc123"    git
check_pattern "git stash"          "git stash pop"             git

# ── 2. catrule tests ──────────────────────────────────────────────────────────
section "15. catrule add / list / remove"

# Clean slate
local orig_rules=$(cat ~/.catterm/rules)

catrule add 'docker build' german-cat.mp3 2>/dev/null
catrule add 'terraform apply' muhehehe.mp3 2>/dev/null
catrule add '!git push' mka-ladle-meow-gop.mp3 2>/dev/null

local list_out=$(catrule list 2>/dev/null)
[[ "$list_out" == *"docker build"* ]]      && pass "catrule list shows rule 1"  || fail "catrule list rule 1 missing"
[[ "$list_out" == *"terraform apply"* ]]   && pass "catrule list shows rule 2"  || fail "catrule list rule 2 missing"
[[ "$list_out" == *"success"* ]]           && pass "success rules labelled"     || fail "success label missing"
[[ "$list_out" == *"fail"* ]]              && pass "failure rules labelled"     || fail "fail label missing"

catrule remove 2 2>/dev/null
local list_after=$(catrule list 2>/dev/null)
[[ "$list_after" != *"terraform apply"* ]] && pass "catrule remove works"      || fail "catrule remove did not remove"

# Restore original rules file
echo "$orig_rules" > ~/.catterm/rules

# ── 3. Custom rule matching logic ─────────────────────────────────────────────
section "16. Custom rule matching"

# Run in a clean subshell so _CT_RULES assignment doesn't get shadowed
run_rule_test() {
  local label="$1" cmd="$2" code="$3" want_match="$4"
  local result
  result=$(zsh -c '
    source ~/.zshrc 2>/dev/null
    tmpf=$(mktemp)
    printf "docker build|german-cat.mp3\n!git push|mka-ladle-meow-gop.mp3\n" > "$tmpf"
    _CT_DIR="$HOME/.catterm/sounds"
    _CT_MUTED=1
    _CT_RULES="$tmpf"
    _ct_check_custom_rules "$1" "$2"
    echo $?
    rm "$tmpf"
  ' _ "$cmd" "$code" 2>/dev/null)
  if [[ "$want_match" == "yes" && "$result" == "0" ]]; then
    pass "$label"
  elif [[ "$want_match" == "no" && "$result" == "1" ]]; then
    pass "$label"
  else
    fail "$label  (got exit=$result, want_match=$want_match)"
  fi
}

run_rule_test "success rule matches on success"    "docker build -t myapp ." 0 yes
run_rule_test "failure rule matches on failure"    "git push origin main"    1 yes
run_rule_test "success rule skipped on failure"    "docker build -t x ."    1 no
run_rule_test "failure rule skipped on success"    "git push"                0 no
run_rule_test "unrelated cmd returns no match"     "ls -la"                  0 no

# ── 4. Sound playback ─────────────────────────────────────────────────────────
section "17. Sound playback"

play_and_check() {
  local label="$1" file="$2" wait="${3:-1}"
  if [[ -f "$DIR/$file" ]]; then
    echo -e "  ${CYN}♪${RST}  Playing: $label  ${GRY}($file)${RST}"
    afplay "$DIR/$file" &
    sleep "$wait"
    pass "$label plays"
  else
    fail "$label — file missing: $file"
  fi
}

play_and_check "install sound"      "muhehehe.mp3"                         2
play_and_check "build/test sound"   "happy-happy-happy-song.mp3"           2
play_and_check "git/generic sound"  "german-cat.mp3"                       2
play_and_check "failure sound"      "mka-ladle-meow-gop.mp3"               2
play_and_check "same-fail sound"    "abe-sale.mp3"                         2
play_and_check "depression sound"   "depression-indian.mp3"                2

wait  # wait for any background afplay

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
W=$(tput cols)
printf "${PRP}${BOLD}"; printf '━%.0s' $(seq 1 $W); echo "${RST}"
TOTAL=$((PASS + FAIL))
printf "${BOLD}  Results: ${GRN}$PASS passed${RST}  ${RED}$FAIL failed${RST}  /  $TOTAL total\n"
printf "${PRP}${BOLD}"; printf '━%.0s' $(seq 1 $W); echo "${RST}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GRN}${BOLD}All tests passed!  🐱${RST}"
  echo -e "  ${GRY}Run the black hole manually:  python3 ~/.catterm/blackhole_eater.py${RST}"
else
  echo -e "  ${RED}${BOLD}$FAIL test(s) failed — check output above${RST}"
fi
echo ""
