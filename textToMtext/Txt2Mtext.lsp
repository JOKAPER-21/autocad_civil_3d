(defun C:MTXT (  ; No arguments.
    / ;_ Local variables:
    acmde  ; Command echo mode.
    ename  ; Entity name of TEXT object being processed.
    icount  ; Loop counter.
    ss1  ; Selection set of TEXT objects on which to operate.
   ) ;_ End arguments and local variables.
  (setq acmde (getvar "CMDECHO")) ; Command echo mode.
  (setvar "CMDECHO" 0)   ; Turn off command echo.
  (prompt "\nSelect TEXT objects to be converted to MTEXT. ")
  (setq ss1    (ssget '((0 . "TEXT")))
 icount 0   ; Initialize loop counter.
  ) ;_ End setq.
  (cond     ; cond A.
    (ss1    ; If TEXT objects selected, do the following:
     (while (setq ename (ssname ss1 icount))
       ;; While unprocessed TEXT objects remain:
       (command "TXT2MTXT" ename "") ; Process text.
       (setq icount (1+ icount)) ; Increment counter.
     ) ;_ End while.
     (prompt "\nAll selected TEXT has been converted to individual MTEXT objects. ")
    ) ;_ End condition A.1.
    (T
     (prompt
       "\nNo TEXT objects selected.  C:MLTPL_TXT2MTXT terminated. "
     ) ;_ End prompt.
    ) ;_ End condition A.2.
  ) ;_ End cond A.
  (setvar "CMDECHO" acmde)  ; Restore previous command echo mode.
  (prin1)    ; Exit quietly.
) ;_ End C:MLTPL_TXT2MTXT.