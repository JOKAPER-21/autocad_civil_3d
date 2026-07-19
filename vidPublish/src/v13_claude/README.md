# VID Publish Pipeline — AutoCAD Civil 3D 2026

| File | Runs in | Purpose |
|---|---|---|
| `VidPublish.lsp` | AutoCAD | The tool. Adds command `VIDPUBLISH` (alias `PUBLISH`). |
| `VidPublish.dcl` | AutoCAD | Dialog layout (Yard list, Commands box, PDF checkbox). Must sit next to the .lsp. |
| `vid_publish_report.py` | Plain Python, outside AutoCAD | Reads the publish log and reports what's been published, what's missing, what's pending. |

---

## 1. Install

1. Copy `VidPublish.lsp` **and** `VidPublish.dcl` into the **same folder**
   on each user's machine (e.g. `C:\CAD-Tools\VidPublish\`). They must sit
   together — the LSP looks for the DCL next to itself automatically.
2. This copy of `VidPublish.lsp` is already configured with:

   ```lisp
   (setq *VP-ROOT-PATH* "\\\\Desktop-igi8ekn\\vid_20d\\share\\updated_projects_files\\section")
   ```

   which points to the UNC server path:
   `\\Desktop-igi8ekn\vid_20d\share\updated_projects_files\section`

   This is the **only line that should differ between users**. Anyone
   who reaches that same folder over the network (mapped drive, direct
   UNC path, etc.) can use this file as-is. If a particular machine
   needs a different path style to reach the same folder (e.g. a
   mapped drive letter instead of the UNC path), change just this one
   line in their copy:

   | Situation                 | Example value                                          |
   |----------------------------|---------------------------------------------------------|
   | Local/mapped drive         | `"J:\\VID_autocad_publish_test"`                        |
   | Mapped drive, diff letter  | `"Z:\\VID_autocad_publish_test"`                        |
   | UNC server path (current)  | `"\\\\Desktop-igi8ekn\\vid_20d\\share\\updated_projects_files\\section"` |

   **Important:** every backslash in an AutoLISP string must be doubled
   (`\\`). A UNC path needs **four** backslashes at the very start
   (`\\\\Desktop-igi8ekn...`) because the leading `\\server` and every
   folder separator each get doubled.

3. In AutoCAD Civil 3D 2026: type `APPLOAD`, browse to `VidPublish.lsp`,
   click **Load**. (Or drag-and-drop the `.lsp` file onto the AutoCAD
   window.)
4. To auto-load every session, add it to the **Startup Suite** in the same
   APPLOAD dialog.

## 2. Use it

