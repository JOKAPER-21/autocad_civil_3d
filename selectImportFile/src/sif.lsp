;;; ==================================================================================================
;;;  File Name   : SIF.lsp
;;;  Title       : Select & Import Files
;;;  Command     : SIF
;;;
;;;  Author      : Rishi
;;;  Creator     : Rishi
;;;  Version     : 01
;;;  Created     : 24-Jul-2026
;;;  Last Update : 24-Jul-2026
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  DESCRIPTION
;;; --------------------------------------------------------------------------------------------------
;;;  SIF (Select & Import Files) is an AutoLISP utility that imports one or more
;;;  DWG/DXF files into the active drawing using a single native Windows file
;;;  selection dialog with multi-select support.
;;;
;;;  Each imported file is:
;;;    • Inserted as a block
;;;    • Automatically exploded (supports nested blocks)
;;;    • Moved onto its own uniquely generated layer
;;;    • Cleaned up through an automatic drawing purge after import
;;;
;;;  The utility is designed for quickly consolidating multiple CAD drawings
;;;  while preserving clear layer organization and minimizing drawing clutter.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  FEATURES
;;; --------------------------------------------------------------------------------------------------
;;;  ✔ Native Windows multi-file selection dialog
;;;      - Ctrl + Click or Shift + Click to select multiple files
;;;      - Supports both DWG and DXF files
;;;      - "All Files" option allows mixed selections
;;;
;;;  ✔ Automatic layer creation
;;;      Layer format:
;;;          <Sequence>_<Filename>_<CreationDate>
;;;
;;;      Example:
;;;          1_StationA_30.11.2026
;;;          2_Culvert_06.03.2025
;;;
;;;  ✔ Import workflow
;;;      • Inserts each drawing as a block reference
;;;      • Automatically explodes imported blocks
;;;      • Supports nested block explosion
;;;      • Forces every imported entity onto its generated layer
;;;      • Ignores original source drawing layers
;;;
;;;  ✔ Automatic numbering
;;;      • Detects existing numbered layers
;;;      • Continues numbering across multiple executions
;;;
;;;  ✔ Drawing cleanup
;;;      Automatically performs PURGE equivalent to:
;;;          • All purgeable items
;;;          • Zero-length geometry
;;;          • Empty text objects
;;;          • Orphaned data
;;;
;;;  ✔ Error handling
;;;      • Processes files independently
;;;      • Skips failed imports
;;;      • Continues importing remaining files
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  WORKFLOW
;;; --------------------------------------------------------------------------------------------------
;;;      1. Execute SIF
;;;      2. Select one or more DWG/DXF files
;;;      3. Layer is created automatically
;;;      4. Drawing is inserted
;;;      5. Block is exploded
;;;      6. Imported entities moved to generated layer
;;;      7. Repeat for remaining files
;;;      8. Perform automatic PURGE
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  REQUIREMENTS
;;; --------------------------------------------------------------------------------------------------
;;;      • AutoCAD / AutoCAD Civil 3D
;;;      • Visual LISP (vl-load-com)
;;;      • Windows PowerShell
;;;      • Windows Script Host (WScript.Shell)
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  DEPENDENCIES
;;; --------------------------------------------------------------------------------------------------
;;;      None
;;;
;;;      PowerShell is executed inline.
;;;      No external .ps1 files are created or required.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  LOAD
;;; --------------------------------------------------------------------------------------------------
;;;      APPLOAD → SIF.lsp
;;;      or Drag & Drop SIF.lsp into AutoCAD
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  RUN
;;; --------------------------------------------------------------------------------------------------
;;;      Command:
;;;          SIF
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  NOTES
;;; --------------------------------------------------------------------------------------------------
;;;      • Supports recursive block explosion using SIF-EXPLODE-DEPTH.
;;;      • Increase SIF-EXPLODE-DEPTH if source drawings contain deeper
;;;        nested block structures.
;;;      • Invalid characters in layer names are automatically replaced.
;;;      • If a file creation date cannot be read, the current drawing date
;;;        is used as a fallback.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  COPYRIGHT
;;; --------------------------------------------------------------------------------------------------
;;;      © 2026 Rishi. All Rights Reserved.
;;;      License: Internal Use
;;; ==================================================================================================

(vl-load-com)

(setq SIF-EXPLODE-DEPTH 2)   ; how many times to explode (handles one level of nested blocks)

