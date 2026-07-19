;Download from excel sheet
(command "osmode" "0")
(command "cmdecho" "0")
(setvar "filedia" 0)
(setvar "filedia" 1)
(setvar "dimzin" 2)
(command "-style" "cs_text" "Arial" "3.0" "" "" "" "" "")	 
(command "-style" "remarks" "complex.shx" "2.0" "" "" "" "" "")
(command "-style" "cs_levels" "monotxt.shx" "1.75" "" "" "" "" "")
(command "-layer" "m" "chainge" "c" "242" ""
	 	  "m" "ground_level" "c" "10" ""
	 	  "m" "formation_level" "c" "202" ""
	          "m" "fsl" "c" "3" "" 
                  "m" "ho_of_bank" "c" "2" ""
	          "m" "de_of_cutting" "c" "242" ""
	 	  "m" "top_of_bank" "c" "32" ""
	 	  "m" "datum" "c" "12" ""
		  "m" "point" "c" "9" ""
	 	  "m" "cs_line" "c" "5" ""
	     	  "m" "surface" "c" "4" ""
	 	  "m" "datum" "c" "12" ""
	 	  "m" "grid" "c" "8" "" "")(terpri)
(command "cmdecho" "0")
(DEFUN	C:mway ()
;Standard functions:
(SETQ	FNAME	(GETSTRING "ENTER FILE NAME:")
	OPE	(OPEN FNAME "r")
	RLI	(READ-LINE OPE)
	Chinage_list 	(list 0)
	Ground_list	(list 0)
	form_list	(list 0)
	fsl_list	(list 0)
	hobank_list 	(list 0)
	dobank_list 	(list 0)
	tobank_list 	(list 0)

);setq close
(WHILE RLI
;chinage getting from excel
(IF (= (SUBSTR RLI 2 1) ",") (SETQ Ground_total (SUBSTR RLI 3) Chinage (SUBSTR RLI 1 1)))
(IF (= (SUBSTR RLI 3 1) ",") (SETQ Ground_total (SUBSTR RLI 4) Chinage (SUBSTR RLI 1 2)))
(IF (= (SUBSTR RLI 4 1) ",") (SETQ Ground_total (SUBSTR RLI 5) Chinage (SUBSTR RLI 1 3)))
(IF (= (SUBSTR RLI 5 1) ",") (SETQ Ground_total (SUBSTR RLI 6) Chinage (SUBSTR RLI 1 4)))
(IF (= (SUBSTR RLI 6 1) ",") (SETQ Ground_total (SUBSTR RLI 7) Chinage (SUBSTR RLI 1 5)))
(IF (= (SUBSTR RLI 7 1) ",") (SETQ Ground_total (SUBSTR RLI 8) Chinage (SUBSTR RLI 1 6)))
(IF (= (SUBSTR RLI 8 1) ",") (SETQ Ground_total (SUBSTR RLI 9) Chinage (SUBSTR RLI 1 7)))
(IF (= (SUBSTR RLI 9 1) ",") (SETQ Ground_total (SUBSTR RLI 10) Chinage (SUBSTR RLI 1 8)))

(setq Chinage_list	(append Chinage_list (list chinage)))
;(Print chinage_list)(princ)
  
;ground level getting from excel  
(IF (= (SUBSTR Ground_total 2 1) ",") (SETQ For_total (SUBSTR Ground_total 3) Ground (SUBSTR Ground_total 1 1)))
(IF (= (SUBSTR Ground_total 3 1) ",") (SETQ For_total (SUBSTR Ground_total 4) Ground (SUBSTR Ground_total 1 2)))
(IF (= (SUBSTR Ground_total 4 1) ",") (SETQ for_total (SUBSTR Ground_total 5) Ground (SUBSTR Ground_total 1 3)))
(IF (= (SUBSTR Ground_total 5 1) ",") (SETQ for_total (SUBSTR Ground_total 6) Ground (SUBSTR Ground_total 1 4)))
(IF (= (SUBSTR Ground_total 6 1) ",") (SETQ for_total (SUBSTR Ground_total 7) Ground (SUBSTR Ground_total 1 5)))
(IF (= (SUBSTR Ground_total 7 1) ",") (SETQ for_total (SUBSTR Ground_total 8) Ground (SUBSTR Ground_total 1 6)))
(IF (= (SUBSTR Ground_total 8 1) ",") (SETQ for_total (SUBSTR Ground_total 9) Ground (SUBSTR Ground_total 1 7)))
(IF (= (SUBSTR Ground_total 9 1) ",") (SETQ for_total (SUBSTR Ground_total 10) Ground (SUBSTR Ground_total 1 8)))
(setq ground_list	(append ground_list (list ground)))
;(print ground_list)(princ)
;Formation level getting from excel
(IF (= (SUBSTR for_total 2 1) ",") (SETQ Fsl_total (SUBSTR for_total 3) Form (SUBSTR For_total 1 1)))
(IF (= (SUBSTR for_total 3 1) ",") (SETQ Fsl_total (SUBSTR for_total 4) form (SUBSTR for_total 1 2)))
(IF (= (SUBSTR for_total 4 1) ",") (SETQ fsl_total (SUBSTR for_total 5) form (SUBSTR for_total 1 3)))
(IF (= (SUBSTR for_total 5 1) ",") (SETQ fsl_total (SUBSTR for_total 6) form (SUBSTR for_total 1 4)))
(IF (= (SUBSTR for_total 6 1) ",") (SETQ fsl_total (SUBSTR for_total 7) form (SUBSTR for_total 1 5)))
(IF (= (SUBSTR for_total 7 1) ",") (SETQ fsl_total (SUBSTR for_total 8) form (SUBSTR for_total 1 6)))
(IF (= (SUBSTR for_total 8 1) ",") (SETQ fsl_total (SUBSTR for_total 9) form (SUBSTR for_total 1 7)))
(IF (= (SUBSTR for_total 9 1) ",") (SETQ fsl_total (SUBSTR for_total 10) form (SUBSTR for_total 1 8)))

(setq form_list	(append form_list (list form)))
;(print form_list)(princ)
;full supply level getting from excel

(IF (= (SUBSTR fsl_total 2 1) ",") (SETQ ho_bank (SUBSTR fsl_total 3) full (SUBSTR Fsl_total 1 1)))
(IF (= (SUBSTR fsl_total 3 1) ",") (SETQ ho_bank (SUBSTR fsl_total 4) full (SUBSTR fsl_total 1 2)))
(IF (= (SUBSTR fsl_total 4 1) ",") (SETQ ho_bank (SUBSTR fsl_total 5) full (SUBSTR fsl_total 1 3)))
(IF (= (SUBSTR fsl_total 5 1) ",") (SETQ ho_bank (SUBSTR fsl_total 6) full (SUBSTR fsl_total 1 4)))
(IF (= (SUBSTR fsl_total 6 1) ",") (SETQ ho_bank (SUBSTR fsl_total 7) full (SUBSTR fsl_total 1 5)))
(IF (= (SUBSTR fsl_total 7 1) ",") (SETQ ho_bank (SUBSTR fsl_total 8) full (SUBSTR fsl_total 1 6)))
(IF (= (SUBSTR fsl_total 8 1) ",") (SETQ ho_bank (SUBSTR fsl_total 9) full (SUBSTR fsl_total 1 7)))
(IF (= (SUBSTR fsl_total 9 1) ",") (SETQ ho_bank (SUBSTR fsl_total 10) full (SUBSTR fsl_total 1 8)))

(setq fsl_list	(append fsl_list (list full)))
;(print fsl_list)(princ)

; Height of Bank getting from excel
(IF (= (SUBSTR ho_bank 2 1) ",") (SETQ do_cutting (SUBSTR ho_bank 3) bank (SUBSTR ho_bank 1 1)))
(IF (= (SUBSTR ho_bank 3 1) ",") (SETQ do_cutting (SUBSTR ho_bank 4) bank (SUBSTR ho_bank 1 2)))
(IF (= (SUBSTR ho_bank 4 1) ",") (SETQ do_cutting (SUBSTR ho_bank 5) bank (SUBSTR ho_bank 1 3)))
(IF (= (SUBSTR ho_bank 5 1) ",") (SETQ do_cutting (SUBSTR ho_bank 6) bank (SUBSTR ho_bank 1 4)))
(IF (= (SUBSTR ho_bank 6 1) ",") (SETQ do_cutting (SUBSTR ho_bank 7) bank (SUBSTR ho_bank 1 5)))
(IF (= (SUBSTR ho_bank 7 1) ",") (SETQ do_cutting (SUBSTR ho_bank 8) bank (SUBSTR ho_bank 1 6)))
(IF (= (SUBSTR ho_bank 8 1) ",") (SETQ do_cutting (SUBSTR ho_bank 9) bank (SUBSTR ho_bank 1 7)))
(IF (= (SUBSTR ho_bank 9 1) ",") (SETQ do_cutting (SUBSTR ho_bank 10) bank (SUBSTR ho_bank 1 8)))

(setq hobank_list	(append hobank_list (list bank)))
;(print hobank_list)(princ)

; Depth of cutting getting from excel
(IF (= (SUBSTR do_cutting 2 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 3) Cutting (SUBSTR do_cutting 1 1)))
(IF (= (SUBSTR do_cutting 3 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 4) cutting (SUBSTR do_cutting 1 2)))
(IF (= (SUBSTR do_cutting 4 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 5) cutting (SUBSTR do_cutting 1 3)))
(IF (= (SUBSTR do_cutting 5 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 6) cutting (SUBSTR do_cutting 1 4)))
(IF (= (SUBSTR do_cutting 6 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 7) cutting (SUBSTR do_cutting 1 5)))
(IF (= (SUBSTR do_cutting 7 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 8) cutting (SUBSTR do_cutting 1 6)))
(IF (= (SUBSTR do_cutting 8 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 9) cutting (SUBSTR do_cutting 1 7)))
(IF (= (SUBSTR do_cutting 9 1) ",") (SETQ Tbank_cutting (SUBSTR do_cutting 10) cutting (SUBSTR do_cutting 1 8)))

(setq dobank_list	(append dobank_list (list cutting)))
;(print dobank_list)(princ)

;top of bank levels getting from excel
(setq tobank_list	(append tobank_list (list tbank_cutting)))
;(print tobank_list)(princ)
  
(SETQ	RLI	(READ-LINE OPE))
 );while function close
(Print chinage_list)(princ);Chinage in meter list
(print ground_list)(princ);ground level list
(print form_list)(princ);formation level list
(print fsl_list)(princ);full supply level list
(print hobank_list)(princ);height of bank level list
(print dobank_list)(princ);depth of bank level list
(print tobank_list)(princ); top of bank level list
(c:scale)
(c:cs_orgion)
(c:all_lvl_insert)
(c:colum_orgion)
(c:profile)
(C:draw_surface)
)
;download function copleated.
******************************
;cross section H&V scale factor
(defun c:scale()
	(initget 3)
	(setq	h_scale	(getreal "\nHor-scale factor - 1:"))
	(initget 3)
  	(setq	v_scale	(getreal "\nVer-scale factor - 1:"))
  	(setq	datum	(getint	"\nEnter the Datum-level ::(#)::(#):::"))
)
;Cross section origion point

