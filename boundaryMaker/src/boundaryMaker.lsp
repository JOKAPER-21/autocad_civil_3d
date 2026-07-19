;; ============================================================
;; Civil 3D - Combined Tool v6.0
;; Fix: (exit) and (return) removed → flag-based exit
;; Fix: All objects → layer "1-BOUNDARY" (auto-created)
;; Command: BM → auto runs JOINCOLORLINES after
;; ============================================================

(defun c:BM ( / pl_ent pl_obj start_ch csv_file csv_data
                           left_pts right_pts *cancelled* *error*)

  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (prompt (strcat "\nError: " msg))
    )
    (princ)
  )

  (vl-load-com)
  (setq *cancelled* nil)

  ;; --- Create "1-BOUNDARY" layer if not exists ---
  (CB-CREATE-LAYER "1-BOUNDARY" 7)

  ;; --- STEP 1: Select Polyline ---
  (setq pl_ent (car (entsel "\nPolyline select pannunga: ")))
  (if (null pl_ent)
    (progn (prompt "\nPolyline select pannalai.") (setq *cancelled* T))
  )

  (if (not *cancelled*)
    (progn
      (setq pl_obj (vlax-ename->vla-object pl_ent))
      (if (not (or (= (cdr (assoc 0 (entget pl_ent))) "LWPOLYLINE")
                   (= (cdr (assoc 0 (entget pl_ent))) "POLYLINE")))
        (progn (prompt "\nSelected object polyline illai!") (setq *cancelled* T))
      )
    )
  )

  ;; --- STEP 2: Starting Chainage ---
  (if (not *cancelled*)
    (progn
      (setq start_ch (getreal "\nStarting Chainage value enter pannunga: "))
      (if (null start_ch) (setq start_ch 0.0))
    )
  )

  ;; --- STEP 3: Select CSV File ---
  (if (not *cancelled*)
    (progn
      (setq csv_file (getfiled "CSV File Select pannunga" "" "csv" 0))
      (if (null csv_file)
        (progn (prompt "\nCSV file select pannalai.") (setq *cancelled* T))
      )
    )
  )

  ;; --- STEP 4: Read CSV ---
  (if (not *cancelled*)
    (progn
      (setq csv_data (CB-READ-CSV csv_file))
      (if (null csv_data)
        (progn (prompt "\nCSV data illai or read error.") (setq *cancelled* T))
        (prompt (strcat "\n" (itoa (length csv_data)) " rows found. Processing..."))
      )
    )
  )

  ;; --- STEP 5: Process rows ---
  (if (not *cancelled*)
    (progn
      (setq left_pts  '())
      (setq right_pts '())
      (foreach row csv_data
        (CB-PROCESS-ROW pl_obj start_ch row)
      )
    )
  )

  ;; --- STEP 6: Left boundary polyline ---
  (if (not *cancelled*)
    (if (> (length left_pts) 1)
      (progn
        (CB-DRAW-POLYLINE left_pts 1 "1-BOUNDARY")
        (prompt (strcat "\n✓ Left (Red) boundary: " (itoa (length left_pts)) " points"))
      )
      (prompt "\n! Left points 2-ku kuraivu - polyline skip")
    )
  )

  ;; --- STEP 7: Right boundary polyline ---
  (if (not *cancelled*)
    (if (> (length right_pts) 1)
      (progn
        (CB-DRAW-POLYLINE right_pts 3 "1-BOUNDARY")
        (prompt (strcat "\n✓ Right (Green) boundary: " (itoa (length right_pts)) " points"))
      )
      (prompt "\n! Right points 2-ku kuraivu - polyline skip")
    )
  )

  ;; --- STEP 8: Summary + Auto JOINCOLORLINES ---
  (if (not *cancelled*)
    (progn
      (prompt "\n")
      (prompt "\n╔══════════════════════════════════╗")
      (prompt "\n║   ✓✓ Boundary Complete!          ║")
      (prompt "\n║   Red   = Left  boundary         ║")
      (prompt "\n║   Green = Right boundary         ║")
      (prompt "\n╚══════════════════════════════════╝")
      (prompt "\n>>> Auto-running JOINCOLORLINES...")
      (CB-JOINCOLORLINES)
    )
  )

  (princ)
)

;; ============================================================
;; JOINCOLORLINES - internal function
;; ============================================================
(defun CB-JOINCOLORLINES ( / ss i ent entdata color pt-list-red pt-list-green endpt)
  (setq ss (ssget "X" '((0 . "LINE"))))
  (if (null ss)
    (prompt "\nJOINCOLORLINES: Drawing-la Line objects illai!")
    (progn
      (setq pt-list-red   '())
      (setq pt-list-green '())
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent     (ssname ss i))
        (setq entdata (entget ent))
        (setq color   (cdr (assoc 62 entdata)))
        (setq endpt   (cdr (assoc 11 entdata)))
        (cond
          ((= color 1)
           (setq pt-list-red (append pt-list-red (list endpt))))
          ((= color 3)
           (setq pt-list-green (append pt-list-green (list endpt))))
        )
        (setq i (1+ i))
      )

      (if (>= (length pt-list-red) 2)
        (progn
          (CB-MAKE-POLYLINE pt-list-red 1)
          (prompt (strcat "\n✓ Red Polyline: " (itoa (length pt-list-red)) " points.")))
        (prompt "\nRed lines: Not enough endpoints (need atleast 2).")
      )

      (if (>= (length pt-list-green) 2)
        (progn
          (CB-MAKE-POLYLINE pt-list-green 3)
          (prompt (strcat "\n✓ Green Polyline: " (itoa (length pt-list-green)) " points.")))
        (prompt "\nGreen lines: Not enough endpoints (need atleast 2).")
      )

      (prompt "\n")
      (prompt "\n╔══════════════════════════════════╗")
      (prompt "\n║   ✓✓ All Done! Both tools done!  ║")
      (prompt "\n╚══════════════════════════════════╝")
    )
  )
)

;; ============================================================
;; Standalone command - JOINCOLORLINES
;; ============================================================
(defun c:JOINCOLORLINES ( / *error*)
  (defun *error* (msg)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (prompt (strcat "\nError: " msg))
    )
    (princ)
  )
  (vl-load-com)
  (CB-CREATE-LAYER "1-BOUNDARY" 7)
  (CB-JOINCOLORLINES)
  (princ)
)

;; ============================================================
;; Create layer if not exists
;; ============================================================
(defun CB-CREATE-LAYER (lname lcolor / layers layer)
  (setq layers (vla-get-layers (vla-get-activedocument (vlax-get-acad-object))))
  (if (not (tblsearch "LAYER" lname))
    (progn
      (setq layer (vla-add layers lname))
      (vla-put-color layer lcolor)
      (prompt (strcat "\n✓ Layer created: " lname))
    )
    (prompt (strcat "\n  Layer already exists: " lname))
  )
)

;; ============================================================
;; Process each row
;; ============================================================
(defun CB-PROCESS-ROW (pl_obj start_ch row
                    / ch lb rb dist pt perp px py pz perpx perpy lpt rpt mid_l mid_r)
  (setq ch   (car row))
  (setq lb   (cadr row))
  (setq rb   (caddr row))
  (setq dist (- ch start_ch))

  (cond
    ((< dist 0.0)
     (prompt (strcat "\nChainage " (rtos ch 2 2) " - skip (dist < 0)")))
    (t
     (setq pt (CB-GET-POINT-AT-DIST pl_obj dist))
     (if (null pt)
       (prompt (strcat "\nChainage " (rtos ch 2 2) " - point illai, skip"))
       (progn
         (setq perp  (CB-GET-PERP-DIR pl_obj dist))
         (setq px    (car pt))
         (setq py    (cadr pt))
         (setq pz    (if (cddr pt) (caddr pt) 0.0))
         (setq perpx (car perp))
         (setq perpy (cadr perp))

         (setq lpt (list (+ px (* perpx lb)) (+ py (* perpy lb)) pz))
         (setq rpt (list (- px (* perpx rb)) (- py (* perpy rb)) pz))

         (if (> (abs lb) 0.0)
           (progn
             (CB-DRAW-LINE pt lpt 1)
             (setq mid_l (list (/ (+ px (car lpt)) 2.0)
                               (/ (+ py (cadr lpt)) 2.0) pz))
             (CB-DRAW-TEXT mid_l (strcat "L=" (rtos lb 2 3)) 1)
             (setq left_pts (append left_pts (list lpt)))
           )
         )

         (if (> (abs rb) 0.0)
           (progn
             (CB-DRAW-LINE pt rpt 3)
             (setq mid_r (list (/ (+ px (car rpt)) 2.0)
                               (/ (+ py (cadr rpt)) 2.0) pz))
             (CB-DRAW-TEXT mid_r (strcat "R=" (rtos rb 2 3)) 3)
             (setq right_pts (append right_pts (list rpt)))
           )
         )

         (prompt (strcat "\nChainage " (rtos ch 2 2)
                         " | L=" (rtos lb 2 3)
                         " | R=" (rtos rb 2 3) " ✓"))
       )
     )
    )
  )
)

;; ============================================================
;; Draw LWPOLYLINE
;; ============================================================
(defun CB-DRAW-POLYLINE (pts clr layer / pt_data)
  (setq pt_data '())
  (foreach p pts
    (setq pt_data (append pt_data
      (list (cons 10 (list (car p) (cadr p))))))
  )
  (entmakex
    (append
      (list
        (cons 0  "LWPOLYLINE")
        (cons 8  layer)
        (cons 62 clr)
        (cons 70 1)
        (cons 90 (length pts))
      )
      pt_data
    )
  )
)

;; ============================================================
;; Read CSV
;; ============================================================
(defun CB-READ-CSV (filepath / f line rows fields ch lb rb)
  (setq f (open filepath "r"))
  (setq rows '())
  (if (null f)
    (progn (prompt "\nFile open error!") (setq rows nil))
    (progn
      (read-line f)
      (while (setq line (read-line f))
        (setq fields (CB-SPLIT-STRING line ","))
        (if (>= (length fields) 3)
          (progn
            (setq ch (CB-CLEAN-ATOF (car fields)))
            (setq lb (CB-CLEAN-ATOF (cadr fields)))
            (setq rb (CB-CLEAN-ATOF (caddr fields)))
            (setq rows (append rows (list (list ch lb rb))))
          )
        )
      )
      (close f)
    )
  )
  rows
)

;; ============================================================
;; Split CSV string
;; ============================================================
(defun CB-SPLIT-STRING (str delim / result token i c in_quote)
  (setq result '() token "" i 1 in_quote nil)
  (while (<= i (strlen str))
    (setq c (substr str i 1))
    (cond
      ((= c "\"") (setq in_quote (not in_quote)))
      ((and (= c delim) (not in_quote))
       (setq result (append result (list (vl-string-trim " " token))))
       (setq token ""))
      (t (setq token (strcat token c)))
    )
    (setq i (1+ i))
  )
  (append result (list (vl-string-trim " " token)))
)

;; ============================================================
;; Remove commas → float
;; ============================================================
(defun CB-CLEAN-ATOF (s / clean i)
  (setq clean "" i 1)
  (while (<= i (strlen s))
    (if (not (= (substr s i 1) ","))
      (setq clean (strcat clean (substr s i 1))))
    (setq i (1+ i))
  )
  (atof clean)
)

;; ============================================================
;; Point on polyline at distance
;; ============================================================
(defun CB-GET-POINT-AT-DIST (pl_obj dist / param)
  (setq param (vlax-curve-getParamAtDist pl_obj dist))
  (if param (vlax-curve-getPointAtParam pl_obj param) nil)
)

;; ============================================================
;; Perpendicular direction
;; ============================================================
(defun CB-GET-PERP-DIR (pl_obj dist / tangent tx ty len)
  (setq tangent (vlax-curve-getFirstDeriv pl_obj
                  (vlax-curve-getParamAtDist pl_obj dist)))
  (setq tx (car tangent) ty (cadr tangent))
  (setq len (sqrt (+ (* tx tx) (* ty ty))))
  (if (> len 0.0) (progn (setq tx (/ tx len) ty (/ ty len))))
  (list (- ty) tx 0.0)
)

;; ============================================================
;; Draw LINE
;; ============================================================
(defun CB-DRAW-LINE (pt1 pt2 clr)
  (entmakex (list (cons 0 "LINE") (cons 8 "1-BOUNDARY")
                  (cons 62 clr) (cons 10 pt1) (cons 11 pt2)))
)

;; ============================================================
;; Draw TEXT
;; ============================================================
(defun CB-DRAW-TEXT (pt txt clr)
  (entmakex (list (cons 0 "TEXT") (cons 8 "1-BOUNDARY")
                  (cons 62 clr) (cons 10 pt) (cons 40 1.5)
                  (cons 1 txt) (cons 72 1)))
)

;; ============================================================
;; Helper: Create LightWeight Polyline
;; ============================================================
(defun CB-MAKE-POLYLINE (pts col / pl-data pt)
  (setq pl-data
    (list
      '(0 . "LWPOLYLINE")
      '(100 . "AcDbEntity")
      (cons 8 "1-BOUNDARY")
      (cons 62 col)
      '(100 . "AcDbPolyline")
      (cons 90 (length pts))
      '(70 . 0)
    )
  )
  (foreach pt pts
    (setq pl-data
      (append pl-data
        (list (cons 10 (list (car pt) (cadr pt))))
      )
    )
  )
  (entmake pl-data)
)

;; ============================================================
;;  LOAD MESSAGE
;; ============================================================
(prompt "\n╔══════════════════════════════════════════╗")
(prompt "\n║   Civil 3D Combined Tool v6.0 Loaded!   ║")
(prompt "\n║                                          ║")
(prompt "\n║   BM → Both tools auto-run!             ║")
(prompt "\n║   Layer '1-BOUNDARY' auto-created!      ║")
(prompt "\n╚══════════════════════════════════════════╝")
(princ)
