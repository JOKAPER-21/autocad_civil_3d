(defun c:SURVEYH ( / lay h hp ss i ent obj )

  ;; Ask layer name first (default = 1-SURVEY)
  (setq lay (getstring T "\nEnter layer name <1-SURVEY>: "))
  (if (= lay "") (setq lay "1-SURVEY"))

  ;; Text Height
  (setq h (getreal "\nEnter new text height: "))

  ;; Point Size
  (setq hp (getreal "\nEnter new point size (PDSIZE): "))

  ;; Change TEXT / MTEXT height
  (if h
    (progn
      (setq ss (ssget "X" (list '(0 . "TEXT,MTEXT") (cons 8 lay))))
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
          (princ
            (strcat
              "\nText height changed to "
              (rtos h 2 2)
              " in layer "
              lay
            )
          )
        )
        (princ (strcat "\nNo TEXT or MTEXT found in layer " lay))
      )
    )
  )

  ;; Change POINT size
  (if hp
    (progn
      (setq ss (ssget "X" (list '(0 . "POINT") (cons 8 lay))))
      (if ss
        (progn
          (setvar "PDSIZE" hp)
          (command "_.REGEN")
          (princ
            (strcat
              "\nPoint size changed to "
              (rtos hp 2 2)
              " in layer "
              lay
            )
          )
        )
        (princ (strcat "\nNo POINT found in layer " lay))
      )
    )
  )

  (princ)
)