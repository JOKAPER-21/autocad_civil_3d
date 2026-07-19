(defun dtr(x) (* (/ pi 180) x))
(command "osmode" "0") (command "cmdecho" "0") (setvar "filedia" 0)
(command "-layer" "m" "grid1" "c" "7" "" "m" "grid2" "c" "7" "" "m" "Profile1" "c" "1" "" "m" "text1" "c" "7" "" "")
(command "-layer" "m" "Profile2" "c" "3" "" "m" "Profile3" "c" "5" "" "m" "Profile4" "c" "6" "" "m" "text2" "c" "7" "" "")
(command "ltscale" "15") (setvar "filedia" 1) (setvar "dimzin" 2)
(command "-style" "section" "complex" "2.0" "" "" "" "" "")
;=============*==========*==========*===========*==H-100,V-100=============
(defun c:sf() 
	(initget 3) (setq hs(getreal "\n Hoz.Scale :") vs(getreal "\n Ver.Scale :")
				hsf(/ 1000 hs) vsf(/ 1000 vs) ) (princ)
)
;=============*==========*==========*===========*===============
(defun c:datum() 
		(if (and (not hs) (not vs))
		     (progn (alert "* Error * Sorry Try Again") (exit) )
		     (progn (initget 1) 
			    (setq dtm(getreal "\nEnter datum :")
				  dtm1(rtos dtm 2 3) dt_m(strcat "Datum:" dtm1)
			    )
		     )
		)
		(princ)
)
;=============*==========*==========*===========*===============
(defun c:sd() (c:datum) (setq dst "l" gl "l" bl "l"  fl "l" tl "l" glt(list 0)  xtt(list 0) 
			       blt(list 0)  flt(list 0) tlt(list 0) dtt(list 0) gtt(list 0) ttt(list 0)
				ab(getstring "\n Enter Chainage :")  
				gh(getstring "\n U/S or D/S :") foot(strcat "C.S OF STREAM @ " ab "m " gh)
			 ) 
	(while (and (/= gl "") (/= gl " "))
		(setq dst(getstring "\n Enter Distance :") 
				dst_(atof dst) dst1(rtos (ABS dst_) 2 2)
				xc(* dst_ hsf) ;xn(- xc 1)
				dtt(append dtt (list dst_)) xtt(append xtt (list xn))
		)
		(if (and (/= dst "") (/= dst " "))
		    (progn (setq gl(getstring "\n Enter Ground Level :")
		     		 
				 gl_(atof  gl)  
				 gl1(rtos gl_ 2 3) 
				 gl2(- gl_ dtm) 
				 yg(* gl2 vsf)  
				 pt1(list xc yg) 
				 glt(append glt (list pt1)) 
				
				 gtt(append gtt (list gl_)) 
				 gp1(list xc 0) gp2(list xc -34)  tp1(list xc -32) tp2(list xc -15)
				
			   )
			   			   
			   (command "-layer" "s" "text1" "" "") (command "text" tp1 90 dst1)
			   (command "text" tp2 90 gl1)  
			   
			   (command "-layer" "s" "grid2" "lt" "CONTINUOUS" "" "") 
			   (command "line" gp1 pt1 "")
		      )
		      (setq gl "" )
		)
	)
		(setq glt(cdr glt)   n8 0 n9 1
			n1 0 n2 0 n3 0 n4 0  asclen(length glt)  dtt(cdr dtt) xtt(cdr xtt)
			glt1(append glt (list ""))   dln(- (length dtt) 2)
			mtt(append gtt ttt)
			
		)
		;(repeat dln 
		;	(setq dt1(nth n8 dtt) dt2(nth n9 dtt) t_d1(- dt2 dt1) tdd(rtos t_d1 2 0)
		;       	      x_t1(nth n8 xtt) x_t2(nth n9 xtt) xc1(/ (+ x_t1 x_t2) 2) tpp(list xc1 -105)
		;              n8(1+ n8) n9(1+ n9)
		;	)
		;	(command "text" "j" "c" tpp 0 tdd)
		;)
		
		(command "-layer" "s" "profile1" "" "")
		(command "pline")
		(repeat (+ 1 asclen) (setq pro_pt1(nth n1 glt1)  n1(1+ n1) )
			 (princ pro_pt1) (princ)
			(command pro_pt1 )  
		)
		

		(setq pts(nth 0 glt) pte(last glt) pt0(list (car pts) 0) px(- (car pts) 40)
		      qt1(list px 0) qt2(list (+ (car pte) 0.3) 0)  lp(polar pt0 pi 20) 
	      		qt3(polar qt1 (* (/ pi 2) 3) 34)  qt4(polar qt3 (/ pi 2) 17) qq(polar qt3 0 35)
	     		pte1(list (car pte) (cdr qr)) tx1(- (car pts) 35) tt1(list tx1 1)
	      		tta(/ (+ (car pte) px) 2) ttb(list tta -45)  pte2(list (car pte) -34)
	      		tt4(list tx1 -47.5)  tt5(list tx1 -62.5) tt6(list tx1 -77.5) 
	      		tt7(list tx1 -92.5)  tt8(list tx1 -8.5) tt9(list tx1 -26)
		)
		(command "-layer" "s" "grid1" "" "")  (command "line" qt1 qt2 "")
	(command "array" "l" "" "r" "3" "1" "-17") 
	;(command "offset" "15" qt4  qt3  "")
	(command "line" qt1 qt3 "")  (command "line" pte1 pte2 "") 
	(command "-layer" "s" "text2" "" "") (command "text" tt1 0 dt_m)
	
	(command "text" tt8 0 "INITIAL LEVEL") (command "text" tt9 0 "OFFSET(m)") (command "text" ttb 0 foot)
	
	
	(setq k1(apply 'max mtt) df(- k1 dtm) k2(+ df 1) k(fix k2)  k6(* k vsf) qr(list (car qq) k6)
	      gap 10 f(/ gap vsf) t(fix (/ k f)) lv(+ dtm f) tt gap
	)
	(command "-layer" "s" "text1" "" "") 
	(repeat t
		(setq rp(polar lp (/ pi 2) gap) lv1(rtos lv 2 3) lv2(strcat lv1 "_") xx(list (car qr) gap) yy(list (car qt2) gap)) 
		(command "text" rp  0 lv2) (command "line" xx yy "")
		(setq lv(+ lv f) gap(+ gap tt) )
	)
	(setq xyz(list (car pte) k6)  xxy(list (car pte) -34) ) 
	(command "line" qq qr "") (command "line" qt2 pte2 "") (command "line" xxy xyz "") 
	
	 (command "line" qr xyz "") (command "zoom" "e")

	
)



