(vl-load-com)

(defun GETPERPPOINT (pt curve)
  (vlax-curve-getClosestPointTo curve pt)
)

(defun ANGLEDIFF (a b)
  (abs
    (- (rem (+ a pi) (* 2 pi))
       (rem (+ b pi) (* 2 pi)))
  )
)

(defun ROUNDVAL (val decimals)
  (/ (float (fix (+ (* val (expt 10 decimals)) 0.5))) (expt 10 decimals))
)

(defun c:SETBOUNDARYYD (/ boundary track coords vlist i pt prev next
                        perp dist dir txtpt txtang param
                        stylename txtstr txth offset endParam
                        angTol runDist spacing isTurn segLen minSegLen
                        trackStart trackEnd trackDir prevTxtAng
                        startKM startM chainDist totalDist km m
                        distRounded kmStr mStr totalDistRounded)

  (setvar "UNITMODE" 0)
  (setvar "LUPREC" 2)

  (setq txth       1.25)
  (setq offset    -2.5)
  (setq minSegLen  2.0)
  (setq spacing   40.0)
  (setq angTol    (* 5 (/ pi 180.0)))
  (setq stylename "ARIAL_TXT")

  (if (not (tblsearch "STYLE" stylename))
    (entmake
      (list
        '(0 . "STYLE")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbTextStyleTableRecord")
        (cons 2 stylename)
        (cons 3 "arial.ttf")
        (cons 40 0.0)
        (cons 41 1.0)
        (cons 50 0.0)
        (cons 71 0)
      )
    )
  )

  (princ "\nSelect Boundary polyline: ")
  (setq boundary (vlax-ename->vla-object (car (entsel))))
  (princ "\nSelect Rail Track polyline: ")
  (setq track (vlax-ename->vla-object (car (entsel))))

  (setq startKM (getint "\nEnter starting Kilometer: "))
  (setq startM  (getint "\nEnter starting Meter: "))

  (if (or (null startKM) (null startM))
    (progn
      (princ "\nInvalid chainage input.")
      (exit)
    )
  )

  (setq endParam (vlax-curve-getEndParam track))

  (setq trackStart (vlax-curve-getPointAtParam track 0.0))
  (setq trackEnd   (vlax-curve-getPointAtParam track endParam))
  (setq trackDir   (angle trackStart trackEnd))

  (setq coords (vlax-get boundary 'Coordinates))
  (setq vlist '() i 0)
  (repeat (/ (length coords) 2)
    (setq vlist
          (append vlist
            (list
              (list
                (nth (* i 2) coords)
                (nth (1+ (* i 2)) coords)
                0.0))))
    (setq i (1+ i))
  )

  (setq i 0 runDist 0.0 prevTxtAng nil)
  (foreach pt vlist

    (setq prev (if (> i 0) (nth (1- i) vlist)))
    (setq next (if (< i (1- (length vlist))) (nth (1+ i) vlist)))
    (setq segLen (if prev (distance prev pt) 0.0))

    (if (and prev (< segLen minSegLen))
      nil
      (progn
        (if prev (setq runDist (+ runDist segLen)))

        (setq isTurn
          (or (null prev) (null next)
              (> (ANGLEDIFF (angle prev pt) (angle pt next)) angTol))
        )

        (if (or isTurn (>= runDist spacing))
          (progn
            (setq perp  (GETPERPPOINT pt track))
            (setq param (vlax-curve-getParamAtPoint track perp))

            (if (and (> param 0.001) (< param (- endParam 0.001)))
              (progn
                (setq dist  (distance pt perp))
                (setq dir   (angle pt perp))
                (setq txtpt (polar pt dir offset))
                (setq distRounded (ROUNDVAL dist 2))

                (setq txtang
                  (angle perp
                    (vlax-curve-getPointAtParam
                      track
                      (min (+ param 0.01) endParam))))

                (if (> (abs (- txtang trackDir)) (/ pi 2))
                  (setq txtang (+ txtang pi))
                )

                (if prevTxtAng
                  (progn
                    (while (> (- txtang prevTxtAng) pi)
                      (setq txtang (- txtang (* 2 pi))))
                    (while (< (- txtang prevTxtAng) (- pi))
                      (setq txtang (+ txtang (* 2 pi))))
                  )
                )
                (setq prevTxtAng txtang)

                (setq chainDist (vlax-curve-getDistAtParam track param))
                (setq totalDist (+ chainDist startM (* startKM 1000)))
                (setq totalDistRounded (ROUNDVAL totalDist 2))
                (setq km (fix (/ totalDistRounded 1000)))
                (setq m (ROUNDVAL (- totalDistRounded (* km 1000)) 0))

                (if (>= m 1000)
                  (progn
                    (setq km (+ km 1))
                    (setq m (- m 1000))
                  )
                )

                (setq kmStr (itoa km))
                (setq mStr
                  (cond
                    ((< m 10)  (strcat "00" (itoa (fix m))))
                    ((< m 100) (strcat "0"  (itoa (fix m))))
                    (T         (itoa (fix m)))
                  )
                )

                (setq txtstr
                  (strcat
                    "{\\pxql;"
                    (rtos distRounded 2 2)
                    "m@\\P"
                    "KM " kmStr "/" mStr
                    "}"
                  )
                )

                (entmake
                  (list
                    '(0 . "MTEXT")
                    '(100 . "AcDbEntity")
                    '(100 . "AcDbMText")
                    (cons 7 stylename)
                    (cons 10 txtpt)
                    (cons 40 txth)
                    (cons 41 11.00)
                    (cons 1 txtstr)
                    (cons 50 txtang)
                    (cons 71 5)
                    '(73 . 1)
                  )
                )

                (setq runDist 0.0)
              )
            )
          )
        )
      )
    )
    (setq i (1+ i))
  )

  (princ "\nLabels added successfully.")
  (princ)
)

(princ "\nType SETBOUNDARYYD to run the command.")
(princ)