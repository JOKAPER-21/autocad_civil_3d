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
;;        e) If "Generate PDF" is checked, the drawing's SINGLE
;;           paper-space layout (besides Model) is plotted to PDF
;;           using "DWG To PDF.pc3", into the SAME subfolder with the
;;           SAME base name:
;;             <stamp>_<filename>.pdf
;;           The layout's existing plot style table (CTB) is left
;;           untouched. If the drawing has 0 or 2+ paper-space layouts
;;           (besides Model), PDF is SKIPPED with a warning -- the
;;           DWG still publishes normally either way.
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
(setq *VP-ROOT-PATH* "\\\\Desktop-igi8ekn\\vid_20d\\share\\updated_projects_files\\section")
;; ----------------------------------------------------------------------
;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;; Ensure Visual LISP ActiveX extensions (vla-*, vlax-*) are loaded.
;; Modern AutoCAD auto-loads these, but this is cheap, standard
;; insurance across different install/profile configurations.
(vl-load-com)

;; PDF plot driver. "DWG To PDF.pc3" ships with every AutoCAD install,
;; so this should not need changing. This is a HARD requirement per
;; spec -- it is always forced on the plotted layout, not a fallback.
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

;; Return this PC's SYSTEM/COMPUTER name (i.e. what Windows shows as
;; %COMPUTERNAME%, or "hostname" in a terminal) -- NOT the AutoCAD/
;; Windows login (user) name, which is a different value returned by
;; the LOGINNAME system variable.
;;
;; AutoLISP has no built-in system variable for the computer name, so
;; this reads it via the Windows Script Host COM object, which is
;; always available on any Windows install (no extra setup needed).
;; Falls back to the %COMPUTERNAME% environment variable, then to
;; LOGINNAME, if WSH is ever unavailable, so the log field is never
;; left blank.
(defun vp-computer-name ( / wsh result name)
  (setq name nil)
  (setq result (vl-catch-all-apply
    '(lambda ()
       (setq wsh (vlax-create-object "WScript.Network"))
       (setq name (vlax-get-property wsh "ComputerName"))
       (vlax-release-object wsh)
     )
    '()
  ))
  (if (or (vl-catch-all-error-p result) (not name) (= name ""))
    (progn
      (setq name (getenv "COMPUTERNAME"))
      (if (or (not name) (= name ""))
        (setq name (getvar "LOGINNAME"))
      )
    )
  )
  name
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
;; Plots the CURRENT (active) layout to a PDF file using the documented
;; AutoCAD ActiveX pattern:
;;   1) Ensure BACKGROUNDPLOT = 0 so the plot runs in the foreground and
;;      finishes (with a result we can check) before this function
;;      returns -- otherwise PlotToFile queues the job and returns
;;      immediately, before the PDF file actually exists.
;;   2) Set the active layout's ConfigName to the PDF driver, UNLESS it
;;      already has a real device assigned, in which case that device
;;      is left alone (so existing paper size / plot style on that
;;      layout is preserved).
;;   3) Call Plot.PlotToFile(pdfpath) -- this plots whichever layout is
;;      currently active, exactly as documented by Autodesk.
;;
;; WHY NOT THE OLD COMMAND-LINE -PLOT SCRIPT:
;; The classic "(command "_.-PLOT" "answer1" "answer2" ...)" approach
;; depends on an EXACT, fixed number of prompts appearing in order. That
;; sequence changes depending on whether the layout already has a
;; plotter assigned and other per-layout settings, so a hardcoded
;; answer list reliably goes out of sync (this is what produced the
;; "Unknown command Y" / "Unknown command PDF" errors -- the script's
;; answers landed on the wrong prompts partway through).
;;
;; PlotToFile has no prompts to get out of sync with -- it is the
;; documented, version-stable way to do unattended/silent plotting from
;; AutoLISP/VBA. Reference: Autodesk ActiveX Reference, "PlotToFile
;; Method (ActiveX)".
;;==========================================================================
;;==========================================================================
;; LAYOUT DISCOVERY
;; Finds the drawing's paper-space layouts, excluding "Model". Per spec:
;;   - exactly 1 paper-space layout -> that's the one to plot
;;   - 0 or 2+ paper-space layouts  -> ambiguous, caller should skip PDF
;;     and warn rather than guess
;; Returns the layout NAME (string) if exactly one is found, else nil.
;;==========================================================================
(defun vp-find-single-paper-layout (docobj / layouts lyt names nm count)
  (setq layouts (vla-get-Layouts docobj))
  (setq names '())
  (vlax-for lyt layouts
    (setq nm (vla-get-Name lyt))
    (if (/= (strcase nm) "MODEL")
      (setq names (append names (list nm)))
    )
  )
  (setq count (length names))
  (cond
    ((= count 1) (car names))
    (T nil)   ;; 0 or 2+ -> caller handles the warning with the count
  )
)

;; Same as above but also returns the count, for clearer warning messages.
(defun vp-count-paper-layouts (docobj / layouts lyt nm count)
  (setq layouts (vla-get-Layouts docobj))
  (setq count 0)
  (vlax-for lyt layouts
    (setq nm (vla-get-Name lyt))
    (if (/= (strcase nm) "MODEL")
      (setq count (1+ count))
    )
  )
  count
)

;;==========================================================================
;; PDF PLOT HELPER
;; Plots a SPECIFIC named paper-space layout (the single non-Model layout
;; found by vp-find-single-paper-layout) to PDF via the documented
;; AutoCAD ActiveX Plot.PlotToFile method:
;;   1) Switch the active layout to the target layout by name (ActiveX
;;      ActiveLayout assignment), so PlotToFile plots THAT layout
;;      regardless of which tab the user had open when they ran
;;      VIDPUBLISH.
;;   2) Force the plot device to "DWG To PDF.pc3" (*VP-PDF-PC3*),
;;      always -- this is a hard requirement, not a fallback.
;;   3) Plot style table (CTB) is left exactly as the layout already
;;      has it -- nothing is changed here, per spec.
;;   4) Plot.PlotToFile(pdfpath) writes the PDF.
;;   5) The original active layout is restored afterward, so the user's
;;      drawing view doesn't change as a side effect of publishing.
;;
;; WHY NOT THE OLD COMMAND-LINE -PLOT SCRIPT:
;; The classic "(command "_.-PLOT" "answer1" "answer2" ...)" approach
;; depends on an EXACT, fixed number of prompts appearing in order. That
;; sequence shifts depending on whether the layout already has a
;; plotter assigned, which produced "Unknown command" errors when the
;; canned answers landed on the wrong prompt. PlotToFile has no prompts
;; to desync from -- it's the documented, version-stable way to do
;; unattended/silent plotting from AutoLISP/VBA (Autodesk ActiveX
;; Reference, "PlotToFile Method").
;;==========================================================================
(defun vp-plot-current-to-pdf (pdfpath layoutname / acadobj docobj
                                          targetlayout plotobj result
                                          success origactivelayout
                                          origbackgroundplot)
  (setq acadobj (vlax-get-acad-object))
  (setq docobj (vla-get-ActiveDocument acadobj))
  (setq plotobj (vla-get-Plot docobj))
  (setq success nil)

  ;; Force foreground plotting so PlotToFile blocks until the file is
  ;; actually written, and restore the user's original setting after.
  (setq origbackgroundplot (getvar "BACKGROUNDPLOT"))
  (setvar "BACKGROUNDPLOT" 0)

  ;; Remember whatever layout tab the user currently has open, so we
  ;; can switch back to it after publishing -- this tool should not
  ;; leave the user's drawing sitting on a different tab than before.
  (setq origactivelayout (vla-get-ActiveLayout docobj))

  (setq result (vl-catch-all-apply
    '(lambda ()
       ;; Switch to the target paper-space layout by name so PlotToFile
       ;; plots THAT layout, not whatever tab happened to be active.
       (setq targetlayout (vla-Item (vla-get-Layouts docobj) layoutname))
       (vla-put-ActiveLayout docobj targetlayout)

       ;; Always force the PDF driver -- this is a hard requirement.
       ;; Plot style table (CTB) is intentionally left untouched.
       (vla-put-ConfigName targetlayout *VP-PDF-PC3*)

       (vla-put-QuietErrorMode plotobj :vlax-true)

       ;; vla-PlotToFile returns T (success) or nil (failure) directly
       ;; in Visual LISP -- no variant unwrapping needed.
       (setq success (vla-PlotToFile plotobj pdfpath))
     )
    '()
  ))

  ;; Always restore the user's original active layout, even on error.
  (vl-catch-all-apply
    '(lambda () (vla-put-ActiveLayout docobj origactivelayout))
    '()
  )

  (setvar "BACKGROUNDPLOT" origbackgroundplot)

  (if (vl-catch-all-error-p result)
    (progn
      (princ (strcat "\nVIDPUBLISH: PDF plot error - "
                      (vl-catch-all-error-message result)))
      nil
    )
    (progn
      ;; The file actually existing on disk is the real proof of
      ;; success -- COM boolean returns can come back as T/nil or
      ;; -1/0 depending on AutoCAD version, so don't rely on `success`
      ;; alone if the file is plainly there.
      (if (findfile pdfpath)
        T
        (progn
          (if (not success)
            (princ "\nVIDPUBLISH: PlotToFile reported failure and no PDF file was found.")
          )
          nil
        )
      )
    )
  )
)



