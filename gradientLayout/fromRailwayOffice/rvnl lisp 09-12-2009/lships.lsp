					;*******************LLLLLLLSSSSSSSSS&&&&&&&&CCCCCCCSSSSSSSS*********
					;****************************BASIC FUNCTIONS**************************






(defun c:sf ()
  (initget 3)
  (setq ysc_in (getreal "\nVer-scale factor - 1:"))
  (initget 3)
  (setq xsc_in (getreal "\nHor-scale factor - 1:"))
  (princ)
)

(defun c:preci ()
  (setq	in_rng ""
	in_dec ""
  )
  (while (= (atoi in_rng) 0)
    (princ "\nRange <")
    (princ rng_in)
    (setq in_rng (getstring ">:"))
    (if	(or (= in_rng " ") (= in_rng ""))
      (setq in_rng (itoa rng_in))
    )
  )
  (while (= (atoi in_dec) 0)
    (princ "\nDecimal precision <")
    (princ
      dec_in
    )
    (setq in_dec (getstring ">:"))
    (if	(or (= in_dec " ") (= in_dec ""))
      (setq in_dec (itoa dec_in))
    )
  )
  (setq	rng_in (atoi in_rng)
	dec_in (atoi in_dec)
	grgap  (txht rng_in dec_in)
  )
  (princ)
)

					;*****************************MAIN FUNCTIONS********************************

;;;;DATUM

(defun c:sec_dtm ()

  (if (and (not ysc_in) (not xsc_in))
    (progn
      (alert
	"*error*
Set scale factors and try again !!!
command : scf"
      )
      (exit)
    )

    (progn
      (initget 1)
      (setq dt_inp (getreal "\nEnter datum :")
	    in_dtm (rtos dt_inp 2 dec_in)
	    datum_ (strcat in_dtm "m")
	    datumm (strcat "DATUM " datum_)
	    dtm_pt (/ (* dt_inp 1000) ysc_in)
      )
    )
  )
  (princ)
)

;;;;CHAINAGE

(defun c:sec_dist ()
  (setq	in_lch (getstring "\n Enter distance :")
  )
)

(defun c:sec_level ()
  (if (/= (strcase in_lch) "U")
    (setq in_lvl     (getstring "\n Enter level :")
	  old_in_lvl in_lvl
    )
    (progn (if (/= old_in_lvl nil)
	     (progn
	       (repeat 4
		 (command "erase" (entlast) "")
	       )
	       (setq linlst	(dellast linlst)
		     old_textp1	(list 0 0)
		     old_justi	"bl"
		     txdist	0
	       )
	     )
	   )
	   (setq in_lvl "U")
    )
  )
)

(defun c:sec_data_build1 ()

  (setq	lv_inp (atof in_lvl)
	ch_inp (atof in_lch)
	in_lvl (rtos lv_inp 2 dec_in)
	in_lch (rtos ch_inp 2 dec_in)
	lvl_pt (- (/ (* lv_inp 1000) ysc_in) dtm_pt)
	chn_pt (neg (/ (* ch_inp 1000) xsc_in))
	coordi (list chn_pt (+ grgap lvl_pt))
	str_pt (list (car coordi) 0)
	brk_pt (polar str_pt (dtr 90) grgap)
	linlst (append linlst (list coordi))
	textp1 (list (car coordi) 2)
	textp2 (list (car coordi) (+ 2 (/ grgap 2)))
	txdist (distance old_textp1 textp1)
  )
)

(defun c:sec_data_build2 ()

  (setq	lv_inp (atof in_lvl)
	ch_inp (atof in_lch)
	in_lvl (rtos lv_inp 2 dec_in)
	in_lch (rtos ch_inp 2 dec_in)
	lvl_pt (- (/ (* lv_inp 1000) ysc_in) dtm_pt)
	chn_pt (/ (* ch_inp 1000) xsc_in)
	coordi (list chn_pt (+ grgap lvl_pt))
	str_pt (list (car coordi) 0)
	brk_pt (polar str_pt (dtr 90) grgap)
	linlst (append linlst (list coordi))
	textp1 (list (car coordi) 2)
	textp2 (list (car coordi) (+ 2 (/ grgap 2)))
	txdist (distance old_textp1 textp1)
  )
)

(defun c:plot_sec_details ()
  (cond	((= old_justi "bl")
	 (if (< txdist 3)
	   (setq justi	"tl"
		 textp1	(list (1+ (car textp1)) (cadr textp1))
		 textp2	(list (1+ (car textp2)) (cadr textp2))
	   )
	   (setq justi "bl")
	 )
	)
	((= old_justi "tl")
	 (if (>= txdist 7)
	   (setq justi "bl")
	   (setq justi	"tl"
		 textp1	(list (1+ (car textp1)) (cadr textp1))
		 textp2	(list (1+ (car textp2)) (cadr textp2))
	   )
	 )
	)
  )
  (command "-layer" "s"	     "grid"   ""       "line"	str_pt
	   brk_pt   ""	     "-layer" "s"      "hidden"	""
	   "line"   brk_pt   coordi   ""       "-layer"	"s"
	   "text"   ""	     "text"   "s"      "section"
	   justi    textp1   "90"     in_lch   "text"	"s"
	   "section"	     justi    textp2   "90"	in_lvl
	  )
  (setq	old_textp1
	 textp1
	old_justi justi
  )
)

(defun c:grid_finishing	()

  (setq	gr1_st	 (list (car (assoc (car asclst) linlst)) 0)
	gr1_nd	 (list (car (assoc (last asclst) linlst)) 0)
	gr1_md	 (polar gr1_st (dtr 0) (/ (distance gr1_st gr1_nd) 2))
	gr2_st	 (polar gr1_st (dtr 90) (/ grgap 2))
	gr2_nd	 (polar gr1_nd (dtr 90) (/ grgap 2))
	gr2_xn	 (polar gr2_st (dtr 180) (* 1.5 grgap))
	gr3_st	 (polar gr1_st (dtr 90) grgap)
	gr3_nd	 (polar gr1_nd (dtr 90) grgap)
	gr3_xn	 (polar gr3_st (dtr 180) (* 1.5 grgap))
	tx1_pt	 (polar gr3_xn (dtr 270) (/ grgap 4))
	tx2_pt	 (polar tx1_pt (dtr 270) (/ grgap 2))
	str_pt	 (polar gr3_xn (dtr 0) grgap)
	dat_pt	 (polar gr3_xn (dtr 90) 5)
	set_zero 0

  )
  (command
    "-layer"  "s"	"grid"	  ""	    "line"    gr1_st
    gr1_nd    ""	"line"	  gr2_st    gr2_nd    ""
    "line"    gr3_st	gr3_nd	  ""	    "line"    gr3_st
    gr3_xn    ""	"line"	  gr2_st    gr2_xn    ""
    "pline"   str_pt	"@3<120"  "@3<0"    "c"	      "-layer"
    "s"	      "text"	""	  "text"    "s"	      "section"
    "ml"      tx1_pt	"0"	  "LEVELS"  "text"    "s"
    "section" "ml"	tx2_pt	  "0"	    "DISTANCE"
    "text"    ""	"IN METERS"	    "move"    "l"
    ""	      tx2_pt	"@2.5<180"	    "text"    "s"
    "section" "ml"	dat_pt	  "0"	    datumm
   )
)

(defun c:plot_cs ()

  (setvar "cmdecho" 0)

  (setq	in_lch "1"
	in_lvl "1"
  )
  (c:sec_dtm)
  (while (and (/= in_lvl "") (/= in_lvl " "))
    (cond
      ((= set_zero 0)
       (c:sec_dist)
       (if (and (/= in_lch " ") (/= in_lch ""))
	 (progn
	   (c:sec_level)
	   (if (and (/= in_lvl "")
		    (/= in_lvl " ")
		    (/= (strcase in_lvl) "U")
	       )
	     (progn (c:sec_data_build1)
		    (c:plot_sec_details)
		    (if	(= (atof in_lch) 0.00)
		      (setq set_zero 1)
		    )
	     )
	     (setq in_lch "1")
	   )
	 )
	 (setq in_lvl "")
       )
      )
      ((= set_zero 1)
       (c:sec_dist)
       (if (and (/= in_lch " ") (/= in_lch ""))
	 (progn
	   (c:sec_level)
	   (if (and (/= in_lvl "")
		    (/= in_lvl " ")
		    (/= (strcase in_lvl) "U")
	       )
	     (progn (c:sec_data_build2)
		    (c:plot_sec_details)
	     )
	     (setq in_lch "1")
	   )
	 )
	 (setq in_lvl "")
       )
      )
    )
  )
  (initget 1 "Y,Yes N,No")
  (setq condi (getstring "\nFinished entering datas[Y/N]?"))
  (if (= (strcase condi) "Y")
    (progn
      (c:make_order)
      (c:grid_finishing)
      (c:draw_surface)
      (setq headtx (getstring "\nCROSS SECTION AT CHAINAGE ")
	    hea_tx (strcase headtx)
      )
      (command "text"
	       "s"
	       "heading"
	       "j"
	       "c"
	       (list (car gr1_md) -10)
	       "0"
	       "CROSS SECTION AT CHAINAGE"
	       "text"
	       ""
	       hea_tx
      )
    )
  )
)

