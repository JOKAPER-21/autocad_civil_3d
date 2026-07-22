;---------------------------------------------------------------;
;  File        : SM.lsp
;  Command     : SM
;  Title       : Survey Map (UTM Zone Selector)
;
;  Description :
;    Displays a dialog to select the UTM coordinate system
;    (UTM84-43N or UTM84-44N) for AutoCAD Civil 3D.
;
;    Features:
;      • Assigns UTM Zone 43 (UTM84-43N)
;      • Assigns UTM Zone 44 (UTM84-44N)
;      • Enables Hybrid GeoMap
;      • Zooms to Extents after assignment
;      • Option to turn GeoMap Off
;
;  Software    : AutoCAD Civil 3D 2026
;  Version     : 1.0.0
;  Language    : AutoLISP + DCL
;
;  Author      : Rishi
;  Created By  : Rishi
;  Copyright   : © 2026 Rishi. All rights reserved.
;  Created     : 22-Jul-2026
;  Last Update : 22-Jul-2026
;
;  Requirements:
;    • AutoCAD Civil 3D 2026
;    • AutoCAD Map 3D functionality
;    • Internet connection for GeoMap imagery
;
;  Usage:
;    Command: SM
;
;  Notes:
;    - Uses a temporary DCL file generated at runtime.
;    - Coordinate systems:
;        UTM84-43N
;        UTM84-44N
;---------------------------------------------------------------;

(defun c:SM (/ dcl_id zone fname f)
  (setq fname (vl-filename-mktemp "smdlg.dcl"))
  (setq f (open fname "w"))
  (write-line "smdlg : dialog {" f)
  (write-line "  label = \"Select UTM Zone\";" f)
  (write-line "  : boxed_row {" f)
  (write-line "    : button { key = \"b43\"; label = \"  43  \"; }" f)
  (write-line "    : button { key = \"b44\"; label = \"  44  \"; }" f)
  (write-line "    : button { key = \"boff\"; label = \" Off \"; }" f)
  (write-line "  }" f)
  (write-line "  spacer;" f)
  (write-line "  : button { key = \"cancel\"; label = \"Cancel\"; is_cancel = true; }" f)
  (write-line "}" f)
  (close f)

  (setq dcl_id (load_dialog fname))
  (if (not (new_dialog "smdlg" dcl_id))
    (progn (alert "Dialog load failed.") (exit))
  )

  (setq zone nil)

  (action_tile "b43"    "(setq zone \"43\") (done_dialog)")
  (action_tile "b44"    "(setq zone \"44\") (done_dialog)")
  (action_tile "boff"   "(setq zone \"Off\") (done_dialog)")
  (action_tile "cancel" "(done_dialog)")

  (start_dialog)
  (unload_dialog dcl_id)
  (vl-file-delete fname)

  (cond
    ((= zone "Off")
     (command "._GEOMAP" "_Off")
     (princ "\nGeoMap turned Off.")
    )
    ((= zone "43")
     (command "._MAPCSASSIGN" "UTM84-43N")
     (command "._GEOMAP" "_Hybrid")
     (command "._ZOOM" "_E")
    )
    ((= zone "44")
     (command "._MAPCSASSIGN" "UTM84-44N")
     (command "._GEOMAP" "_Hybrid")
     (command "._ZOOM" "_E")
    )
    (t
     (princ "\nCancelled.")
    )
  )
  (princ)
)