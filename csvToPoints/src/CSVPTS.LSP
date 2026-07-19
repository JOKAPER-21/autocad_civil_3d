;;; ========================================================
;;;  CSVPTS.LSP
;;;  Import Point Name, Code, Northing, Easting, Elevation
;;;  from a CSV and create:
;;;    - POINT entity  (PDSIZE = 0.2)
;;;    - MTEXT: Point Name  -> Justify Middle Right (MR)
;;;    - MTEXT: Elevation   -> Justify Bottom Left  (BL)
;;;    - MTEXT: Code        -> Justify Top Left     (TL)
;;;  All 4 objects share the same insertion coordinate.
;;;  Command: CSVPTS
;;; ========================================================

(vl-load-com)

;; ---- split a string on a delimiter ----
(defun StrSplit (str delim / pos lst)
  (setq lst '())
  (while (setq pos (vl-string-search delim str))
    (setq lst  (append lst (list (substr str 1 pos))))
    (setq str  (substr str (+ pos 1 (strlen delim))))
  )
  (append lst (list str))
)

;; ---- trim spaces ----
(defun Trim$ (s) (vl-string-trim " \t" s))

;; ---- create layer if missing ----
(defun AddLayer (name color)
  (if (not (tblsearch "LAYER" name))
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 name)
        '(70 . 0)
        (cons 62 color)
        '(6 . "Continuous")
      )
    )
  )
)

;; ---- create an MTEXT at pt with given attachment code ----
;; attach: 1=TL 2=TC 3=TR 4=ML 5=MC 6=MR 7=BL 8=BC 9=BR
(defun MakeMText (pt txt ht layer attach / )
  (entmake
    (list
      '(0 . "MTEXT")
      '(100 . "AcDbEntity")
      (cons 8 layer)
      '(100 . "AcDbMText")
      (cons 10 pt)
      (cons 40 ht)
      (cons 41 0.0)         ; width 0 = no wrap
      (cons 71 attach)
      (cons 72 1)           ; left-to-right
      (cons 1  txt)
      '(7 . "Standard")
      '(210 0.0 0.0 1.0)
    )
  )
)

;; ---- main command ----
(defun c:CSVPTS ( / file f ln fields cnt
                    pname code north east elev pt
                    txtht zone oldpdsize hdrSkipped)

  (setq txtht 0.2)   ; text height for all MTEXT
  (setq oldpdsize (getvar "PDSIZE"))
  (setvar "PDSIZE" 0.2)   ; point display scale

  ;; --- select CSV file ---
  (setq file (getfiled "Select Point CSV File" "" "csv" 4))
  (if (not file)
    (progn (princ "\nNo file selected. Command cancelled.") (exit))
  )

  ;; --- ask for UTM zone ---
  (initget "43 44")
  (setq zone (getkword "\nSpecify UTM Zone (WGS84) [43/44] <43>: "))
  (if (not zone) (setq zone "43"))

  ;; --- create layers ---
  (AddLayer "PNT"       7)   ; point
  (AddLayer "PNT-NAME"  1)   ; point name  (red)
  (AddLayer "PNT-ELEV"  3)   ; elevation   (green)
  (AddLayer "PNT-CODE"  5)   ; code        (blue)
  (AddLayer "UTM-ZONE-NOTE" 2)

  ;; --- add a reference note for the UTM zone ---
  (MakeMText '(0.0 0.0 0.0)
             (strcat "UTM Zone " zone "N (WGS84)")
             txtht "UTM-ZONE-NOTE" 1)

  ;; --- open and read CSV ---
  (setq f (open file "r"))
  (if (not f)
    (progn (princ "\nCould not open file.") (exit))
  )

  (setq cnt 0)
  (setq hdrSkipped nil)

  (while (setq ln (read-line f))
    (if (not hdrSkipped)
      (setq hdrSkipped T)   ; skip header row
      (if (/= (Trim$ ln) "")
        (progn
          (setq fields (StrSplit ln ","))
          (if (>= (length fields) 5)
            (progn
              (setq pname (Trim$ (nth 0 fields)))
              (setq code  (Trim$ (nth 1 fields)))
              (setq north (atof (Trim$ (nth 2 fields))))
              (setq east  (atof (Trim$ (nth 3 fields))))
              (setq elev  (atof (Trim$ (nth 4 fields))))

              ;; Easting = X, Northing = Y, Elevation = Z
              (setq pt (list east north elev))

              ;; POINT entity
              (entmake
                (list
                  '(0 . "POINT")
                  (cons 8 "PNT")
                  (cons 10 pt)
                  '(210 0.0 0.0 1.0)
                )
              )

              ;; Point Name -> Middle Right
              (MakeMText pt pname txtht "PNT-NAME" 6)

              ;; Elevation -> Bottom Left (3 decimal places)
              (MakeMText pt (rtos elev 2 3) txtht "PNT-ELEV" 7)

              ;; Code -> Top Left
              (MakeMText pt code txtht "PNT-CODE" 1)

              (setq cnt (1+ cnt))
            )
          )
        )
      )
    )
  )

  (close f)
  (setvar "PDSIZE" oldpdsize)
  (princ (strcat "\n" (itoa cnt) " points imported successfully."))
  (princ)
)

(princ "\nCSVPTS loaded. Type CSVPTS to run.")
(princ)