(defun c:cs_orgion()
(setq 	cs_chinage (getreal "Enter the LONGITUDINAL SECTION CHINAGE###########:")
	 
	cs_text	(getstring "Enter the <<<(LHS)>>> or <<<(RHS)>>>crossection:")
	
	Cs_orgion (getpoint "Where 'UUUUUUUUUUUU' want to pick the LONGITUDINAL SECTION:")
)
(if (= "L" cs_text)
    (setq direction_text (strcat "LONGITUDINAL SECTION AT CH." (rtos cs_chinage 2 2) "m. LHS OF CANAL"))
)

(if (= "R" cs_text)
    (setq direction_text (strcat "LONGITUDINAL SECTION AT CH." (rtos cs_chinage 2 2) "m. RHS OF CANAL"))
   )
;(PRINT direction_text) (princ)
      )
;table creation and level insert
;table creation and level insert
(defun c:all_lvl_insert ()
  	(setq	f 1
	  	s 2
	  	ft_se_dist 0
	  	len		(length chinage_list)
	  	howmany_times 	(- len s)
		
;symbol_orgion is a base line for the programe
	symbol_orgion		(polar Cs_orgion (/(* pi 0) 180) 10)		
	1level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 7.200)
	2level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 20.600)
	3level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 33.800)
	4level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 47.800)
	5level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 60.200)
	6level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 73.400)
	7level_text_orgion	(polar symbol_orgion (/(* pi 90) 180) 86.600)
		
	2symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 14.000)
	3symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 27.200)
	4symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 40.400)
	5symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 53.600)
	6symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 66.800)
	7symbol_orgion	(polar symbol_orgion (/(* pi 90) 180) 80.000)
	 )

