(defun c:SCBL (/ ss lay i ent obj blkName blkDef doc)

  (vl-load-com)

  ;; Active document
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  ;; Ask for target layer
  (setq lay (getstring T "\nEnter target existing layer: "))

  ;; Validate layer
  (if (not (tblsearch "LAYER" lay))
    (progn
      (princ "\n❌ Layer does not exist.")
      (exit)
    )
  )

  ;; Select ANY objects
  (setq ss (ssget))

  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))

        (setq ent (ssname ss i))
        (setq obj (vlax-ename->vla-object ent))

        ;; Change layer for selected object
        (if (vlax-property-available-p obj 'Layer)
          (vla-put-layer obj lay)
        )

        ;; If it's a block (INSERT)
        (if (= (vla-get-ObjectName obj) "AcDbBlockReference")
          (progn
            (setq blkName (vla-get-Name obj))

            ;; Skip Xrefs safely
            (if (not (vl-string-search "|" blkName))
              (progn
                (setq blkDef (vla-item (vla-get-Blocks doc) blkName))

                ;; Change all entities inside block definition
                (vlax-for e blkDef
                  (if (and (vlax-property-available-p e 'Layer)
                           (not (vlax-erased-p e)))
                    (vla-put-layer e lay)
                  )
                )
              )
            )
          )
        )

        (setq i (1+ i))
      )

      (princ "\n✅ Selected objects + blocks updated to target layer.")
    )
    (princ "\n⚠️ Nothing selected.")
  )

  (princ)
)