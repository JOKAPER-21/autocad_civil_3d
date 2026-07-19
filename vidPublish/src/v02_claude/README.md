# Yard Publish Pipeline — AutoCAD Civil 3D 2026

Three files:

| File | Runs in | Purpose |
|---|---|---|
| `YardPublish.lsp` | AutoCAD | The tool. Adds command `YARDPUBLISH` (alias `PUBLISH`). |
| `YardPublish.dcl` | AutoCAD | Dialog box layout for the dropdown. Must sit next to the .lsp. |
| `yard_publish_report.py` | Plain Python, outside AutoCAD | Reads the publish log and reports what's been published, what's missing, and what's never been touched. |

---

## 1. Install the LSP

1. Copy `YardPublish.lsp` **and** `YardPublish.dcl` into the **same folder**
   on each user's machine (e.g. `C:\CAD-Tools\YardPublish\`). They must sit
   together — the LSP looks for the DCL next to itself automatically.
2. Open `YardPublish.lsp` and find this line near the top:

   ```lisp
   (setq *YP-ROOT-PATH* "J:\\VID_autocad_publish_test")
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

3. In AutoCAD Civil 3D 2026: type `APPLOAD`, browse to `YardPublish.lsp`,
   click **Load**. (Or drag-and-drop the `.lsp` file onto the AutoCAD
   window.)
4. To auto-load every session, add it to the **Startup Suite** in the same
   APPLOAD dialog.

## 2. Use it

1. Keep open the drawing you want to publish.
2. Type `YARDPUBLISH` (or the shorter alias `PUBLISH`).
3. A dialog lists all yard names. Pick one — the line underneath the list
   updates to show exactly where it will go.
4. Click **OK**.

The tool then:
- Saves the current drawing (`QSAVE`) — it keeps its original name and
  stays open exactly as before.
- Creates the target `publish` folder if it doesn't exist yet.
- Copies the saved file into that folder as:
  `YYYYMMDD_HHMMSS_<originalfilename>.<ext>`
- Appends one line to `<root>\publish_log.csv` recording who published
  what, when, from where, and to where.

If the drawing has never been saved, you're told to save it with a real
filename first — there's nothing on disk yet to copy.

If the target folder can't be created (server not connected, wrong root
path for that machine, etc.), you get an error naming the exact path it
tried. That's almost always a root-path/drive issue on that machine, not
a bug in the tool.

## 3. Folder mapping (reference)

Both `YardPublish.lsp` and `yard_publish_report.py` contain an identical
70-entry table mapping each yard code to its segment folder (`w1\MEJ_TEN`,
`w4\EDP_QLN`, etc.), built from your full yard list. The target for any
code is always:

```
<root>\<segment>\dwg\yard\yd_<code>\publish\
```

If a yard moves to a different segment, or a new yard is added, update
the table in **both** files — find a similar existing entry (e.g. search
`KTHY` in both files) and copy its pattern.

## 4. Run the report script (optional — no AutoCAD needed)

```bash
python yard_publish_report.py "J:\VID_autocad_publish_test"
```

or for a UNC root:

```bash
python yard_publish_report.py "\\FILESERVER\Projects\VID_autocad_publish_test"
```

Useful flags:

```bash
python yard_publish_report.py "J:\VID_autocad_publish_test" --missing-only
python yard_publish_report.py "J:\VID_autocad_publish_test" --csv-out status.csv
python yard_publish_report.py "J:\VID_autocad_publish_test" --json-out status.json
```

This script never touches AutoCAD or any DWG file — it only reads
`publish_log.csv` and checks whether the logged destination files still
exist on disk. Safe to run anytime, from anyone's PC.

## 5. About mixed server/local paths

This was built specifically for the situation where some people have the
project on a local/mapped drive and others on a UNC server share:

- Each user edits **only one line** (`*YP-ROOT-PATH*`) in their own copy
  of the LSP. The yard table and all logic underneath is identical for
  everyone.
- All path-building in both the LSP and the Python script normalizes
  slash direction and collapses accidental double-separators, so a root
  typed with a trailing slash or a stray forward slash won't break folder
  creation or the file copy.
- The log records the literal destination path each machine used, so the
  Python report can flag it if two people end up logging publishes to two
  different roots that were supposed to be the same shared folder (shows
  up as differing path styles in the report output).

## 6. Known formatting note in your yard list

Two display codes repeat in the source list you gave me (`KARK_...`
appears twice with slightly different spellings, and `EDN_...` appears
twice for two different towns — `edapalayam` and `edaman`). Both are
kept as separate dropdown entries since they map to two different real
folders; just be aware the dropdown will show two entries that start
with `EDN_` and two starting `KARK`-ish — check the live preview line
under the list before clicking OK if that's ever ambiguous.
