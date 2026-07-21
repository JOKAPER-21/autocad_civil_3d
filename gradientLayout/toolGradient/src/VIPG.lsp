;;; ============================================================
;;; VIPG - Railway Gradient Index Plan Generator
;;; ============================================================

(defun c:VIPG (/ csvFile f hdr ln rows row idx startRow baseCH
                 baseNewCH i ch rl rf newCH newRL xOff basePt
                 lyrProf lyrLbl startCH hScale vScale ip
                 topVerts baseXs rfVals lineNum skipped)

  (setq lyrProf "RAIL_PROFILE")
  (setq lyrLbl  "1 INDEX PLAN GRADIENT")
  (VIPG:ensure-layer lyrProf)
  (VIPG:ensure-layer lyrLbl)

  (setq csvFile (getfiled "Select CSV File" "" "csv" 16))
  (if (not csvFile) (progn (princ "\nNo file selected.") (exit)))

  (setq startCH (getreal "\nEnter starting chainage: "))
  (setq hScale  (getreal "\nEnter horizontal scale: "))
  (setq vScale  (getreal "\nEnter vertical scale: "))
  (setq ip      (getpoint "\nPick insertion point: "))
  (if (not ip) (progn (princ "\nNo insertion point picked.") (exit)))

  (setq rows '() lineNum 0 skipped 0)
  (setq f (open csvFile "r"))
  (setq hdr (read-line f))
  (while (setq ln (read-line f))
    (setq lineNum (1+ lineNum))
    (setq ln (vl-string-trim " \r\t" ln))
    (if (/= ln "")
      (progn
        (setq row (VIPG:parse-row ln))
        (if row
          (setq rows (append rows (list row)))
          (progn
            (setq skipped (1+ skipped))
            (princ (strcat "\nWarning: skipped malformed CSV row #" (itoa lineNum) ": " ln))
          )
        )
      )
    )
  )
  (close f)

  (if (> skipped 0)
    (princ (strcat "\n" (itoa skipped) " row(s) skipped due to formatting issues."))
  )

  (if (not rows) (progn (princ "\nNo valid data rows found in CSV.") (exit)))

  (setq idx (VIPG:find-row rows startCH))
  (if (not idx) (progn (princ "\nStarting chainage not found in CSV.") (exit)))

  (setq startRow  (nth idx rows))
  (setq baseCH    (float (car startRow)))
  (setq baseNewCH (/ baseCH hScale))
  (setq topVerts '())
  (setq baseXs   '())
  (setq rfVals   '())

  (setq rl (cadr startRow))
  (setq rf (caddr startRow))
  (setq newRL (/ rl vScale))
  (setq topVerts (append topVerts (list (VIPG:draw-station ip rl newRL lyrProf lyrLbl))))
  (setq baseXs   (append baseXs (list (car ip))))
  (setq rfVals   (append rfVals (list (VIPG:format-rf rf))))

  (setq i (1+ idx))
  (while (< i (length rows))
    (setq row (nth i rows))
    (setq ch (float (car row)))
    (setq rl (cadr row))
    (setq rf (caddr row))
    (setq newCH (/ ch hScale))
    (setq newRL (/ rl vScale))
    (setq xOff (- newCH baseNewCH))
    (setq basePt (list (+ (car ip) xOff) (cadr ip) 0.0))
    (setq topVerts (append topVerts (list (VIPG:draw-station basePt rl newRL lyrProf lyrLbl))))
    (setq baseXs   (append baseXs (list (car basePt))))
    (setq rfVals   (append rfVals (list (VIPG:format-rf rf))))
    (setq i (1+ i))
  )

  (VIPG:draw-gradient-line topVerts lyrProf)
  (VIPG:draw-rf-labels baseXs rfVals (cadr ip) lyrLbl)

  (princ "\nVIPG complete.")
  (princ)
)

(defun VIPG:ensure-layer (name)
  (if (not (tblsearch "LAYER" name))
    (command "._-LAYER" "_M" name "")
  )
)

(defun VIPG:split (str delim / pos lst)
  (setq lst '())
  (while (setq pos (vl-string-search delim str))
    (setq lst (append lst (list (substr str 1 pos))))
    (setq str (substr str (+ pos 1 (strlen delim))))
  )
  (append lst (list str))
)

(defun VIPG:parse-row (ln / parts chStr rlStr rfStr chVal rlVal)
  (setq parts (VIPG:split ln ","))
  (if (< (length parts) 3)
    nil
    (progn
      (setq chStr (vl-string-trim " " (nth 0 parts)))
      (setq rlStr (vl-string-trim " " (nth 1 parts)))
      (setq rfStr (vl-string-trim " " (nth 2 parts)))
      (setq chVal (atof chStr))
      (setq rlVal (atof rlStr))
      (if (or (= chStr "") (= rlStr "") (= rfStr ""))
        nil
        (list chVal rlVal rfStr)
      )
    )
  )
)

(defun VIPG:find-row (rows ch / i found)
  (setq i 0 found nil)
  (while (and (< i (length rows)) (not found))
    (if (equal (car (nth i rows)) ch 0.001)
      (setq found i)
    )
    (setq i (1+ i))
  )
  found
)

(defun VIPG:format-rf (rf / parts letter num)
  (if (or (not rf) (not (= (type rf) 'STR)))
    "?"
    (progn
      (setq parts (VIPG:split (vl-string-trim " " rf) " "))
      (setq letter (nth 0 parts))
      (setq num    (nth 1 parts))
      (if (and letter num)
        (strcat letter " 1 IN " num)
        rf
      )
    )
  )
)

(defun VIPG:draw-station (basePt ogRL newRL lyrProf lyrLbl /
                           topPt1 labelPt poly2Start poly2Top txt)
  (setq topPt1     (list (car basePt) (+ (cadr basePt) 1.0) 0.0))
  (setq labelPt    (list (car topPt1) (+ (cadr topPt1) 0.2) 0.0))
  (setq poly2Start (list (car topPt1) (+ (cadr topPt1) 12.0) 0.0))
  (setq poly2Top   (list (car poly2Start) (+ (cadr poly2Start) newRL) 0.0))
  (setq txt (rtos ogRL 2 3))

  (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lyrProf)
                 '(100 . "AcDbPolyline") '(90 . 2) '(70 . 0)
                 (cons 10 (list (car basePt) (cadr basePt)))
                 (cons 10 (list (car topPt1) (cadr topPt1)))))

  ;; RailLevel MTEXT ($mTextRailLevel: width 11.5)
  (entmake (list '(0 . "MTEXT") '(100 . "AcDbEntity") (cons 8 lyrLbl)
                 '(100 . "AcDbMText")
                 (cons 10 labelPt)
                 (cons 40 2.0) (cons 41 11.5) (cons 50 (/ pi 2.0))
                 (cons 71 4) (cons 1 txt)))

  (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lyrProf)
                 '(100 . "AcDbPolyline") '(90 . 2) '(70 . 0)
                 (cons 10 (list (car poly2Start) (cadr poly2Start)))
                 (cons 10 (list (car poly2Top) (cadr poly2Top)))))

  poly2Top
)

(defun VIPG:draw-gradient-line (pts lyr / verts p)
  (if (< (length pts) 2)
    (princ "\nNot enough points to draw gradient line.")
    (progn
      (setq verts '())
      (foreach p pts
        (setq verts (append verts (list (cons 10 (list (car p) (cadr p))))))
      )
      (entmake (append
                 (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lyr)
                       '(100 . "AcDbPolyline")
                       (cons 90 (length pts)) '(70 . 0))
                 verts))
    )
  )
)

;; RF label between each consecutive station pair, 12m above baseline
;; ($mTextRiseFall: width 21)
(defun VIPG:draw-rf-labels (baseXs rfVals baseY lyrLbl / i midX ypt pt txt)
  (setq i 1)
  (while (< i (length baseXs))
    (setq midX (/ (+ (nth (1- i) baseXs) (nth i baseXs)) 2.0))
    (setq ypt  (+ baseY 1.0 12.0)) ; 1m buffer tick + 12m offset above it
    (setq pt   (list midX ypt 0.0))
    (setq txt  (nth i rfVals))
    (entmake (list '(0 . "MTEXT") '(100 . "AcDbEntity") (cons 8 lyrLbl)
                   '(100 . "AcDbMText")
                   (cons 10 pt)
                   (cons 40 2.0) (cons 41 21.0) (cons 50 (/ pi 2.0))
                   (cons 71 4)
                   (cons 1 txt)))
    (setq i (1+ i))
  )
)

(princ "\nVIPG loaded. Type VIPG to run.")
(princ)