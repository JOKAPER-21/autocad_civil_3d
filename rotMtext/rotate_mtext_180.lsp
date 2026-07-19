;; ============================================================
;; ROTATE-MTEXT-180
;; Rotates all selected MTEXT objects by 180 degrees (π radians)
;; in place, around each object's own insertion point.
;;
;; Usage:
;;   Load the file:  (load "rotate_mtext_180.lsp")
;;   Run the command: ROTMTEXT180
;; ============================================================

(defun c:ROTMTEXT180 ( / ss i ent entdata ins ang)

  ;; Prompt user to select objects (filter for MTEXT only)
  (setq ss (ssget '((0 . "MTEXT"))))

  (if (null ss)
    (progn
      (princ "\nNo MTEXT objects selected.")
      (princ)
    )
    (progn
      (setq i 0)

      (while (< i (sslength ss))

        ;; Get the entity and its data
        (setq ent     (ssname ss i)
              entdata (entget ent))

        ;; Group code 10 = insertion point, 50 = rotation angle (radians)
        (setq ins (cdr (assoc 10 entdata))
              ang (cdr (assoc 50 entdata)))

        ;; Default rotation is 0 if not present in entity data
        (if (null ang) (setq ang 0.0))

        ;; Add 180 degrees (π radians), keep within 0–2π range
        (setq ang (rem (+ ang pi) (* 2 pi)))

        ;; Update the rotation angle in entity data
        (setq entdata (subst (cons 50 ang)
                             (assoc 50 entdata)
                             entdata))

        ;; If group code 50 was not originally present, add it
        (if (null (assoc 50 (entget ent)))
          (setq entdata (append entdata (list (cons 50 ang))))
        )

        ;; Write updated data back to the entity
        (entmod entdata)
        (entupd ent)

        (setq i (1+ i))
      )

      (princ (strcat "\nDone. Rotated " (itoa (sslength ss)) " MTEXT object(s) by 180 degrees."))
      (princ)
    )
  )
)

(princ "\nRotate MText 180° loaded. Run command: ROTMTEXT180")
(princ)
