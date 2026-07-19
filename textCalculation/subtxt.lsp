(defun c:SUBTXT ( / ent1 ent2 val1 val2 result pt)
  
  ; First Text Select
  (setq ent1 (car (entsel "\nSelect First Text: ")))
  (if (null ent1) (exit))
  (setq val1 (atof (cdr (assoc 1 (entget ent1)))))
  
  ; Second Text Select
  (setq ent2 (car (entsel "\nSelect Second Text: ")))
  (if (null ent2) (exit))
  (setq val2 (atof (cdr (assoc 1 (entget ent2)))))
  
  ; Subtraction
  (setq result (- val1 val2))
  
  ; Click Location
  (setq pt (getpoint "\nClick location to place result: "))
  
  ; Place Result as Text
  (entmake
    (list
      (cons 0 "TEXT")
      (cons 10 pt)
      (cons 40 2.5) ; Text Height - மாத்திக்கலாம்
      (cons 1 (rtos result 2 3)) ; 3 decimal places
      (cons 72 0)
      (cons 11 pt)
    )
  )
  
  (princ (strcat "\nResult: " (rtos result 2 3)))
  (princ)
)