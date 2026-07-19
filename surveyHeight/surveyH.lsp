(defun c:SURVEYH ( / h hp ss i ent obj )
  ; --- Text Height ---
  (setq h (getreal "\nEnter new text height: "))
  
  ; --- Point Size ---
  (setq hp (getreal "\nEnter new point size (PDSIZE): "))
  
  (if h
    (progn
      (setq ss (ssget "X" '((0 . "TEXT,MTEXT") (8 . "1-SURVEY"))))
      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i))
            (setq obj (vlax-ename->vla-object ent))
            (cond
              ((= (vla-get-objectname obj) "AcDbText")
               (vla-put-height obj h)
              )
              ((= (vla-get-objectname obj) "AcDbMText")
               (vla-put-Height obj h)
              )
            )
            (setq i (1+ i))
          )
          (princ (strcat "\nText height changed to " (rtos h 2 2)))
        )
        (princ "\nNo TEXT or MTEXT found in layer 1-SURVEY.")
      )
    )
  )

  ; --- Change PDSIZE for POINT entities on layer 1-SURVEY ---
  (if hp
    (progn
      (setq ss (ssget "X" '((0 . "POINT") (8 . "1-SURVEY"))))
      (if ss
        (progn
          (setvar "PDSIZE" hp)
          (princ (strcat "\nPoint size (PDSIZE) changed to " (rtos hp 2 2)))
          ; Force regen to reflect PDSIZE change visually
          (command "_.REGEN")
        )
        (princ "\nNo POINT entities found in layer 1-SURVEY.")
      )
    )
  )

  (princ)
)
