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
2. Open `VidPublish.lsp` and find this line near the top:

   ```lisp
   (setq *VP-ROOT-PATH* "J:\\VID_autocad_publish_test")
   ```

   This is the **only line that should differ between users**. Set it to
   whatever that user's drive/share actually is:

   | Situation                 | Example value                                          |
   |----------------------------|---------------------------------------------------------|
   | Local/mapped drive         | `"J:\\VID_autocad_publish_test"`                        |
   | Mapped drive, diff letter  | `"Z:\\VID_autocad_publish_test"`                        |
   | UNC server path            | `"\\\\FILESERVER\\Projects\\VID_autocad_publish_test"`  |

   **Important:** every backslash in an AutoLISP string must be doubled
   (`\\`). A UNC path needs **four** backslashes at the very start
   (`\\\\FILESERVER...`) because the leading `\\server` and every folder
   separator each get doubled.

3. In AutoCAD Civil 3D 2026: type `APPLOAD`, browse to `VidPublish.lsp`,
   click **Load**. (Or drag-and-drop the `.lsp` file onto the AutoCAD
   window.)
4. To auto-load every session, add it to the **Startup Suite** in the same
   APPLOAD dialog.

## 2. Use it

1. Keep open the drawing you want to publish.
2. Type `VIDPUBLISH` (or the shorter alias `PUBLISH`).
3. A dialog appears with:
   - **Yard Names** — a list. Click a yard, or arrow-key to it. The line
     underneath updates live to show exactly where it will publish to.
     **Pressing Enter accepts the dialog the same as clicking OK** (OK is
     the dialog's default button, which is standard Windows-dialog
     behavior — Enter always triggers it, from any control).
   - **Commands** — a free-text box. Whatever you type here gets written
     into the drawing's **DWGPROPS → Comments** field before the file is
     saved/published. Leave it blank to skip.
   - **Generate PDF** — checkbox, ticked by default.
4. Click **OK** (or press Enter).

### What happens on OK

1. If you typed anything in **Commands**, it's written to the drawing's
   DWGPROPS Comments field (same field you'd see if you ran the AutoCAD
   `DWGPROPS` command and looked at the Summary tab — see note below).
2. The drawing is **saved** (`QSAVE`) — it keeps its original name and
   stays open exactly as before; nothing about your session changes.
3. A **subfolder is created** inside the selected yard's publish folder,
   named `<timestamp>_<originalfilename>`.
4. The DWG is copied into that subfolder with the **same** base name.
5. If **Generate PDF** is checked, AutoCAD looks at the drawing's
   layout tabs. If there is **exactly one** paper-space layout besides
   Model, that layout is plotted to PDF using `DWG To PDF.pc3`, into
   the **same subfolder**, with the same base name. The layout's
   existing plot style table (CTB) is left exactly as-is — only the
   plot device is forced to `DWG To PDF.pc3`. If unchecked, the
   subfolder is still created — it just won't contain a PDF.
   - If the drawing has **zero or two-or-more** paper-space layouts
     (besides Model), PDF is **skipped with a warning** — VIDPUBLISH
     won't guess which layout you meant. The DWG still publishes
     normally either way.
   - Your drawing's open tab doesn't matter — VIDPUBLISH finds and
     switches to the correct layout itself, plots it, then switches
     back to whatever tab you had open before running the command.
6. One line is appended to `<root>\publish_log.csv`.

### Example result

Drawing `delete-this.dwg`, published to yard `VVR_viravanallur`, with PDF
checked, at 2026-06-21 09:29:03:

```
J:\VID_autocad_publish_test\w1\TEN_TSI\dwg\yard\yd_VVR_viravanallur\publish\
  20260621_092903_delete-this\
    20260621_092903_delete-this.dwg
    20260621_092903_delete-this.pdf
```

If PDF is unchecked, the same subfolder is created but only contains the
`.dwg`.

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

**Which layout gets plotted:** VIDPUBLISH looks at the drawing's layout
tabs, ignoring "Model". If there's exactly one other layout, that's the
one plotted — it switches to that layout internally (regardless of which
tab you had open), forces the plot device to `DWG To PDF.pc3`, and
leaves the plot style table (CTB) exactly as that layout already has it.
After plotting, it switches back to whatever tab you originally had open
so your view doesn't change. If there's more than one layout (or none),
it skips the PDF rather than guess which one you meant.

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

```bash
python vid_publish_report.py "J:\VID_autocad_publish_test"
```

or for a UNC root:

```bash
python vid_publish_report.py "\\FILESERVER\Projects\VID_autocad_publish_test"
```

Useful flags:

```bash
python vid_publish_report.py "J:\VID_autocad_publish_test" --missing-only
python vid_publish_report.py "J:\VID_autocad_publish_test" --csv-out status.csv
python vid_publish_report.py "J:\VID_autocad_publish_test" --json-out status.json
```

The report now shows, per yard: publish count, last publish time/user,
whether the last DWG still exists on disk, whether the last PDF was
generated/exists (`OK` / `PLOT FAILED` / `not requested`), and the last
Commands text logged for that yard.

This script never touches AutoCAD or any DWG/PDF file — it only reads
`publish_log.csv` and checks whether the logged files still exist on
disk. Safe to run anytime, from anyone's PC.

## 6. publish_log.csv format (updated)

Each line now has **9 comma-separated fields**:

```
timestamp,computer_name,code,filename,srcpath,destdwg,pdfresult,destpdf,commands
```

| Field | Meaning |
|---|---|
| `timestamp` | `YYYYMMDD_HHMMSS` of the publish |
| `computer_name` | The publisher's **PC system name** (Windows `%COMPUTERNAME%` / hostname) — e.g. `DESKTOP-7F3K2QX`. This is the machine's name, not the person's Windows login name. |
| `code` | Selected yard code, e.g. `VVR_viravanallur` |
| `filename` | Original drawing's file name (with extension) |
| `srcpath` | Full path of the open/saved drawing at publish time |
| `destdwg` | Full path of the copied DWG inside the timestamp subfolder |
| `pdfresult` | `ok`, `failed`, or `skipped` |
| `destpdf` | Full path the PDF is (or would be) at — only meaningful when `pdfresult = ok` |
| `commands` | The text from the Commands box (commas/newlines stripped, kept as one field) |

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
