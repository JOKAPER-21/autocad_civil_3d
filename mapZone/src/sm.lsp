;---------------------------------------------------------------;
; File Name    : SM.lsp
; Command      : SM
; Title        : Survey Map (UTM Zone Selector)
;
; Description  :
;   Assigns the drawing coordinate system and manages GeoMap
;   display for AutoCAD Civil 3D 2026.
;
; Features
;   • Select UTM84-43N
;   • Select UTM84-44N
;   • Enable Hybrid GeoMap
;   • Zoom Extents automatically
;   • Turn GeoMap Off
;
; Software     : AutoCAD Civil 3D 2026
; Language     : AutoLISP
;
; Author       : Rishi
; Version      : 0.2.0
; Created      : 2026-07-22
; Last Updated : 2026-07-22
;
; Version History
;   v0.1.0
;     - Initial release using DCL dialog.
;
;   v0.2.0
;     - Replaced DCL dialog with command-line prompt.
;     - Added default option (Z43).
;     - Simplified workflow and reduced dependencies.
;
; Usage
;   Command: SM
;
; Coordinate Systems
;   Z43 -> UTM84-43N
;   Z44 -> UTM84-44N
;---------------------------------------------------------------;

(defun c:SM (/ zone csName)
  (initget "Z43 Z44 Off")
  (setq zone (getkword "\nEnter UTM Zone [Z43/Z44/Off] <Z43>: "))
  (if (null zone)
    (setq zone "Z43")
  )
  (cond
    ;; If user selects Off -> switch off GeoMap
    ((= zone "Off")
     (command "._GEOMAP" "_Off")
     (princ "\nGeoMap turned Off.")
    )
    ;; Zone 43
    ((= zone "Z43")
     (command "._MAPCSASSIGN" "UTM84-43N")
     (command "._GEOMAP" "_Hybrid")
     (command "._ZOOM" "_E")
    )
    ;; Zone 44
    ((= zone "Z44")
     (command "._MAPCSASSIGN" "UTM84-44N")
     (command "._GEOMAP" "_Hybrid")
     (command "._ZOOM" "_E")
    )
  )
  (princ)
)