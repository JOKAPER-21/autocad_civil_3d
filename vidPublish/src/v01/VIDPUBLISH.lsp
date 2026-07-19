
(vl-load-com)
(setq *VID_ROOT* "J:\\VID_autocad_publish_test")

(setq *VID_YARDS*
'(
("NRK_naraikkinar" . "w1\\MEJ_TEN\\dwg\\yard\\yd_NRK_naraikkinar\\publish")
("GDN_gangaikondan" . "w1\\MEJ_TEN\\dwg\\yard\\yd_GDN_gangaikondan\\publish")
("TAY_talaiyuthu" . "w1\\MEJ_TEN\\dwg\\yard\\yd_TAY_talaiyuthu\\publish")
("TEN_tirunelveli" . "w1\\MEJ_TEN\\dwg\\yard\\yd_TEN_tirunelveli\\publish")
("KTHY_kalthurutty" . "w4\\EDP_QLN\\dwg\\yard\\yd_KTHY_kalthurutty\\publish")
("QLN_kollam" . "w4\\EDP_QLN\\dwg\\yard\\yd_QLN_kollam\\publish")
))

(defun c:VIDPUBLISH (/ yard rel target dwg cmd)
  (command "_.QSAVE")
  (setq yard (getstring T "\\nEnter Yard Name: "))
  (setq rel (cdr (assoc yard *VID_YARDS*)))
  (if rel
    (progn
      (setq dwg (strcat (getvar "DWGPREFIX") (getvar "DWGNAME")))
      (setq target (strcat *VID_ROOT* "\\" rel))
      (setq cmd (strcat "python \"" (findfile "vidpublish.py") "\" \"" dwg "\" \"" target "\" \"" yard "\""))
      (startapp "cmd.exe" (strcat "/c " cmd))
      (princ (strcat "\\nPublished to: " target))
    )
    (princ "\\nYard not found in mapping table.")
  )
  (princ)
)
