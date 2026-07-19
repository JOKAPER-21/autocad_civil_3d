;;==========================================================================
;; VidPublish.lsp
;; AutoCAD Civil 3D 2026 - VID Publish Pipeline
;;
;; WHAT THIS DOES:
;;   1) Run command VIDPUBLISH (alias PUBLISH) in any open drawing.
;;   2) A dialog shows:
;;        - Yard Names list (press Enter or double-click to accept,
;;          same as clicking OK)
;;        - Commands text box (written into the drawing's DWGPROPS
;;          Comments field before saving)
;;        - "Generate PDF" checkbox (checked by default)
;;        - OK / Cancel
;;   3) On OK, for the selected yard:
;;        a) The Commands text is written into DWGPROPS -> Comments.
;;        b) The current drawing is SAVED (QSAVE). It keeps its name,
;;           stays open, nothing about the open document changes.
;;        c) A timestamped subFOLDER is created inside that yard's
;;           publish folder, named after the file + timestamp:
;;             <publish>\<stamp>_<filename>\
;;        d) The DWG is copied into that subfolder as:
;;             <stamp>_<filename>.dwg
;;        e) If "Generate PDF" is checked, the current layout is
;;           plotted to PDF (DWG To PDF.pc3) into the SAME subfolder
;;           with the SAME base name:
;;             <stamp>_<filename>.pdf
;;        f) A line is appended to <ROOT>\publish_log.csv (more columns
;;           than before -- see CSV header note below).
;;
;;   Example final layout:
;;     J:\VID_autocad_publish_test\w1\TEN_TSI\dwg\yard\
;;       yd_VVR_viravanallur\publish\
;;         20260621_092903_delete-this\
;;           20260621_092903_delete-this.dwg
;;           20260621_092903_delete-this.pdf
;;
;; INSTALL:
;;   1) Put VidPublish.lsp and VidPublish.dcl in the SAME folder.
;;   2) In AutoCAD:  APPLOAD  ->  add VidPublish.lsp  -> Load
;;      (or drag-and-drop the .lsp onto the AutoCAD window)
;;   3) Type:  VIDPUBLISH   (alias: PUBLISH)
;;
;; ----------------------------------------------------------------------
;; >>>>>>>>>>>>>>>>>>>  EDIT THIS SECTION PER MACHINE  <<<<<<<<<<<<<<<<<<<
;; ----------------------------------------------------------------------
;; Root path is the ONLY thing that should change between users/machines.
;; Examples:
;;   Local drive :  "J:\\VID_autocad_publish_test"
;;   UNC server  :  "\\\\FILESERVER\\Projects\\VID_autocad_publish_test"
;;   Mapped drive:  "Z:\\VID_autocad_publish_test"
;; NOTE: In AutoLISP strings, every backslash must be doubled ( \\ ).
;; Do NOT put a trailing slash at the end.
;; ----------------------------------------------------------------------
(setq *VP-ROOT-PATH* "J:\\VID_autocad_publish_test")
;; ----------------------------------------------------------------------
;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;; PDF plot driver / page setup. "DWG To PDF.pc3" ships with every
;; AutoCAD install, so this should not need changing. If a site uses a
;; custom PC3 with preset page setups, change the name here.
(setq *VP-PDF-PC3* "DWG To PDF.pc3")

;; Full path to this LSP's own folder, resolved at load time, so the
;; .dcl file is found regardless of where the user's support paths point.
(setq *VP-LSP-DIR* (if (findfile "VidPublish.lsp")
                       (vl-filename-directory (findfile "VidPublish.lsp"))
                       "."))

