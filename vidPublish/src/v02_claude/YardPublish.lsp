;;==========================================================================
;; YardPublish.lsp
;; AutoCAD Civil 3D 2026 - Yard Publish Pipeline
;;
;; WHAT THIS DOES:
;;   1) Run command YARDPUBLISH (or PUBLISH) in any open drawing.
;;   2) A dialog shows the list of Yard Names.
;;   3) User picks a yard and clicks "Publish".
;;   4) The current drawing is SAVED (QSAVE), then a COPY of the saved
;;      file is placed into:
;;         <ROOT-PATH>\<segment>\dwg\yard\yd_<code>\publish\
;;      with filename:
;;         YYYYMMDD_HHMMSS_<originalfilename>.<ext>
;;   5) The publish folder is auto-created if it does not exist.
;;   6) A log line is appended to <ROOT-PATH>\publish_log.csv so the
;;      companion Python script can verify / report on publishes.
;;
;; INSTALL:
;;   1) Put YardPublish.lsp and YardPublish.dcl in the SAME folder.
;;   2) In AutoCAD:  APPLOAD  ->  add YardPublish.lsp  -> Load
;;      (or drag-and-drop the .lsp onto the AutoCAD window)
;;   3) Type:  YARDPUBLISH   (alias: PUBLISH)
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
(setq *YP-ROOT-PATH* "J:\\VID_autocad_publish_test")
;; ----------------------------------------------------------------------
;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;; Full path to this LSP's own folder, resolved at load time, so the
;; .dcl file is found regardless of where the user's support paths point.
(setq *YP-LSP-DIR* (if (findfile "YardPublish.lsp")
                       (vl-filename-directory (findfile "YardPublish.lsp"))
                       "."))

