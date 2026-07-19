;; ============================================
;; BANK CUTTING TOOL v11
;; Command: SBC
;; Changes from v10:
;;   1. Block insert rotation + 90 degrees (pi/2) added
;;      Rotation = center → foot angle + 90°
;; Changes from v9:
;;   1. DCL embedded in LSP (write_dcl method) - no external .dcl needed
;;   2. Distance pick → insert at COGO center point directly
;;      Rotation = center → foot angle
;;   3. PICK ME → foot + *BC_OFFSET* towards click (unchanged)
;;   4. *BC_OFFSET* global (default 3.0) - SETBCOFFSET command
;;   5. Show distance label = optional toggle (*BC_SHOW_DIST*)
;; ============================================

;; ── WRITE DCL TO TEMP FILE ──────────────────
(defun BC-write-dcl ( / dcl_file dcl_path)
  (setq dcl_path (strcat (getenv "TEMP") "\\bank_cutting_v10.dcl"))
  (setq dcl_file (open dcl_path "w"))
  (write-line "bank_cutting : dialog {" dcl_file)
  (write-line "  label = \"Bank Cutting v10\";" dcl_file)
  (write-line "  : row {" dcl_file)
  (write-line "    : text { key = \"height_lbl\"; label = \"H:\"; width = 2; }" dcl_file)
  (write-line "    : text { key = \"height_val\"; label = \"\"; width = 8; }" dcl_file)
  (write-line "    : button { key = \"btn_height\"; label = \"Pick H\"; width = 10; }" dcl_file)
  (write-line "  }" dcl_file)
  (write-line "  : row {" dcl_file)
  (write-line "    : text { key = \"dist_lbl\"; label = \"D:\"; width = 2; }" dcl_file)
  (write-line "    : text { key = \"dist_val\"; label = \"\"; width = 8; }" dcl_file)
  (write-line "    : button { key = \"btn_dist\"; label = \"Pick D\"; width = 10; is_enabled = false; }" dcl_file)
  (write-line "  }" dcl_file)
  (write-line "  spacer;" dcl_file)
  (write-line "  : row {" dcl_file)
  (write-line "    : text { key = \"offset_lbl\"; label = \"Offset (m):\"; width = 10; }" dcl_file)
  (write-line "    : text { key = \"offset_val\"; label = \"3.00\"; width = 6; }" dcl_file)
  (write-line "    : button { key = \"btn_offset\"; label = \"Set Offset\"; width = 12; }" dcl_file)
  (write-line "  }" dcl_file)
  (write-line "  : toggle { key = \"chk_showdist\"; label = \"Show Distance Label\"; }" dcl_file)
  (write-line "  spacer;" dcl_file)
  (write-line "  : row {" dcl_file)
  (write-line "    : button { key = \"btn_up\";     label = \"UP\";      width = 8;  is_enabled = false; }" dcl_file)
  (write-line "    : button { key = \"btn_dn\";     label = \"DN\";      width = 8;  is_enabled = false; }" dcl_file)
  (write-line "    : button { key = \"btn_pickme\"; label = \"PICK ME\"; width = 12; is_enabled = false; }" dcl_file)
  (write-line "  }" dcl_file)
  (write-line "  spacer;" dcl_file)
  (write-line "  : text { key = \"status_lbl\"; label = \"Ready\"; width = 40; }" dcl_file)
  (write-line "  spacer;" dcl_file)
  (write-line "  cancel_button;" dcl_file)
  (write-line "}" dcl_file)
  (close dcl_file)
  dcl_path
)

