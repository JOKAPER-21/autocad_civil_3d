(defun c:SM (/ zone csName)

  (initget "43 44")
  (setq zone (getkword "\nEnter UTM Zone [43/44] <43>: "))

  (if (null zone)
    (setq zone "43")
  )

  (setq csName (strcat "UTM84-" zone "N"))

  ;; Assign Coordinate System
  (command "._MAPCSASSIGN" csName)

  ;; Turn on Bing Hybrid
  (command "._GEOMAP" "_Hybrid")

  ;; Zoom Extents
  (command "._ZOOM" "_E")

  (princ)
)