;;--------------------------------------------------------------------------
;; YARD MAP
;; Each entry: (CODE . SEGMENT-SUBPATH)
;; SEGMENT-SUBPATH is everything between ROOT and "\dwg\yard\yd_<code>\publish"
;; The full target folder is built as:
;;   ROOT \ SEGMENT \ dwg \ yard \ yd_<CODE> \ publish
;;--------------------------------------------------------------------------
(setq *VP-YARD-MAP*
  (list
    (cons "NRK_naraikkinar" "w1\\MEJ_TEN")
    (cons "GDN_gangaikondan" "w1\\MEJ_TEN")
    (cons "TAY_talaiyuthu" "w1\\MEJ_TEN")
    (cons "TEN_tirunelveli" "w1\\MEJ_TEN")

    (cons "PCO_palayankottai" "w1\\TEN_TCN")
    (cons "SDNR_seydunganallur" "w1\\TEN_TCN")
    (cons "TTQ_thathankulam" "w1\\TEN_TCN")
    (cons "SVV_srivaikuntam" "w1\\TEN_TCN")
    (cons "AWT_alwarTirunagari" "w1\\TEN_TCN")
    (cons "NZT_nazareth" "w1\\TEN_TCN")
    (cons "KCHV_kachchanavilai" "w1\\TEN_TCN")
    (cons "KZB_kurumbur" "w1\\TEN_TCN")
    (cons "ANY_arumuganeri" "w1\\TEN_TCN")
    (cons "KZY_kayalpattinam" "w1\\TEN_TCN")
    (cons "TCN_tiruchendur" "w1\\TEN_TCN")

    (cons "TYT_tirunelveliTown" "w1\\TEN_TSI")
    (cons "PEA_pettai" "w1\\TEN_TSI")
    (cons "SMD_cheranmahadevi" "w1\\TEN_TSI")
    (cons "KARK_karraikkurichichi" "w1\\TEN_TSI")
    (cons "VVR_viravanallur" "w1\\TEN_TSI")
    (cons "KIC_kallidaikurichi" "w1\\TEN_TSI")
    (cons "ASD_ambasamudram" "w1\\TEN_TSI")
    (cons "KIB_kizhaAmbur" "w1\\TEN_TSI")
    (cons "AZK_azhwarkurichi" "w1\\TEN_TSI")
    (cons "RVS_ravanasamudram" "w1\\TEN_TSI")
    (cons "KKY_kilakadaiyam" "w1\\TEN_TSI")

    (cons "NLL_nalli" "w2\\NLL_TN")
    (cons "CVP_kovilpatti" "w2\\NLL_TN")
    (cons "KPM_kumarapuram" "w2\\NLL_TN")
    (cons "KDU_kadambur" "w2\\NLL_TN")
    (cons "MEJ_vanchiManiyachchi" "w2\\NLL_TN")
    (cons "KLPM_kailasapuram" "w2\\NLL_TN")
    (cons "TIP_tattapparai" "w2\\NLL_TN")
    (cons "MVN_milavittan" "w2\\NLL_TN")
    (cons "TME_tutimelur" "w2\\NLL_TN")
    (cons "TN_tuticorin" "w2\\NLL_TN")
    (cons "MMDR_melmarudur" "w2\\NLL_TN")

    (cons "TDN_tiruparankundram" "w3\\MDU_NLL")
    (cons "TMQ_tirumangalam" "w3\\MDU_NLL")
    (cons "KGD_kalligudi" "w3\\MDU_NLL")
    (cons "VPT_virudunagar" "w3\\MDU_NLL")
    (cons "TY_tulikapatti" "w3\\MDU_NLL")
    (cons "SRT_sattur" "w3\\MDU_NLL")

    (cons "TTL_tiruttangal" "w3\\VPT_SNKL")
    (cons "SVKS_sivakasi" "w3\\VPT_SNKL")
    (cons "SVPR_srivilliputtur" "w3\\VPT_SNKL")
    (cons "RJPM_rajapalayam" "w3\\VPT_SNKL")

    (cons "SNKL_sankarankovil" "w4\\SNKL_EDP")
    (cons "PBKS_pambakovilShandy" "w4\\SNKL_EDP")
    (cons "KDNL_kadayanallur" "w4\\SNKL_EDP")
    (cons "TSI_tenkasi" "w4\\SNKL_EDP")
    (cons "SCT_sengottai" "w4\\SNKL_EDP")
    (cons "BJM_bhagavathipuram" "w4\\SNKL_EDP")
    (cons "AYV_aryankavu" "w4\\SNKL_EDP")
    (cons "AYVN_newAryankavu" "w4\\SNKL_EDP")
    (cons "EDN_edapalayam" "w4\\SNKL_EDP")

    (cons "KTHY_kalthurutty" "w4\\EDP_QLN")
    (cons "TML_tenmalai" "w4\\EDP_QLN")
    (cons "OKL_ottakkal" "w4\\EDP_QLN")
    (cons "EDN_edaman" "w4\\EDP_QLN")
    (cons "PUU_punalur" "w4\\EDP_QLN")
    (cons "AVS_avaneeswarem" "w4\\EDP_QLN")
    (cons "KIF_kuri" "w4\\EDP_QLN")
    (cons "KKZ_kottarakkara" "w4\\EDP_QLN")
    (cons "EKN_ezhukone" "w4\\EDP_QLN")
    (cons "KFV_kundaraEast" "w4\\EDP_QLN")
    (cons "KUV_kundara" "w4\\EDP_QLN")
    (cons "CTPE_chandanattop" "w4\\EDP_QLN")
    (cons "KLQ_kilikollur" "w4\\EDP_QLN")
    (cons "QLN_kollam" "w4\\EDP_QLN")
  )
)

