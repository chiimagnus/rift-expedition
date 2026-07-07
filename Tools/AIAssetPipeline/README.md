# AI Asset Pipeline (P2 sprite generation helper scripts)

These are the Python scripts used to post-process the AI-generated (Notion AI `images.generate`)
character sprite strips into game-ready animation sheets for the P2 tasks (P2-T2 warrior, P2-T3
archer, etc). They were written as a **sandbox fallback** because this environment has no
Swift toolchain / `$imagegen` / network access. The official acceptance path is still the real
`RiftValidator` / Swift asset pipeline described in `plan-p2.md` — treat these scripts as a
convenience for local iteration, not a replacement for the real validator.

## Requirements

- Python 3 with Pillow and numpy (pure-numpy only; no scipy, since the sandbox has no network
  access to install extra packages).

## Scripts

### `detect_lines.py`

Detects the black grid divider lines drawn by the AI inside a generated sprite strip (per our
prompt convention, every strip is generated with an explicit black grid line between cells plus
a black border). It scans for near-pure-black rows/columns and reports the pixel centers of each
grid line, so you know the exact cell boundaries before slicing — rather than trusting the
requested layout (e.g. "12 cells") blindly, since the model doesn't always follow the exact
row/column arrangement.

```bash
python3 detect_lines.py <path-to-strip.png>
```

Prints the detected column line centers and row line centers.

### `build_final_sheet.py`

Takes one generated strip per direction (down/left/right/up), slices each into its 12 cells using
the grid-line boundaries from `detect_lines.py`, chroma-keys out the background (green `#00ff00`
by default, magenta `#ff00ff` for subjects that contain green tones), trims/centers each pose into
a fixed 96x96 frame, and composites everything into the final `*_anim.png` animation sheet
(4 directions x 12 poses x 96px = 1152x384) expected by `AssetValidation.swift`.

Important: the chroma-key sample points are taken from the **interior corners of each individual
cell**, not the corners of the whole image — once the strip has a black grid line/border, the
outer image corners are black, not the background color.

```bash
python3 build_final_sheet.py \
  --down down.png --left left.png --right right.png --up up.png \
  --key 00ff00 \
  --out actor_archer_anim.png
```

### `validate_assets.py`

A lightweight local check (not a replacement for `RiftValidator`) that verifies:

- final sheet dimensions (1152x384) and per-frame size (96x96)
- `assets-manifest.json` / `*-animations.json` entries reference files that exist and match the
  expected `allowedLicenses` / banned id fragments / animation frame layout from
  `AssetValidation.swift`

```bash
python3 validate_assets.py
```

## Typical flow per character

1. Generate the down/front-facing 12-pose strip via `images.generate` (see prompts in the
   "美术素材提示词大全" Notion page).
2. Pass that strip back in as a reference image and generate left/right/up strips.
3. Run `detect_lines.py` on each strip to confirm a clean 12-cell grid.
4. Run `build_final_sheet.py` to slice, chroma-key, and composite the 4 strips into the final
   animation sheet.
5. Update `assets-manifest.json` / `*-animations.json` to point at the new sheet.
6. Run `validate_assets.py` as a local sanity check before considering the task done.