;; ---------- split a string on a delimiter ----------
(defun SIF:StrSplit (str delim / pos result)
  (setq result '())
  (while (setq pos (vl-string-search delim str))
    (setq result (append result (list (substr str 1 pos))))
    (setq str (substr str (+ pos 1 (strlen delim))))
  )
  (append result (list str))
)

;; ---------- replace ALL occurrences of a char ----------
(defun SIF:ReplaceAll (old new str / p out)
  (setq out "")
  (while (setq p (vl-string-search old str))
    (setq out (strcat out (substr str 1 p) new))
    (setq str (substr str (+ p 1 (strlen old))))
  )
  (strcat out str)
)

;; ---------- strip characters AutoCAD layer names reject ----------
(defun SIF:CleanLayerName (name / badchars ch result)
  (setq badchars (list "<" ">" "/" "\\" "\"" ":" ";" "?" "*" "|" "," "=" " "))
  (setq result name)
  (foreach ch badchars
    (setq result (SIF:ReplaceAll ch "_" result))
  )
  result
)

;; ---------- turn a raw COM date string into dd.mm.yyyy ----------
(defun SIF:FormatDate (dstr / datepart parts mm dd yyyy)
  (setq datepart (car (SIF:StrSplit dstr " ")))
  (setq parts (SIF:StrSplit datepart "/"))
  (if (/= (length parts) 3)
    (error "SIF: unrecognised date format")
  )
  (setq mm (nth 0 parts) dd (nth 1 parts) yyyy (nth 2 parts))
  (if (= (strlen mm) 1) (setq mm (strcat "0" mm)))
  (if (= (strlen dd) 1) (setq dd (strcat "0" dd)))
  (strcat dd "." mm "." yyyy)
)

;; ---------- safely get "creation date" of a file, never crashes ----------
(defun SIF:GetCreateDate (filePath / fso fileObj raw res out)
  (setq out nil)
  (setq res
    (vl-catch-all-apply
      '(lambda ()
         (setq fso (vlax-create-object "Scripting.FileSystemObject"))
         (setq fileObj (vlax-invoke-method fso 'GetFile filePath))
         (setq raw (vl-princ-to-string (vlax-get-property fileObj 'DateCreated)))
         (vlax-release-object fileObj)
         (vlax-release-object fso)
         (SIF:FormatDate raw)
       )
    )
  )
  (if (and res (not (vl-catch-all-error-p res)) (= (type res) 'STR))
    (setq out res)
  )
  (if (not out)
    (setq out (menucmd "M=$(edtime,$(getvar,date),DD.MO.YYYY)"))
  )
  out
)

;; ---------- TRUE multi-select dialog (Ctrl+Click) via inline PowerShell ----------
;; No separate .ps1 file is created or required - the whole command
;; is passed inline to powershell.exe, run hidden, and we WAIT for it.
(defun SIF:PickFilesMulti ( / wsh tempFile cmd f line result)
  (setq tempFile (strcat (getenv "TEMP") "\\sif_pick_" (rtos (getvar "CDATE") 2 6) ".txt"))
  (setq cmd
    (strcat
      "powershell.exe -NoProfile -WindowStyle Hidden -Command "
      "\"Add-Type -AssemblyName System.Windows.Forms; "
      "$f = New-Object System.Windows.Forms.OpenFileDialog; "
      "$f.Filter = 'CAD Files (*.dxf;*.dwg)|*.dxf;*.dwg|All Files (*.*)|*.*'; "
      "$f.Multiselect = $true; "
      "$f.Title = 'SIF - Select DWG/DXF files (Ctrl+Click for multiple)'; "
      "if ($f.ShowDialog() -eq 'OK') { $f.FileNames | Out-File -FilePath \\\"" tempFile "\\\" -Encoding UTF8 } "
      "else { '' | Out-File -FilePath \\\"" tempFile "\\\" -Encoding UTF8 }\""
    )
  )
  (setq wsh (vlax-create-object "WScript.Shell"))
  (vlax-invoke-method wsh 'Run cmd 0 :vlax-true)  ; 0 = hidden window, wait until closed
  (vlax-release-object wsh)

  (setq result '())
  (if (findfile tempFile)
    (progn
      (setq f (open tempFile "r"))
      (while (setq line (read-line f))
        (if (/= line "") (setq result (append result (list line))))
      )
      (close f)
      (vl-file-delete tempFile)
    )
  )
  result
)

;; ---------- check if a string is all digits ----------
(defun SIF:IsNumeric (str / i ok)
  (setq ok (> (strlen str) 0))
  (setq i 0)
  (while (and ok (< i (strlen str)))
    (if (not (wcmatch (substr str (1+ i) 1) "#"))
      (setq ok nil)
    )
    (setq i (1+ i))
  )
  ok
)

;; ---------- scan existing layers, return the next free sequence number ----------
;; Looks for layers already named like  "3_something_dd.mm.yyyy"
;; and returns (max found) + 1, so numbering continues across runs
;; instead of restarting at 1 every time.
(defun SIF:GetNextIndex ( / le lname us numPart n maxN)
  (setq maxN 0)
  (setq le (tblnext "LAYER" T))
  (while le
    (setq lname (cdr (assoc 2 le)))
    (setq us (vl-string-search "_" lname))
    (if us
      (progn
        (setq numPart (substr lname 1 us))
        (if (SIF:IsNumeric numPart)
          (progn
            (setq n (atoi numPart))
            (if (> n maxN) (setq maxN n))
          )
        )
      )
    )
    (setq le (tblnext "LAYER"))
  )
  (1+ maxN)
)

;; ---------- PURGE ALL: All items + Zero-length geometry + Orphaned data ----------
;; Mimics ticking "All items", "Zero-length geometry" and "Orphaned data" in the
;; Purge dialog and clicking "Purge All" repeatedly until the drawing is clean
;; (purging one thing - e.g. a block - can make another thing - e.g. a layer -
;; purgeable, so we loop a few passes, same as re-clicking Purge All).
(defun SIF:PurgeAll ( / pass)
  (princ "\n[SIF] Purging unused items (all items, zero-length geometry, orphaned data)...")
  (setq pass 1)
  (while (<= pass 3)                      ; a few passes = same effect as repeatedly hitting "Purge All"
    (vl-catch-all-apply
      '(lambda () (command "_.-PURGE" "_A" "*" "_N"))       ; All named items, no per-item confirmation
    )
    (setq pass (1+ pass))
  )
  ;; Zero-length geometry (lines/arcs/circles/plines with zero length, empty text)
  (vl-catch-all-apply
    '(lambda () (command "_.-PURGE" "_Z" "*" "_N"))
  )
  ;; Orphaned data (obsolete/unreferenced data left in the drawing database)
  (vl-catch-all-apply
    '(lambda () (command "_.-PURGE" "_O" "*" "_N"))
  )
  (princ "\n[SIF] Purge complete.")
  (princ)
)

;; ---------- explode every block reference added after a marker ----------
;; Unlike EXPLODE "_L" (which only ever touches the single most-recently
;; created entity and errors out with "not able to be exploded" the moment
;; that entity happens to be a plain line/arc/etc.), this walks every
;; entity added since afterEnt, collects the ones that are still INSERTs
;; (block references - i.e. nested blocks), and explodes all of them in
;; one real selection set. Repeats up to SIF-EXPLODE-DEPTH passes, or
;; stops early as soon as no block references remain.
(defun SIF:ExplodeNew (afterEnt / e ed etype ss pass foundBlock)
  (setq pass 0)
  (setq foundBlock T)
  (while (and foundBlock (< pass SIF-EXPLODE-DEPTH))
    (setq foundBlock nil)
    (setq ss (ssadd))
    (setq e (if afterEnt (entnext afterEnt) (entnext)))
    (while e
      (setq ed (entget e))
      (setq etype (cdr (assoc 0 ed)))
      (if (= etype "INSERT")
        (progn (setq ss (ssadd e ss)) (setq foundBlock T))
      )
      (setq e (entnext e))
    )
    (if foundBlock
      (vl-catch-all-apply '(lambda () (command "_.EXPLODE" ss "")))
    )
    (setq pass (1+ pass))
  )
)

;; ---------- force every entity added after a marker onto a layer ----------
(defun SIF:SetLayerFrom (afterEnt layerName / e ed pair)
  (setq e (if afterEnt (entnext afterEnt) (entnext)))
  (while e
    (setq ed (entget e))
    (setq pair (assoc 8 ed))
    (if pair
      (entmod (subst (cons 8 layerName) pair ed))
    )
    (setq e (entnext e))
  )
)

;; ---------- purge the drawing: all items + zero-length geometry + orphaned data ----------
;; Command-line equivalent of opening the PURGE dialog, ticking
;; "All items", ticking "Zero-length geometry" and "Orphaned data"
;; under Options, and clicking "Purge All".
;; Each pass is wrapped in vl-catch-all-apply so an unsupported
;; keyword on older AutoCAD versions never aborts the routine.
(defun SIF:PurgeAll ( / oldCmdEcho)
  (setq oldCmdEcho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (princ "\n[SIF] Purging drawing (all items)...")
  ;; "All items" ticked, wildcard = everything, N = no verification prompts.
  ;; Run twice: purging e.g. a block can free up a layer/linetype it used.
  (vl-catch-all-apply '(lambda () (command "_.-PURGE" "_All" "*" "_N")))
  (vl-catch-all-apply '(lambda () (command "_.-PURGE" "_All" "*" "_N")))
  (princ "\n[SIF] Purging zero-length geometry / empty text objects...")
  (vl-catch-all-apply '(lambda () (command "_.-PURGE" "_Zero" "_N")))
  (princ "\n[SIF] Purging orphaned data...")
  (vl-catch-all-apply '(lambda () (command "_.-PURGE" "_Orphaned" "_N")))
  ;; final all-items sweep to catch anything freed up by the two passes above
  (vl-catch-all-apply '(lambda () (command "_.-PURGE" "_All" "*" "_N")))
  (setvar "CMDECHO" oldCmdEcho)
  (princ "\n[SIF] Purge complete.")
)

;; ---------- import + explode ONE file, isolated so a bad file can't ----------
;; ---------- desync the rest of the run (command-line garbling)      ----------
(defun SIF:ImportOne (filePath idx / fname cdate layerName lastEnt)
  (setq fname (vl-filename-base filePath))
  (setq cdate (SIF:GetCreateDate filePath))
  (setq layerName (SIF:CleanLayerName
                    (strcat (itoa idx) "_" fname "_" cdate)))

  (command "_.-LAYER" "_M" layerName "")
  (setvar "CLAYER" layerName)

  ;; remember where the drawing database ends, so we can find
  ;; every new entity created by this import afterwards
  (setq lastEnt (entlast))

  ;; Bring the file in as a block. A leading "_Y" is a safety net: if a
  ;; block with this name already exists AutoCAD will ask
  ;; "Block already exists. Redefine it? [Yes/No]" and "_Y" answers it
  ;; automatically. If that prompt does NOT appear, "_Y" is simply an
  ;; invalid answer to "Specify insertion point" and gets silently
  ;; re-prompted, so it's harmless either way.
  (command "_.-INSERT" filePath "_Y" "0,0" "1" "1" "0")

  ;; explode every block reference that came in (handles nested blocks
  ;; up to SIF-EXPLODE-DEPTH levels) without ever trying to explode a
  ;; plain line/arc/etc, which is what caused "not able to be exploded"
  (SIF:ExplodeNew lastEnt)

  ;; force ALL entities that came in with this file onto the
  ;; new layer, no matter what layer they were on originally
  (SIF:SetLayerFrom lastEnt layerName)

  (princ (strcat "\n[SIF] " (itoa idx) ". " fname " -> layer \"" layerName "\" (full content moved in)"))
)

;; ---------- main command ----------
(defun c:SIF ( / fileList idx filePath oldFiledia result)

  (princ "\n[SIF] Opening file picker (Ctrl+Click to select multiple DWG/DXF files)...")
  (setq fileList (SIF:PickFilesMulti))

  (if (= fileList nil)
    (progn (princ "\n[SIF] No files selected. Command cancelled.") (princ))
    (progn
      ;; Force FILEDIA off for the whole run. Otherwise "Block already
      ;; exists. Redefine it?" (and similar warnings) pop up as a MODAL
      ;; DIALOG instead of a command-line Yes/No prompt; the script's
      ;; queued keystrokes then go nowhere, and everything after that
      ;; point desyncs - which is exactly what produced the
      ;; "*Invalid selection* / Expects a point or Last/ALL/Group" errors.
      (setq oldFiledia (getvar "FILEDIA"))
      (setvar "FILEDIA" 0)

      (setq idx (SIF:GetNextIndex))
      (princ (strcat "\n[SIF] Continuing sequence from " (itoa idx) "..."))
      (foreach filePath fileList
        ;; isolate each file: if one file throws an error mid-way,
        ;; catch it here so the remaining files still get processed
        ;; instead of the whole command aborting/desyncing
        (setq result
          (vl-catch-all-apply 'SIF:ImportOne (list filePath idx))
        )
        (if (vl-catch-all-error-p result)
          (princ (strcat "\n[SIF] " (itoa idx) ". FAILED (" (vl-catch-all-error-message result) ") - skipped, continuing..."))
        )
        (setq idx (1+ idx))
      )

      (princ (strcat "\n[SIF] Done. " (itoa (length fileList)) " file(s) processed."))

      ;; final cleanup: purge everything unused (all items + zero-length
      ;; geometry + orphaned data), same as ticking those boxes and
      ;; hitting "Purge All" in the Purge dialog
      (SIF:PurgeAll)

      (setvar "FILEDIA" oldFiledia)
      (princ)
    )
  )
)

(princ "\nSIF loaded. Type SIF to select & import multiple DWG/DXF files.")
(princ)
