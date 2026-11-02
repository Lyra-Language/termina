# Termina — open work

Open work for Termina only (compiler and binding gaps it finds go in `../lyra/todo.md`). The
milestones are in `CLAUDE.md` § Plan; finished items move to `done.md`.

## The command line (M3)

## M1 — a classic terminal

## Hyperlinks (M1)
- [x] RawInput cursor: added `cursor` field to RawInput, `cursor_at` method, `PointerMoved` → `platform.set_cursor`
- [x] Warp-style hover: light blue (#64B5F6) text + solid underline for hyperlink cells under pointer
- [x] Cursor changes to Hand shape when over a hyperlink
- [x] Fix crash on echo'd URLs: `marks_of` masked `HYPERLINK` but not `DETECTED` (bit 18 → marks index 64 → oob in `combining`)
- [x] Fix Hand cursor alignment: `is_link` used `t.size` (window) for frame layout instead of painter area (`h - 2*PAD`), causing row y positions to misalign
## Settings

## Found along the way
