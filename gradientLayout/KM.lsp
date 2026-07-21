(defun c:KMGRID (/ doc ms i x txt obj pts pl)

  (vl-load-com)

  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq ms  (vla-get-ModelSpace doc))

  (setq i 0)

  (while (<= i 70)

    ;; X Coordinate
    (setq x (* i 20.0))

    ;;----------------------------------------
    ;; MTEXT
    ;;----------------------------------------
    (setq obj
      (vla-AddMText
        ms
        (vlax-3D-point (list x 0.0 0.0))
        3.5
        (itoa i)
      )
    )

    ;; Properties
    (vla-put-Height obj 2.0)

    ;; Middle Center
    ;; acAttachmentPointMiddleCenter = 5
    (vla-put-AttachmentPoint obj 5)

    ;;----------------------------------------
    ;; POLYLINE
    ;; from (x,-1) to (x,0)
    ;;----------------------------------------
    (setq pts
      (vlax-make-safearray
        vlax-vbDouble
        '(0 . 5)
      )
    )

    (vlax-safearray-fill
      pts
      (list
        x -3.0
        x  0.0
        x  0.0
      )
    )

    (setq pl
      (vla-AddLightWeightPolyline
        ms
        pts
      )
    )

    (setq i (1+ i))

  )

  (princ "\nCompleted.")
  (princ)
)