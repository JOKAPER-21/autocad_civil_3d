(defun c:DXF_MERGE_MAP (/ files filePath fileName prefix doc)

  (vl-load-com)

  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  (prompt "\nSelect DXF files to merge with layer mapping...")

  ;; Select multiple DXF files
  (setq files (vl-file-syst-explore "Select DXF Files" "" "dxf"))

  (if files
    (progn

      (foreach filePath files

        ;; Extract file name without extension
        (setq fileName (vl-filename-base filePath))
        (setq prefix fileName)

        (prompt (strcat "\nProcessing: " fileName))

        ;; Create a container layer for this DXF
        (command "_.-LAYER" "M" prefix "" "")

        ;; Insert DXF at origin
        (command "_.-INSERT" filePath "0,0,0" "1" "1" "0")

        ;; Get last inserted entity
        (setq ent (entlast))

        ;; Move inserted objects to prefixed layer system
        (command "_.CHPROP" "L" "" "LA" prefix "")

        ;; Explode block so geometry becomes native
        (command "_.EXPLODE" ent)

        ;; After explode, rename all resulting layers (optional cleanup)
        (command "_.REGEN")

      )

      (prompt "\n\n✔ DXF Merge with Layer Mapping Completed!")
    )
    (prompt "\nNo files selected.")
  )

  (princ)
)