1. Keep open the drawing you want to publish.
2. Type `VIDPUBLISH` (or the shorter alias `PUBLISH`).
3. A dialog appears with:
   - **Yard** (boxed section) — the yard list, organized by segment.
     Each segment name (`MEJ_TEN`, `TEN_TCN`, `TEN_TSI`, `NLL_TN`,
     `MDU_NLL`, `VPT_SNKL`, `SNKL_EDP`, `EDP_QLN`) appears as a plain
     header row, with that segment's yards indented underneath — one
     scrollable list, visually grouped, no extra picker step. Header
     rows aren't real yards: clicking or arrowing onto one
     automatically jumps to the nearest yard row instead. **The list
     auto-selects a yard based on the current drawing's filename**, if
     it can confidently tell which one you mean — see
     [section 3d](#3d-about-yard-auto-detection-from-filename). The line
     underneath the list updates live to show exactly where the
     selected yard will publish to, and says `Target [auto]:` instead
     of `Target:` when the current selection came from auto-detection.
     You can freely change the selection before clicking OK either way.
     **Pressing Enter accepts the dialog the same as clicking OK** (OK is
     the dialog's default button — standard Windows-dialog behavior,
     triggered from any control).
   - **Publish Options** (boxed section):
     - **Commands** — a free-text box. Whatever you type here gets
       written into the drawing's **DWGPROPS → Comments** field before
       the file is saved/published. Leave it blank to skip.
     - **Generate PDF** — checkbox, ticked by default.
     - **New Version** — checkbox, unticked by default. See
       [section 3c](#3c-about-the-new-version-checkbox) for full details.
4. Click **OK** (or press Enter).

### What happens on OK

1. The drawing is **saved** (`QSAVE`) — clean first save, before anything
   is modified.
2. If you typed anything in **Commands**, it's written into the drawing's
   DWGPROPS Comments field (same field you'd see if you ran the AutoCAD
   `DWGPROPS` command and looked at the Summary tab — see note in
   section 3b).
3. The drawing is **saved again** (`QSAVE`) — this embeds the Comments
   you just wrote into the file, so the copy that goes to the server
   actually contains them. If you left the Commands box empty, this is
   still a clean, harmless no-op save.
4. A **subfolder is created** inside the selected yard's publish folder,
   named `<timestamp>_<currentfilename>`.
4. The DWG is copied into that subfolder with the **same** base name.
5. If **Generate PDF** is checked, AutoCAD looks at the drawing's
   layout tabs. If there is **exactly one** paper-space layout besides
   Model, that layout is plotted to PDF into the **same subfolder**,
   with the same base name, using **whatever plot device and settings
   that layout already has configured** — nothing about the layout's
   existing setup (plotter, paper size, plot style table, plot area) is
   changed; only the output is redirected to a PDF file instead of a
   printer. If unchecked, the subfolder is still created — it just
   won't contain a PDF.
   - If the layout has **no plot device assigned at all**, PDF is
     **skipped with a warning** rather than forcing any device onto
     the layout. The DWG still publishes normally.
   - If the drawing has **zero or two-or-more** paper-space layouts
     (besides Model), PDF is **skipped with a warning** — VIDPUBLISH
     won't guess which layout you meant. The DWG still publishes
     normally either way.
   - Your drawing's open tab doesn't matter — VIDPUBLISH finds and
     switches to the correct layout itself, plots it, then switches
     back to whatever tab you had open before running the command.
6. **If New Version is checked**, the (still current-named) DWG and PDF
   are ALSO copied into a new server-side version folder — see
   [section 3c](#3c-about-the-new-version-checkbox). This still happens
   under the **current/old** filename.
7. **Only now, with everything already on the server**, if New Version
   is checked, the local drawing is renamed on disk to bump its own
   version number (e.g. `..._v02.dwg` → `..._v03.dwg`, or `....dwg` →
   `..._v01.dwg` if it had no version yet) — see
   [section 3c](#3c-about-the-new-version-checkbox). If this rename
   fails for any reason, everything published above is unaffected —
   you just keep working in the original filename, with a warning.
8. One line is appended to `<root>\publish_log.csv`.

### Example result

Drawing `delete-this.dwg`, published to yard `VVR_viravanallur`, with PDF
checked and New Version **unchecked**, at 2026-06-21 09:29:03:

```
\\Desktop-igi8ekn\vid_20d\share\updated_projects_files\section\w1\TEN_TSI\dwg\yard\yd_VVR_viravanallur\publish\
  20260621_092903_delete-this\
    20260621_092903_delete-this.dwg
    20260621_092903_delete-this.pdf
```

If PDF is unchecked, the same subfolder is created but only contains the
`.dwg`. See section 3c below for what changes when New Version is
checked too.

### Error handling

- **Drawing never saved**: you're told to save it with a real filename
  first — there's nothing on disk yet to copy.
- **Target folder can't be created** (server not connected, wrong root
  path for that machine, etc.): you get an error naming the exact path it
  tried. Almost always a root-path/drive issue on that machine, not a bug.
- **Drawing has 0 or 2+ paper-space layouts besides Model**: PDF is
  skipped with a warning telling you how many layouts it found. The DWG
  still publishes normally. This is intentional — VIDPUBLISH only auto-
  plots when there's exactly one unambiguous layout to plot.
- **PDF plot fails** (one layout found, but the plot itself errors): the
  DWG still publishes successfully; you get a warning, and the log
  records `pdfresult = failed` for that entry so it shows up in the
  Python report too.

## 3a. About the PDF plot method (fixed)

An earlier version of this tool drove PDF plotting through the
command-line `-PLOT` sequence, answering each AutoCAD prompt in a fixed
order. That approach is fragile: the exact number and order of prompts
shifts depending on whether the active layout already has a plot device
assigned, which produced errors like `Unknown command "Y"` once the
script's canned answers landed on the wrong prompt.

The tool now drives plotting through AutoCAD's documented ActiveX
`Plot.PlotToFile` method instead, which has no prompts to desync from —
it sets the output file directly and returns a clear success/failure
result. This is the same mechanism Autodesk's own examples use for
silent/scripted plotting, and it requires `BACKGROUNDPLOT` to be `0`
during the call (the tool sets this automatically and restores your
original setting afterward) so the plot finishes before the file is
checked.

**Which layout gets plotted, and which plot device is used:** VIDPUBLISH
looks at the drawing's layout tabs, ignoring "Model". If there's exactly
one other layout, that's the one plotted — it switches to that layout
internally (regardless of which tab you had open) and plots using
**whatever plot device and page setup that layout already has** —
nothing is forced or changed. If that layout has no device assigned at
all, the PDF is skipped with a warning rather than guessing one. After
plotting, VIDPUBLISH switches back to whatever tab you originally had
open so your view doesn't change. If there's more than one layout (or
none), it skips the PDF rather than guess which one you meant.

## 3b. About the DWGPROPS command

AutoCAD's built-in `DWGPROPS` command only opens the Drawing Properties
**dialog box** — there's no way to script text into that dialog's
Comments field without it popping up and waiting for clicks. So
`VidPublish.lsp` writes directly to the drawing's underlying
**SummaryInfo** object instead, which is the exact same data DWGPROPS
reads and writes. The result is identical to typing the text into
DWGPROPS → Summary tab → Comments yourself, just done silently with no
dialog appearing. If you open `DWGPROPS` afterward, you'll see your
Commands text sitting right there in the Comments field.

## 3c. About the "New Version" checkbox

This does two **independent** things, both triggered by one checkbox —
and the **order matters**: everything that needs to reach the server
happens FIRST using the drawing's current name, and the local rename
happens LAST, only after the server-side work is done.

### Order of operations when "New Version" is checked

1. Drawing is saved (`QSAVE`) under its **current** name, as always.
2. The normal timestamped publish happens — DWG copied to
   `publish\<timestamp>_<currentname>\`, PDF generated into the same
   subfolder if requested — all using the **current/old** filename.
3. A new **server-side version folder** is created and the (still
   old-named) DWG + PDF are copied into it — see part 2 below.
4. **Only now**, with everything already safely on the server, is the
   local drawing file **renamed on disk** to bump its own version — see
   part 1 below.

This ordering means that if the rename step ever fails for some reason
(permissions, file locked, etc.), nothing that already reached the
server is affected — you just keep working in the original filename
locally, with a warning, while the publish itself completed normally.

### 1. Bumps the drawing's own filename version (last step)

Expected filename pattern:

```
yd_<yardCode>_<yardName>[_v<NN>][_<command>]
```

The `_v<NN>` version tag and any trailing `_<command>` suffix are both
optional. Examples:

| Current filename | After "New Version" |
|---|---|
| `yd_GDN_gangaikondan_v01_ROR.dwg` | `yd_GDN_gangaikondan_v02_ROR.dwg` |
| `yd_NRK_naraikkinar_v02.dwg` | `yd_NRK_naraikkinar_v03.dwg` |
| `yd_KARK_karraikkurichichi_v04.dwg` | `yd_KARK_karraikkurichichi_v05.dwg` |
| `yd_NRK_naraikkinar.dwg` (no version yet) | `yd_NRK_naraikkinar_v01.dwg` |

The currently open drawing is genuinely **renamed on disk** (via
`SaveAs` to the new name, then the old file is removed) — you keep
working in the new, higher-versioned file from that point on, in the
same AutoCAD session. This happens **after** everything below has
already been copied to the server.

### 2. Creates a new server-side version folder (before the rename)

This is tracked **completely independently** from the filename version
above — it looks at the yard's folder structure on the server, not at
the file's own name. It finds the highest existing `vNN` folder sitting
**next to** (a sibling of) that yard's `publish` folder, and creates the
next one up. The DWG and PDF copied in here use the file's name **at
the time of copying** — i.e. the OLD/pre-bump name, since the rename
hasn't happened yet at this point:

```
<root>\...\yd_KTHY_kalthurutty\
  publish\           <- normal timestamped publishes go here, always
  v05\                <- already existed
  v06\                <- NEW, created this run (v05 was the highest found)
    yd_KTHY_kalthurutty_v02.dwg   <- OLD/pre-bump name (no subfolder)
    yd_KTHY_kalthurutty_v02.pdf   <- the PDF, if one was generated
```

(In this example the file becomes `_v03` locally afterward — but the
copy already sitting in `v06` keeps the `_v02` name it had at copy
time. The CSV log's `filename`/`srcpath` columns also reflect this same
old/pre-bump name, since they're written before the rename too —
`newfilever` is where you find what it became.)

Because the two version numbers come from different places, **they
will often not match** — e.g. the file becomes `_v03` while the new
server folder is `v06`. That's expected: one counts the file's own
version tag, the other counts existing version folders already on the
server for that yard.

The normal timestamped publish (section 2, steps 4–6 above) still
happens exactly as before, in addition to this — New Version doesn't
replace the regular publish, it adds the version-folder copy and the
filename rename on top of it.

If the version folder can't be created or copied into for some reason
(permissions, disconnected drive, etc.), you get a warning and the
normal publish + PDF are unaffected, and the local rename still happens
afterward regardless.

## 3d. About yard auto-detection from filename

When the dialog opens, VIDPUBLISH tries to guess which yard you mean
from the current drawing's filename, and pre-selects it in the list —
purely as a convenience. **You can always change the selection before
clicking OK**; nothing is locked in.

Three ways a filename can match, checked in this priority order:

| Tier | What it looks for | Example filename | Matches |
|---|---|---|---|
| 1 (highest) | Full code, exactly as in the list | `yd_TIP_tattapparai_v04` | `TIP_tattapparai` |
| 2 | Just the short code | `TIP` | `TIP_tattapparai` |
| 3 | Just the yard's name part | `yard_tattapparai` | `TIP_tattapparai` |

A higher tier always wins outright over a lower one. The match is
**bounded** — `TIP` matches `yd_TIP_v04` or `TIP-revised`, but won't
falsely match the `TIP` inside an unrelated word like `TIPTOP`. It's
also case-insensitive.

**If a filename could match more than one yard within the same tier**
(this can happen with the two duplicate-looking codes mentioned in
section 8 below, e.g. a filename containing just `EDN`, which fits both
`EDN_edapalayam` and `EDN_edaman`), VIDPUBLISH does **not** guess — it
leaves the list on its normal default (the first yard) rather than risk
picking the wrong one. A full code like `EDN_edaman` in the filename
disambiguates fine, since that's a tier-1 exact match.

When a yard IS auto-detected, the line under the list reads
`Target [auto]:  ...` instead of `Target:  ...`, so you can see at a
glance that it was a guess. The moment you click or arrow to a
different yard, that tag disappears — it only ever describes the
dialog's starting selection, never something that persists after you've
touched the list yourself.

## 4. Folder mapping (reference)

Both `VidPublish.lsp` and `vid_publish_report.py` contain an identical
70-entry table mapping each yard code to its segment folder (`w1\MEJ_TEN`,
`w4\EDP_QLN`, etc.). The target **publish folder** (before the timestamp
subfolder) is always:

```
<root>\<segment>\dwg\yard\yd_<code>\publish\
```

If a yard moves to a different segment, or a new yard is added, update
the table in **both** files — find a similar existing entry (e.g. search
`KTHY` in both files) and copy its pattern.

## 5. Run the report script (optional — no AutoCAD needed)

Since `ROOT_PATH` in the script is already set to the same root as the
LSP, you can just run it with no argument:

```bash
python vid_publish_report.py
```

or pass the path explicitly (useful if a particular machine reaches the
same folder via a different path style, e.g. a mapped drive):

```bash
python vid_publish_report.py "\\Desktop-igi8ekn\vid_20d\share\updated_projects_files\section"
python vid_publish_report.py "J:\VID_autocad_publish_test"
```

Useful flags:

```bash
python vid_publish_report.py --missing-only
python vid_publish_report.py --csv-out status.csv
python vid_publish_report.py --json-out status.json
```

The report now shows, per yard: publish count, last publish time/user,
whether the last DWG still exists on disk, whether the last PDF was
generated/exists (`OK` / `PLOT FAILED` / `not requested`), and the last
Commands text logged for that yard.

This script never touches AutoCAD or any DWG/PDF file — it only reads
`publish_log.csv` and checks whether the logged files still exist on
disk. Safe to run anytime, from anyone's PC.

## 6. publish_log.csv format (updated)

Each line now has **12 comma-separated fields**:

```
timestamp,computer_name,code,filename,srcpath,destdwg,pdfresult,destpdf,commands,newversion,newfilever,verfolder
```

| Field | Meaning |
|---|---|
| `timestamp` | `YYYYMMDD_HHMMSS` of the publish |
| `computer_name` | The publisher's **PC system name** (Windows `%COMPUTERNAME%` / hostname) — e.g. `DESKTOP-7F3K2QX`. This is the machine's name, not the person's Windows login name. |
| `code` | Selected yard code, e.g. `VVR_viravanallur` |
| `filename` | Drawing's file name at publish time, with extension — already reflects the bumped version name if New Version was checked |
| `srcpath` | Full path of the open/saved drawing at publish time — already the renamed path if New Version was checked |
| `destdwg` | Full path of the copied DWG inside the timestamp subfolder |
| `pdfresult` | `ok`, `failed`, or `skipped` |
| `destpdf` | Full path the PDF is (or would be) at — only meaningful when `pdfresult = ok` |
| `commands` | The text from the Commands box (commas/newlines stripped, kept as one field) |
| `newversion` | `yes` or `no` — whether "New Version" was checked for this publish |
| `newfilever` | The drawing's own bumped version number (e.g. `3` for `_v03`), or blank if `newversion` was `no` |
| `verfolder` | The server-side version folder name created (e.g. `v06`), or blank if `newversion` was `no`. Tracked independently of `newfilever` — they often differ; see section 3c. |

## 7. About mixed server/local paths

Same approach as before — each user edits **only one line**
(`*VP-ROOT-PATH*`) in their own copy of the LSP. All path-building in
both the LSP and the Python script normalizes slash direction and
collapses accidental double-separators, so a root typed with a trailing
slash or a stray forward slash won't break folder creation, the file
copy, or the PDF plot.

## 8. Known formatting note in your yard list

Two display codes repeat in the source list (`KARK_...` appears twice
with slightly different spellings, and `EDN_...` appears twice for two
different towns — `edapalayam` and `edaman`). Both are kept as separate
dropdown entries since they map to two different real folders; check the
live preview line under the list before clicking OK if that's ever
ambiguous.
