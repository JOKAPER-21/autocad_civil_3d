(defun c:SM (/ zone cs mapOpt)

  ;; Check if MAPCSASSIGN is available
  (if (not (tblsearch "LAYER" "MAPCSASSIGN"))
    (progn
      (princ "\nMAPCSASSIGN command is not available. Please ensure you have the necessary components installed.")
      (exit)
    )
  )
  
  ;; Ask for UTM Zone
  (initget "43 44")
  (setq zone (getkword "\nEnter UTM Zone [43/44] <43>: "))

  (if (null zone)
    (setq zone "43")
  )

  ;; Build Coordinate System Name
  (setq cs (strcat "UTM84-" zone "N"))

  ;; Assign Coordinate System
  (command "_.MAPCSASSIGN" cs)

  ;; Ask whether to turn map on or off
  (initget "On Off")
  (setq mapOpt
        (getkword
          "\nDisplay Bing Hybrid Map? [On/Off] <On>: "
        )
  )

  (if (null mapOpt)
    (setq mapOpt "On")
  )

  (if (= mapOpt "On")
    (command "_.GEOMAP" "_Hybrid")
    (command "_.GEOMAP" "_Off")
  )

  ;; Zoom Extents
  (command "_.ZOOM" "_Extents")

  (princ)
)