;;--------------------------------------------------------------------------
;; YARD MAP
;; Each entry: (CODE . SEGMENT-SUBPATH)
;; SEGMENT-SUBPATH is everything between ROOT and "\dwg\yard\yd_<code>\publish"
;; The full target folder is built as:
;;   ROOT \ SEGMENT \ dwg \ yard \ yd_<CODE> \ publish
;;--------------------------------------------------------------------------
(setq *YP-YARD-MAP*
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
;; These exist specifically to handle the "different users, different
;; path styles" problem:
;;   - Local drive      J:\Folder\Sub
;;   - Mapped drive      Z:\Folder\Sub
;;   - UNC server path   \\server\share\Folder\Sub
;;   - Forward slashes   J:/Folder/Sub   (rare, but some users paste these)
;; All internal joins use backslash, and we normalize/clean any path
;; that gets built or read so double slashes, trailing slashes, or
;; forward slashes do not break file/dir operations.
;;==========================================================================

;; Replace every forward slash with a backslash (Windows-safe)
(defun yp-slashfix (s / out i ch)
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
(defun yp-collapse-slashes (s / unc body out i ch prev)
  (setq unc "")
  (setq body s)
  ;; preserve UNC leading double backslash
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
(defun yp-strip-trailing-slash (s)
  (if (and (> (strlen s) 0)
           (member (substr s (strlen s) 1) '("\\" "/")))
    (substr s 1 (1- (strlen s)))
    s
  )
)

;; Full normalize: fix slash direction, collapse doubles, strip trailing
(defun yp-normpath (s)
  (yp-strip-trailing-slash (yp-collapse-slashes (yp-slashfix s)))
)

;; Join path parts with a single backslash between them, normalizing
;; the final result. Accepts any number of string args via a list.
(defun yp-pathjoin (parts / result)
  (setq result "")
  (foreach p parts
    (setq p (yp-strip-trailing-slash (yp-slashfix p)))
    (setq result
      (if (= result "")
        p
        (strcat result "\\" p)
      )
    )
  )
  (yp-normpath result)
)

;;==========================================================================
;; FOLDER / FILE HELPERS
;;==========================================================================

;; Recursively create a folder path, one level at a time.
;; vl-mkdir fails if the parent doesn't exist, so we walk up from root.
(defun yp-mkdir-p (path / parts cur i unc rest)
  (setq path (yp-normpath path))
  (setq unc "")
  (setq rest path)
  (if (= (substr path 1 2) "\\\\")
    (progn
      (setq unc "\\\\")
      (setq rest (substr path 3))
    )
  )
  (setq parts (yp-strsplit rest "\\"))
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
(defun yp-strsplit (s delim / result pos)
  (setq result '())
  (while (setq pos (vl-string-search delim s))
    (setq result (append result (list (substr s 1 pos))))
    (setq s (substr s (+ pos 1 (strlen delim))))
  )
  (if (/= s "") (setq result (append result (list s))))
  result
)

;; Build YYYYMMDD_HHMMSS from the current system clock
(defun yp-timestamp ( / dt y mo d h mi sec)
  (setq dt (rtos (getvar "CDATE") 2 6))
  ;; CDATE format: YYYYMMDD.HHMMSSssssss  -- parse via substr on the
  ;; fixed-width string representation to avoid locale/decimal issues.
  (setq dt (rtos (getvar "CDATE") 2 6))
  (setq y  (substr dt 1 4))
  (setq mo (substr dt 5 2))
  (setq d  (substr dt 7 2))
  (setq h  (substr dt 10 2))
  (setq mi (substr dt 12 2))
  (setq sec (substr dt 14 2))
  (strcat y mo d "_" h mi sec)
)

;; Return file name without path, WITH extension
(defun yp-filename-only (fullpath)
  (vl-filename-base fullpath)
)

;; Return file extension WITHOUT the dot, e.g. "dwg"
(defun yp-fileext-only (fullpath)
  (vl-filename-extension fullpath)  ;; returns ".dwg" (with dot) in most builds
)

;; Append one line of text to a log file, creating it if needed
(defun yp-log-line (logpath line / f)
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

;;==========================================================================
;; DIALOG: show yard list, return selected CODE string or nil if cancelled
;;==========================================================================
(defun yp-show-dialog ( / dcl_id codes result sel dclfile)
  (setq dclfile (yp-pathjoin (list *YP-LSP-DIR* "YardPublish.dcl")))
  (if (not (findfile dclfile))
    (progn
      (princ (strcat "\nERROR: Cannot find YardPublish.dcl at: " dclfile))
      (princ "\nMake sure YardPublish.dcl is in the same folder as YardPublish.lsp.")
      nil
    )
    (progn
      (setq codes '())
      (foreach pair *YP-YARD-MAP*
        (setq codes (append codes (list (car pair))))
      )
      (setq dcl_id (load_dialog dclfile))
      (if (not (new_dialog "yard_publish_dlg" dcl_id))
        (progn
          (princ "\nERROR: Could not load dialog yard_publish_dlg.")
          (unload_dialog dcl_id)
          nil
        )
        (progn
          (start_list "yard_list")
          (mapcar 'add_list codes)
          (end_list)
          (set_tile "yard_list" "0")
          (set_tile "target_preview"
            (strcat "Target: " (yp-preview-path (car codes))))

          (action_tile "yard_list" "(yp-update-preview)")

          (setq result nil)
          (action_tile "accept" "(setq result (yp-selected-code)) (done_dialog 1)")
          (action_tile "cancel" "(done_dialog 0)")

          (setq sel (start_dialog))
          (unload_dialog dcl_id)
          (if (= sel 1) result nil)
        )
      )
    )
  )
)

;; Helper used inside DCL action_tile callbacks: list of codes in display order
(defun yp-code-list ( / codes)
  (setq codes '())
  (foreach pair *YP-YARD-MAP*
    (setq codes (append codes (list (car pair))))
  )
  codes
)

;; Helper used inside DCL action_tile callback: currently highlighted code
(defun yp-selected-code ( / idx codes)
  (setq idx (atoi (get_tile "yard_list")))
  (setq codes (yp-code-list))
  (nth idx codes)
)

;; Called from the DCL list_box action_tile when selection changes.
;; Updates the "target_preview" text tile to show the resolved folder.
(defun yp-update-preview ( / code)
  (setq code (yp-selected-code))
  (if code
    (set_tile "target_preview" (strcat "Target: " (yp-preview-path code)))
  )
)

;; Build a short human-readable preview of the target folder for a code
(defun yp-preview-path (code / seg)
  (setq seg (cdr (assoc code *YP-YARD-MAP*)))
  (if seg
    (yp-pathjoin (list seg "dwg" "yard" (strcat "yd_" code) "publish"))
    "(unknown)"
  )
)

;;==========================================================================
;; MAIN COMMAND
;;==========================================================================
(defun c:YARDPUBLISH ( / code seg targetfolder srcpath srcname srcext
                          stamp newname destpath docobj rootnorm logpath
                          logline ok fnresult)

  (setq docobj (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq fnresult (vl-catch-all-apply 'vla-get-FullName (list docobj)))
  (setq srcpath
    (if (vl-catch-all-error-p fnresult) "" fnresult))

  (if (or (= srcpath "") (not srcpath))
    (progn
      (princ "\nYARDPUBLISH: Current drawing has never been saved. Save it first with a real file name, then run YARDPUBLISH again.")
      (princ)
    )
    (progn
      (setq code (yp-show-dialog))
      (if (not code)
        (progn (princ "\nYARDPUBLISH: Cancelled.") (princ))
        (progn
          (setq seg (cdr (assoc code *YP-YARD-MAP*)))
          (if (not seg)
            (progn
              (princ (strcat "\nYARDPUBLISH: No folder mapping found for code: " code))
              (princ)
            )
            (progn
              ;; ---- 1) Save current drawing (current file stays open) ----
              (princ "\nYARDPUBLISH: Saving current drawing...")
              (command "_.QSAVE")

              ;; Re-read path/name AFTER save in case it changed (it shouldn't, but safe)
              (setq fnresult (vl-catch-all-apply 'vla-get-FullName (list docobj)))
              (setq srcpath (if (vl-catch-all-error-p fnresult) srcpath fnresult))
              (setq srcname (yp-filename-only srcpath))
              (setq srcext  (yp-fileext-only srcpath)) ;; includes leading dot, e.g. ".dwg"
              (if (not srcext) (setq srcext ".dwg"))

              ;; ---- 2) Build normalized target folder path ----
              (setq rootnorm (yp-normpath *YP-ROOT-PATH*))
              (setq targetfolder
                (yp-pathjoin (list rootnorm seg "dwg" "yard" (strcat "yd_" code) "publish")))

              ;; ---- 3) Auto-create folder if missing ----
              (if (not (vl-file-directory-p targetfolder))
                (progn
                  (princ (strcat "\nYARDPUBLISH: Creating folder: " targetfolder))
                  (yp-mkdir-p targetfolder)
                )
              )

              (if (not (vl-file-directory-p targetfolder))
                (progn
                  (princ (strcat "\nYARDPUBLISH ERROR: Could not create or access target folder:\n  "
                                  targetfolder
                                  "\nCheck that the root path is correct and the drive/server is connected."))
                  (princ)
                )
                (progn
                  ;; ---- 4) Build timestamped destination filename ----
                  (setq stamp (yp-timestamp))
                  (setq newname (strcat stamp "_" srcname srcext))
                  (setq destpath (yp-pathjoin (list targetfolder newname)))

                  ;; ---- 5) Copy file ----
                  (if (vl-file-copy srcpath destpath)
                    (progn
                      (princ (strcat "\nYARDPUBLISH: Published successfully.\n  From: "
                                      srcpath "\n  To:   " destpath))

                      ;; ---- 6) Append to log CSV (best effort, never blocks) ----
                      (setq logpath (yp-pathjoin (list rootnorm "publish_log.csv")))
                      (setq logline
                        (strcat (yp-timestamp) ","
                                (getvar "LOGINNAME") ","
                                code ","
                                srcname srcext ","
                                srcpath ","
                                destpath))
                      (setq ok (yp-log-line logpath logline))
                      (if (not ok)
                        (princ "\nYARDPUBLISH: Note - could not write to publish_log.csv (non-fatal).")
                      )
                    )
                    (progn
                      (princ (strcat "\nYARDPUBLISH ERROR: File copy failed.\n  From: "
                                      srcpath "\n  To:   " destpath))
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
(defun c:PUBLISH () (c:YARDPUBLISH))

(princ "\nYardPublish loaded. Type YARDPUBLISH or PUBLISH to run.")
(princ)
