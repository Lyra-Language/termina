#!/bin/sh
# termina played headless (SDL's dummy driver, `--script`), its screens checked: a program's
# output, keys sent raw (a line to `cat`, Ctrl+D, Ctrl+C), the window's size reaching the
# program, the tabs — a new one, the first chosen by its tab and by Alt+1, the shown one closed
# from the header bar's ☰ — the Settings tab — a theme chosen from the keys and the font made
# bigger, both kept in the file, and the tab closed by its key — and, where zsh is installed,
# the command line at its prompt as uitest checked it on the ImGui host: a command run, the
# frame written as a PNG; an edit by the arrows and Backspace; Home; history by Up; Ctrl+U;
# Tab's completion. Exit 1 on a failure. After ./build.sh:
#
#     tools/check.sh
#
# Each run has a HOME of its own: no settings, no shell config, nothing added to the user's
# history.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/termina"
[ -x "$BIN" ] || { echo "no $BIN: run ./build.sh"; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export SDL_VIDEODRIVER=dummy
failed=0

# termina with HOME and its config in $TMP, ended after 60 s if it hangs.
run() {
  HOME="$TMP" XDG_CONFIG_HOME="$TMP/.config" perl -e 'alarm 60; exec @ARGV' "$BIN" "$@"
}

# check NAME GOT WANT: the output a run printed against the one wanted, exactly.
check() {
  if [ "$2" = "$3" ]; then
    echo "ok    $1"
  else
    echo "FAIL  $1"
    echo "  got:";  echo "$2" | sed 's/^/    /'
    echo "  want:"; echo "$3" | sed 's/^/    /'
    failed=1
  fi
}

check "a program's screen" "$(run --print printf 'hello\n')" "termina: 1 lines
hello"

check "a line to cat, and Ctrl+D" \
  "$(run --print --script "wait:500 'abc' Enter wait:300 Ctrl+d wait:500" cat)" "termina: 3 lines
abc
abc
^D"

check "Ctrl+C ends a program" "$(run --print --script "wait:300 Ctrl+c wait:500" sleep 30)" "termina: 1 lines
^C"

# The tabs, drawn as off a Mac (`--header`) so a Mac and Linux are alike: `cat` in the first, a
# new tab's shell in the second (shown), then the first shown again — its screen printed.
tabs() {
  SHELL=/bin/sh run --header --print --script "wait:300 'one' Enter wait:300 Primary+Shift+t wait:600 $1 wait:300" cat
}
cat_screen="termina: 2 lines
one
one"
check "a new tab, then the first chosen by its tab" "$(tabs 'click:20,57')" "$cat_screen"
check "a new tab, then the first chosen by Alt+1" "$(tabs 'Alt+1')" "$cat_screen"
check "the shown tab closed by ☰ ▸ Shell ▸ Close Tab" \
  "$(tabs 'click:819,20 move:830,114 move:600,118 click:600,215')" "$cat_screen"

# The Settings tab, by its keys alone (its controls' places are the font's): Settings…, Tab to
# the Theme list and Down to the next theme, the font a point bigger; then the file.
run --header --script "wait:300 Primary+, wait:200 Tab Tab Tab Tab Tab Tab Tab Tab Tab Down Primary+Shift+= wait:100" cat >/dev/null
file="$TMP/.config/termina/settings.json"
check "Settings: the next theme, chosen from the keys, kept" "$(grep -o '"theme": "[^"]*"' "$file")" '"theme": "Termina Light"'
check "Settings: the font a point bigger, kept" "$(grep -o '"font_size": [0-9]*' "$file")" '"font_size": 15'
rm -rf "$TMP/.config"
check "Settings closed by its key: typing reaches the terminal again" \
  "$(run --header --print --script "wait:300 'one' Enter Primary+, wait:200 Primary+Shift+w wait:200 'two' Enter wait:200" cat)" "termina: 4 lines
one
one
two
two"

cols="$(run --print sh -c 'tput cols' | tail -1)"
if [ "$cols" -gt 40 ] 2>/dev/null; then
  echo "ok    the window's columns reach the program ($cols)"
else
  echo "FAIL  the window's columns reach the program: got '$cols'"
  failed=1
fi

if ZSH="$(command -v zsh)"; then
  out="$(SHELL="$ZSH" run --print --script "wait:2500 'echo one' Enter wait:1500" --png "$TMP/frame.png")"
  if echo "$out" | grep -qx "one" && [ -s "$TMP/frame.png" ]; then
    echo "ok    a command run from zsh's prompt, the frame written"
  else
    echo "FAIL  a command run from zsh's prompt, the frame written"
    echo "$out" | sed 's/^/    /'
    failed=1
  fi
  # typed STEPS WANT NAME: STEPS typed at zsh's prompt, and the output line WANT among the
  # screen's lines (the prompt's own are the user's machine's, so only it is compared).
  typed() {
    out="$(SHELL="$ZSH" run --print --script "wait:2500 $1 wait:1500")"
    if echo "$out" | grep -qx -- "$2"; then
      echo "ok    $3"
    else
      echo "FAIL  $3: no line \"$2\""
      echo "$out" | sed 's/^/    /'
      failed=1
    fi
  }
  typed "'echo abc' Left Left Backspace 'X' Enter" "Xbc" "the command line edited by the arrows and Backspace"
  typed "'world' Home 'echo hello ' Enter" "hello world" "Home to the command line's start"
  typed "'garbage' Ctrl+u 'echo cleared' Enter" "cleared" "Ctrl+U clears the command line"
  typed "'echo /usr/bi' Tab wait:1500 Enter" "/usr/bin/" "Tab completes from zsh"
  # History: the command again by Up — its output twice.
  out="$(SHELL="$ZSH" run --print --script "wait:2500 'echo again' Enter wait:1200 Up Enter wait:1500")"
  if [ "$(echo "$out" | grep -cx again)" = 2 ]; then
    echo "ok    Up brings the last command back"
  else
    echo "FAIL  Up brings the last command back"
    echo "$out" | sed 's/^/    /'
    failed=1
  fi
else
  echo "skip  zsh's prompt: no zsh"
fi

exit $failed
