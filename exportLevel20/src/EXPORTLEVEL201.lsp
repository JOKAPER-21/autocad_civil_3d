(defun c:EXPORTLEVEL20 ( / ent obj coords interval dist len ch elev pt data file)
  (vl-load-com)
  (setq ent (car (entsel "\nSelect polyline with elevation: ")))

  (if ent
    (progn
      (setq obj (vlax-ename->vla-object ent))

      ;; Check if it's a supported polyline type
      (if (or (eq (vla-get-ObjectName obj) "AcDbPolyline") 
              (eq (vla-get-ObjectName obj) "AcDb3dPolyline"))
        (progn
          ;; Total length
          (setq len (vlax-curve-getDistAtParam obj (vlax-curve-getEndParam obj)))
          (initget 7)
          (setq interval (getreal "\nEnter chainage interval (e.g. 20): "))
          (setq dist 0)
          (setq data '("Chainage,Elevation"))

          ;; Loop every interval
          (while (<= dist len)
            (setq pt (vlax-curve-getPointAtDist obj dist))
            (if pt
              (progn
                (setq ch (rtos dist 2 3))
                (setq elev (rtos (caddr pt) 2 3))
                (setq data (cons (strcat ch "," elev) data))
              )
            )
            (setq dist (+ dist interval))
          )

          ;; Save CSV
          (setq file (getfiled "Save CSV As" "Chainage_Levels.csv" "csv" 1))
          (if file
            (progn
              (setq f (open file "w"))
              (foreach line (reverse data)
                (write-line line f)
              )
              (close f)
              (alert (strcat "Export successful to:\n" file))
            )
            (prompt "\nCancelled export.")
          )
        )
        (prompt "\nSelected object is not a supported polyline.")
      )
    )
    (prompt "\nNo entity selected.")
  )
  (princ)
)