;; ── GLOBALS INIT ────────────────────────────
(if (not (boundp '*BC_LAST_DIR*))  (setq *BC_LAST_DIR*  nil))
(if (not (boundp '*BC_OFFSET*))    (setq *BC_OFFSET*    3.0))
(if (not (boundp '*BC_SHOW_DIST*)) (setq *BC_SHOW_DIST* 1))

;; ── SET OFFSET COMMAND ──────────────────────
(defun C:SETBCOFFSET ( / val)
  (setq val (getreal (strcat "\nCurrent offset: " (rtos *BC_OFFSET* 2 2)
                             "\nNew offset value (metres): ")))
  (if (and val (> val 0))
    (progn
      (setq *BC_OFFSET* val)
      (prompt (strcat "\nBC Offset set to: " (rtos *BC_OFFSET* 2 2) "m"))
    )
    (prompt "\nCancelled - offset unchanged.")
  )
  (princ)
)

;; ============================================
;; MAIN COMMAND
;; ============================================
(defun C:SBC ( / dcl_path dcl_id result ready
               h_val d_val h_positive last_dir
               p1 p2 mtext1 mtext2 etype1 etype2 n1 n2 diff
               pt_sel pt_ent pt_type pt_coord center_pt
               pline_sel pline_ent pline_type pline_obj
               foot_pt_3d foot_pt dist
               pick_pt pick_foot_3d pick_foot
               status_str _ov)

  (setq h_val      ""
        d_val      ""
        h_positive nil
        last_dir   nil)

  (setq dcl_path (BC-write-dcl))
  (setq dcl_id   (load_dialog dcl_path))
  (if (< dcl_id 0) (progn (alert "DCL load failed!") (exit)))

  (setq result -1)

  (while (not (= result 0))

    (if (not (new_dialog "bank_cutting" dcl_id))
      (progn (alert "Dialog open failed!") (exit))
    )

    (set_tile "height_val"   h_val)
    (set_tile "dist_val"     d_val)
    (set_tile "offset_val"   (rtos *BC_OFFSET* 2 2))
    (set_tile "chk_showdist" (itoa *BC_SHOW_DIST*))

    (mode_tile "btn_dist" (if h_positive 0 1))

    (setq ready (or (= h_val "LG")
                    (and h_positive (not (= d_val "")))))

    (mode_tile "btn_up"     (if ready 0 1))
    (mode_tile "btn_dn"     (if ready 0 1))
    (mode_tile "btn_pickme" (if (and ready *BC_LAST_DIR*) 0 1))

    (setq status_str
      (cond
        ((and ready *BC_LAST_DIR*)
          (strcat "Ready! Dir=" *BC_LAST_DIR* " Offset=" (rtos *BC_OFFSET* 2 2) "m"))
        (ready "UP or DN press pannu")
        (h_positive "Pick D pannunga")
        (T "Pick H pannunga")
      )
    )
    (set_tile "status_lbl" status_str)

    (action_tile "btn_height"   "(done_dialog 1)")
    (action_tile "btn_dist"     "(done_dialog 2)")
    (action_tile "btn_offset"   "(done_dialog 3)")
    (action_tile "chk_showdist" "(setq *BC_SHOW_DIST* (atoi $value))")
    (action_tile "btn_up"       "(done_dialog 5)")
    (action_tile "btn_dn"       "(done_dialog 6)")
    (action_tile "btn_pickme"   "(done_dialog 8)")
    (action_tile "cancel"       "(done_dialog 0)")

    (setq result (start_dialog))

    (cond

      ;; ── HEIGHT PICK ──────────────────────────────
      ((= result 1)
        (prompt "\nFirst TEXT/MTEXT select pannunga (BE or FT): ")
        (setq p1 (entsel))
        (if p1 (progn
          (prompt "\nSecond TEXT/MTEXT select pannunga (TOE or GL): ")
          (setq p2 (entsel))
        ))
        (if (and p1 p2)
          (progn
            (setq mtext1 (car p1) mtext2 (car p2))
            (setq etype1 (cdr (assoc 0 (entget mtext1))))
            (setq etype2 (cdr (assoc 0 (entget mtext2))))
            (if (not (or (= etype1 "MTEXT") (= etype1 "TEXT")))
              (alert "First entity TEXT or MTEXT ah irukkanum!")
              (if (not (or (= etype2 "MTEXT") (= etype2 "TEXT")))
                (alert "Second entity TEXT or MTEXT ah irukkanum!")
                (progn
                  (setq n1 (atof (cdr (assoc 1 (entget mtext1)))))
                  (setq n2 (atof (cdr (assoc 1 (entget mtext2)))))
                  (setq diff (- n1 n2))
                  (if (>= diff 0)
                    (progn
                      (setq h_val (rtos diff 2 2) h_positive T d_val "")
                      (prompt (strcat "\nHeight: " h_val " OK"))
                    )
                    (progn
                      (setq h_val "LG" h_positive nil d_val "")
                      (prompt "\nHeight negative -> H-LG")
                    )
                  )
                )
              )
            )
          )
          (prompt "\nCancelled.")
        )
        (setq result -1)
      )

      ;; ── DISTANCE PICK ────────────────────────────
      ;; COGO point select → polyline select → distance calculate
      ;; *BC_CLICK_PT* = center_pt  (insert point = center pt)
      ;; *BC_FOOT_PT*  = foot pt    (for rotation angle)
      ((= result 2)
        (prompt "\nPOINT entity select pannunga (COGO / AutoCAD Point): ")
        (setq pt_sel (entsel))
        (if pt_sel
          (progn
            (setq pt_ent  (car pt_sel))
            (setq pt_type (cdr (assoc 0 (entget pt_ent))))
            (if (or (= pt_type "POINT")
                    (wcmatch pt_type "*COGO*")
                    (wcmatch pt_type "*AECCDB*"))
              (progn
                (setq pt_coord  (cdr (assoc 10 (entget pt_ent))))
                (setq center_pt (list (car pt_coord) (cadr pt_coord) 0.0))
                (prompt (strcat "\nPoint: "
                  (rtos (car center_pt) 2 3) ", "
                  (rtos (cadr center_pt) 2 3) " OK"))
                (prompt "\nPolyline select pannunga: ")
                (setq pline_sel (entsel))
                (if pline_sel
                  (progn
                    (setq pline_ent  (car pline_sel))
                    (setq pline_type (cdr (assoc 0 (entget pline_ent))))
                    (if (or (= pline_type "LWPOLYLINE")
                            (= pline_type "POLYLINE")
                            (= pline_type "LINE"))
                      (progn
                        (setq pline_obj  (vlax-ename->vla-object pline_ent))
                        (setq foot_pt_3d (vlax-curve-getClosestPointTo pline_obj center_pt))
                        (setq foot_pt    (list (car foot_pt_3d) (cadr foot_pt_3d) 0.0))
                        (setq dist (distance center_pt foot_pt))
                        (setq d_val (rtos dist 2 2))
                        (setq *BC_CENTER_PT* center_pt)
                        (setq *BC_FOOT_PT*   foot_pt)
                        (setq *BC_PLINE_OBJ* pline_obj)
                        ;; KEY: click_pt = center_pt so BC-do-insert places block here
                        (setq *BC_CLICK_PT*  center_pt)
                        (prompt (strcat "\nDistance: " d_val " OK"))
                        (prompt "\nUP or DN press pannunga - block insert aagum!")
                      )
                      (alert "LWPOLYLINE, POLYLINE or LINE select pannunga!")
                    )
                  )
                  (prompt "\nCancelled.")
                )
              )
              (alert "POINT entity select pannunga!")
            )
          )
          (prompt "\nCancelled.")
        )
        (setq result -1)
      )

      ;; ── SET OFFSET ───────────────────────────────
      ((= result 3)
        (prompt (strcat "\nCurrent offset: " (rtos *BC_OFFSET* 2 2) "m"))
        (setq _ov (getreal "\nNew offset value (metres): "))
        (if (and _ov (> _ov 0))
          (progn
            (setq *BC_OFFSET* _ov)
            (prompt (strcat "\nOffset set: " (rtos *BC_OFFSET* 2 2) "m OK"))
          )
          (prompt "\nCancelled - offset unchanged.")
        )
        (setq result -1)
      )

      ;; ── UP ───────────────────────────────────────
      ;; If *BC_CLICK_PT* set (from Distance pick) → insert immediately at center pt
      ;; else → set direction, wait for PICK ME
      ((= result 5)
        (setq last_dir "UP" *BC_LAST_DIR* "UP")
        (prompt "\nDirection: UP")
        (if (and (boundp '*BC_CLICK_PT*) *BC_CLICK_PT*
                 (boundp '*BC_FOOT_PT*)  *BC_FOOT_PT*)
          (progn
            (BC-do-insert h_val d_val "UP")
            (setq h_val "" d_val "" h_positive nil last_dir nil)
            (setq *BC_LAST_DIR* nil)
            (setq *BC_CENTER_PT* nil *BC_FOOT_PT* nil *BC_CLICK_PT* nil)
            (prompt "\nInserted at COGO point! Values cleared.")
          )
          (prompt " set! PICK ME press pannu.")
        )
        (setq result -1)
      )

      ;; ── DN ───────────────────────────────────────
      ;; Same - insert immediately if COGO point set
      ((= result 6)
        (setq last_dir "DN" *BC_LAST_DIR* "DN")
        (prompt "\nDirection: DN")
        (if (and (boundp '*BC_CLICK_PT*) *BC_CLICK_PT*
                 (boundp '*BC_FOOT_PT*)  *BC_FOOT_PT*)
          (progn
            (BC-do-insert h_val d_val "DN")
            (setq h_val "" d_val "" h_positive nil last_dir nil)
            (setq *BC_LAST_DIR* nil)
            (setq *BC_CENTER_PT* nil *BC_FOOT_PT* nil *BC_CLICK_PT* nil)
            (prompt "\nInserted at COGO point! Values cleared.")
          )
          (prompt " set! PICK ME press pannu.")
        )
        (setq result -1)
      )

      ;; ── PICK ME ──────────────────────────────────
      ;; Manual click mode: foot + *BC_OFFSET* towards click = insert point
      ((= result 8)
        (prompt (strcat "\nClick pannunga - foot point irundhu click pakkam "
                        (rtos *BC_OFFSET* 2 2) "m-la block varum: "))
        (setq pick_pt (getpoint))
        (if pick_pt
          (progn
            (if (and (boundp '*BC_PLINE_OBJ*) *BC_PLINE_OBJ*)
              (progn
                (setq click_3d     (list (car pick_pt) (cadr pick_pt) 0.0))
                (setq pick_foot_3d (vlax-curve-getClosestPointTo *BC_PLINE_OBJ* click_3d))
                (setq pick_foot    (list (car pick_foot_3d) (cadr pick_foot_3d) 0.0))
                (setq *BC_CLICK_PT* click_3d)
                (setq *BC_FOOT_PT*  pick_foot)
                (BC-do-insert h_val d_val "PICKME")
                (setq h_val "" d_val "" h_positive nil last_dir nil)
                (setq *BC_LAST_DIR* nil)
                (setq *BC_CENTER_PT* nil *BC_FOOT_PT* nil *BC_CLICK_PT* nil)
                (prompt "\nInserted! Values cleared - next block ready!")
              )
              (alert "First Distance pick pannunga - polyline set aaganum!")
            )
          )
          (prompt "\nCancelled.")
        )
        (setq result -1)
      )

      ;; ── CLOSE ────────────────────────────────────
      ((= result 0)
        (prompt "\nBank Cutting closed.")
      )
    )
  )

  (unload_dialog dcl_id)
  (princ)
)

;; ============================================
;; INSERT BLOCK
;; ============================================
(defun BC-do-insert (h_val d_val direction /
                      blk_dir block_name insert_pt
                      dx dy mag
                      h_str d_str
                      rot_angle
                      ent_before blk_ent ss2 ent_cur etype)

  (setq blk_dir (cond
    ((= direction "PICKME") (if (boundp '*BC_LAST_DIR*) *BC_LAST_DIR* "UP"))
    (T direction)
  ))

  (setq block_name (cond
    ((and (= blk_dir "UP") (not (= h_val "LG"))) "bank_cutting_up")
    ((and (= blk_dir "DN") (not (= h_val "LG"))) "bank_cutting_dn")
    ((and (= blk_dir "UP") (= h_val "LG"))        "bank_cutting_up_lg")
    ((and (= blk_dir "DN") (= h_val "LG"))        "bank_cutting_dn_lg")
  ))

  (if (not (tblsearch "BLOCK" block_name))
    (BC-create-block block_name)
  )

  ;; ── INSERT POINT ──────────────────────────────
  ;; UP/DN (after Distance pick): insert at *BC_CLICK_PT* = center_pt
  ;; PICKME: foot + *BC_OFFSET* towards click
  (if (and (boundp '*BC_CLICK_PT*) *BC_CLICK_PT*
           (boundp '*BC_FOOT_PT*)  *BC_FOOT_PT*)
    (progn
      (if (= direction "PICKME")
        (progn
          ;; foot → click direction, offset from foot
          (setq dx  (- (car  *BC_CLICK_PT*) (car  *BC_FOOT_PT*)))
          (setq dy  (- (cadr *BC_CLICK_PT*) (cadr *BC_FOOT_PT*)))
          (setq mag (sqrt (+ (* dx dx) (* dy dy))))
          (if (> mag 0.0001)
            (progn (setq dx (/ dx mag)) (setq dy (/ dy mag)))
            (progn (setq dx 0.0)        (setq dy 1.0))
          )
          (setq insert_pt (list
            (+ (car  *BC_FOOT_PT*) (* *BC_OFFSET* dx))
            (+ (cadr *BC_FOOT_PT*) (* *BC_OFFSET* dy))
            0.0))
        )
        (progn
          ;; UP/DN: insert directly at COGO center point
          (setq insert_pt (list
            (car  *BC_CLICK_PT*)
            (cadr *BC_CLICK_PT*)
            0.0))
        )
      )
    )
    (progn
      (prompt "\nInsert point manual select pannunga: ")
      (setq insert_pt (getpoint))
    )
  )

  (if (not insert_pt) (progn (prompt "\nInsert cancelled.") (exit)))

  (setq h_str (if (= h_val "LG") "H-LG" (strcat "H-" h_val)))
  (setq d_str (if (= h_val "LG") nil     (strcat "D-" d_val)))

  ;; ── ROTATION ──────────────────────────────────
  ;; center → foot vector = block rotation (faces slope)
  ;; + 90 degrees (pi/2) offset added for correct orientation
  (setq rot_angle 0.0)
  (if (and (boundp '*BC_CLICK_PT*) *BC_CLICK_PT*
           (boundp '*BC_FOOT_PT*)  *BC_FOOT_PT*)
    (progn
      (setq rot_angle (angle
        (list (car *BC_CLICK_PT*) (cadr *BC_CLICK_PT*) 0.0)
        (list (car *BC_FOOT_PT*)  (cadr *BC_FOOT_PT*)  0.0)))
      (setq rot_angle (+ rot_angle (/ pi 2.0)))  ;; 90 degree rotate
      (if (= blk_dir "DN")
        (setq rot_angle (+ rot_angle pi))
      )
    )
  )

  ;; ── ENTMAKE INSERT ────────────────────────────
  (setq ent_before (entlast))

  (if (not (entmake (list
    (cons 0   "INSERT")
    (cons 100 "AcDbEntity")
    (cons 8   "1-BANK CUTTING")
    (cons 100 "AcDbBlockReference")
    (cons 2   block_name)
    (cons 10  (list (car insert_pt) (cadr insert_pt) 0.0))
    (cons 41  1.0) (cons 42 1.0) (cons 43 1.0)
    (cons 50  rot_angle)
  )))
    (progn (alert "entmake INSERT FAILED!") (exit))
  )

  ;; ── EXPLODE ───────────────────────────────────
  (setq blk_ent (entlast))
  (if (and blk_ent (= (cdr (assoc 0 (entget blk_ent))) "INSERT"))
    (command "._EXPLODE" blk_ent "")
    (alert "Explode failed!")
  )

  ;; ── TEXT REPLACE ──────────────────────────────
  (setq ss2 (ssadd))
  (setq ent_cur (if ent_before (entnext ent_before) (entnext)))
  (while ent_cur
    (setq etype (cdr (assoc 0 (entget ent_cur))))
    (if (or (= etype "TEXT") (= etype "MTEXT"))
      (ssadd ent_cur ss2)
    )
    (setq ent_cur (entnext ent_cur))
  )

  (if (> (sslength ss2) 0)
    (progn
      (BC-replace-text ss2 "H-0.00" h_str)
      (if d_str
        (if (= *BC_SHOW_DIST* 1)
          (BC-replace-text ss2 "D-0.00" d_str)
          (BC-delete-text  ss2 "D-0.00")
        )
        (BC-delete-text ss2 "D-0.00")
      )
      (prompt "\nBank Cutting block inserted! OK")
    )
    (prompt "\nWarning: Block inserted but text not found.")
  )
)

;; ============================================
;; CREATE BLOCK (from bc.dxf - replaced)
;; ============================================
(defun BC-create-block (bname / knots cpts)

  (setq knots (list 0 0 0 0 10.08453945767035 18.50469869594143 25.30291761361675 30.54339124591493 34.74349876778776 37.45033649523087 39.05364180500556 40.05028483968155 40.05028483968155 40.05028483968155 40.05028483968155))

  (cond
    ((= bname "bank_cutting_up")
      (setq cpts (list
        (list -5.271450595620308 0.146656780036778 0.0)
        (list 0.87374858383555 -0.034991525854139 0.0)
        (list 12.14992634220039 -0.368308464546317 0.0)
        (list -10.88054205813728 1.908136378793642 0.0)
        (list 9.30554790281144 0.899770236899258 0.0)
        (list -6.674415462570095 3.151200564663099 0.0)
        (list 5.819706994302805 2.177710108343717 0.0)
        (list -2.089974102247197 3.904503719069111 0.0)
        (list 2.007558298971162 3.352151684718023 0.0)
        (list 1.124585854597626 4.192095493899046 0.0)
        (list 0.786114421280899 4.514072732950353 0.0)
      ))
    )
    ((= bname "bank_cutting_dn")
      (setq cpts (list
        (list 5.299076975850084 -0.147315118192864 0.0)
        (list -0.846122203606228 0.034333187697712 0.0)
        (list -12.12229996197015 0.367650126389208 0.0)
        (list 10.90816843836705 -1.908794716949273 0.0)
        (list -9.277921522581437 -0.900428575056139 0.0)
        (list 6.702041842799644 -3.151858902819526 0.0)
        (list -5.792080614073029 -2.178368446499803 0.0)
        (list 2.1176004824772 -3.905162057225879 0.0)
        (list -1.979931918741158 -3.352810022874336 0.0)
        (list -1.096959474367622 -4.192753832055473 0.0)
        (list -0.758488041050896 -4.51473107110678 0.0)
      ))
    )
    ((= bname "bank_cutting_up_lg")
      (setq cpts (list
        (list 5.301005621748572 -0.14736100098537 0.0)
        (list -0.844193557707285 0.034287304905206 0.0)
        (list -12.12037131607167 0.367604243596588 0.0)
        (list 10.91009708426554 -1.908840599741779 0.0)
        (list -9.275992876682722 -0.900474457848645 0.0)
        (list 6.703970488697905 -3.151904785611804 0.0)
        (list -5.790151968174768 -2.178414329292309 0.0)
        (list 2.119529128376143 -3.905207940018499 0.0)
        (list -1.97800327284267 -3.352855905666729 0.0)
        (list -1.095030828469134 -4.192799714847978 0.0)
        (list -0.756559395152408 -4.514776953899286 0.0)
      ))
    )
    ((= bname "bank_cutting_dn_lg")
      (setq cpts (list
        (list -5.271450595620535 0.146656780036437 0.0)
        (list 0.873748583835322 -0.034991525854252 0.0)
        (list 12.1499263421997 -0.368308464545976 0.0)
        (list -10.88054205813751 1.908136378792846 0.0)
        (list 9.305547902811213 0.899770236899712 0.0)
        (list -6.67441546257055 3.151200564662758 0.0)
        (list 5.819706994303714 2.177710108344058 0.0)
        (list -2.089974102248561 3.904503719068884 0.0)
        (list 2.007558298970707 3.352151684718023 0.0)
        (list 1.124585854597171 4.192095493899046 0.0)
        (list 0.786114421280445 4.514072732950353 0.0)
      ))
    )
  )

  (entmake (list (cons 0 "BLOCK") (cons 2 bname) (cons 70 0) (cons 10 (list 0.0 0.0 0.0))))

  (entmake (append
    (list
      (cons 0 "SPLINE") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
      (cons 100 "AcDbSpline") (cons 210 (list 0.0 0.0 1.0))
      (cons 70 1064) (cons 71 3) (cons 72 15) (cons 73 11) (cons 74 0)
      (cons 42 0.000000001) (cons 43 0.0000000001)
    )
    (mapcar (function (lambda (k) (cons 40 k))) knots)
    (apply (function append)
      (mapcar (function (lambda (p) (list (cons 10 p)))) cpts)
    )
  ))

  (cond
    ((= bname "bank_cutting_up")
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list -0.046180084606249 -1.946914994069288 0.0))
        (cons 40 1.75) (cons 41 7.080390915559914) (cons 71 5) (cons 72 5) (cons 1 "H-0.00") (cons 73 1) (cons 44 1.0)))
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list -0.015701285770774 6.422633372707764 0.0))
        (cons 40 1.75) (cons 41 7.195188719232315) (cons 71 5) (cons 72 5) (cons 1 "D-0.00") (cons 73 1) (cons 44 1.0)))
    )
    ((= bname "bank_cutting_dn")
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list 0.012848867165531 1.946256655912861 0.0))
        (cons 40 1.75) (cons 41 7.080390915559914) (cons 71 5) (cons 72 5) (cons 1 "H-0.00") (cons 73 1) (cons 44 1.0)))
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list 0.043327666001005 -6.423291710864191 0.0))
        (cons 40 1.75) (cons 41 7.195188719232315) (cons 71 5) (cons 72 5) (cons 1 "D-0.00") (cons 73 1) (cons 44 1.0)))
    )
    ((= bname "bank_cutting_up_lg")
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list 0.014777513064018 1.946210773120355 0.0))
        (cons 40 1.75) (cons 41 7.080390915559914) (cons 71 5) (cons 72 5) (cons 1 "H-LG") (cons 73 1) (cons 44 1.0)))
    )
    ((= bname "bank_cutting_dn_lg")
      (entmake (list (cons 0 "MTEXT") (cons 100 "AcDbEntity") (cons 8 "1-BANK CUTTING")
        (cons 100 "AcDbMText") (cons 10 (list 0.014777513064018 -1.946914994069288 0.0))
        (cons 40 1.75) (cons 41 7.080390915559914) (cons 71 5) (cons 72 5) (cons 1 "H-LG") (cons 73 1) (cons 44 1.0)))
    )
  )

  (entmake (list (cons 0 "ENDBLK")))
  (princ (strcat "\nBlock created: " bname))
)

;; ============================================
;; REPLACE TEXT
;; ============================================
(defun BC-replace-text (ss find_str replace_str / i ent ed txt)
  (setq i 0)
  (while (< i (sslength ss))
    (setq ent (ssname ss i))
    (setq ed  (entget ent))
    (setq txt (cdr (assoc 1 ed)))
    (if (and txt (= txt find_str))
      (progn
        (setq ed (subst (cons 1 replace_str) (assoc 1 ed) ed))
        (entmod ed) (entupd ent)
      )
    )
    (setq i (1+ i))
  )
)

;; ============================================
;; DELETE TEXT
;; ============================================
(defun BC-delete-text (ss find_str / i ent ed txt)
  (setq i 0)
  (while (< i (sslength ss))
    (setq ent (ssname ss i))
    (setq ed  (entget ent))
    (setq txt (cdr (assoc 1 ed)))
    (if (and txt (= txt find_str))
      (entdel ent)
    )
    (setq i (1+ i))
  )
)

;; ============================================
(prompt "\nBank Cutting Tool v11 loaded. [Block insert: +90 deg rotation]")
(prompt "\n  SBC          - Run tool")
(prompt "\n  SETBCOFFSET  - Change PICKME offset (current: ")
(prompt (rtos *BC_OFFSET* 2 2))
(prompt "m)")
(princ)
