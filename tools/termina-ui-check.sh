#!/bin/sh
# termina-ui played headless (SDL's dummy driver, `--script`), its screens checked: a program's
# output, keys sent raw (a line to `cat`, Ctrl+D, Ctrl+C), the window's size reaching the
# program, and — where zsh is installed — a command run from the command line at its prompt,
# the frame written as a PNG. Exit 1 on a failure. After ./build.sh:
#
#     tools/termina-ui-check.sh
#
# Each run has a HOME of its own: no settings, no shell config, nothing added to the user's
# history.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/termina-ui"
[ -x "$BIN" ] || { echo "no $BIN: run ./build.sh"; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export SDL_VIDEODRIVER=dummy
failed=0

# termina-ui with HOME and its config in $TMP, ended after 60 s if it hangs.
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

check "a program's screen" "$(run --print printf 'hello\n')" "termina-ui: 1 lines
hello"

check "a line to cat, and Ctrl+D" \
  "$(run --print --script "wait:500 'abc' Enter wait:300 Ctrl+d wait:500" cat)" "termina-ui: 3 lines
abc
abc
^D"

check "Ctrl+C ends a program" "$(run --print --script "wait:300 Ctrl+c wait:500" sleep 30)" "termina-ui: 1 lines
^C"

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
else
  echo "skip  zsh's prompt: no zsh"
fi

exit $failed