(command "layer" "s" "point" "")
(command "insert" "do" symbol_orgion "" "" "" )
(command "insert" "do" 2symbol_orgion "" "" "" )
(command "insert" "do" 3symbol_orgion "" "" "" )
(command "insert" "do" 4symbol_orgion "" "" "" )
(command "insert" "do" 5symbol_orgion "" "" "" )
(command "insert" "do" 6symbol_orgion "" "" "" )
(command "insert" "do" 7symbol_orgion "" "" "" )

(setq 1_chinage (atof (nth f chinage_list)))
(setq 2_chinage (atof (nth f ground_list)))
(setq 3_chinage (atof (nth f form_list)))
(setq 4_chinage (atof (nth f fsl_list)))
(setq 5_chinage (atof (nth f hobank_list)))
(setq 6_chinage (atof (nth f dobank_list)))
(setq 7_chinage (atof (nth f tobank_list)))
(command "layer" "s" "chainge" "")
(command "text" "s" "cs_levels" "j" "mc" 1level_text_orgion "90" (rtos 1_chinage 2 3))(terpri)
(command "layer" "s" "ground_level" "")
(command "text" "s" "cs_levels" "j" "mc" 2level_text_orgion "90" (rtos 2_chinage 2 3))(terpri)
(command "layer" "s" "formation_level" "")
(command "text" "s" "cs_levels" "j" "mc" 3level_text_orgion "90" (rtos 3_chinage 2 3))(terpri)
(command "layer" "s" "fsl" "")
(command "text" "s" "cs_levels" "j" "mc" 4level_text_orgion "90" (rtos 4_chinage 2 3))(terpri)
(command "layer" "s" "ho_of_bank" "")
(command "text" "s" "cs_levels" "j" "mc" 5level_text_orgion "90" (rtos 5_chinage 2 3))(terpri)
(command "layer" "s" "de_of_cutting" "")  
(command "text" "s" "cs_levels" "j" "mc" 6level_text_orgion "90" (rtos 6_chinage 2 3))(terpri)
(command "layer" "s" "top_of_bank" "")  
(command "text" "s" "cs_levels" "j" "mc" 7level_text_orgion "90" (rtos 7_chinage 2 3))(terpri)
 