(defun c:make_order ()

  (setq	firlst (list 0)
	first_ nil
	cnt_or 0
	linlen (length linlst)
					;linlst (cdr linlst)
  )
  (repeat linlen
    (setq first_ (car (nth cnt_or linlst))
	  firlst (append firlst (list first_))
	  cnt_or (1+ cnt_or)
    )
  )
  (setq	firlst (cdr firlst)
	asclst (list 0)
  )
  (repeat (length firlst)
    (setq firmin (apply 'min firlst)
	  firmem (cdr (member firmin firlst))
	  memlen (length firmem)
	  firbal (abs (- memlen (1- (length firlst))))
	  asclst (append asclst (list firmin))
	  cnt_or 0
	  tmplst (list 0)
    )
    (if	(= firbal 0)
      (setq firlst firmem)
      (progn
	(repeat	firbal
	  (setq	tmpval (nth cnt_or firlst)
		tmplst (append tmplst (list tmpval))
		cnt_or (1+ cnt_or)
	  )
	)
	(setq tmplst (cdr tmplst)
	      firlst (append firmem tmplst)
	)
      )
    )
  )
  (setq asclst (cdr asclst))
)

(defun c:draw_surface ()

  (setq	cnt_st 0
	asclen (length asclst)
  )
  (command "-layer" "s" "surface" "" "pline")
  (repeat asclen
    (setq compar (nth cnt_st asclst)
	  sur_pt (assoc compar linlst)
	  cnt_st (1+ cnt_st)
    )
    (command sur_pt)
  )
  (command "" "-layer" "s" "0" "")
  (setq	linlst nil
	set_zero 0
	old_in_ldec
	 nil
  )
)


(defun c:reset ()
  (setq	rng_in	    3
	dec_in	    2
	old_in_lch  nil
	old_in_ldec nil
	grgap	    (txht rng_in dec_in)
	set_zero    0			;linlst	(list 0)
	txdist	    5
	old_textp1  (list 0 0)
  )
)

(defun c:plot_ls ()

  (setvar "cmdecho" 0)

  (setq	in_lch "1"
	in_lvl "1"
  )
  (c:sec_dtm)
  (while (and (/= in_lvl "") (/= in_lvl " "))
    (c:sec_dist)
    (if	(and (/= in_lch " ") (/= in_lch ""))
      (progn
	(c:sec_level)
	(if (and (/= in_lvl "")
		 (/= in_lvl " ")
		 (/= (strcase in_lvl) "U")
	    )
	  (progn (c:sec_data_build2)
		 (c:plot_sec_details)
	  )
	  (setq in_lch "1")
	)
      )
      (setq in_lvl "")
    )
  )
  (initget 1 "Y,Yes N,No")
  (setq condi (getstring "\nFinished entering datas[Y/N]?"))
  (if (= (strcase condi) "Y")
    (progn
      (c:make_order)
      (c:grid_finishing)
      (c:draw_surface)
      (setq headtx1 (getstring "\nLONGITUDINAL SECTION FROM CHAINAGE ")
	    headtx2 (getstring "\nTO")
	    headtx  (strcat headtx1 (strcat " to " headtx2))
	    hea_tx  (strcase headtx)
      )
      (command "text"
	       "s"
	       "heading"
	       "j"
	       "c"
	       (list (car gr1_md) -10)
	       "0"
	       "LONGITUDINAL SECTION FROM CHAINAGE"
	       "text"
	       ""
	       hea_tx
      )
    )
  )
)


					;**********************APPLICATION 
FUNCTIONS*******************************

(defun c:cs ()
					;AUTOMATIC CROSS SECTION & LONGITUDINAL SECTION PLOTTING PROGRAM
					;	Funtions : 1. SF (scale factor)	  
					;		   2. CS (cross section plotting)
					;		   3. LS (longitudinal section plotting)
					;******************************STANDARD SETTINGS******************************

  (defun dtr (x) (* (/ pi 180) x))
  (defun neg (x) (- 0 x))
  (command "osmode" "0")
  (command "cmdecho" "0")
  (setvar "filedia" 0)
  (if (not (tblsearch "ltype" "hidden"))
    (command "-linetype" "l" "hidden" "acad.lin" "" "ltscale" "15")
  )
  (command "-layer"	   "m"	   "grid"  "c"	   "4"	   ""
	   "m"	   "text"  "c"	   "1"	   ""	   "m"	   "surface"
	   "c"	   "3"	   ""	   "m"	   "hidden"	   "c"
	   "2"	   ""	   "lt"	   "hidden"	   ""	   ""
	  )
  (if (not (tblsearch "style" "section"))
    (command "-style" "section" "romans" "2.5" "" "" "" "" "")
  )
  (if (not (tblsearch "style" "heading"))
    (command "-style" "heading" "romant" "3.0" "" "" "" "" "")
  )
  (setvar "filedia" 1)
  (setvar "dimzin" 2)
  (command "zoom" "c" "0,0" "200")

					;******************************USER DEFINED*******************************

  (defun dtr (x) (* (/ pi 180) x))
  (defun neg (x) (- 0 x))
  (defun txht (x y) (* (+ (* (+ x y) 2) 7) 2))
  (defun dellast (x)
    (setq _x 0
	  y  nil
    )
    (repeat (1- (length x))
      (setq y  (append y (list (nth _x x)))
	    _x (1+ _x)
      )
    )
    (setq x y)
  )

					;******************************GLOBAL VARIABLES*******************************

  (setq	rng_in	    3
	dec_in	    2
	old_in_lch  nil
	old_in_ldec nil
	grgap	    (txht rng_in dec_in)
	set_zero    0			;linlst	(list 0)
	txdist	    5
	old_textp1  (list 0 0)
	old_justi   "bl"
  )


  (c:plot_cs)
)
(defun c:ls ()
  AUTOMATIC
  CROSS
  SECTION
  &
  LONGITUDINAL
  SECTION
  PLOTTING
  PROGRAM
					;
					;	Funtions : 1. SF (scale factor)	  
					;		   2. CS (cross section plotting)
					;		   3. LS (longitudinal section plotting)
					;
					;	
					;






					;******************************STANDARD SETTINGS******************************

  (defun dtr (x) (* (/ pi 180) x))
  (defun neg (x) (- 0 x))
  (command "osmode" "0")
  (command "cmdecho" "0")
  (setvar "filedia" 0)
  (if (not (tblsearch "ltype" "hidden"))
    (command "-linetype" "l" "hidden" "acad.lin" "" "ltscale" "15")
  )
  (command "-layer"	   "m"	   "grid"  "c"	   "4"	   ""
	   "m"	   "text"  "c"	   "1"	   ""	   "m"	   "surface"
	   "c"	   "3"	   ""	   "m"	   "hidden"	   "c"
	   "2"	   ""	   "lt"	   "hidden"	   ""	   ""
	  )
  (if (not (tblsearch "style" "section"))
    (command "-style" "section" "romans" "2.5" "" "" "" "" "")
  )
  (if (not (tblsearch "style" "heading"))
    (command "-style" "heading" "romant" "3.0" "" "" "" "" "")
  )
  (setvar "filedia" 1)
  (setvar "dimzin" 2)
  (command "zoom" "c" "0,0" "200")

					;******************************USER DEFINED*******************************

  (defun dtr (x) (* (/ pi 180) x))
  (defun neg (x) (- 0 x))
  (defun txht (x y) (* (+ (* (+ x y) 2) 7) 2))
  (defun dellast (x)
    (setq _x 0
	  y  nil
    )
    (repeat (1- (length x))
      (setq y  (append y (list (nth _x x)))
	    _x (1+ _x)
      )
    )
    (setq x y)
  )

					;******************************GLOBAL VARIABLES*******************************

  (setq	rng_in	    3
	dec_in	    2
	old_in_lch  nil
	old_in_ldec nil
	grgap	    (txht rng_in dec_in)
	set_zero    0			;linlst	(list 0)
	txdist	    5
	old_textp1  (list 0 0)
	old_justi   "bl"
  )


  (c:plot_ls)
)

					;***************************LS & CS END****************************************

					;********************LAYERS    EMD*********CHT       START*****************************
(defun chtxt (/	      sset    opt     ssl     nsset   temp    unctr
	      ct_ver  cht_er  cht_oe  sslen   style   hgt     rot
	      txt     ent     cht_oc  cht_ot  cht_oh  loc     loc1
	      justp   justq   orthom
	     )

  (setq ct_ver "1.02")			; Reset this local if you make a change.
  (defun cht_er	(s)			; If an error (such as CTRL-C) occurs
					; while this command is active...
    (if	(/= s "Function cancelled")
      (if (= s "quit / exit abort")
	(princ)
	(princ (strcat "\nError: " s))
      )
    )
    (eval (read U:E))
    (if	cht_oe				; If an old error routine exists
      (setq *error* cht_oe)		; then, reset it 
    )
    (if	temp
      (redraw temp 1)
    )
    (if	cht_oc
      (setvar "cmdecho" cht_oc)
    )					; Reset command echoing
    (if	cht_ot
      (setvar "texteval" cht_ot)
    )
    (if	cht_oh
      (setvar "highlight" cht_oh)
    )
    (princ)
  )
  (if *error*				; Set our new error handler
    (setq cht_oe  *error*
	  *error* cht_er
    )
    (setq *error* cht_er)
  )

  (setq	U:G "(command \"undo\" \"group\")"
	U:E "(command \"undo\" \"en\")"
  )

  (setq cht_oc (getvar "cmdecho"))
  (setq cht_oh (getvar "highlight"))
  (setvar "cmdecho" 0)

  (eval (read U:G))

  (princ (strcat "\nChange text, Version "
		 ct_ver
		 ", (c) 1990-1991 by Autodesk, Inc. "
	 )
  )
  (prompt "\nSelect text to change. ")
  (setq sset (ssget))
  (if (null sset)
    (progn
      (princ "\nERROR: Nothing selected.")
      (exit)
    )
  )
  ;; Verify the entity set.
  (cht_ve)
  ;; This is the main option loop.
  (cht_ol)

  (if cht_oe
    (setq *error* cht_oe)
  )					; Reset old error function if error
  (eval (read U:E))
  (if cht_ot
    (setvar "texteval" cht_ot)
  )
  (if cht_oh
    (setvar "highlight" cht_oh)
  )
  (if cht_oc
    (setvar "cmdecho" cht_oc)
  )					; Reset command echoing
  (princ)
)
(defun cht_ve ()
  (setq	ssl   (sslength sset)
	nsset (ssadd)
  )
  (if (> ssl 25)
    (princ "\nVerifying the selected entities -- please wait. ")
  )
  (while (> ssl 0)
    (setq temp (ssname sset (setq ssl (1- ssl))))
    (if	(= (cdr (assoc 0 (entget temp))) "TEXT")
      (ssadd temp nsset)
    )
  )
  (setq	ssl   (sslength nsset)
	sset  nsset
	unctr 0
  )
  (print ssl)
  (princ "text entities found. ")
)
(defun cht_ol ()
  (setq opt T)
  (while (and opt (> ssl 0))
    (setq unctr (1+ unctr))
    (command "_.UNDO" "_GROUP")
    (initget
      "Location Justification Style Height Rotation Width Text Undo"
    )
    (setq opt
	   (getkword
	     "\nHeight/Justification/Location/Rotation/Style/Text/Undo/Width: "
	   )
    )
    (if	opt
      (cond
	((= opt "Undo")
	 (cht_ue)			; Undo the previous command.
	)
	((= opt "Location")
	 (cht_le)			; Change the location.
	)
	((= opt "Justification")
	 (cht_je)			; Change the justification.
	)
	((= opt "Style") (cht_pe "Style" "style name" 7))
	((= opt "Height") (cht_pe "Height" "height" 40))
	((= opt "Rotation") (cht_pe "Rotation" "rotation angle" 50))
	((= opt "Width") (cht_pe "Width" "width factor" 41))
	((= opt "Text")
	 (cht_te)			; Change the text.
	)
      )
      (setq opt nil)
    )
    (command "_.UNDO" "_END")
  )
)
(defun cht_ue ()
  (if (> unctr 1)
    (progn
      (command "_.UNDO" "_END")
      (command "_.UNDO" "2")
      (setq unctr (- unctr 2))
    )
    (progn
      (princ "\nNothing to undo. ")
      (setq unctr (- unctr 1))
    )
  )
)
(defun cht_le ()
  (setq	sslen (sslength sset)
	style ""
	hgt   ""
	rot   ""
	txt   ""
  )
  (command "_.CHANGE" sset "" "")
  (while (> sslen 0)
    (setq ent (entget (ssname sset (setq sslen (1- sslen))))
	  opt (list (cadr (assoc 11 ent))
		    (caddr (assoc 11 ent))
		    (cadddr (assoc 11 ent))
	      )
    )
    (prompt "\nNew text location: ")
    (command pause)
    (if	(null loc)
      (setq loc opt)
    )
    (command style hgt rot txt)
  )
  (command)
)
(defun cht_je ()
  (if (getvar "DIMCLRD")
    (initget (strcat "TLeft TCenter TRight "
		     "MLeft MCenter MRight "
		     "BLeft BCenter BRight "
		     "Aligned Center Fit Left Middle Right ?"
	     )
    )
    (initget "Aligned Center Fit Left Middle Right ?")
  )
  (setq sslen (sslength sset))
  (setq	justp (getkword
		(strcat	"\nJustification point(s) - "
			"Aligned/Center/Fit/Left/Middle/Right/<?>: "
		)
	      )
  )
  (cond
    ((= justp "Left")
     (setq justp 0
	   justq 0
     )
    )
    ((= justp "Center")
     (setq justp 1
	   justq 0
     )
    )
    ((= justp "Right")
     (setq justp 2
	   justq 0
     )
    )
    ((= justp "Aligned")
     (setq justp 3
	   justq 0
     )
    )
    ((= justp "Fit")
     (setq justp 5
	   justq 0
     )
    )
    ((= justp "TLeft")
     (setq justp 0
	   justq 3
     )
    )
    ((= justp "TCenter")
     (setq justp 1
	   justq 3
     )
    )
    ((= justp "TRight")
     (setq justp 2
	   justq 3
     )
    )
    ((= justp "MLeft")
     (setq justp 0
	   justq 2
     )
    )
    ((= justp "Middle")
     (setq justp 4
	   justq 0
     )
    )
    ((= justp "MCenter")
     (setq justp 1
	   justq 2
     )
    )
    ((= justp "MRight")
     (setq justp 2
	   justq 2
     )
    )
    ((= justp "BLeft")
     (setq justp 0
	   justq 1
     )
    )
    ((= justp "BCenter")
     (setq justp 1
	   justq 1
     )
    )
    ((= justp "BRight")
     (setq justp 2
	   justq 1
     )
    )
    ((= justp "?") (setq justp nil))
    (T (setq justp nil))
  )
  (if justp
    (justpt)				; Process them...
    (justpn)				; List options...
  )
  (command)
)
(defun justpt ()
  (while (> sslen 0)
    (setq ent (entget (ssname sset (setq sslen (1- sslen))))
	  ent (subst (cons 72 justp) (assoc 72 ent) ent)
	  opt (trans (list (cadr (assoc 11 ent))
			   (caddr (assoc 11 ent))
			   (cadddr (assoc 11 ent))
		     )
		     (cdr (assoc -1 ent)) ; from ECS
		     1
	      )				; to current UCS
    )
    (if	(getvar "DIMCLRD")
      (setq ent (subst (cons 73 justq) (assoc 73 ent) ent))
    )
    (cond
      ((or (= justp 3) (= justp 5))
       (prompt "\nNew text alignment points: ")
       (if (= (setq orthom (getvar "orthomode")) 1)
	 (setvar "orthomode" 0)
       )
       (redraw (cdr (assoc -1 ent)) 3)
       (initget 1)
       (setq loc (getpoint))
       (initget 1)
       (setq loc1 (getpoint loc))
       (redraw (cdr (assoc -1 ent)) 1)
       (setvar "orthomode" orthom)
       (setq ent (subst (cons 10 loc) (assoc 10 ent) ent))
       (setq ent (subst (cons 11 loc1) (assoc 11 ent) ent))
      )
      ((or (/= justp 0) (/= justq 0))
       (redraw (cdr (assoc -1 ent)) 3)
       (prompt "\nNew text location: ")
       (if (= (setq orthom (getvar "orthomode")) 1)
	 (setvar "orthomode" 0)
       )
       (setq loc (getpoint opt))
       (setvar "orthomode" orthom)
       (redraw (cdr (assoc -1 ent)) 1)
       (if (null loc)
	 (setq loc opt)
	 (setq loc (trans loc 1 (cdr (assoc -1 ent))))
       )
       (setq ent (subst (cons 11 loc) (assoc 11 ent) ent))
      )
    )
    (entmod ent)
  )
)
(defun justpn ()
  (if (getvar "DIMCLRD")
    (textpage)
  )
  (princ "\nAlignment options: ")
  (princ "\n\t TLeft   TCenter   TRight ")
  (princ "\n\t MLeft   MCenter   MRight ")
  (princ "\n\t BLeft   BCenter   BRight ")
  (princ "\n\t  Left    Center    Right")
  (princ "\n\tAligned   Middle    Fit")
  (if (not (getvar "DIMCLRD"))
    (textscr)
  )
  (princ "\n\nPress any key to return to your drawing. ")
  (grread)
  (princ "\r                                           ")
  (graphscr)
)
(defun cht_te ()
  (setq sslen (sslength sset))
  (initget "Globally Individually Retype")
  (setq	ans
	 (getkword
	   "\nSearch and replace text.  Individually/Retype/<Globally>:"
	 )
  )
  (setq cht_ot (getvar "texteval"))
  (setvar "texteval" 1)
  (cond
    ((= ans "Individually")
     (if (= (getvar "popups") 1)
       (progn
	 (initget "Yes No")
	 (setq ans (getkword "\nEdit text in dialogue? <Yes>:"))
       )
       (setq ans "No")
     )

     (while (> sslen 0)
       (redraw (setq sn (ssname sset (setq sslen (1- sslen)))) 3)
       (setq ss (ssadd))
       (ssadd (ssname sset sslen) ss)
       (if (= ans "No")
	 (chgtext ss)
	 (command "_.DDEDIT" sn "")
       )
       (redraw sn 1)
     )
    )
    ((= ans "Retype")
     (while (> sslen 0)
       (setq ent (entget (ssname sset (setq sslen (1- sslen)))))
       (redraw (cdr (assoc -1 ent)) 3)
       (prompt (strcat "\nOld text: " (cdr (assoc 1 ent))))
       (setq nt (getstring T "\nNew text: "))
       (redraw (cdr (assoc -1 ent)) 1)
       (if (> (strlen nt) 0)
	 (entmod (subst (cons 1 nt) (assoc 1 ent) ent))
       )
     )
    )
    (T
     (chgtext sset)			; Change 'em all
    )
  )
  (setvar "texteval" cht_ot)
)
(defun C:CHGTEXT () (chgtext nil))

(defun chgtext (objs   /      last_o tot_o  ent	   o_str  n_str	 st
		s_temp n_slen o_slen si	    chf	   chm	  cont	 ans
	       )
  (if (null objs)
    (setq objs (ssget))			; Select objects if running standalone
  )
  (setq chm 0)
  (if objs
    (progn				; If any objects selected
      (if (= (type objs) 'ENAME)
	(progn
	  (setq ent (entget objs))
	  (princ (strcat "\nExisting string: " (cdr (assoc 1 ent))))
	)
	(if (= (sslength objs) 1)
	  (progn
	    (setq ent (entget (ssname objs 0)))
	    (princ (strcat "\nExisting string: " (cdr (assoc 1 ent))))
	  )
	)
      )
      (setq o_str (getstring "\nMatch string   : " t))
      (setq o_slen (strlen o_str))
      (if (/= o_slen 0)
	(progn
	  (setq n_str (getstring "\nNew string     : " t))
	  (setq n_slen (strlen n_str))
	  (setq	last_o 0
		tot_o  (if (= (type objs) 'ENAME)
			 1
			 (sslength objs)
		       )
	  )
	  (while (< last_o tot_o)	; For each selected object...
	    (if
	      (= "TEXT"			; Look for TEXT entity type (group 0)
		 (cdr (assoc 0 (setq ent (entget (ssname objs last_o)))))
	      )
	       (progn
		 (setq chf nil
		       si  1
		 )
		 (setq s_temp (cdr (assoc 1 ent)))
		 (while	(= o_slen
			   (strlen (setq st (substr s_temp si o_slen)))
			)
		   (if (= st o_str)
		     (progn
		       (setq s_temp (strcat
				      (if (> si 1)
					(substr s_temp 1 (1- si))
					""
				      )
				      n_str
				      (substr s_temp (+ si o_slen))
				    )
		       )
		       (setq chf t)	; Found old string
		       (setq si (+ si n_slen))
		     )
		     (setq si (1+ si))
		   )
		 )
		 (if chf
		   (progn		; Substitute new string for old
					; Modify the TEXT entity
		     (entmod (subst (cons 1 s_temp) (assoc 1 ent) ent))
		     (setq chm (1+ chm))
		   )
		 )
	       )
	    )
	    (setq last_o (1+ last_o))
	  )
	)
      )
    )
  )
  (if (/= (type objs) 'ENAME)
    (if	(/= (sslength objs) 1)		; Print total lines changed
      (princ (strcat "Changed "
		     (rtos chm 2 0)
		     " text lines."
	     )
      )
    )
  )
  (terpri)
)
(defun cht_pe (typ prmpt fld / temp ow nw ent tw sty w hw lw sslen n sn
	       ssl)
  (if (= (sslength sset) 1)
    (cht_p1)
    (progn
      (cht_sp)
      (if (= nw "List")
	(cht_pl)
	(if (= nw "Individual")
	  (cht_pi)
	  (if (= nw "Select")
	    (cht_ps)
	    (progn
	      (if (= typ "Rotation")
		(setq nw (* (/ nw 180.0) pi))
	      )
	      (if (= (type nw) 'STR)
		(if (not (tblsearch "style" nw))
		  (progn
		    (princ (strcat "\nStyle " nw " not found. "))
		  )
		  (cht_pa)
		)
		(cht_pa)
	      )
	    )
	  )
	)
      )
    )
  )
)
(defun cht_pa (/ cht_oh temp)
  (setq sslen (sslength sset))
  (setq cht_oh (getvar "highlight"))
  (setvar "highlight" 0)
  (while (> sslen 0)
    (setq temp (ssname sset (setq sslen (1- sslen))))
    (entmod (subst (cons fld nw)
		   (assoc fld (setq ent (entget temp)))
		   ent
	    )
    )

  )
  (setvar "highlight" cht_oh)
)
(defun cht_p1 ()
  (setq temp (ssname sset 0))
  (setq ow (cdr (assoc fld (entget temp))))
  (if (= opt "Rotation")
    (setq ow (/ (* ow 180.0) pi))
  )
  (redraw (cdr (assoc -1 (entget temp))) 3)
  (initget 0)
  (if (= opt "Style")
    (setq nw (getstring	(strcat "\nNew " prmpt ". <" ow ">: ")
	     )
    )
    (setq nw (getreal (strcat "\nNew "
			      prmpt
			      ". <"
			      (rtos ow 2)
			      ">: "
		      )
	     )
    )
  )
  (if (or (= nw "") (= nw nil))
    (setq nw ow)
  )
  (redraw (cdr (assoc -1 (entget temp))) 1)
  (if (= opt "Rotation")
    (setq nw (* (/ nw 180.0) pi))
  )
  (if (= opt "Style")
    (if	(null (tblsearch "style" nw))
      (princ (strcat "\nStyle " nw " not found. "))

      (entmod (subst (cons fld nw)
		     (assoc fld (setq ent (entget temp)))
		     ent
	      )
      )
    )
    (entmod (subst (cons fld nw)
		   (assoc fld (setq ent (entget temp)))
		   ent
	    )
    )
  )
)
(defun cht_sp ()
  (if (= typ "Style")
    (progn
      (initget "Individual List New Select ")
      (setq
	nw (getkword (strcat "\nIndividual/List/Select style/<New "
			     prmpt
			     " for all text entities>: "
		     )
	   )
      )
      (if (or (= nw "") (= nw nil) (= nw "Enter"))
	(setq nw (getstring (strcat "\nNew "
				    prmpt
				    " for all text entities: "
			    )
		 )
	)
      )
    )
    (progn
      (initget "List Individual" 1)
      (setq nw (getreal	(strcat	"\nIndividual/List/<New "
				prmpt
				" for all text entities>: "
			)
	       )
      )
    )
  )
)
(defun cht_pl ()
  (setq unctr (1- unctr))
  (setq sslen (sslength sset))
  (setq tw 0)
  (while (> sslen 0)
    (setq temp (ssname sset (setq sslen (1- sslen))))
    (if	(= typ "Style")
      (progn
	(if (= tw 0)
	  (setq tw (list (cdr (assoc fld (entget temp)))))
	  (progn
	    (setq sty (cdr (assoc fld (entget temp))))
	    (if	(not (member sty tw))
	      (setq tw (append tw (list sty)))
	    )
	  )
	)
      )
      (progn
	(setq tw (+ tw (setq w (cdr (assoc fld (entget temp))))))
	(if (= (sslength sset) (1+ sslen))
	  (setq	lw w
		hw w
	  )
	)
	(if (< hw w)
	  (setq hw w)
	)
	(if (> lw w)
	  (setq lw w)
	)
      )
    )
  )
  (if (= typ "Rotation")
    (setq tw (* (/ tw pi) 180.0)
	  lw (* (/ lw pi) 180.0)
	  hw (* (/ hw pi) 180.0)
    )
  )
  (if (= typ "Style")
    (progn
      (princ (strcat "\n"
		     typ
		     "(s) -- "
	     )
      )
      (princ tw)
    )
    (princ (strcat "\n"
		   typ
		   " -- Min: "
		   (rtos lw 2)
		   "\t Max: "
		   (rtos hw 2)
		   "\t Avg: "
		   (rtos (/ tw (sslength sset)) 2)
	   )
    )
  )
)
(defun cht_pi ()
  (setq sslen (sslength sset))
  (while (> sslen 0)
    (setq temp (ssname sset (setq sslen (1- sslen))))
    (setq ow (cdr (assoc fld (entget temp))))
    (if	(= typ "Rotation")
      (setq ow (/ (* ow 180.0) pi))
    )
    (initget 0)
    (redraw (cdr (assoc -1 (entget temp))) 3)
    (if	(= typ "Style")
      (progn
	(setq nw (getstring (strcat "\nNew " prmpt ". <" ow ">: ")
		 )
	)
      )
      (progn
	(setq nw (getreal (strcat "\nNew "
				  prmpt
				  ". <"
				  (rtos ow 2)
				  ">: "
			  )
		 )
	)
      )
    )
    (if	(or (= nw "") (= nw nil))
      (setq nw ow)
    )
    (if	(= typ "Rotation")
      (setq nw (* (/ nw 180.0) pi))
    )
    (entmod (subst (cons fld nw)
		   (assoc fld (setq ent (entget temp)))
		   ent
	    )
    )
    (redraw (cdr (assoc -1 (entget temp))) 1)
  )
)
(defun cht_ps ()
  (princ "\nSearch for which Style name?  <*>: ")
  (setq	sn    (strcase (getstring))
	n     -1
	nsset (ssadd)
	ssl   (1- (sslength sset))
  )
  (if (or (= sn "*") (null sn) (= sn ""))
    (setq nsset	sset
	  sn	"*"
    )
    (while (and sn (< n ssl))
      (setq temp (ssname sset (setq n (1+ n))))
      (if (= (cdr (assoc 7 (entget temp))) sn)
	(ssadd temp nsset)
      )
    )
  )
  (setq ssl (sslength nsset))
  (princ "\nFound ")
  (princ ssl)
  (princ " text entities with STYLE of ")
  (princ sn)
  (princ ". ")
)
(defun c:cht () (chtxt))
					;**************************************CHT    END*******************


(defun c:* ()
  (setvar "osmode" 0)
  (setvar "cmdecho" 0)
  (command "style" "RS" "romans" "" "" "" "" "" "")
  (setq filnam (getfiled "Select Data File" "" "prn" 2))
  (setq op (open filnam "r"))
  (setq n 0)
  (princ "\n Point importing Please wait..... ")
  (while (setq re (read-line op))
    (setq xcor (rtos (read (substr re 13 12))))
    (setq ycor (rtos (read (substr re 25 12))))
    (setq zcor (rtos (read (substr re 37 12))))
    (setq lay (substr re 49))
    (Setq slno (rtos (read (substr re 1 12))))
    (setq inspt (strcat xcor "," ycor "," zcor))
    (setq pnt (strcat xcor "," ycor))
    (command "layer" "m" "Points" "")
					;(command "pdmode" "3")
    ;(command "pdsize" "0.25")
    ;(command "Point" pnt)
    (command "layer" "m" "Code" "C" "191" "" "")
    (command "Text" inspt "0.5" "0" lay)
    ;(command "layer" "m" "LVL" "C" "6" "" "")
    ;(command "Text" inspt "0.5" "45" zcor)
    (setq n (1+ n))
  )
  (close op)
  (princ (rtos n 2 0))
  (PROGN "Data points imported")
  (command "zoom" "0.8X")

)

(Defun c:Expt ()
  (setq	fname (getstring "Enter the file name with extension <prn>: ")
	ss    (ssget "x" (list (CONS 0 "ELEVATION") (cons 8 "`CODE")))
	n     0
	e     (ssname ss n)
	fhan  (open fname "a")
  )
  (while (/= e nil)
    (setq txt (cdr (assoc 1 (entget e)))
	  co  (cdr (assoc 10 (entget e)))
	  x   (rtos (nth 0 co) 2 3)
	  y   (rtos (nth 1 co) 2 3)
	  z   (rtos (nth 2 co) 2 3)
	  lin (strcat "," x "," y "," z "," TXT)
    )
    (write-line lin fhan)
    (setq n (+ 1 n)
	  e (ssname ss n)
    )
  )
  (close fhan)
  (princ (rtos N 2 0))
  (PROGN "Points Exported")
)


(defun c:Tin ()
  (setq cod (getstring "\nEnter CODE name:"))
  (setq blk (getstring "\nEnter BLOCK name:"))
  (setq ss1 (ssget "x" (list (cons 0 "TEXT") (cons 1 COD))))
  (setq n 0)
  (repeat (sslength ss1)
    (setq nam (ssname ss1 n))
    (setq pnt (cdr (assoc 10 (entget nam))))
    (setq pnt (list (car pnt) (cadr pnt) 0))
    (command "insert" blk pnt "" "" "")
    (setq n (1+ n))
  )
  (princ (rtos n 2 0))
  (PROGN "Blocks inserted")


)

(Defun c:** ()
  (setq	ent (entget (Car (entsel)))
	la  (cdr (Assoc 8 ent))
	en  (cdr (assoc 0 ent))
	col (Cdr (Assoc 62 ent))
  )
  (if (/= nil col)
    (Setq sel (ssget "x" (list (cons 0 en) (cons 8 la) (cons 62 col))))
    (Setq sel (ssget "x" (list (cons 0 en) (cons 8 la))))
  )
)
(defun c:jn ()
  (setvar "cmdecho" 0)
  (setq	ent (entget (car (entsel "Select one entity\n")))
	ss1 (ssget "x" (list (assoc 1 ent) (assoc 40 ent)))
	p2  (list 0)
	i   (- (sslength ss1) 1)
  )
  (setq la (cdr (assoc 8 ent)))
  (command "clayer" la)
  (setq len (getdist "\nMaximum length of line :"))
  (repeat (sslength ss1)
    (setq ent1 (ssname ss1 i)
	  p1   (list (car (cdr (assoc 10 (entget ent1))))
		     (cadr (cdr (assoc 10 (entget ent1))))
		     0
	       )
	  i    (- i 1)
    )
    (if	(= (length p2) 3)
      (if (> len (distance p2 p1))
	(progn (command "pLINE" p2 p1 "")
	       (setq p2 p1)
	)
	(setq p2 p1)
      )
      (setq p2 p1)
    )
  )
)


(defun c:j () (command "pedit" "j"))

(defun c:gap ()
  (setq	a  (entget (car (entsel)))
	a1 (cdr (assoc 1 a))
	el (strlen a1)
	c  1
	n  ""
  )
  (while (<= c el)
    (setq n (strcat n (substr a1 c 1) " ")
	  c (+ 1 c)
    )
  )
  (setq	text_style	(cdr (assoc 7 a))
	text_height	(cdr (assoc 40 a))
	text_just	(cdr (assoc 72 a))
	text_al		(cdr (assoc 11 a))
	text_startpoint	(cdr (assoc 10 a))
	text_angle	(cdr (assoc 50 a))
	text_oblique	(cdr (assoc 51 a))
	text_layer	(cdr (assoc 8 a))
  )
  (entmake (list (cons 0 "text")
		 (cons 1 n)
		 (cons 7 text_style)
		 (cons 40 text_height)
		 (cons 72 text_just)
		 (cons 11 text_al)
		 (cons 10 text_startpoint)
		 (cons 50 text_angle)
		 (cons 51 text_oblique)
		 (cons 8 text_layer)
	   )
  )
  (entdel (cdr (assoc -1 a)))
  (princ)
)
(Defun c:cap ()
  (setq	ss (ssget)
	n  0
	e  (ssname ss n)
  )
  (while (/= e nil)
    (setq Txt (cdr (assoc 1 (entget e)))
	  nt  (strcase Txt)
    )
    (command "change" e "" "" "" "" "" nt)
    (setq n (+ 1 n)
	  e (ssname ss n)
    )
  )
)
(Defun C:Cen ()
  (SEtvar "osmode" 0)
  (Setq
    Spt	(getpoint "Specify Starting Point of centre line : ")
  )
  (command "pline" spt spt "")
  (setvar "osmode" 512)
  (Setq sleft (Getpoint "\n Specify the Left edge of the Road: "))
  (While (/= sleft Nil)
    (Setq left sleft)
    (Setvar "osmode" 128)
    (Setq
      right (Getpoint left "\nSpecify the Right edge of the road: ")
      pl    (entlast)
      zc    (rtos (* (distance left right) 6))
					;Change value of zc here as per the accuracy
      Li    (List 2.0 2.0 2.0)
      Add   (Mapcar '+ left right)
      Midpt (Mapcar '/ Add Li)
    )
    (command "pedit"	 pl    "e"   "n"   "n"	 "n"   "N"   "N"
	     "N"   "N"	 "N"   "n"   "n"   "N"	 "N"   "N"   "N"
	     "N"   "N"	 "N"   "n"   "i"   midpt "X"   ""
	    )
    (command "zoom" "c" midpt zc)
    (Setvar "osmode" 512)
    (setq sleft (getpoint "\n Specify the Left edge of the Road: "))
  )
)

(defun c:HT ()
  (setq	sset  (ssget)
	len   (sslength sset)
	ts    (getreal "Enter new text size  ")
	index 0
	objs  (ssname sset index)
  )
  (repeat len
    (setq ent  (entget objs)
	  text (cdr (assoc 0 ent))
    )
    (if	(= "TEXT" text)
      (progn
	(setq old_ht (assoc 40 ent)
	      new_ht (cons (car old_ht) ts)
	      sub_ht (subst new_ht old_ht ent)
	      index  (1+ index)
	      Objs   (ssname sset index)
	)
	(entmod sub_ht)
      )
    )
  )

)


(DEFUN C:RT ()
  (setvar "osmode" 512)
  (SETQ	SSEl	(SSGET)
	sset	(ssget "p"
		       '((-4 . "<or")
			 (-4 . "<and")
			 (0 . "TEXT")
			 (-4 . "and>")
			 (-4 . "<and")
			 (0 . "tEXT")
			 (-4 . "and>")
			 (-4 . "or>")
			)
		)

	NEW_ANG	(angtos (GETANGLE "Pick an angle for text :"))
	INDEX	0
	ROBJS	(SSNAME SSET INDEX)
  )
  (while (/= NIL ROBJS)
    (progn
      (Setq old_ang (angtos (cdr (assoc 50 (entget robjs))))
	    ins_pt  (cdr (assoc 10 (entget robjs)))
      )
      (command "rotate" robjs "" ins_pt "r" old_Ang new_ang)
      (SETQ INDEX (+ 1 INDEX)
	    ROBJS (SSNAME SSET INDEX)
      )
    )
  )
)

(DEFUN C:RX ()
  (setvar "osmode" 512)
  (SETQ	SSEl	(SSGET)
	sset	(ssget "p"
		       '((-4 . "<or")
			 (-4 . "<and")
			 (0 . "INSERT")
			 (-4 . "and>")
			 (-4 . "<and")
			 (0 . "insert")
			 (-4 . "and>")
			 (-4 . "or>")
			)
		)

	NEW_ANG	(angtos (GETANGLE "Pick an angle for text :"))
	INDEX	0
	ROBJS	(SSNAME SSET INDEX)
  )
  (while (/= NIL ROBJS)
    (progn
      (Setq old_ang (angtos (cdr (assoc 50 (entget robjs))))
	    ins_pt  (cdr (assoc 10 (entget robjs)))
      )
      (command "rotate" robjs "" ins_pt "r" old_Ang new_ang)
      (SETQ INDEX (+ 1 INDEX)
	    ROBJS (SSNAME SSET INDEX)
      )
    )
  )
)
(Defun c:RR ()
  (setq snapreset (getvar "osmode"))
  (command "osnap" "nea")
  (setq tr (car (entsel "Select the text\n")))
  (if (= tr nil)
    (alert "Select the text first")
    (PROGN
      (setq entity (entget tr)
	    pt1	   (getpoint "Pick the first point\n")
	    pt2	   (getpoint pt1 "Pick the second point\n")
	    an	   (angle pt1 pt2)
	    InsPt  (cdr (assoc 10 Entity))
	    oldang (cdr (assoc 50 entity))
	    Ang	   (- An OldAng)
	    NewAng (angtos Ang)
      )
      (command "Rotate" Tr "" InsPt NewAng)
      (setvar "osmode" snapreset)
    )
  )
)
(defun c:points	()
  (setq	sset  (ssget)
	index 0
	len   (Sslength sset)
  )
  (repeat len
    (Setq
      plin  (ssname sset index)
      pline (entget plin)
      plist nil
    )
    (while pline
      (Setq elem  (list (Car pline))
	    pline (Cdr pline)
	    chk	  (car (assoc 10 elem))
      )
      (if (= 10 chk)
	(progn
	  (Setq
	    vert   (cdr (assoc 10 elem))
	    xv	   (car vert)
	    yv	   (cadr vert)
	    vertex (list xv yv)
	  )
	  (command "point" vertex)

	)

      )
    )
    (Setq index (+ 1 index))
  )

(defun c:cul ()
  (command "layer" "m" "culbr" "" "")
  (command "setvar" "osmode" "0")
  (command "setvar" "plinetype" "2")
  (setq	a (entsel "select the first text:")
	b (entsel "select the second text:")
	c (entsel "selec the third text:")
  )
  (setq	a1 (cdr (assoc 10 (entget (car a))))
	b1 (cdr (assoc 10 (entget (car b))))
	c1 (cdr (assoc 10 (entget (car c))))
  )
  (setq	d  (angle b1 c1)
	e  (distance b1 c1)
	d1 (polar a1 d e)
  )
  (command "pline" a1 b1 c1 d1 "c")
  (setq f (entlast))
  (setq off (polar a1 (angle a1 b1) (+ (distance a1 b1) 0.60)))
  (command "offset" "0.60" f off "")
  (sub1)
)
---------------------
(DEFUN SUB1 ()
  (setq	f1  (entlast)
	g   (entget f1)
	li  (assoc 10 g)
	NLL '()
  )
  (while (/= li nil)
    (IF	(/= LI NIL)
      (PROGN
	(SETQ nl  (LIST (CAR (CDR LI)) (CADR (CDR LI)))
	      NLL (APPEND NLL (LIST NL))
	      G	  (SUBST (CONS 0 "SUB") LI G)
	      LI  (ASSOC 10 G)
	)
      )
    )
  )


  (command "setvar" "plinewid" "0.20")
  (command "pline"
	   (list (car (nth 0 nll)) (cadr (nth 0 nll)))
	   (list (car a1) (cadr a1))
	   (list (car b1) (cadr b1))
	   (list (car (nth 1 nll)) (cadr (nth 1 nll)))
	   ""
  )
  (command "pline"
	   (list (car (nth 3 nll)) (cadr (nth 3 nll)))
	   (list (car d1) (cadr d1))
	   (list (car c1) (cadr c1))
	   (list (car (nth 2 nll)) (cadr (nth 2 nll)))
	   ""
  )
  (command "setvar" "plinewid" "0.00")
  (entdel f1)
  (entdel f)
)
  
)
(DEFUN C:CODES ()			;list codes of all attdef in the drawing
  (SETQ A (SSGET "x" (LIST (CONS 0 "txt"))))
  (if (= a nil)
    (ALERT "SURVEY POINTS ARE
    NOT ENTER")
  )
  (IF (/= A NIL)
    (PROGN
      (TEXTPAGE)
      (PRINC)
      (SETQ B  (SSLENGTH A)
	    C  0
	    LI '()
      )
      (REPEAT B
	(SETQ D	(SSNAME A C)
	      E	(ENTGET D)
	      F	(CDR (ASSOC 1 E))
	      C	(1+ C)
	)
	(IF (= (MEMBER F LI) NIL)
	  (PROGN
	    (SETQ LI (APPEND LI (LIST F)))
	  )
	)
      )
      (SETQ LI (ACAD_STRLSORT LI))
      (setq co 0)
      (repeat (length li)
	(print (nth co li))
	(princ)
	(setq co (1+ co))
      )
    )
  )
  (princ)
)
(Defun c:Merge ()
  (setq	firstobj    (car (entsel "Select the first object "))
	firstentity (entget firstobj)
	mergeset    (ssget)		; "Select the objects in order ")
	txt	    (cdr (assoc 1 firstentity))
	no	    0
	entity	    (ssname mergeset no)
  )
  (while (/= entity nil)
    (setq newtxt (cdr (assoc 1 (entget entity)))
	  txt	 (strcat txt "" newtxt)
	  no	 (1+ no)
	  entity (ssname mergeset no)
    )
  )
  (setq	oldtxt (assoc 1 firstentity)
	newtxt (cons 1 txt)
	newobj (subst newtxt oldtxt firstentity)
  )
  (entmod newobj)
  (command "erase" mergeset "")
)
(defun c:pt ()
  (setq ptn (getpoint "\nSpecifyt a Point:"))
  (setq ele (getreal "\nEnter Elevation:"))
  (setq cod (getstring "\nDescription Code:"))
  (setq	ptn (list (atof (rtos (car ptn) 2 3))
		  (atof (rtos (cadr ptn) 2 3))
		  ele
	    )
  )
  (setq	pt (list (atof (rtos (car ptn) 2 3))
		 (atof (rtos (cadr ptn) 2 3))
		 0
	   )
  )
  (command "layer" "s" "points" "")
  (command "pdmode" "3")
  (command "pdsize" "0.15")
  (command "point" pt)
  (command "layer" "s" "code" "")
  (command "style" "rs" "romans" "" "" "" "" "" "")
					;(command "layer" "s" "elevation" "")
  (command "text" ptn "45" (rtos ele 2 3))
)


(defun c:1 ()
  (setvar "osmode" 512)
  (setq pt1 (entget (car (entsel "\nSelect First source Point:"))))
  (setq pt2 (entget (car (entsel "\nSelect Second source Point:"))))
  (setq pt3 (getpoint "\nSelect a Point:"))
  (setq cod (getstring "\nDescription Code:"))
  (setq pnt1 (cdr (assoc 10 pt1)))
  (setq pnt2 (cdr (assoc 10 pt2)))
  (setq pnt3 pt3)
  (setq	dis12 (distance	(list (car pnt1) (cadr pnt1) 0)
			(list (car pnt2) (cadr pnt2) 0)
	      )
  )
  (setq	dis13 (distance	(list (car pnt1) (cadr pnt1) 0)
			(list (car pnt3) (cadr pnt3) 0)
	      )
  )
  (setq elev (- (last pnt2) (last pnt1)))
  (setq elen (* (/ dis13 dis12) elev))
  (setq elen (+ (last pnt1) elen))
  (setq pnt3 (list (car pnt3) (cadr pnt3) elen))
  (setq pnt (list (car pnt3) (cadr pnt3) 0))
  (command "layer" "s" "points" "")
					;  	(command "pdmode" "3") (command "pdsize" "0.15")
					;(command "point" pnt)
  (command "style" "rs" "" "" "" "" "" "" "")
  (command "layer" "s" "code" "")
  (command "text" pnt3 "0" cod "")
					; (command "layer" "s" "elevation" "")
  (command "text" pnt3 "45" (rtos elen 2 3))
)

(defun c:2 ()

  (setq pt1 (entget (car (entsel "\nSelect first point"))))
  (setq pt2 (entget (car (entsel "\nSelect second point"))))
  (setq cod (getstring "\nDescription Code:"))
  (command "clayer" (cdr (assoc 8 pt1)))
					;	(command "style" (cdr (assoc 7 pt1)) "" "" "" "" "" "" "")
  (setq pt1 (cdr (assoc 10 pt1)))
  (setq pt2 (cdr (assoc 10 pt2)))
  (setq	dis (distance (list (car pt1) (cadr pt1) 0)
		      (list (car pt2) (cadr pt2) 0)
	    )
  )
  (setq ele (- (last pt2) (last pt1)))
					;	(setq dsp (strcat "\nDistance between Points ." (rtos dis 2 3) "m, Elevation. " (rtos ele 2 3)))
  (princ dsp)
  (setq num (getint "\nEnter number of point to add :"))
  (setq ndis (/ dis (+ num 1)))
  (setq nele (/ ele (+ num 1)))
  (setq ptx pt1)
  (setq n 0)
  (while (< n num)
    (setq ptn (polar ptx (angle pt1 pt2) ndis))
    (setq ptn (list (car ptn) (cadr ptn) (+ (last ptn) nele)))
    (setq ptn (list (atof (rtos (car ptn) 2 3))
		    (atof (rtos (cadr ptn) 2 3))
		    (atof (rtos (last ptn) 2 3))
	      )
    )
    (setq pt (list (atof (rtos (car ptn) 2 3))
		   (atof (rtos (cadr ptn) 2 3))
	     )
    )
					;		(command "layer" "s" "points" "")
					;  		(command "pdmode" "3") (command "pdsize" "0.15")
					;	  	(command "point" ptn)
					;	 	(command "layer" "s" "elevation" "")
					;		(command "text" ptn "45" (rtos (last ptn) 2 3))
					; (command "layer" "s" "code" "")
    (command "text" ptn "0" cod "")
    (setq n (1+ n))
    (setq ptx ptn)
  )
)

(defun c:3 ()
  (setvar "osmode" 0)
  (setq pt1 (entget (car (entsel "\nSelect First source Point:"))))
  (setq pt2 (entget (car (entsel "\nSelect Second source Point:"))))
					;	(setq code (entget (car (entsel "\nSelect Description Code:"))))
  (setq pt3 (getpoint "\nSelect a Point:"))
  (setq po (list (car pt3) (cadr pt3) 0))
  (setq co (cdr (assoc 1 pt1)))
					;	(setq code (cdr (assoc 1 code)))
					;	(setq cod (getstring "\nDescription Code:"))
  (setq pnt1 (cdr (assoc 10 pt1)))
  (setq pnt2 (cdr (assoc 10 pt2)))
  (setq pnt3 pt3)
  (setq	dis12 (distance	(list (car pnt1) (cadr pnt1) 0)
			(list (car pnt2) (cadr pnt2) 0)
	      )
  )
  (setq	dis13 (distance	(list (car pnt1) (cadr pnt1) 0)
			(list (car pnt3) (cadr pnt3) 0)
	      )
  )
  (setq elev (- (last pnt2) (last pnt1)))
  (setq elen (* (/ dis13 dis12) elev))
  (setq elen (+ (last pnt1) elen))
  (setq pnt3 (list (car pnt3) (cadr pnt3) elen))
  (setq pnt (list (car pnt3) (cadr pnt3) 0))
  (setq pot (list (car po) (cadr po) (+ (caddr po) elen)))
  (command "layer" "s" "points" "")
					;  	(command "pdmode" "3") (command "pdsize" "0.15")
					;	(command "point" pnt)
  (command "style" "rs" "" "" "" "" "" "" "")
					; (command "layer" "s" "code" "")
  (command "text" pot "0" co "")
)
;(command "layer" "s" "elevation" "")
					;	(command "text" pot "45" (rtos elen 2 3)))	


(defun c:2a ()

  (setq pt1 (entget (car (entsel "\nSelect first point"))))
  (setq pt2 (entget (car (entsel "\nSelect second point"))))
  (setq cod (cdr (assoc 1 pt1)))

  (command "clayer" (cdr (assoc 8 pt1)))
  (setq pt1 (cdr (assoc 10 pt1)))
  (setq pt2 (cdr (assoc 10 pt2)))
  (setq	dis (distance (list (car pt1) (cadr pt1) 0)
		      (list (car pt2) (cadr pt2) 0)
	    )
  )
  (setq ele (- (last pt2) (last pt1)))
  (princ dsp)
  (setq num 1)
  (setq ndis (/ dis (+ num 1)))
  (setq nele (/ ele (+ num 1)))
  (setq ptx pt1)
  (setq n 0)
  (while (< n num)
    (setq ptn (polar ptx (angle pt1 pt2) ndis))
    (setq ptn (list (car ptn) (cadr ptn) (+ (last ptn) nele)))
    (setq ptn (list (atof (rtos (car ptn) 2 3))
		    (atof (rtos (cadr ptn) 2 3))
		    (atof (rtos (last ptn) 2 3))
	      )
    )
    (setq pt (list (atof (rtos (car ptn) 2 3))
		   (atof (rtos (cadr ptn) 2 3))
	     )
    )
    (command "text" ptn "0" COD "")
    (setq n (1+ n))
    (setq ptx ptn)
  )
)


(Defun C:GT ()
  (setvar "osmode" 11)
  (if (= BlkName nil)
    (setq BlkName (getstring "Enter the Block Name\n"))
  )
  (setq	FPoint	  (getpoint "Pick the First Point\n")
	SPoint	  (getpoint "Pick the Second Point\n")
	StPoint	  (list (car FPoint) (cadr FPoint))
	EnPoint	  (list (car SPoint) (cadr SPoint))
	PointDist (distance StPoint EnPoint)
	Dist	  (/ PointDist 2.0)
	Ang	  (angle StPoint EnPoint)
	InsPoint  (polar StPoint Ang Dist)
  )
  (setq OldSnap (getvar "OsMode"))
  (setvar "OsMode" 0)
  (command "Insert" BlkName InsPoint PointDist 1 (angtos Ang))
  (setvar "OsMode" OldSnap)
)
(defun c:gg ()
  (setvar "osmode" 0)
  (setq p1 (getpoint "Pick the lower corner:"))
  (setq p3 (getpoint "Pick the higher corner:"))
  (setq int (getdist "Enter the interval of grid:"))
  (setq th (getreal "Enter the hight of text:"))
  (setq p2 (list (car p3) (cadr p1)))
  (setq p4 (list (car p1) (cadr p3)))
  (setq x1 (list (car p1) (+ (cadr p1) 10)))
  (setq x2 (list (car p1) (+ (cadr p1) 20)))
  (setq y1 (list (+ (car p1) 10) (cadr p1)))
  (setq y2 (list (+ (car p1) 20) (cadr p1)))
  (setq d1 (rtos (+ (/ (- (car p3) (car p1)) int) 1) 2 0))
  (setq t1 (rtos (+ (/ (- (cadr p3) (cadr p1)) int) 1) 2 0))
  (command "STYLE" "Gtxt" "ROMAND" th "" "" "" "" "")
  (command "layer" "n" "grid" "c" "blue" "grid" "s" "grid" "")
  (command "line" p1 p2 "")
  (command "line" p1 p4 "")
  (command "array" "f" y1 y2 "" "" "" t1 "" int)
  (command "array" "f" x1 x2 "" "" "" "" d1 int)
  (setq east (rtos (car p1) 2 0))
  (setq north (rtos (cadr p1) 2 0))
  (command "layer" "n" "east" "c" "yellow" "east" "s" "east" "")
  (command "text" "bl" p1 "90" east)
  (command "layer" "n" "north" "c" "red" "north" "s" "north" "")
  (command "text" "bl" p1 "0" north)
  (setq zn (list (+ (car p1) 10) (+ (cadr p1) 10)))
  (setq zn1 (list (+ (car p1) 1) (+ (cadr p1) 1)))
  (setq ze (list (- (car p1) 10) (+ (cadr p1) 50)))
  (command "array" "w" p1 ze "" "" "" d1 int)
  (command "array" "f" zn1 zn "" "" "" t1 "" int)
)
(defun c:che ()
  (setvar "cmdecho" 0)
  (command "layer" "n" "east" "c" "yellow" "east" "s" "east" "")
  (setq ent (entget (car (entsel "Select an Entity:"))))
  (setq
    ss1	(ssget "X" (list (assoc 0 ent) (assoc 7 ent) (assoc 8 ent)))
  )
  (setq n 0)
  (repeat (sslength ss1)
    (setq nam (ssname ss1 n))
    (setq pnt (cdr (assoc 10 (entget nam))))
    (setq pnt (list (car pnt)
		    (cadr pnt)
		    (atof (cdr (assoc 1 (entget nam))))
	      )
    )
    (command "style"
	     (cdr (assoc 7 (entget nam)))
	     ""
	     ""
	     ""
	     ""
	     ""
	     ""
	     ""
    )
    (command "erase" nam "")
    (command "text"
	     pnt
	     "90"
	     (strcat (rtos (+ (car pnt) 83) 2 0) " E")
    )
    (setq n (1+ n))
  )
)
(defun c:chn ()
  (setvar "cmdecho" 0)
  (command "layer" "n" "north" "c" "red" "north" "s" "north" "")
  (setq ent (entget (car (entsel "Select an Entity:"))))
  (setq
    ss1	(ssget "X" (list (assoc 0 ent) (assoc 7 ent) (assoc 8 ent)))
  )
  (setq n 0)
  (repeat (sslength ss1)
    (setq nam (ssname ss1 n))
    (setq pnt (cdr (assoc 10 (entget nam))))
    (setq pnt (list (car pnt)
		    (cadr pnt)
		    (atof (cdr (assoc 1 (entget nam))))
	      )
    )
    (command "style"
	     (cdr (assoc 7 (entget nam)))
	     ""
	     ""
	     ""
	     ""
	     ""
	     ""
	     ""
    )
    (command "erase" nam "")
    (command "text"
	     pnt
	     "0"
	     (strcat (rtos (- (cadr pnt) 83) 2 0) " N")
    )
    (setq n (1+ n))
  )
)
(defun c:ds ()
  (setvar "osmode" 9)
  (setq pt1 (getpoint "\nSelect first point"))
  (setq pt2 (getpoint "\nSelect second point"))
  (setq	len (distance (list (car pt1) (cadr pt1) 0)
		      (list (car pt2) (cadr pt2) 0)
	    )
  )
  (setq ang (angle pt1 pt2))
  (setq orig (polar pt1 ang (/ len 2)))
  (setvar "osmode" 0)
  (command "text" "bc" orig pt2 (strcat (rtos len 2 2) "m"))
  (command "style" "0-DIST" "romanS" "0.05" "" "" "" "" "")
  (command "layer" "m" "0-DIST" "c" "blue" "dist" "")
)
(defun c:Cth ()
  (setq	sset  (ssget)
	len   (sslength sset)
	ts    (getreal "Enter new text size  ")
	index 0
	objs  (ssname sset index)
  )
  (repeat len
    (setq ent  (entget objs)
	  text (cdr (assoc 0 ent))
    )
    (if	(= "TEXT" text)
      (progn
	(setq old_ht (assoc 40 ent)
	      new_ht (cons (car old_ht) ts)
	      sub_ht (subst new_ht old_ht ent)
	      index  (1+ index)
	      Objs   (ssname sset index)
	)
	(entmod sub_ht)
      )
    )
  )

)

;;;******************************************************************************************************************************************


  (Defun c:Re ()
(setq	repset(ssget)
	repset(ssget "p" (list (cons 0 "text")))
	newcode(getstring "Enter the new code to be replaced (RR lisp):")
	no 0
	object(ssname repset no)
)
(while (/= object nil)
	(setq	entity(entget object)
		attrib1(assoc 1 entity)
		attrib2(assoc 2 entity)
		newattrib1(cons 1 newcode)
		newattrib2(cons 2 newcode)
		newobject(subst newattrib1 attrib1 entity)
		newobject(subst newattrib2 attrib2 newobject)
		no(1+ no)
		object(ssname repset no)
	)
	(entmod newobject)(prinT "Select objects to be Changed...                         # Raja-LISP ")

)
)

(defun c:join ()
  (setvar "cmdecho" 0)
  (setq	ent (entget (car (entsel "\n Select a Code to join the Line:")))
	ss1 (ssget "x" (list (assoc 0 ent) (assoc 1 ent)))
	p2  (list 0)
	i   (- (sslength ss1) 1)
  )
  (setq la (cdr (assoc 8 ent)))
					;	(command "clayer" la)	
  (setq len (getdist "\nMaximum length of line :"))
  (repeat (sslength ss1)
    (setq ent1 (ssname ss1 i)
	  p1   (list (car (cdr (assoc 10 (entget ent1))))
		     (cadr (cdr (assoc 10 (entget ent1))))
		     0
	       )
	  i    (- i 1)
    )
    (if	(= (length p2) 3)
      (if (> len (distance p2 p1))
	(progn (command "pLINE" p2 p1 "")
	       (setq p2 p1)
	)
	(setq p2 p1)
      )
      (setq p2 p1)
    )
  )
)

(Defun c:are ()
  (Setq	sset  (Ssget)
	index 0
  )
  (repeat (sslength sset)
    (setq ent	(ssname sset index)
	  inspt	(cdr (ASsoc 10 (Entget ent)))
    )
    (command "Area" "o" ent)
    (setq ar	   (getvar "area")
	  areasqm  (strcat (rtos ( areasqm 2 4) "sqm")
	  areaacre (/ ar 4046.87)
	  areaacre (strcat (rtos areaacre 2 4) "Acre")
	  areasqft (* ar 10.763689)
	  areasqft (strcat (rtos areasqft 2 4) "sqft")
    )
    (command "text" inspt "" areasqm)
					(Command "text" "" areaacre)
					(Command "text" "" areasqft)
    (Setq index (+ 1 index))

  )
)



(Defun c:ae ()
  (setq	ent   (car (entsel))
	inspt (getpoint "\n Specify Text insertion Point: ")
  )
  (command "Area" "o" ent)
  (setq	ar	 (getvar "area")
	areasqm	 (strcat (rtos ar 2 4) "sqm")
	areaacre (/ ar 4046.87)
	areaacre (strcat (rtos areaacre 2 4) "Acre")
	areasqft (* ar 10.763689)
	areasqft (strcat (rtos areasqft 2 4) "sqft")
  )
  (setq kword (getstring "Enter the Type of units:  <M/A/F>"))
  (if (= (strcase kword) "M")
    (command "text" inspt "" "" areasqm)
  )
  (if (= (strcase kword) "A")
    (command "text" inspt "" "" areaacre)
  )
  (if (= (strcase kword) "F")
    (command "text" inspt "" "" areasqft)
  )
)


(Defun C:BE ()
  (setq	Object (car (entsel))
	BPoint (getpoint "\nPick the Break   point")
  )
  (command "Break" Object BPoint BPoint)
)
(defun c:b1 ()
  (command "change" (ssget) "" "p" "ltype" "build1" "")
)
(defun c:b2 ()
  (command "change" (ssget) "" "p" "ltype" "build" "")
)

(DEFUN C:VL ()
  (setvar "osmode" 512)
  (COMMAND "TEXT" "S" "M" PAUSE PAUSE "Vacant Land" "")
  (COMMAND "CHANGE" "L"	"" "P" "LA" "0-NRTXT" "C" "BYLAYER" "")
)
(DEFUN C:AL ()
  (setvar "osmode" 512)
  (COMMAND "TEXT" "s" "M" PAUSE PAUSE "Agricultural Land" "")
  (COMMAND "CHANGE" "L"	"" "P" "LA" "0-NRTXT" "C" "BYLAYER" "")
)
(DEFUN C:OL ()
  (COMMAND "TEXT" "S" "M" PAUSE PAUSE "Open Land" "")
  (COMMAND "CHANGE" "L"	"" "P" "LA" "0-NRTXT" "C" "BYLAYER" "")
)
(DEFUN C:CC ()
  (setvar "osmode" 512)
  (COMMAND "TEXT" "S" "M" PAUSE PAUSE "Coconut Plantation" "")
  (COMMAND "CHANGE" "L"	"" "p" "LA" "0-NRTXT" "C" "BYLAYER" "")
)
(DEFUN C:MUD ()
  (setvar "osmode" 512)
  (COMMAND "TEXT" "S" "rS" PAUSE PAUSE "Mud Road" "")
  (COMMAND "CHANGE" "L" "" "P" "LA" "0-NRTXT" "")
)
(DEFUN C:CM ()
  (COMMAND "TEXT" "S" "rS" PAUSE PAUSE "Cement Road" "")
  (COMMAND "CHANGE" "L" "" "P" "LA" "0-NRTXT" "")
)

(DEFUN C:BT ()
  (setvar "osmode" 512)
  (COMMAND "TEXT" "S" "RS" PAUSE PAUSE "Bitumen Road" "")
  (COMMAND "CHANGE" "L" "" "P" "LA" "0-NRTXT" "")
)
(defun c:bss ()
  (setvar "osmode" 2560)
  (command "clayer" "0-build" "")
  (setq p1 (getpoint "Insert point of Bus Shelter:"))
  (command "insert" "bs" p1 "" "" "")
)
(defun c:ad ()
  (setvar "osmode" 2560)
  (command "clayer" "text" "")
  (setq p1 (getpoint "Insert point of arrow:"))
  (command "insert" "a" p1 "" "")
)
(defun c:c () (command "copy"))
(defun c:c3 () (command "copy" "cp"))
(defun c:r () (command "rotate"))
(defun c:cx () (command "circle"))


(command "ucsicon" "off")
(COMMAND "MODEMACRO" "Htm Survey")

(defun c:ch () (Command "change"))
(defun c:lk ()
  (prompt " **Select layer which you want to make it lock**: "
  )
  (setq	ent	 (car (Entsel))
	Entity	 (entget ent)
	lay_name (cdr (assoc 8 entity))
  )
  (command "layer" "lock" lay_name "")
  (Princ)
)
(defun c:fr (/ e n)
  (setq e (car (entsel "Pick an object for freezing the layer : ")))
  (if e
    (progn
      (setq e (entget e))
      (setq n (cdr (assoc 8 e)))
      (command "layer" "f" n "")
    )
  )
  (princ)
)

(defun c:d () (command "ddedit"))
(defun c:ed () (command "ddim"))

(DEFUN C:ZZ ()
  (cOMMAND "ZOOM" "1.2x")
  (PRINC)
)
(DEFUN C:ZX ()
  (cOMMAND "ZOOM" "0.8x")
  (PRINC)
)
(defun c:dd ()
  (setvar "osmode" 8)
  (command "ucs" "")
  (setq sc (getdist "Enter the drain wide:"))
  (command "clayer" "0-drain" "")
  (command "mline" "s" sc "")
  (command "mline")
)


(defun c:cF ()
  (command "chamfer" "d" 0 "" "")
  (command "chamfer")
)
(defun c:ss ()
  (setvar "edgemode" 1)
  (command "qsave")
  (princ "\n\*** Successfully yours drawing saved ***")
  (princ)
)
(defun c:css ()
  (command "cursorsize")
)
(defun c:ze ()
  (command "zoom" "e" "")
)
(defun c:zw ()
  (command "zoom" "w" "")
)
(defun c:zd ()
  (command "zoom" "d")
)
(defun c:zp ()
  (command "zoom" "p" "")
)
(defun c:ce () (command "qsave") (command "close" ""))
(defun c:qq ()
  (command "qsave")
  (command "zoom" "e" "")
  (command "quit" "")
)
(defun c:cr ()
  (setq	ent (entget
	      (car (entsel "\nSelect an Object to current layer:"))
	    )
  )
  (setq lay (cdr (assoc 8 ent)))
  (command "clayer" lay "")
)
(defun c:lo ()
  (setq ent (entget (car (entsel "\nSelect an Object only to on:"))))
  (setq lay (cdr (assoc 8 ent)))
  (command "layer" "off" lay "" "")
)
(defun c:FR ()
  (setq ent (entget (car (entsel "\nSelect an Object only to on:"))))
  (setq lay (cdr (assoc 8 ent)))
  (command "layer" "FREEZE" lay "" "")
)
(defun c:ln ()
  (setq ent (entget (car (entsel "\nSelect an Object only to on:"))))
  (setq lay (cdr (assoc 8 ent)))
  (command "layer" "off" "*" "Y" "on" lay "" "")
)
(defun c:r1 ()
  (setq p1 (getpoint "Pick the rotation point of Text:"))
  (command "rotate" pause "" p1 "180")
)
(defun c:on ()
  (command "layer" "on" "*" "")
)
(defun c:THA () (command "layer" "THAW" "*" ""))
(defun c:y () (command "change" pause "" "p" "c" "2" ""))


  
  ;****************************close************

(princ
  "\n\Megastar survey lisp 1.43 version New edition at October 2002 Cell:98400 70614"
)

(princ
  "\n\                  htmsurvey@yahoo.com"
)

;;;**********************************************************************************
