(defun c:SRCH (/ ent obj len dist step km m maxM pt param deriv ang
                   txt txtPt doc ms circ hatch loop mtx oldLay
                   offset sideVec)

  (vl-load-com)

  ;; Select polyline
  (setq ent (car (entsel "\nSelect polyline (increasing chainage direction): ")))

  (if (and ent (member (cdr (assoc 0 (entget ent))) '("LWPOLYLINE" "POLYLINE")))
    (progn

      (setq obj (vlax-ename->vla-object ent))

      ;; Inputs
      (setq km (getint "\nEnter KM: "))
      (setq m  (getint "\nEnter Meter: "))

      ;; Settings
      (setq step 100)
      (setq maxM 900)
      (setq offset 1.5)

      ;; Ensure TEXT layer
      (if (not (tblsearch "LAYER" "1-TEXT"))
        (command "_.LAYER" "_M" "1-TEXT" "")
      )

      ;; Doc
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
      (setq ms  (vla-get-ModelSpace doc))

      ;; Store layer
      (setq oldLay (getvar "CLAYER"))

      ;; Length
      (setq len (vlax-curve-getDistAtParam ent (vlax-curve-getEndParam ent)))

      (setq dist 0)

      (while (and (<= dist len) (<= m maxM))

        ;; Point
        (setq pt (vlax-curve-getPointAtDist ent dist))

        ;; Tangent
        (setq param (vlax-curve-getParamAtDist ent dist))
        (setq deriv (vlax-curve-getFirstDeriv ent param))

        ;; Angle (for text rotation)
        (setq ang (angle '(0 0 0) deriv))

        ;; ---- Circle ----
        (setq circ (vla-AddCircle ms (vlax-3d-point pt) 0.30))
        (vla-put-Layer circ "0")

        ;; ---- Hatch ----
        (setq hatch (vla-AddHatch ms acHatchPatternTypePreDefined "SOLID" :vlax-true))
        (vla-put-Layer hatch "0")

        (setq loop (vlax-make-safearray vlax-vbObject '(0 . 0)))
        (vlax-safearray-put-element loop 0 circ)
        (vla-AppendOuterLoop hatch loop)
        (vla-put-Color hatch 7)
        (vla-Evaluate hatch)

        ;; ---- RHS vector (IMPORTANT FIX) ----
        ;; RHS = (dy, -dx)
        (setq sideVec (list (cadr deriv) (- (car deriv)) 0))

        ;; Text point
        (setq txtPt (polar pt (angle '(0 0 0) sideVec) offset))

        ;; ---- Chainage format ----
        (setq txt
          (strcat
            (itoa km) "/"
            (substr (strcat "000" (itoa m))
                    (- (strlen (strcat "000" (itoa m))) 2))
          )
        )

        ;; ---- MText ----
        (setq mtx (vla-AddMText ms (vlax-3d-point txtPt) 10 txt))

        (vla-put-AttachmentPoint mtx acAttachmentPointMiddleCenter)
        (vla-put-InsertionPoint mtx (vlax-3d-point txtPt))
        (vla-put-Rotation mtx ang)

        (vla-put-Layer mtx "1-TEXT")
        (vla-put-Height mtx 2)

        ;; Increment
        (setq m (+ m step))
        (setq dist (+ dist step))
      )

      (setvar "CLAYER" oldLay)

      (princ "\n✅ SRCH completed (RHS of chainage direction).")
    )
    (princ "\n❌ Select valid polyline.")
  )

  (princ)
)