;howmany times programe
(repeat howmany_times
    (setq	
            	ft_Chinage		(atof (nth f chinage_list))
      		se_chinage		(atof (nth s chinage_list))
	 	gr_chinage		(atof (nth s ground_list))
		fo_chinage		(atof (nth s form_list))
		fsl_chinage		(atof (nth s fsl_list))
		ho_chinage		(atof (nth s hobank_list))
		do_chinage		(atof (nth s dobank_list))
		to_chinage		(atof (nth s tobank_list))

      		ft_se_dist		(+ (* (/ (abs (- ft_chinage se_chinage)) h_scale) 1000) ft_se_dist)
	 	level_orgion		(polar symbol_orgion (/(* pi 0) 180) ft_se_dist)

		chinage_text_orgion	(polar Level_orgion (/(* pi 90) 180) 7.200)
		ground_text_orgion	(polar Level_orgion (/(* pi 90) 180) 20.60)
		form_text_orgion	(polar Level_orgion (/(* pi 90) 180) 33.80)
		fsl_text_orgion		(polar Level_orgion (/(* pi 90) 180) 47.80)
		hobank_text_orgion	(polar Level_orgion (/(* pi 90) 180) 60.20)
		dobank_text_orgion	(polar Level_orgion (/(* pi 90) 180) 73.40)
		tobank_text_orgion	(polar Level_orgion (/(* pi 90) 180) 86.60)

	  	2symbol_orgion	(polar level_orgion (/(* pi 90) 180) 14.000)
	  	3symbol_orgion	(polar level_orgion (/(* pi 90) 180) 27.200)
	  	4symbol_orgion	(polar level_orgion (/(* pi 90) 180) 40.400)
	  	5symbol_orgion	(polar level_orgion (/(* pi 90) 180) 53.600)
	  	6symbol_orgion	(polar level_orgion (/(* pi 90) 180) 66.800)
	  	7symbol_orgion	(polar level_orgion (/(* pi 90) 180) 80.000)
		
		f			(+ f 1)
	  	s			(+ s 1)
	  )

(command "layer" "s" "point" "" )
(command "insert" "do" level_orgion "" "" "" )
(command "insert" "do" 2symbol_orgion "" "" "" )
(command "insert" "do" 3symbol_orgion "" "" "" )
(command "insert" "do" 4symbol_orgion "" "" "" )
(command "insert" "do" 5symbol_orgion "" "" "" )
(command "insert" "do" 6symbol_orgion "" "" "" )
(command "insert" "do" 7symbol_orgion "" "" "" )

(command "layer" "s" "chainge" "")    
(command "text" "s" "cs_levels" "j" "mc" Chinage_text_orgion "90" (rtos se_chinage 2 3))
(command "layer" "s" "Ground_level" "")    
(command "text" "s" "cs_levels" "j" "mc" ground_text_orgion "90" (rtos gr_chinage 2 3))
(command "layer" "s" "formation_level" "")
(command "text" "s" "cs_levels" "j" "mc" form_text_orgion "90" (rtos fo_chinage 2 3))
(command "layer" "s" "fsl" "")    
(command "text" "s" "cs_levels" "j" "mc" fsl_text_orgion "90" (rtos fsl_chinage 2 3))
(command "layer" "s" "ho_of_bank" "")      
(command "text" "s" "cs_levels" "j" "mc" hobank_text_orgion "90" (rtos ho_chinage 2 3))
(command "layer" "s" "de_of_cutting" "")
(command "text" "s" "cs_levels" "j" "mc" dobank_text_orgion "90" (rtos do_chinage 2 3))
(command "layer" "s" "top_of_bank" "")
(command "text" "s" "cs_levels" "j" "mc" tobank_text_orgion "90" (rtos to_chinage 2 3))
);repeat close
); level insert
**************************************************************************
;column setting
(defun c:colum_orgion()
(setq 	Colum_orgion 		(polar cs_orgion (/(* pi 180) 180) 40)
	colum_orgion_end 	(polar colum_orgion (/(* pi 0) 180)(+ 60 ft_se_dist))
	cs_text_orgion		(polar	colum_orgion (/(* pi 0) 180)(/(+ 60 ft_se_dist) 2))
	cs_text_location	(polar cs_text_orgion (/(* pi 270) 180) 8.0)
	1vertical_colum		(polar colum_orgion (/(* pi 90) 180) 93.20)
	2vertical_colum		(polar cs_orgion (/(* pi 90) 180) 93.20)
	3vertical_colum		(polar colum_orgion_end (/(* pi 90) 180) 93.20)
	1hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 14.00)
	2hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 27.20)
	3hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 40.40)
	4hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 53.60)	
	5hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 66.80)
	6hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 80.00)
	7hor_colum_start	(polar colum_orgion (/(* pi 90) 180) 93.20)
	;datum vertical way
	vertical_datum_line_end	(polar 2vertical_colum (/(* pi 90) 180) 50.0)
	1datum_text_location	(polar 2vertical_colum (/(* pi 162) 180) 6.29)
	 
	1text_location		(polar colum_orgion (/(* pi 19) 180) 22.101)
	2text_location		(polar 1hor_colum_start (/(* pi 18) 180) 21.913)
	3text_location		(polar 2hor_colum_start (/(* pi 18) 180) 21.913)
	4text_location		(polar 3hor_colum_start (/(* pi 18) 180) 21.913)
	5text_location		(polar 4hor_colum_start (/(* pi 18) 180) 21.913)
	6text_location		(polar 5hor_colum_start (/(* pi 18) 180) 21.913)
	7text_location		(polar 6hor_colum_start (/(* pi 13) 180) 21.619)
	8text_location		(polar 6hor_colum_start (/(* pi 23) 180) 23.074)
	9text_location		(polar 1vertical_colum	(/(* pi 5) 180) 21.579)
	
	1hor_colum_end		(polar 1hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	2hor_colum_end		(polar 2hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	3hor_colum_end		(polar 3hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	4hor_colum_end		(polar 4hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	5hor_colum_end		(polar 5hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	6hor_colum_end		(polar 6hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	7hor_colum_end		(polar 7hor_colum_start (/(* pi 0) 180)(+ 60 ft_se_dist))
	)
 (command "layer" "s" "grid" "")
 (command 	"line" colum_orgion colum_orgion_end ""
 		"line" colum_orgion 1vertical_colum ""
  		"line" cs_orgion 2vertical_colum ""
  		"line" colum_orgion_end 3vertical_colum ""
   		"line" 1hor_colum_start 1hor_colum_end ""
   		"line" 2hor_colum_start 2hor_colum_end ""
   		"line" 3hor_colum_start 3hor_colum_end ""
   		"line" 4hor_colum_start 4hor_colum_end ""
   		"line" 5hor_colum_start 5hor_colum_end ""
   		"line" 6hor_colum_start 6hor_colum_end ""
   		"line" 7hor_colum_start 7hor_colum_end ""
   		"line" 2vertical_colum vertical_datum_line_end ""
      )

(command "layer" "s" "chainge" "")    
(command "text" "s" "remarks" "j" "mc" 1text_location "0" "Distance in Meters")
(command "layer" "s" "Ground_level" "")    
(command "text" "s" "remarks" "j" "mc" 2text_location "0" "Ground  Levels")
(command "layer" "s" "formation_level" "")
(command "text" "s" "remarks" "j" "mc" 3text_location "0" "Formation  Levels")
(command "layer" "s" "fsl" "")    
(command "text" "s" "remarks" "j" "mc" 4text_location "0" "Full Supply Levels")
(command "layer" "s" "ho_of_bank" "")      
(command "text" "s" "remarks" "j" "mc" 5text_location "0" "Height of Bank")
(command "layer" "s" "de_of_cutting" "")
(command "text" "s" "remarks" "j"	 "mc" 6text_location "0" "Depth of Cutting")
(command "layer" "s" "top_of_bank" "")    
(command "text" "s" "remarks" "j" "mc" 7text_location "0" "Road Surface Levels")
(command "text" "s" "remarks" "j" "mc" 8text_location "0" "Top of Bank Levels/")
(command "layer" "s" "datum" "")
(command "text" "s" "remarks" "j" "mc" 9text_location "0" "Datum")
(command "text" "s" "remarks" "j" "mc" 1datum_text_location "0" (rtos (+ datum 0) 2 2))
(command "layer" "s" "0" "")
(command "text" "s" "cs_text" "j" "mc" cs_text_location "0" direction_text)
)
;profile function
(defun c:profile ()
  	(setq	a 1
	  	b 2
	  	profile_dist 0
	  	len		(length chinage_list)
	  	howmany_times 	(- len b)
	 )
(setq
	 	1gr_chinage		(atof (nth a ground_list))
      		profile_height		(* (/ (- 1gr_chinage datum) v_scale) 1000)
  		profile_base		(polar 2vertical_colum (/(* pi 0) 180) 10)
      		profile_top1		(polar profile_base (/(* pi 90) 180) profile_height)
  		profile_surface_list	(list profile_top1)
  )
(command "layer" "s" "cs_line" "")
(command "line" profile_base profile_top1 "")

;howmany times programe
  (repeat howmany_times
    (setq	
           	ft_Chinage		(atof (nth a chinage_list))
      		se_chinage		(atof (nth b chinage_list))
	 	gr_chinage		(atof (nth b ground_list))
      
      		profile_height		(* (/ (- gr_chinage datum) v_scale) 1000)
      
      		profile_dist		(+ (* (/ (abs (- ft_chinage se_chinage)) h_scale) 1000) profile_dist)
      
      		next_base		(polar profile_base (/(* pi 0) 180) profile_dist)

      		profile_top		(polar next_base (/(* pi 90) 180) profile_height)

      		profile_surface_list	(append profile_surface_list (list profile_top))
      	      
       		a (+ 1 a)
      		b (+ 1 b)
)
(command "line" next_base profile_top "")
 
  );repeat
  ;(print profile_surface_list)(princ)
);profile 
(defun c:draw_surface()
	(setq 	cnt_st 0
	      	asclen (length profile_surface_list))
	(command "-layer" "s" "surface" ""
		 "pline")
	 	(repeat	asclen
			(setq	compar (nth cnt_st profile_surface_list)
				cnt_st (1+ cnt_st))
			(command compar)
		)
  (command "" "-layer" "s" "0" "")

)
;end function
      