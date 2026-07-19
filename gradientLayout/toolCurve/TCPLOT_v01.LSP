;;; TCPLOT.LSP - Plots track geometry (Transition/Curve) from CSV as a bulge polyline
;;; CSV format expected: TC,LH/RH,distance   (header row required)

(defun c:TCPLOT ( / file f line parts rows n vlist k)

  (vl-load-com)

  (setq file (getfiled "Select Track Geometry CSV File" "" "csv" 16))

  (if file
    (progn
      (setq f (open file "r"))
      (setq line (read-line f))          ; discard header row
      (setq rows '())
      (while (setq line (read-line f))
        (setq line (vl-string-trim " \t\r\n" line))
        (if (> (strlen line) 0)
          (progn
            (setq parts (tcplot-split line))
            (if (>= (length parts) 3)
              (setq rows
                (append rows
                  (list
                    (list
                      (strcase (vl-string-trim " \t" (nth 0 parts)))
                      (strcase (vl-string-trim " \t" (nth 1 parts)))
                      (atof   (vl-string-trim " \t" (nth 2 parts)))
                    )
                  )
                )
              )
            )
          )
        )
      )
      (close f)

      (setq n (length rows))
      (if (> n 0)
        (progn
          (setq vlist (list (list 0.0 0.0 (tcplot-bulge (nth 0 rows)))))
          (setq k 1)
          (repeat (1- n)
            (setq vlist
              (append vlist
                (list (list (caddr (nth (1- k) rows)) 0.0 (tcplot-bulge (nth k rows))))
              )
            )
            (setq k (1+ k))
          )
          (setq vlist
            (append vlist (list (list (caddr (nth (1- n) rows)) 0.0 0.0)))
          )
          (tcplot-makepoly vlist)
          (princ (strcat "\nDone. " (itoa n) " segments plotted from CSV."))
        )
        (princ "\nNo data rows found in CSV.")
      )
    )
    (princ "\nNo file selected.")
  )
  (princ)
)

(defun tcplot-split (str / result pos)
  (setq result '())
  (while (setq pos (vl-string-search "," str))
    (setq result (append result (list (substr str 1 pos))))
    (setq str (substr str (+ pos 2)))
  )
  (append result (list str))
)

(defun tcplot-bulge (row / tc dir)
  (setq tc  (nth 0 row))
  (setq dir (nth 1 row))
  (cond
    ((and (= tc "CURVE") (= dir "LH")) 1.0)   ; bulges upward (+Y)
    ((and (= tc "CURVE") (= dir "RH")) -1.0)  ; bulges downward (-Y)
    (t 0.0)                                  ; Transition = straight
  )
)

(defun tcplot-makepoly (vlist / dxf v)
  (setq dxf
    (list
      '(0 . "LWPOLYLINE")
      '(100 . "AcDbEntity")
      (cons 8 (getvar "CLAYER"))
      '(100 . "AcDbPolyline")
      (cons 90 (length vlist))
      '(70 . 0)
      '(38 . 0.0)
    )
  )
  (foreach v vlist
    (setq dxf
      (append dxf
        (list (cons 10 (list (car v) (cadr v))) (cons 42 (caddr v)))
      )
    )
  )
  (entmake dxf)
)

(princ "\nTCPLOT loaded. Type TCPLOT to run.")
(princ)