;;==========================================================================
;; PATH HELPERS
;; Handle the "different users, different path styles" problem:
;;   - Local drive      J:\Folder\Sub
;;   - Mapped drive      Z:\Folder\Sub
;;   - UNC server path   \\server\share\Folder\Sub
;;   - Forward slashes   J:/Folder/Sub   (rare, but some users paste these)
;; All internal joins use backslash, and we normalize/clean any path
;; that gets built or read so double slashes, trailing slashes, or
;; forward slashes do not break file/dir operations.
;;==========================================================================

;; Replace every forward slash with a backslash (Windows-safe)
(defun vp-slashfix (s / out i ch)
  (setq out "")
  (setq i 0)
  (while (< i (strlen s))
    (setq ch (substr s (1+ i) 1))
    (setq out (strcat out (if (= ch "/") "\\" ch)))
    (setq i (1+ i))
  )
  out
)

;; Collapse any run of multiple backslashes into one, EXCEPT a leading
;; "\\\\" (UNC server prefix), which must be preserved.
(defun vp-collapse-slashes (s / unc body out i ch prev)
  (setq unc "")
  (setq body s)
  (if (and (>= (strlen s) 2) (= (substr s 1 2) "\\\\"))
    (progn
      (setq unc "\\\\")
      (setq body (substr s 3))
    )
  )
  (setq out "")
  (setq prev "")
  (setq i 0)
  (while (< i (strlen body))
    (setq ch (substr body (1+ i) 1))
    (if (not (and (= ch "\\") (= prev "\\")))
      (setq out (strcat out ch))
    )
    (setq prev ch)
    (setq i (1+ i))
  )
  (strcat unc out)
)

