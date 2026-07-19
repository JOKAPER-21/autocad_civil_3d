;; ============================================
;; BANK CUTTING TOOL v23
;; ============================================
(defun BC-clean (txt / res i ch)
  (setq res "" i 1)
  (while (<= i (strlen txt))
    (setq ch (substr txt i 1))
    (if (or (and (>= ch "0") (<= ch "9"))
            (= ch ".")
            (= ch "-"))
      (setq res (strcat res ch))
    )
    (setq i (1+ i))
  )
  res
)

(defun C:SBC ( / e1 e2 t1 t2 n1 n2 diff
                 pt pl foot dist dir ang blk blk-path ss e d pick-pt)
  (prompt "\n--- BC TOOL v23 ---")

  ;; 1. SELECT TEXTS
  (setq e1 (car (entsel "\nSelect First TEXT: ")))
  (setq e2 (car (entsel "\nSelect Second TEXT: ")))

  ;; GET VALUES
  (setq t1 (cdr (assoc 1 (entget e1))))
  (setq t2 (cdr (assoc 1 (entget e2))))
  (setq n1 (atof (BC-clean t1)))
  (setq n2 (atof (BC-clean t2)))

  (if (or (= n1 0.0) (= n2 0.0))
    (progn
      (alert "Text value read agala! Check text format!")
      (exit)
    )
  )

  ;; HEIGHT DIFF
  (setq diff (- n1 n2))
  (cond
    ((and (>= diff -0.3) (<= diff 0.3))
      (setq h "LG" rev nil)
    )
    ((< diff -0.3)
      (setq h (rtos (abs diff) 2 2) rev T)
    )
    (T
      (setq h (rtos diff 2 2) rev nil)
    )
  )

  ;; INSERT POINT = e2 text assoc 10
  (setq pt (cdr (assoc 10 (entget e2))))

  ;; 2. USER CLICKED POINT for distance measurement
  (setq pick-pt (getpoint "\nPick point for distance measurement: "))

  ;; 3. SELECT POLYLINE
  (setq pl (car (entsel "\nSelect Polyline: ")))

  ;; PERPENDICULAR FOOT from picked point to polyline (force Z=0)
  (setq foot (vlax-curve-getClosestPointTo pl
               (list (car pick-pt) (cadr pick-pt) 0.0)))

  ;; 2D DISTANCE ONLY (XY - ignore Z)
  (setq dist (rtos (distance
                     (list (car pick-pt) (cadr pick-pt))
                     (list (car foot)    (cadr foot)))
                   2 2))

  ;; 4. DIRECTION
  (initget "UP DN")
  (setq dir (getkword "\nDirection [UP/DN]: "))
  (if rev
    (setq dir (if (= dir "UP") "DN" "UP"))
  )

  ;; BLOCK NAME
  (setq blk
    (cond
      ((and (= dir "UP") (not (= h "LG"))) "bank_cutting_up")
      ((and (= dir "DN") (not (= h "LG"))) "bank_cutting_dn")
      ((and (= dir "UP") (= h "LG"))       "bank_cutting_up_lg")
      ((and (= dir "DN") (= h "LG"))       "bank_cutting_dn_lg")
    )
  )

  ;; BLOCK PATH
  (setq blk-path (strcat "D:\\railway\\projects\\TEST\\bankcutting\\New folder\\" blk))

  ;; ANGLE - pt to foot = perpendicular direction to polyline
  (setq ang (+ (angle pt foot) (/ pi 2)))
  (if (= dir "DN") (setq ang (+ ang pi)))
  (if rev          (setq ang (+ ang pi)))

  ;; INSERT BLOCK at e2 point
  (command "-insert" blk-path pt 1 1 (* 180 (/ ang pi)))

  ;; EXPLODE & UPDATE TEXT
  (command "explode" (entlast))
  (setq ss (ssget "_X" '((0 . "TEXT,MTEXT"))))
  (if ss
    (progn
      (repeat (sslength ss)
        (setq e (ssname ss 0))
        (setq d (entget e))
        (cond
          ((= (cdr (assoc 1 d)) "H-0.00")
            (entmod (subst (cons 1 (if (= h "LG") "H-LG" (strcat "H-" h)))
                           (assoc 1 d) d))
          )
          ((= (cdr (assoc 1 d)) "D-0.00")
            (if (= h "LG")
              (entdel e)
              (entmod (subst (cons 1 (strcat "D-" dist))
                             (assoc 1 d) d))
            )
          )
        )
        (ssdel e ss)
      )
    )
  )

  (prompt "\n✅ Done macha!")
  (princ)
)