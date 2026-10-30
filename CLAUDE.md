# Termina — Project Context

Termina (γ Lyrae) is a terminal emulator written in Lyra, after Warp: commands and their
output as **blocks**, and a command line that edits like a text editor rather than a shell's
line editor. **Open source, MIT** (`LICENSE`); the repository is private until published, and
contributions are not being accepted yet. Lives in the Lyra workspace beside `lyra/`; the
workspace's `CLAUDE.md` rules apply here too. **macOS and Linux** — Windows waits on Lyra
(`pkg/abi` has no Windows convention, `std.io` is POSIX, and Windows' PTY is ConPTY).

## Commands

```bash
../lyra/build.sh            # the compiler, std/, bindings/, ui/ and lib/liblyra-*.a
./build.sh                  # -> build/: termina (and Termina.app on macOS), vttest
build/termina               # the login shell ($SHELL -l) in a window of tabs: ⌘T new (in the
                            #    shown tab's directory), ⌘W close, ⌘1–⌘9, ⌘⇧[ ⌘⇧]; a tab
                            #    closes when its shell ends, the window with the last
build/termina CMD [ARG…]    # that program instead (as xterm -e), no integration — a test
                            #    script's colors, say, seen without typing
open build/Termina.app      # the same, as a Mac app
                            # Settings… (⌘,; Ctrl+, off macOS): font, size, spacing, colors,
                            #    the window — kept in ~/.config/termina/settings.json
build/termina --header …    # drawn as off a Mac on a Mac too — the header bar — for checks
build/termina --print CMD … # and, when it ends, its screen printed
build/termina --script STEPS [--png FILE] [CMD …]   # played headless (with
                            #    SDL_VIDEODRIVER=dummy): `ui.script`'s steps, `wait:N` real time
tools/check.sh              # the window's checks, scripted, each in a HOME of its own
build/vttest                # parser, screen, editor, PTY, zsh and bash checks, and the
                            #    window's logic; exit 1 on a failure
../lyra/build/lui src/settings_page.lui  # regenerate the Settings markup's module after
                            #    editing it (or `lui --watch src/*.lui`); build.sh refuses a stale one
./package.sh 0.4.0          # after build.sh: build/release/Termina-0.4.0-macos-arm64.zip, or
                            #    termina-0.4.0-linux-<arch>.tar.gz, SDL3 inside; with
                            #    TERMINA_APPIMAGE=1 on Linux, Termina-0.4.0-linux-<arch>.AppImage
tools/textlibs.sh build/deps/text   # static FreeType and HarfBuzz, for a release's build
                            #    (PKG_CONFIG_PATH=build/deps/text/lib/pkgconfig:… ./build.sh)
tools/sdl3_image.sh build/deps/image  # static SDL3_image (PNG, JPEG, SVG…), likewise, against
                            #    the SDL3 pkg-config finds
git tag v0.4.0 && git push origin v0.4.0   # a release: built, checked and published by
                            #    .github/workflows/release.yml (macOS arm64, Linux x86_64
                            #    and arm64); Actions ▸ Release ▸ Run workflow is a dry run
```

## Releases

- **A tag is a release.** `release.yml` checks out lyra and tree-sitter-lyra at `main`
  (a dry run may name other refs) beside Termina, builds SDL3, lyra (Go's build cache
  cleared first: it does not hash the grammar's `#include`d parser, so a restored one
  builds lyra with the old grammar) and Termina, runs
  vttest and `tools/check.sh`, packages, and publishes the archives with the commits each
  was built from in the notes — a tag of Termina pins nothing of the compiler's.
- **FreeType, HarfBuzz and SDL3_image are built static** (`tools/textlibs.sh`,
  `tools/sdl3_image.sh`, pinned and SHA-256 checked, no optional dependencies — HarfBuzz from
  its one amalgamated source without a C++ runtime, SDL3_image with its own decoders only:
  stb_image's PNG and JPEG, nanosvg's SVG, no libpng, libavif, libwebp, libjxl, libtiff or
  ImageIO) and come first on `PKG_CONFIG_PATH`, so the program carries them: `ui` draws its
  text with the first two, the backgrounds' images are decoded by the last, and a machine may
  have none (Homebrew's are built for the macOS they run on). SDL3_image is built against the
  release's own SDL3. `package.sh` refuses a Linux program linking any of them as a shared
  library, and a Mac's linking anything outside the system and the bundle. On Linux lyrac links a program's
  libraries as one group, since two static archives depend on each other in an order the
  linker would otherwise need given.
- **SDL3 is built from source** (`tools/sdl3.sh`, lyra's pin — move the two together) and
  **travels with the program**: in `Termina.app/Contents/Frameworks` (found through
  `@rpath`), or in the archive's `lib/` (an rpath of `$ORIGIN/lib`, set by patchelf).
  Homebrew's is built for the Mac it runs on, and Ubuntu 24.04 has none.
- **Linux releases are an AppImage too**: the archive's directory as an AppDir (`AppRun` a
  link to the program, `assets/dev.lyra_language.Termina.desktop` and the icon beside it,
  as SVG and PNG under that id), made by
  appimagetool and its runtime as `tools/appimagetool.sh` pins them, SHA-256 checked. No
  sandbox — a Flatpak's would need the shell started on the host — and no
  `LD_LIBRARY_PATH`, so the shells Termina starts load nothing of its. Run extracted, not
  mounted, where there is no FUSE (`APPIMAGE_EXTRACT_AND_RUN`); an AppImage of another
  processor does not run under emulation, its header's magic tripping the emulator.
- **The Mac app runs on macOS 13 and later** (`MACOSX_DEPLOYMENT_TARGET`, read by clang,
  SDL3's CMake and the text libraries' build). Linux archives run on glibc 2.39 and later (Ubuntu
  24.04's).
- **The Mac app is signed with a Developer ID and notarized** when the repository has the
  secrets below; without them, ad hoc, with a warning in the run and the release notes.
  `package.sh` does it from `TERMINA_SIGN_IDENTITY` and `TERMINA_NOTARY_*`: the hardened
  runtime with a secure timestamp, `notarytool` (its answer checked for `Accepted`, Apple's
  log printed otherwise) and the ticket stapled. **The bundled SDL3 is signed with the same
  identity**, or library validation refuses to load it ("different Team IDs").
  **Not the App Store**: its sandbox would confine the user's shell and everything run
  from it to the app's container.

  | secret | what |
  |---|---|
  | `MACOS_CERTIFICATE_P12` | the Developer ID Application certificate and its key, exported as `.p12`, base64 (`base64 -i cert.p12 \| gh secret set MACOS_CERTIFICATE_P12`) |
  | `MACOS_CERTIFICATE_PASSWORD` | the `.p12`'s password |
  | `NOTARY_KEY_P8` | an App Store Connect API key (Developer role), the `.p8` file's text (`gh secret set NOTARY_KEY_P8 < AuthKey_….p8`) |
  | `NOTARY_KEY_ID` | that key's id |
  | `NOTARY_ISSUER_ID` | the account's issuer id (App Store Connect ▸ Users and Access ▸ Integrations) |

- **What the app may ask for is its commands'**: macOS asks about a child process's
  camera, microphone, Apple Events, local network and folders as the app's that started it.
  `assets/Termina.entitlements` (signed into the app, not SDL3) lets the hardened runtime
  pass Apple Events, the microphone and the camera — without it they are refused with no
  prompt — and `build.sh`'s `Info.plist` gives every prompt its reason (those three, Local
  Network for `ssh` to a machine nearby, Desktop, Documents, Downloads, removable and
  network volumes). Full Disk Access is the user's to grant. A new kind of access a command
  needs is an entitlement there, if the hardened runtime gates it, and a usage string.

## Architecture

```
shell ⇄ bindings.pty ──bytes──▶ vt.Parser ──[]Action──▶ vt.Screen ──▶ face (ui's PaintOps)
  ▲                                                       │ marks
  │                                                       ▼ (OSC 133)
  ├──── keys as typed (control_bytes…) ◀──── Mode: Raw ─┬─ AtPrompt(line, col)
  └──── submission (bracketed paste + ⏎) ◀── term.CommandLine ◀─ editor.Editor
```

**One front end over the terminal.** `session`, `term`, `vt`, `editor`, `shell` and
`settings` know no interface framework — they import only `ui.draw`'s `Point` and
`ui.backend`'s keys, pure Lyra. `face` paints them on lyra's `ui` (`../lyra/ui/WINDOW.md`):
each tab a painter taking input raw, under `ui`'s tab bar, menus and Settings tab. (Until
10/23 a Dear ImGui front end, `gui`, drew them; `ui` replaced it.)

| file | what |
|---|---|
| `src/termina.lyra` | `main`: the fonts (the settings' family as `mono`, the fallbacks), the window on the GPU — at its remembered place, see-through if the background is — or played headless by `--script` through SDL's 2D renderer, a `wait:` taking real time in slices so the shell is heard; `--print`, `--png`, `--header`; on Linux the window's id and an AppImage's desktop entry |
| `package.sh`, `tools/sdl3.sh`, `tools/sdl3_image.sh`, `tools/textlibs.sh`, `tools/appimagetool.sh` | a release archive with SDL3 inside — the Mac app signed and notarized when given an identity and key, an AppImage on Linux — SDL3, and static SDL3_image, FreeType and HarfBuzz, built from source for it, and the pinned appimagetool (Releases, above) |
| `tools/check.sh` | the window's checks: scripted runs, each in a `HOME` of its own, their screens or settings compared — tabs, menus, the Settings tab, and the command line at zsh's prompt |
| `assets/` | the icon: `termina.svg` the source; `Termina.icns` (the app's) and `termina.png` made from it (`assets/README.md`); `Termina.entitlements`, what the signed app's commands may ask for (Releases, above) |
| `src/desktop/desktop.lyra` | Termina on a Linux desktop: the id its windows go by (`APP_ID`), and, run as an AppImage, the desktop entry and icon it installs for the launcher and the dock |
| `src/session/session.lyra` | one tab: its PTY (opened at the window's cells, measured before the program starts), screen, `Mode`, blocks and command line, read when it has written; where its frame's parts go (`frame_layout`: the box, the grid's lines, `Rows` incl. folded blocks' hidden lines, the page), the grid's selection, a block's copy (`block_copy_at`, a right click's target), its whole-selection (`select_block_at`) and fold state (`toggle_fold_at`, `fold_at`, `Block.folded`), the bytes a key sends (`key_sequence`, `control_bytes`) — no framework |
| `src/term/line.lyra` | the editor at the prompt (`CommandLine`): keys and typed text (`LineInput`) and the mouse into editor calls, history, Ctrl+R, the completion menu's layout; what it asks of its host as an `Outcome` (`Submit`, `Send`, `Complete`, `Clip`, `PasteWanted`) — no framework |
| `src/term/tabs.lyra` | a tab's label and the tab commands the window carries out (`TabCommand`) |
| `src/term/theme.lyra` | recorded colors → pixels (ABGR): the theme's own pair, ANSI 16, xterm's 256; inverse, dim, hidden |
| `src/term/typeahead.lyra` | keys typed ahead, raw, made into lines (Backspace, Ctrl+U/W applied; escapes dropped) |
| `src/face/app.lyra` | the window on `ui` (`Term`, `TermEvent`): the bars over the shown tab's painter taking raw input, each tab's PTY a `Readable`, the shortcuts, update |
| `src/face/settings.lyra` | the Settings tab on `ui`: its events carried out on the window's settings — the theme, the font (a family loaded through `LoadFonts`), the file written a moment after the last change |
| `src/settings_page.lui` | the Settings tab as `ui`-target markup — font family or file, size, spacing, theme (saved ones too), every color, bold as bright, the window; `settings_page.lyra` is generated from it (edit the `.lui`) |
| `src/face/window.lyra` | the chrome on `ui`: the tab bar, the header bar off a Mac, the menus as data (`menus_of` for the Mac's bar, `header_entries` for ☰), all in `ui`'s theme made from Termina's |
| `src/face/fills.lyra` | the backgrounds' fills drawn (`fill_ops`: a color, `ui`'s gradient, or `ui`'s `picture_fill`, at the color's opacity), and their images decoded once a file (`fill_images`, `bindings.sdl3_image`) |
| `src/face/paint.lyra` | a tab painted (`paint_tab`): the grid as `PaintCells`, the cards, the box, the command line and its menu, the scrollbar, the hovered block's copy button (`hovered_block`, `copy_button`) — from `session.frame_layout` |
| `src/face/input.lyra` | keys, typed text and the pointer as the painter hears them: to the command line at a prompt, else encoded for the program; the mouse selecting, a block whole on the terminal's chord, folded on a card-gutter click, copied on a right click, its output copied by its copy button, editing or reported |
| `src/shell/shell.lyra` | shell integration (zsh's `.zshenv` through `ZDOTDIR`, bash's rc file through `--rcfile`): the marks, Tab's completion widget and its request file, the command lookup widget and its file, the history files, what Return sends |
| `src/editor/editor.lyra` | the command line's editor — text, caret, selection, motions, words, undo, layout; **pure** |
| `src/editor/syntax.lyra` | the command line's syntax for coloring: each rune's kind (command, option, quoted, variable, operator, comment), and the plain command words to ask the shell about; **pure** |
| `src/vt/parser.lyra` | bytes → `Action`s — Paul Williams' DEC parser; **pure**, keeps all state across reads |
| `src/vt/screen.lyra` | `Action`s → the cell grid, cursor, scroll region, scrollback ring |
| `src/vt/width.lyra` | how many cells a rune takes: 2 wide (CJK, emoji), 0 combining, 1 the rest |
| `src/vt/selection.lyra` | a selection on the screen and scrollback: its text, a word's span; **pure** |
| `src/vt/style.lyra` | a `Cell`'s colors and attributes, and SGR on the `Pen` that writes them; **pure** |
| `src/settings/backing.lyra` | a background's fill (`Backing`): its color alone, a gradient (linear or radial, 2 to 8 stops) or an image and how it fits — part of the colors, so a saved theme keeps them |
| `src/settings/settings.lyra` | the user's settings, the themes offered, the file (read leniently), the monospaced families found |
| `src/vttest.lyra` | the checks: byte strings against actions and screens, the editor on text, real programs, zsh and bash on a PTY (each skipped, and said so, where not installed), and the window's logic — the theme, sessions, mouse reports, the settings file |

- **A constructor's name is the program's, not its module's**: Lyra matches them program-wide
  by name, so Termina's own may not take one `ui` or `bindings.sdl3` has (`vt`'s parser state
  is `EscapeState`, not `Escape`; the editor's `OtherEdit`, not `Other`).
- **The menus are one tree as data** (`face/window.lyra`): on a Mac `App.menus`
  installs them in the system's bar, which holds their keys (⌘⇧[ given to AppKit as `⌘{`,
  `ui.sdl3`'s doing); elsewhere `App.title_bar` is `DrawnTitleBar` and the header bar draws
  `+`, the title, ☰ (`menu_button` over `header_entries`) and `window_buttons`, the app taking
  the drawn menus' keys. Off a Mac, Edit's Undo and Redo show no key: Ctrl+Z is a running
  program's. The chrome is `themed` in a `ui` theme made from Termina's (`chrome_theme`,
  `chrome_sheet`): the tab colours, the completion menu's for a menu.
- **The Settings tab's controls are on a panel** (`.panel`, `chrome_sheet`: the output
  section's colour, rounded as a card) set `PAD` in, the window's background a band round
  it: over a background clear enough to show the desktop, controls are hard to read. The
  panel scrolls, not the page.
- **The Settings tab** is the last of the tab bar's, out of the tabs' order, shown in
  place of the terminal (which goes on being read); ⌘W while it is shown closes it. A change
  takes at once: the theme is rebuilt and told to every tab — the window's root takes its
  background, `App.background` being fixed at the start — and the font is measured again; a
  family not loaded yet is added under its own name (`family <name> <regular file>`) by
  `LoadFonts` and the grid's `FontSpec` switched to it. The file is written
  `SAVE_DELAY_MS` after the last change (a save a change, only the last carried out) and as
  the window closes (`save_now`). Buttons and the chosen option take the text's colour
  (`chrome_sheet`): a light theme's chosen row is light.
- **The backgrounds alone may be translucent** — the window's and the sections' (input and
  output, `may_be_clear`): a settings colour is `0xRRGGBB` with how transparent it is in the
  top byte, so every theme's own `0xRRGGBB` is opaque; the file writes `#rrggbbaa` for one
  that is not (`hex_of`, `color_of`), and every other colour is made opaque wherever it comes
  from (`backgrounds_alone_clear`, `with_color`, `with_ansi`; their swatches are `opaque`, no
  opacity strip). A card's input and output bands are painted side by side, never one over
  the other. **Each translucent section blurs what is behind it** (`paint.lyra`'s `section`, a
  `ui` backdrop under its fill) by its own blur — `input_blur` (the box, a block's prompt and
  command) and `output_blur`, 16 points to begin with — the desktop through a see-through
  window, and under the box the transcript scrolled behind it (unblurred, its text runs
  through the prompt's). macOS only, as `ui`'s backdrops are. **A translucent box shows the
  transcript scrolled under it.** The three blurs — those two and `background_blur` — are
  set in their colours' pickers, under the opacity strip (`blur_named`, `with_blur`,
  `SetBlur(field, …)`). **The transcript is
  clipped at the box, never covered** (`paint_tab`'s `PushClip`: at its top while it is opaque,
  at its foot while not), and the rule along its top stops at its rounded corners: anything
  drawn behind them — a rectangle of the window's background, doubling a see-through one —
  shows round the corners. **A background that is not
  opaque makes the window see-through** (`ui`'s `set_see_through`; Termina clears to
  nothing and its view's root paints the background), its title bar staying opaque (a Mac's
  through `bindings.gpu`'s shim, the header bar's own background elsewhere), with what is
  behind it blurred by `background_blur` (its picker, macOS only). On Linux the window
  is see-through only if it opened so: a change takes effect at the next start.
- **A background may be filled beyond its color** — a gradient (linear at an angle, or
  radial, 2 to 8 stops each with its own opacity) or an image file and how it fits (tiled at
  its own pixels, stretched, or stretched and cropped) — `Colors.bg_fill`, `input_fill`,
  `output_fill` (`settings/backing.lyra`), set in Settings ▸ Backgrounds. **The color still
  sets the opacity, and is what shows** until an image decodes, or where one will not.
  Images decode once a path (`fill_images`, at start and each change), are kept by path with a
  revision, and are `ui` pictures the host keeps as textures. The window's own is a painted
  layer under everything; without a fill, the root's color as before. An SVG is drawn 2048
  pixels wide.
- **Termina reopens the window where it was last closed** (Settings ▸ Window,
  `Settings.remember_window`, on by default): as the window closes, `place_of` keeps its place,
  size and whether it is maximized in the settings file (`window`) — while maximized or
  minimized, the place and size from before, since the system no longer says them — and it
  opens at that size, moved there if a display shows the place, maximized again. No place on
  Wayland, which never tells a window where it is: the size alone. A script's run neither
  restores nor records it.
- **The sections stand `PAD` in from the window's edges**, the tab bar too: the
  text is set `INSET` (`PAD + BOX_MARGIN`) in across, the cards and the box reaching
  `BOX_MARGIN` out from it, and the box ends `PAD` above the window's foot. Every place a
  column turns into an x, or back (the pointer, the caret), goes through `INSET`. The tabs
  are rounded above only (`Style.corners`), 8 points below the title bar, and stand on a
  rule across the whole window (`tab_rule`), past their margins: a theme's color
  (`Colors.tab_rule`, the text faint over the background to begin with) and
  `Settings.tab_rule_width` thick (1 point to begin with, 0 for none), both set in its
  picker (Tabs ▸ Underline).
- **The terminal takes the keyboard when its painter is first laid out** (`ViewSized` asks
  `FocusKeyed("term")`): `ui` focuses nothing by itself. The painter takes input raw
  (`RawInput`): the arrows and Tab are the shell's, ⌘ (Ctrl+Shift off macOS) is the
  terminal's own, Ctrl+letter the control character. **Text typed at a prompt is handed over
  without the modifiers**: SDL types nothing for a Ctrl or ⌘ chord, and the last key's may be
  stale (a script's text comes with no key before it). **The terminal scrolls itself**, not
  in a `ui` scroller, since its columns and rows are the view's (`face/app.lyra`'s note).
- **On Linux the window's id is `dev.lyra_language.Termina`** (`desktop.APP_ID`, set as
  SDL's `SDL_APP_ID` before the window opens: its Wayland app id and X11 class), and a
  desktop entry's file name and `StartupWMClass` must be that id for the dock to show its
  icon. **Run as an AppImage, Termina installs its own entry** in
  `$XDG_DATA_HOME/applications` (else `~/.local/share`), `Exec` and `TryExec` the
  AppImage's path, with the icon (the Mac app's art, `termina.svg`) in the user's hicolor
  theme — written only when either would change, so a moved or newer AppImage updates
  them, and a launcher hides the entry once the AppImage is gone.
- **The parser recognises, the screen acts.** Neither reads the other's input: the parser is
  tested on bytes alone, the screen on actions. A new sequence is a `Screen.csi`/`esc`/`osc`
  case and a `vttest` line.
- **Every tab is read every frame, shown or not** (`Session.step`), so a program writing in a
  hidden tab never waits on a full terminal; only the shown one is drawn and gets keys.
  **Reading only ever ends a tab** (`alive` cleared, never set): a tab the user closed
  (`request_close`) stays closed though its program has not ended yet. **Tabs drag into a new
  order** (`ui`'s tab bar raising `TabMoved`, `face/app.lyra`'s `tab_moved`), the window's
  list put in it — one order for the bar, ⌘1–9 and ⌘⇧[ ⌘⇧], the shown tab followed. A tab
  is keyed by its session's id (`tab <id>`), which a changing title must not move. Past the
  strip's width the gap between tabs narrows from 6 to 2, then the tabs shrink, then the rest go
  into the strip's more-tabs menu.
- **Edit's items are one path with their keys** (`EditAction`): `CommandLine.edit_action` at a
  prompt, and while a program runs only Paste, sent bracketed when the program set
  `?2004` (`session.pasted`). The Mac's bar holds ⌘Z/⌘X/⌘C/⌘V/⌘A and sends Edit's item
  (`EditAsked`); each item is greyed where it would do nothing (`Session.can`). **On the
  Settings tab they are its focused field's** (`field_edit`, `ui`'s `Command.EditField`) — a
  colour's hex, a theme's name — which never hears the keys the bar holds; Redo greyed.
- **The screen answers questions through `replies`** (DA1, DA2, XTVERSION, DSR, DECRQM, the
  color queries OSC 10/11/12), which a session writes to the program each frame; a check
  running a program on a PTY must answer them too (`vttest`'s `full_screen`).
- **The alternate screen keeps no scrollback and shows none**: lines leaving it are not
  history, and a session draws from the screen's first row while it is on (`base`). The main
  screen behind it is fitted on resize.
- **A wide rune is a cell and a `SPACER`**; writing over either half blanks the other, and a
  wide rune with one column left wraps first, the column it left blank marked `FILLER` — the
  screen's own writing, which a copy joining the wrapped line drops alone (a line's own
  trailing blanks are kept). Drawing puts a wide glyph on its two cells
  alone, centred. The command line lays runes out the same way (`editor.layout`, `cells_of`):
  a wide rune two columns, wrapped whole, a combining mark none.
- **A zero-width rune joins the cell before it** (`Screen.combine`): a cell's combining marks
  are the screen's `combining` table, and the bits of its `attrs` above `MARKS_SHIFT` say
  which run (`marks_of`, 0 for none) — so a cell stays four scalars and width, words and
  selection read its base rune as before. Drawing and copying put the marks after it; a
  marked cell is drawn alone, so a mark's own advance cannot move what follows.
- **A soft wrap is `WRAPPED` on a line's last cell**, set as the text goes on to the next
  line; a copy joins such a line to the next, its trailing blanks kept. Being a cell's bit
  it travels with the line through scrolls, scrollback and inserts, and a write or erase of
  that cell clears it.
- **Text is hinted off macOS** (`ui.text`'s `Fonts.hinting`, FreeType's light hinting): a
  Linux display is most often a pixel a point, where unhinted stems straddle two columns and
  look soft. A Mac draws text unhinted, and Termina there does too. Hinted advances are whole
  pixels, so a cell is.
- **Glyphs a family lacks come from fallback fonts** (`settings.fallback_fonts`: Arial
  Unicode or Noto Sans CJK, then Apple Symbols or DejaVu Sans), `ui.text`'s fallbacks
  (`add_fallback`). Color emoji are not drawn yet (`ui.text` has no colour glyphs).
- **A command is a block of the transcript** (`Session.blocks`, `Block`): `C` opens one
  from the last prompt's `A` line (`OutputStart(line)`), `D` closes it
  (`CommandEnd(status, line)`, its line the first the output did not write on) — or, where the
  program ends without its `D`, the program's status does (`Session.exit`, kept once
  `exit_status()` answers, its end the screen's used rows). The block also keeps where the
  command's text began (`cmd_line`, `cmd_col`: where the input began, past the prompt — from the
  command line's send, the shell's `B` mark, or the prompt's line whole), so a right click on a
  block copies it: its command on the input's lines, its output on the output's
  (`Session.block_copy_at`, read the way a selection over the lines would be). The block under
  the pointer also shows a copy button in the card's right margin on its first output line in
  view, placed and sized as the fold chevron is in the left (`margin_mark`), which
  copies the output (`copy_button`, `Session.output_copy`) and says "Copied" until the pointer is
  over another block — one geometry for drawing and clicking (`hovered_block`, from
  `Term.pointer`, the pointer's last place over the terminal). Drawn as a
  card: the input on the theme's input color, the output on its output color, rounded,
  with padding around each and a margin between cards; the duration and a failure's `exit N` over its
  first row's right end where the text leaves room, a red bar down a failed one's left. A press
  under the terminal's chord on a block's line (or Block ▸ Select Block) selects the block whole
  (`Session.select_block_at`); a finished block whose output is more than a line folds — a click in
  the card's left gutter (or Block ▸ Fold/Unfold) hides the output's lines past its first, which
  stand in for them as a line count on that line's own row (`Block.folded`). **The gutter shows
  the toggle**: ▾ on the first output line of the block under the pointer while it is open
  (`fold_toggle`), ▸ there always while it is folded (`fold_line`), drawn half again the text's
  size (a speck otherwise) and brightened with the pointer on it. **Only the chevron toggles**:
  a press inside its rect (`fold_toggle`, shared by paint and input), not the gutter around it or
  the count. The margins are `BOX_MARGIN` wide, room for the chevron and the copy button clear of
  the card's edge and the text.
- **On the main screen the grid ends at the rows in use** (`Screen.used_rows`: the cursor's
  row, or a lower one with anything on it): the blank rows below a running command's output
  would pad the page past the view, with the box and the cards' room, and the view, following
  the bottom, would scroll what was written — sudo's password prompt — out of sight. A
  full-screen program on the alternate screen has every row.
- **Rows are not evenly spaced: `Rows` is where every line goes** (`block_rows_layout`, a
  frame's gaps above lines, from the blocks). Everything that turns a line into a height
  or back — drawing, the cursor, selection, the first line in view, the page's height, the
  mouse — asks it (`y_of`, `y_above`, `line_at_y`); `i × cell.y` is wrong wherever blocks
  are. A folded block's hidden output lines (past its first) are ranges in `Rows`
  (`is_hidden`, `hidden_before`): they take no room, `line_at_y` lands on the next drawn line,
  and a view's end (`visible_end`) counts drawn lines only. A program's mouse reports still count the screen's own rows: blocks put no gaps on
  the alternate screen, and a `clear` drops those on the main one. A screen
  erased whole on the main screen (`\e[2J`, `\e[J` from its first cell: `clear`, Ctrl+L)
  is the `Cleared(line)` mark, and the blocks on it go. None on the alternate screen.
- **The grid's selection is absolute lines and column boundaries** (`vt.Spot`), so it stays
  on its text as output scrolls. The mouse selects above the command line at a prompt, and
  with Shift when a program has asked for the mouse (`?1000`/`?1002`/`?1003`, SGR `?1006` or
  X10), which is otherwise told of it; a press under the terminal's chord on a block's line (or
  Block ▸ Select Block) takes the block whole. On the alternate screen an unreporting program gets
  the wheel as arrows (`?1007`).
- **Erase at a pending wrap erases the last column**, as xterm does: a line exactly as wide as
  the screen followed by `\e[K` loses its last character (less's status on a long path).
- **Nothing blocks**: `Pty.read` is non-blocking and drained once a frame, at most
  `READS_PER_FRAME` reads, so a program that never stops writing cannot freeze the window.
- **Settings live in `~/.config/termina/settings.json`** (`$XDG_CONFIG_HOME` first); with
  none there, the file the terminal kept as Sulafat (`~/.config/sulafat/`, `OLD_NAME`) is
  read, and the next save writes the new one. The old file is left alone. **Colors are
  `colors` in it, read as `colours` where a file has no `colors`** (`colors_in`,
  `OLD_COLORS_KEY`): files from before 10/20 spelled them so, the current ones and each
  saved theme's.
- **Settings take at once and are kept a moment after the last change** (`face/settings.lyra`,
  above). The file is read leniently — a
  setting missing or wrong keeps its default — and a theme named in it gives the colors a
  `colors` object does not. Programs asking the colors (OSC 10/11) are told the theme's.
- **A theme is every color Termina draws**, not only the grid's: the sections' input (the
  box, a block's prompt and command) and output, the input's text (where a program gave
  it no color: `Theme.for_input`, for the rows in view a block's input takes and the
  box's prompt), the tabs (a tab, under the pointer, shown —
  labelled in the text's color), and the command line's text, completion menu and chosen
  row. A theme names its text, background, cursor, selection, sections and ANSI sixteen;
  the rest is made from them (`settings.colors_of`), and a dark theme's sections lighten
  its background, a light one's darken it (`sections_of`). The settings edit each, and an
  edit makes the theme `Custom`. The chrome — tabs, menus, the Settings tab's controls — is
  `ui`'s, in a `ui` theme made from Termina's (`chrome_theme`).
- **The settings are markup** (`settings_page.lui`) whose every control is an event
  (`SettingsEvent`, carried out by `face/settings.lyra`'s `settings_asked`): the sliders'
  values (the size made whole points), and each color by its field's name
  (`SetColor("tab_hovered", …)`, `settings.color_named`/`with_color`) or its ANSI index
  (`with_ansi`, into an array of its own — the one a theme's colors hold is shared by
  every copy of them). An edited color makes the theme `Custom`. The color groups stand side
  by side as the width allows (a wrapping `Flex` of columns, each its heading over its
  swatches), wrapping to new lines in a narrow window.
- **The user's themes are saved in the settings file** (`Settings.themes`, `SavedTheme`):
  the colors under a name not Termina's own nor `Custom` (`can_save_as`; a saved one of
  that name replaced), listed after Termina's, deleted to `Custom` with the colors kept.
  A theme named in the file is looked for among them before Termina's. **A saved theme
  edited by hand is remembered** (`Settings.edited_from`, `edit_colors`, kept in the file
  while the theme is `Custom` and it is still saved): the Theme list shows it at its own place,
  marked `*` (`edited_name`), not as `Custom`, and Save (`can_save`) puts the colors back over
  it and makes it current again, unmarked. Choosing the marked entry keeps the edits: a select
  raises nothing for the option already chosen.
- **The Family list shows each family in itself** (`option_families`): each one's regular face
  loaded under `preview_name` — not the name the grid loads the whole family under, which would
  then count as loaded with no bold or italic — the first time the Settings tab opens
  (`settings_opened`).
- **Font families are found by file name** (`Mono`, `Code`, `Courier`, `Consol`, as
  capitalised; faces by `-Bold`/` Bold`/`Bold` suffixes), after the ones Termina knows by path
  (SF Mono, Menlo, DejaVu Sans Mono), whose files are not offered twice.
- **A color is one `u32`** (`DEFAULT`, a palette index, or RGB — `vt/style.lyra`): the
  screen records what the program asked for; the theme decides what it looks like.
- **Erases and scrolls fill with the pen's background** (xterm's BCE, which
  `TERM=xterm-256color` promises), and nothing else of the pen.
- **Bold is a face when the family has one, else drawn twice a pixel apart** — SF Mono is
  one variable font. Bold italic falls back to the italic face drawn bold.
- **Lines are separate arrays** (`blank_line`): rows are written in place, and two rows
  sharing one array show each other's text.
- **A cell is the font's advance wide** (`face.grid_of`, from `MeasureFont`'s metrics) and
  its size times the spacing tall, whole points.
- **At a prompt the command line is a box pinned to the window's foot**, as Warp has it: the
  shell's prompt (the `B` line's cells before the input column) on its first row, the
  editor from column 0 below, the completion menu opening upward (`Place.menu_above`, its
  foot `Place.lift` points over the text: just above the box). Both rows are set in
  `BOX_INSET` from the grid's sides, so the command wraps a few columns before the grid
  does. The grid draws only the lines above the prompt's, and the page counts the box's height so the
  last line rests on it at the bottom; the box is drawn at the view's foot
  (`origin.y + scroll + avail.y`), wherever the view is scrolled, and grid clicks stop at
  its top. **While a command sent from it runs, the box stays, greyed**, showing the
  command's first line — the keys are the program's, as in any terminal — but not on the
  alternate screen, where a full-screen program has the window. zsh's echo of the command still lands in
  the transcript as `prompt command`.
- **The command line is Termina's only between `B` and the next mark.** zsh and bash report
  `A`/`B`/`C`/`D` (OSC 133) through `shell/shell.lyra`'s hooks; at `B`, `Mode` becomes
  `AtPrompt(line, col)` and the editor is drawn from that cell, the shell's empty input
  hidden under it; any other mark is `Raw`. **A `B` where the command was just sent from is
  that prompt redrawn** (`Session.sent_from`) — bash's readline redraws its line on a paste
  of several lines, before `C` — and is not a new prompt. A shell without integration (a
  bash older than 4.4, another shell, a remote one over ssh) never reaches `AtPrompt` — a
  classic terminal.
- **bash is started `bash --rcfile <Termina's> -i`** — an rc file is read only by an
  interactive non-login shell — and the file reads what `bash -l` would (`/etc/profile`, then
  the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile`). `D`, OSC 7 and `A` come
  from the front of `PROMPT_COMMAND`, `B` is added to the end of `PS1` from its back, `C`
  from `PS0`, once for what was entered (a paste of several lines is several commands to
  bash). Each hook hands back the `$?` it found. Type-ahead is read at the end of
  `PROMPT_COMMAND` with `read -n 1 -t`, which turns canonical mode off while it waits (`-t 0`
  sees only whole lines), and arrives just before `B`.
- **Return sends the command as a bracketed paste, then `\r`**, so the shell's line editor
  takes several lines as one command and echoes it into the transcript where the editor
  was. The shell turns the mode on just *after* the `B` mark, once zsh's `zle-line-init` has
  read what was typed ahead — a check that answers `B` at once must wait for it
  (`check_shell`, `check_completion`), or its key is read as typed ahead.
- **The `A` mark is the start of `PS1` and `B` its end**, re-added at each prompt by a
  precmd hook that moves itself last (bash: the last of `PROMPT_COMMAND`), so a theme's own
  hook has built `PS1` first. `A` in `PS1`, not printed by the hook, falls where the prompt
  is drawn — after zsh's `PROMPT_SP`, partway along a line that output did not end — and
  carries that line and column (`PromptStart`). A theme that redraws the prompt
  asynchronously is untested.
- **The box shows the prompt from `A` to `B`**: up to `PROMPT_ROWS` lines (a prompt of
  several lines whole), the first from `A`'s column — output before it on that line stays
  in the grid, drawn up to there — and a right prompt (zsh's `RPROMPT`: what follows the
  input column on `B`'s line, the shell's own input being empty) right-aligned in the last
  row. An `A` repeated with its line (a redraw) does not clear `Session.sent_from`.
- **Tab completion is the shell's, run in the live shell.** Termina writes `caret\ntext` to
  the window's request file (`TERMINA_COMPLETE_FILE`) and sends `\e[9898~`, bound to a widget
  that reports matches as OSC 7770 (`b`, `m;prefix;insert;suffix;shown;description`
  percent-encoded, `e`) — none inserted, none listed. zsh's (bound once the user's `.zshrc`
  has chosen emacs or vi keys) loads the text into `BUFFER` and runs `complete-word` with
  `compadd` captured. bash's (`bind -x`, every keymap) splits the caret's command into
  words as readline does (`COMP_WORDBREAKS`: `--opt=val` completes `val`, `if=` kept as the
  prefix), and runs the command's compspec — loaded through bash-completion's `-D` loader
  when there is none yet — its `-F` function with `COMP_*` set and its other options
  through `compgen`, commands for the first word, file names failing all; a `compopt`
  stand-in notes `nospace`, `filenames` and the rest. **The function is given the word
  unquoted** (`COMP_WORDS`, `COMP_LINE` and `$2`): bash-completion quotes it again for
  `compgen`, counting on readline's dequoting too, which a widget does not have. bash's
  matches have no descriptions; file names are `%q`-quoted, a directory gets `/`. **Termina finds the word itself** (`editor.shell_word_at`, quotes and escapes
  included): inside quotes zsh measures positions with the quote removed. The answer for a
  line edited since the request is dropped. **Typing asks the shell again** (`refreshing`):
  its answer is the menu as given — a case-insensitive or substring `matcher-list`
  honoured — nothing put in; meanwhile the menu narrows locally (`CommandLine.narrow`, by
  start, case aside, kept when nothing starts so), keeping the choice chosen. It closes
  when the shell finds nothing, the word is typed in full, or the caret moves off. **A
  completion's `/` or space gives way** to the next key when that would double it or end
  the word (`suffix_left`): zsh's `AUTO_REMOVE_SLASH`. `compinit` is loaded only if the
  user's config has not, its dump in Termina's cache.
- **The command line is colored by its syntax** (`editor.kinds`, a small lexer that only
  ever chooses a color): commands, options, quoted text, variables, operators and comments,
  in the theme's ANSI green, cyan, yellow, magenta, blue and its faint grey. `$(…)` is
  lexed as a command line of its own.
- **A command the shell cannot run is red** — the shell's answer, not Termina's guess: each
  plain command word (`editor.command_words`: whole, no quoting, variable, `~` or glob) is
  asked of the live shell as Tab's completions are, through a request file of its own
  (`TERMINA_COMMANDS_FILE`) and the key `\e[9897~` — zsh's `whence`, bash's `type -t` —
  reported as OSC 7770 `c;<word>;<1|0>`, then `c`. **The asking is after every event**
  (`settle` → `Session.ask_commands`), not in `step`: typing writes nothing back, so no
  `step` follows it. One ask at a time (`CommandLine.asking`), the answers kept until a new
  prompt (`CommandLine.prompt_at` — a command may change what exists); a word not yet
  answered stays green. An ask the shell reads as typed ahead is dropped (`typeahead`), and
  the prompt's words stay green.
- **Ctrl+R searches the history** (`CommandLine.searching`): the editor's text is the query,
  the menu — the box's width — the history's commands with it in them, case aside, each once,
  the newest last and chosen; ↑/Ctrl+R older, ↓/Ctrl+S newer, Return or Tab puts one in,
  Escape or Ctrl+G puts back what was there. A bash compspec's `-C` command is run as
  readline runs it.
- **Keys typed while a command runs go to it; what it leaves unread is Termina's.** At each
  new line zsh's `zle-line-init` (Termina's, running the user's first) reads what is waiting
  — before zsh's own line editor would take it into a buffer hidden under Termina's — and
  reports it raw (OSC 7770 `t`). `term.typed_lines` makes lines of it; at the prompt the first
  line ended by Return runs, as in any terminal, the next at the next prompt, and the
  unended rest goes into the editor.
- **Editor edits build new arrays** (undo snapshots share buffers); typing joins one undo
  step until a word ends, rune deletes join, word and line deletes stand alone.
- **Gaps in Lyra or its bindings go in `../lyra/todo.md`**, as Sheliak's do.

## Plan

1. **M0 — a terminal (done 10/16)**: PTY, parser, monochrome grid, scrollback, keys, paste.
2. **M1 — a classic terminal (done 10/16)**: SGR colors and attributes, wide characters, the
   DEC private modes (alternate screen, cursor keys, autowrap, DECSCUSR, bracketed paste,
   mouse reporting, focus), device reports, selection and copy, Alt as Meta. vim, less and
   top run correctly (`vttest`'s `check_full_screen`).
3. **M2 — blocks (done 10/29, begun 10/19)**: the shell integration's marks (zsh's and bash's) — OSC
   133 (`A` prompt, `B` command, `C` output, `D;status` end) and OSC 7 (directory). Each
   command is a block, drawn as a card — its input and output in the theme's colors,
   padded, with room between cards — its duration and a failure's status at its right, a
   red bar down a failed one. A right click on it copies its command (past the prompt) or its
   output, whichever part is clicked; a press under the terminal's chord (or Block ▸ Select
   Block) selects the block whole, and a finished block's output — more than a line — folds from
   the ▾ chevron in the card's left margin or Block's Fold/Unfold, hiding the lines past its
   first (a ▸ and the count stand in for them). M2 done 10/29.
4. **M3 — the editor (begun 10/16, before M1 and the block cards)**: zsh's integration,
   then the command line as Termina's editor — multi-line, soft wrap, the mouse (click,
   drag, double-click a word, triple-click a line), word and line motions, undo, the
   clipboard, history from `~/.zsh_history`, Tab completion (zsh's own, in a menu); bash's
   integration and its completion, syntax coloring, Ctrl+R history search, prompts of
   several lines and right prompts in the box, the box kept, greyed, while a command runs
   (10/19); a command the shell cannot run in red (10/30).

Open work is in `todo.md`; finished work in `done.md`.