;;==========================================================================
;; DIALOG
;; Returns a list (CODE CMDTEXT PDFFLAG) on OK, or nil if cancelled.
;;   CODE     - selected yard code string
;;   CMDTEXT  - text typed into the Commands box (string, may be empty)
;;   PDFFLAG  - T if "Generate PDF" was checked, nil otherwise
;;
;; LIST GROUPING: the list box shows segment names (MEJ_TEN, TEN_TCN,
;; ...) as plain-text header rows, with that segment's yard codes
;; indented underneath -- one flat list, visually grouped, no separate
;; picker step. Header rows are not real yards, so they are treated as
;; non-selectable: clicking or arrowing onto a header automatically
;; jumps to the nearest real yard row instead of leaving a header
;; "selected".
;;
;; *VP-DISPLAY-ROWS* is built once per dialog call as a list of
;; (CODE . DISPLAY-STRING) pairs, in list-box row order. CODE is nil
;; for header rows. This keeps "what row index am I on" and "what code
;; does that map to" in exact sync with what's actually drawn on screen.
;;
;; NOTE ON GLOBALS: action_tile callback strings run as standalone
;; AutoLISP expressions, NOT inside vp-show-dialog's local scope. So we
;; stage results in global *VP-TMP-*  variables, then copy them into
;; proper locals immediately after start_dialog returns. This is the
;; standard, reliable DCL pattern.
;;==========================================================================
(defun vp-show-dialog ( / dcl_id result sel dclfile firstyardrow)
  (setq dclfile (vp-pathjoin (list *VP-LSP-DIR* "VidPublish.dcl")))
  (if (not (findfile dclfile))
    (progn
      (princ (strcat "\nERROR: Cannot find VidPublish.dcl at: " dclfile))
      (princ "\nMake sure VidPublish.dcl is in the same folder as VidPublish.lsp.")
      nil
    )
    (progn
      (setq *VP-DISPLAY-ROWS* (vp-build-display-rows))
      (setq firstyardrow (vp-nearest-yard-row 0))

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
          (mapcar 'add_list (mapcar 'cdr *VP-DISPLAY-ROWS*))
          (end_list)
          (set_tile "yard_list" (itoa firstyardrow))
          (set_tile "target_preview"
            (strcat "Target:  " (vp-preview-path (vp-row-code firstyardrow))))
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

;; Build the (CODE . DISPLAY-STRING) row list: a header row (CODE=nil)
;; before each segment's yards, yard rows indented underneath.
(defun vp-build-display-rows ( / rows curseg pair code seg)
  (setq rows '())
  (setq curseg nil)
  (foreach pair *VP-YARD-MAP*
    (setq code (car pair))
    (setq seg (cdr pair))
    (if (not (equal seg curseg))
      (progn
        (setq curseg seg)
        (setq rows (append rows (list (cons nil (vp-segment-label seg)))))
      )
    )
    (setq rows (append rows (list (cons code (strcat "     " code)))))
  )
  rows
)

;; Turn a segment subpath like "w1\MEJ_TEN" into a clean header label,
;; e.g. "MEJ_TEN" -- strips the "w#\" prefix so the header matches the
;; plain segment names as given (MEJ_TEN, TEN_TCN, TEN_TSI, NLL_TN,
;; MDU_NLL, VPT_SNKL, SNKL_EDP, EDP_QLN).
(defun vp-segment-label (seg / parts)
  (setq parts (vp-strsplit seg "\\"))
  (if (> (length parts) 1) (nth 1 parts) seg)
)

;; Given a row index, return the nearest row index that is a REAL yard
;; row (code /= nil), searching forward first, then backward. Used both
;; to pick the initial selection and to auto-correct a click/arrow onto
;; a header row.
(defun vp-nearest-yard-row (idx / n total i)
  (setq total (length *VP-DISPLAY-ROWS*))
  (setq n idx)
  ;; search forward
  (setq i n)
  (while (and (< i total) (not (vp-row-code i)))
    (setq i (1+ i))
  )
  (if (< i total)
    i
    (progn
      ;; not found going forward (idx was on/after the last header with
      ;; no yards after it) -- search backward instead
      (setq i n)
      (while (and (>= i 0) (not (vp-row-code i)))
        (setq i (1- i))
      )
      (max i 0)
    )
  )
)

;; CODE at a given display-row index, or nil if that row is a header.
(defun vp-row-code (idx)
  (car (nth idx *VP-DISPLAY-ROWS*))
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

;; Called from the DCL list_box action_tile whenever selection changes
;; (by click OR arrow keys). If the newly selected row is a header,
;; silently jump the selection to the nearest real yard row instead --
;; this is what makes headers "unselectable" despite DCL list_box
;; having no built-in concept of a disabled row.
(defun vp-update-preview ( / idx code fixedidx)
  (setq idx (atoi (get_tile "yard_list")))
  (setq code (vp-row-code idx))
  (if (not code)
    (progn
      (setq fixedidx (vp-nearest-yard-row idx))
      (set_tile "yard_list" (itoa fixedidx))
      (setq code (vp-row-code fixedidx))
    )
  )
  (if code
    (set_tile "target_preview" (strcat "Target:  " (vp-preview-path code)))
  )
)

;; Currently highlighted yard code (never a header, thanks to
;; vp-update-preview always correcting the selection immediately).
(defun vp-selected-code ( / idx)
  (setq idx (atoi (get_tile "yard_list")))
  (vp-row-code idx)
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
                        ok fnresult pdfresult layoutcount targetlayoutname)

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
                          (setq layoutcount (vp-count-paper-layouts docobj))
                          (setq targetlayoutname (vp-find-single-paper-layout docobj))
                          (cond
                            ((not targetlayoutname)
                             (setq pdfresult "skipped")
                             (princ (strcat "\nVIDPUBLISH WARNING: Expected exactly 1 paper-space layout "
                                             "(besides Model) to plot, found " (itoa layoutcount)
                                             ". Skipping PDF.\n  (DWG was still published successfully.)"))
                            )
                            (T
                             (princ (strcat "\nVIDPUBLISH: Generating PDF for layout: " targetlayoutname "..."))
                             (if (vp-plot-current-to-pdf destpdf targetlayoutname)
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
                        )
                      )

                      ;; ---- 8) Append to log CSV (best effort, never blocks) ----
                      (setq logpath (vp-pathjoin (list rootnorm "publish_log.csv")))
                      (setq logline
                        (strcat (vp-timestamp) ","
                                (vp-csv-safe (vp-computer-name)) ","
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