;; Strip a single trailing slash/backslash, if present
(defun vp-strip-trailing-slash (s)
  (if (and (> (strlen s) 0)
           (member (substr s (strlen s) 1) '("\\" "/")))
    (substr s 1 (1- (strlen s)))
    s
  )
)

;; Full normalize: fix slash direction, collapse doubles, strip trailing
(defun vp-normpath (s)
  (vp-strip-trailing-slash (vp-collapse-slashes (vp-slashfix s)))
)

;; Join path parts with a single backslash between them, normalizing
;; the final result. Accepts any number of string args via a list.
(defun vp-pathjoin (parts / result)
  (setq result "")
  (foreach p parts
    (setq p (vp-strip-trailing-slash (vp-slashfix p)))
    (setq result
      (if (= result "")
        p
        (strcat result "\\" p)
      )
    )
  )
  (vp-normpath result)
)

;;==========================================================================
;; FOLDER / FILE HELPERS
;;==========================================================================

;; Recursively create a folder path, one level at a time.
;; vl-mkdir fails if the parent doesn't exist, so we walk up from root.
(defun vp-mkdir-p (path / parts cur unc rest)
  (setq path (vp-normpath path))
  (setq unc "")
  (setq rest path)
  (if (= (substr path 1 2) "\\\\")
    (progn
      (setq unc "\\\\")
      (setq rest (substr path 3))
    )
  )
  (setq parts (vp-strsplit rest "\\"))
  (setq cur unc)
  (foreach p parts
    (setq cur (if (= cur "") p
                (if (= cur unc) (strcat cur p) (strcat cur "\\" p))))
    (if (and (/= cur "") (not (vl-file-directory-p cur)))
      (vl-mkdir cur)
    )
  )
  (vl-file-directory-p path)
)

;; Simple string split on a single-character delimiter
(defun vp-strsplit (s delim / result pos)
  (setq result '())
  (while (setq pos (vl-string-search delim s))
    (setq result (append result (list (substr s 1 pos))))
    (setq s (substr s (+ pos 1 (strlen delim))))
  )
  (if (/= s "") (setq result (append result (list s))))
  result
)

;; Build YYYYMMDD_HHMMSS from the current system clock
(defun vp-timestamp ( / dt y mo d h mi sec)
  (setq dt (rtos (getvar "CDATE") 2 6))
  (setq y  (substr dt 1 4))
  (setq mo (substr dt 5 2))
  (setq d  (substr dt 7 2))
  (setq h  (substr dt 10 2))
  (setq mi (substr dt 12 2))
  (setq sec (substr dt 14 2))
  (strcat y mo d "_" h mi sec)
)

;; Return file name without path, WITHOUT extension
(defun vp-filename-only (fullpath)
  (vl-filename-base fullpath)
)

;; Return file extension WITH the leading dot, e.g. ".dwg"
(defun vp-fileext-only (fullpath)
  (vl-filename-extension fullpath)
)

;; Sanitize a string for safe use as a Windows folder/file name:
;; strip characters that are illegal in Windows file/folder names
;; ( \ / : * ? " < > | ) -- the timestamp+filename string should
;; already be clean in normal use, but this guards against odd
;; original DWG names (e.g. containing a colon or question mark).
(defun vp-sanitize-name (s / out i ch bad)
  (setq bad '("\\" "/" ":" "*" "?" "\"" "<" ">" "|"))
  (setq out "")
  (setq i 0)
  (while (< i (strlen s))
    (setq ch (substr s (1+ i) 1))
    (setq out (strcat out (if (member ch bad) "_" ch)))
    (setq i (1+ i))
  )
  out
)

;; Append one line of text to a log file, creating it if needed
(defun vp-log-line (logpath line / f)
  (setq f (open logpath "a"))
  (if f
    (progn
      (write-line line f)
      (close f)
      T
    )
    nil
  )
)

;; Make a free-text string safe to store as ONE CSV field: strip commas
;; and newlines (replace with space) since the log format here is plain
;; comma-separated with no quoting. Keeps the publish_log.csv simple and
;; readable in any text editor or Excel without needing quoted-field
;; parsing for this column.
(defun vp-csv-safe (s / out i ch)
  (if (not s) (setq s ""))
  (setq out "")
  (setq i 0)
  (while (< i (strlen s))
    (setq ch (substr s (1+ i) 1))
    (setq out (strcat out
      (cond ((= ch ",") " ")
            ((= ch "\n") " ")
            ((= ch "\r") "")
            (T ch))))
    (setq i (1+ i))
  )
  out
)

;;==========================================================================
;; DWGPROPS / SUMMARY INFO HELPER
;; The AutoCAD command DWGPROPS just opens the Drawing Properties dialog
;; (the same dialog you reach via File > Drawing Properties). It cannot
;; be driven non-interactively/silently from a script -- there is no
;; command-line way to "type text into" that dialog's Comments field
;; without it popping up and waiting for clicks.
;;
;; The reliable, silent equivalent is to write directly to the drawing's
;; SummaryInfo COM object, which is the SAME data DWGPROPS reads and
;; writes. Setting SummaryInfo.Comments here updates exactly the field
;; you'd see under DWGPROPS -> Summary tab -> Comments, with no dialog
;; popping up and no extra clicks needed.
;;==========================================================================
(defun vp-set-dwgprops-comments (docobj text / si result)
  (setq result (vl-catch-all-apply
    '(lambda ()
       (setq si (vla-get-SummaryInfo docobj))
       (vla-put-Comments si text)
     )
    '()
  ))
  (not (vl-catch-all-error-p result))
)

;;==========================================================================
;; PDF PLOT HELPER
;; Plots the CURRENT layout (model space or whichever paper space tab is
;; active when VIDPUBLISH is run) to a PDF file using the DWG To PDF.pc3
;; driver, via the command-line -PLOT sequence (fully scriptable, no
;; dialogs). Uses the layout's own existing page setup (size/orientation/
;; plot style) rather than overriding it, since most offices already
;; have each layout's plot settings configured the way they want.
;;
;; pdfpath must be a full path ending in .pdf (no extension juggling
;; needed -- -PLOT writes exactly the file name given when "Plot to
;; File" / file dialog steps are answered via the scripted responses).
;;==========================================================================
(defun vp-plot-current-to-pdf (pdfpath / curlayout cmdecho result)
  (setq cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  (setq curlayout (getvar "CTAB"))
  (setq result (vl-catch-all-apply
    '(lambda ()
       (command "_.-PLOT"
                 "_Y"                ;; Detailed plot configuration? Yes
                 curlayout            ;; Enter a layout name
                 *VP-PDF-PC3*         ;; printer/plotter name
                 ""                   ;; paper size -> use default from page setup
                 ""                   ;; paper units -> default
                 ""                   ;; drawing orientation -> default
                 ""                   ;; plot upside down? -> default (No)
                 ""                   ;; plot area -> default (Layout/Extents per setup)
                 ""                   ;; plot scale -> default
                 ""                   ;; plot offset -> default
                 ""                   ;; plot options -> default
                 "_N"                 ;; shaded viewport options? No extra change
                 "_Y"                 ;; proceed with plot? Yes
                 pdfpath              ;; output PDF file name/path
       )
     )
    '()
  ))
  (setvar "CMDECHO" cmdecho)
  (and (not (vl-catch-all-error-p result))
       (findfile pdfpath))
)

;;==========================================================================
;; DIALOG
;; Returns a list (CODE CMDTEXT PDFFLAG) on OK, or nil if cancelled.
;;   CODE     - selected yard code string
;;   CMDTEXT  - text typed into the Commands box (string, may be empty)
;;   PDFFLAG  - T if "Generate PDF" was checked, nil otherwise
;;
;; NOTE ON GLOBALS: action_tile callback strings run as standalone
;; AutoLISP expressions, NOT inside vp-show-dialog's local scope. So we
;; stage results in global *VP-TMP-*  variables inside vp-on-accept,
;; then copy them into proper locals immediately after start_dialog
;; returns. This is the standard, reliable DCL pattern.
;;==========================================================================
(defun vp-show-dialog ( / dcl_id codes result sel dclfile cmdtext pdfflag)
  (setq dclfile (vp-pathjoin (list *VP-LSP-DIR* "VidPublish.dcl")))
  (if (not (findfile dclfile))
    (progn
      (princ (strcat "\nERROR: Cannot find VidPublish.dcl at: " dclfile))
      (princ "\nMake sure VidPublish.dcl is in the same folder as VidPublish.lsp.")
      nil
    )
    (progn
      (setq codes '())
      (foreach pair *VP-YARD-MAP*
        (setq codes (append codes (list (car pair))))
      )
      (setq dcl_id (load_dialog dclfile))
      (if (not (new_dialog "vid_publish_dlg" dcl_id))
        (progn
          (princ "\nERROR: Could not load dialog vid_publish_dlg.")
          (unload_dialog dcl_id)
          nil
        )
        (progn
          (setq *VP-TMP-CODE* nil)
          (setq *VP-TMP-CMDTEXT* "")
          (setq *VP-TMP-PDFFLAG* T)

          (start_list "yard_list")
          (mapcar 'add_list codes)
          (end_list)
          (set_tile "yard_list" "0")
          (set_tile "target_preview"
            (strcat "Target: " (vp-preview-path (car codes))))
          (set_tile "pdf_check" "1")
          (set_tile "cmd_text" "")

          (action_tile "yard_list" "(vp-update-preview)")
          (action_tile "accept" "(vp-on-accept)")
          (action_tile "cancel" "(done_dialog 0)")

          (setq sel (start_dialog))
          (unload_dialog dcl_id)
          (if (= sel 1)
            (list *VP-TMP-CODE* *VP-TMP-CMDTEXT* *VP-TMP-PDFFLAG*)
            nil
          )
        )
      )
    )
  )
)

;; Called when OK is clicked (or Enter pressed, since OK is the dialog's
;; default button) -- stages all three field values into globals, then
;; closes the dialog with status 1 (accepted).
(defun vp-on-accept ( / )
  (setq *VP-TMP-CODE* (vp-selected-code))
  (setq *VP-TMP-CMDTEXT* (get_tile "cmd_text"))
  (setq *VP-TMP-PDFFLAG* (= (get_tile "pdf_check") "1"))
  (done_dialog 1)
)

;; Called from the DCL list_box action_tile when selection changes.
(defun vp-update-preview ( / code)
  (setq code (vp-selected-code))
  (if code
    (set_tile "target_preview" (strcat "Target: " (vp-preview-path code)))
  )
)

;; List of codes in display order (matches *VP-YARD-MAP* order)
(defun vp-code-list ( / codes)
  (setq codes '())
  (foreach pair *VP-YARD-MAP*
    (setq codes (append codes (list (car pair))))
  )
  codes
)

;; Currently highlighted code in the list box
(defun vp-selected-code ( / idx codes)
  (setq idx (atoi (get_tile "yard_list")))
  (setq codes (vp-code-list))
  (nth idx codes)
)

;; Build a short human-readable preview of the target folder for a code
(defun vp-preview-path (code / seg)
  (setq seg (cdr (assoc code *VP-YARD-MAP*)))
  (if seg
    (vp-pathjoin (list seg "dwg" "yard" (strcat "yd_" code) "publish"))
    "(unknown)"
  )
)

;;==========================================================================
;; MAIN COMMAND
;;==========================================================================
(defun c:VIDPUBLISH ( / dlgresult code seg cmdtext pdfflag targetbase
                        subfolder srcpath srcname srcext stamp basename
                        destdwg destpdf docobj rootnorm logpath logline
                        ok fnresult pdfresult)

  (setq docobj (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq fnresult (vl-catch-all-apply 'vla-get-FullName (list docobj)))
  (setq srcpath
    (if (vl-catch-all-error-p fnresult) "" fnresult))

  (if (or (= srcpath "") (not srcpath))
    (progn
      (princ "\nVIDPUBLISH: Current drawing has never been saved. Save it first with a real file name, then run VIDPUBLISH again.")
      (princ)
    )
    (progn
      (setq dlgresult (vp-show-dialog))
      (if (not dlgresult)
        (progn (princ "\nVIDPUBLISH: Cancelled.") (princ))
        (progn
          (setq code (nth 0 dlgresult))
          (setq cmdtext (nth 1 dlgresult))
          (setq pdfflag (nth 2 dlgresult))
          (setq seg (cdr (assoc code *VP-YARD-MAP*)))

          (if (not seg)
            (progn
              (princ (strcat "\nVIDPUBLISH: No folder mapping found for code: " code))
              (princ)
            )
            (progn
              ;; ---- 1) Write Commands text into DWGPROPS Comments ----
              (if (and cmdtext (/= cmdtext ""))
                (progn
                  (if (vp-set-dwgprops-comments docobj cmdtext)
                    (princ "\nVIDPUBLISH: Drawing properties (Comments) updated.")
                    (princ "\nVIDPUBLISH: Note - could not update drawing properties (non-fatal).")
                  )
                )
              )

              ;; ---- 2) Save current drawing (current file stays open) ----
              (princ "\nVIDPUBLISH: Saving current drawing...")
              (command "_.QSAVE")

              ;; Re-read path/name AFTER save in case it changed (safety only)
              (setq fnresult (vl-catch-all-apply 'vla-get-FullName (list docobj)))
              (setq srcpath (if (vl-catch-all-error-p fnresult) srcpath fnresult))
              (setq srcname (vp-filename-only srcpath))
              (setq srcext  (vp-fileext-only srcpath))
              (if (not srcext) (setq srcext ".dwg"))

              ;; ---- 3) Build normalized target base (yard's publish folder) ----
              (setq rootnorm (vp-normpath *VP-ROOT-PATH*))
              (setq targetbase
                (vp-pathjoin (list rootnorm seg "dwg" "yard" (strcat "yd_" code) "publish")))

              ;; ---- 4) Build timestamped base name and SUBFOLDER ----
              (setq stamp (vp-timestamp))
              (setq basename (vp-sanitize-name (strcat stamp "_" srcname)))
              (setq subfolder (vp-pathjoin (list targetbase basename)))

              ;; ---- 5) Auto-create the subfolder (and everything above it) ----
              (if (not (vl-file-directory-p subfolder))
                (progn
                  (princ (strcat "\nVIDPUBLISH: Creating folder: " subfolder))
                  (vp-mkdir-p subfolder)
                )
              )

              (if (not (vl-file-directory-p subfolder))
                (progn
                  (princ (strcat "\nVIDPUBLISH ERROR: Could not create or access target folder:\n  "
                                  subfolder
                                  "\nCheck that the root path is correct and the drive/server is connected."))
                  (princ)
                )
                (progn
                  (setq destdwg (vp-pathjoin (list subfolder (strcat basename srcext))))
                  (setq destpdf (vp-pathjoin (list subfolder (strcat basename ".pdf"))))

                  ;; ---- 6) Copy DWG into the subfolder ----
                  (if (vl-file-copy srcpath destdwg)
                    (progn
                      (princ (strcat "\nVIDPUBLISH: DWG published.\n  From: "
                                      srcpath "\n  To:   " destdwg))

                      ;; ---- 7) Generate PDF if requested ----
                      (setq pdfresult "skipped")
                      (if pdfflag
                        (progn
                          (princ "\nVIDPUBLISH: Generating PDF...")
                          (if (vp-plot-current-to-pdf destpdf)
                            (progn
                              (setq pdfresult "ok")
                              (princ (strcat "\nVIDPUBLISH: PDF created: " destpdf))
                            )
                            (progn
                              (setq pdfresult "failed")
                              (princ (strcat "\nVIDPUBLISH WARNING: PDF generation failed for: " destpdf
                                              "\n  (DWG was still published successfully.)"))
                            )
                          )
                        )
                      )

                      ;; ---- 8) Append to log CSV (best effort, never blocks) ----
                      (setq logpath (vp-pathjoin (list rootnorm "publish_log.csv")))
                      (setq logline
                        (strcat (vp-timestamp) ","
                                (getvar "LOGINNAME") ","
                                code ","
                                srcname srcext ","
                                srcpath ","
                                destdwg ","
                                pdfresult ","
                                destpdf ","
                                (vp-csv-safe cmdtext)))
                      (setq ok (vp-log-line logpath logline))
                      (if (not ok)
                        (princ "\nVIDPUBLISH: Note - could not write to publish_log.csv (non-fatal).")
                      )
                    )
                    (progn
                      (princ (strcat "\nVIDPUBLISH ERROR: File copy failed.\n  From: "
                                      srcpath "\n  To:   " destdwg))
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  (princ)
)

;; Convenience alias
(defun c:PUBLISH () (c:VIDPUBLISH))

(princ "\nVidPublish loaded. Type VIDPUBLISH or PUBLISH to run.")
(princ)
