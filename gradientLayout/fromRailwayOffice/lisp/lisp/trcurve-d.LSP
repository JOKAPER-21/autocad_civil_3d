;***********Railway Transition Curve ***********18/05/2011*******************
;  This application will collect curve details and plot a trasition          
;curve as per Engineering parameters Specified in PWAY MANUAL in autocad and 
;to collect X,Y co-ordinates of curve points at 10m interval to upload       
;Total station to setout the Curve at Site.                                  
;                                                  By                        
;                                         Ajantha Krishnamoorthy             
;                                            0091-9381043378                 
;****************************************************************************

; SET OF TANGENT LINES, APEX, RADIUS AND TRL ARE THE INPUTS

;NOTE:
; 1. PROVISION FOR DIFFERENT TRANSITION LENGTH ON BOTH THE ENDS OF CURVE
;    NOT MADE AVAILABLE

; 2. PROVISION FOR COMPOUND CURVE WITH DIFFERENT RADIUS TO BE ADDED


; 3. FORMULAS USED
;
;
;    A. TANGENT LENGTH   TL= R x TAN(A/2)
;                            R=RADIUS
;                            A=DIFFLECTION ANGLE
;
;    B. CURVE LENGTH     CL= Pi x R x A /180
;                            R=RADIUS
;                            A=DIFFLECTION ANGLE
;
;
;    C. SHIFT            S = (TRL^2)/24R
;                            R=RADIUS
;                            TRL=TRANSITION LENGTH
;
;    D. TRANSITION CURVE SETTING    ( CUBIC PARABOLA )
;                        d = (30 x CHORD^2) / (Pi x R x TRL)
;                            d    = DIFLECTION FOR CHORD LENGTH IN DEGREES
;                            R    = RADIUS
;                            TRL  = TRANSITION LENGTH
;                            CHORD= CHORD LENGTH
;    D1. CIRCULAR CURVE SETTING
;                        d = (1718.9xCHORD) / (60xR) IN DEGREES
;                            d    = DIFLECTION FOR CHORD LENGTH
;                            R    = RADIUS
;                            CHORD= CHORD LENGTH
;
;    E. CIRCULAR CURVE SETTING
;                        ARC DRAWN WITH ACAD 'ARC' COMMAND FROM BCC-ECC
;                        WITH GIVEN RADIUS            
;
;
; 4. PERPENDICULAR DISTANCE FROM TANGENT LINE TO BCC = 4xS
;     (ALWAYS CHECKED INTERNALLY)
;
; 5. PERPENDICULAR DISTANCE FROM TANGENT LINE TO 
;             TP1 or TP2 (Middle of Transition Curve) = (1/2)xS
;     (ALWAYS CHECKED INTERNALLY)
;
; 6. THEARITICAL X,Y CO-ORDINATES AT 5m INTERVAL CAN BE UPLOADED TO TOTAL STATION
;    FROM ACAD FOR  TRANSFERING  AT SITE.
;    (SO THAT NO MANUAL/CALCULATION ERRORS AT SITE)
;
; 7  Simple Combined Curve Length = CL+TRL { (TP1-TP2) + Trasition Length }
;
;                             (or)= (Pi x R x A /180) + TRL
;
; 7a Actual Combined Curve Length = Cubic parabola Curve length (BTC-BCC) +
;                                   SHIFTED CIRCULAR CURVE (BCC-ECC)+
;                                   Cubic parabola Curve length (ECC-ETC)
;
; length of 7 & 7a are not Equal Because 7a Follows a shortest Route due to shift.
;


 (COMMAND "LAYER" "N" "TRANSISTION_CURVE"
            ""
 )
  
 (COMMAND "UCS" "W")
 (COMMAND "PLAN" "C") 
 (COMMAND "STYLE" "TRL" "MONOS.TTF" "5" "" "" "" "")
 (COMMAND "STYLE" "TRL-T" "MONOS.TTF" ".1" "" "" "" "")
 (COMMAND)

(DEFUN SETT ()
  
    ;POINTS INTERVAL 2.0 5.0 10.00
    (SETQ PINT 10.0)
  
    ;inputs
    ;(setq R 875.0)
    ;(setq A 30.0)
    ;(setq TRL1 120.0)
    ;(setq TRL2 120.0)
    ;(SETQ TRL (MAX TRL1 TRL2))

    (SETVAR "SNAPMODE" 0)
    (SETVAR "ELEVATION" 0) 
    (SETVAR "MIRRTEXT" 0)   
    (SETVAR "DIMSCALE" 5)
    (SETVAR "PDMODE" 35)
    (SETVAR "PDSIZE" 0.50)
   
    (SETVAR "OSMODE" 16384)
  (COMMAND "LAYER" "S" "TRANSISTION_CURVE"
                             
            ""
)
)

(defun c:cu ()
    
    (SETT)
    (COMMAND "STYLE" "TRL-T"  "" "" "" "" "" "" )
    (command) 
    (SETVAR "OSMODE" 32)
    (SETQ APEX (GETPOINT "\nSELECT APEX POINT"))
    
    (SETVAR "OSMODE" 16384)
    (setq t1 (entsel "\nSelect a First Tangent Line:"))
    
    (WHILE  (/= (cdr (assoc 0 (entget (car t1)))) "LINE")
	(setq t1 (entsel "\nSelect a First Tangent Line:"))
    )  
     
    (setq t2 (entsel "\nSelect a Second Tangent Line:"))
    (WHILE  (/= (cdr (assoc 0 (entget (car t2)))) "LINE")
	   (setq t2 (entsel "\nSelect a Second Tangent Line:"))
    )
    (IF 
     (OR (< (DISTANCE (CDR (assoc 10 (entget (car t1)))) APEX) 0.001) 
         (< (DISTANCE (CDR (assoc 11 (entget (car t1)))) APEX) 0.001)
     )
     ()
     (PROGN
      (PRINT "TANGENT1 NOT MEETS APEX!")
      (ERR)
     )
    )
  
    (IF 
     (OR (< (DISTANCE (CDR (assoc 10 (entget (car t2)))) APEX) 0.001) 
         (< (DISTANCE (CDR (assoc 11 (entget (car t2)))) APEX) 0.001)
     )
     ()
     (PROGN
     (PRINT "TANGENT2 NOT MEETS APEX!")
      (ERR)
     )
    ) 		
    (SETQ TT1L (entget (car t1)))
    (SETQ TT1 (MID (CDR (ASSOC 10 TT1L)) (CDR (ASSOC 11 TT1L))))
    (SETQ TT2L (entget (car t2)))
    (SETQ TT2 (MID (CDR (ASSOC 10 TT2L)) (CDR (ASSOC 11 TT2L))))

  
    (SETQ A (* (- (ANGLE TT1 APEX) (ANGLE APEX TT2)) (/ 180.0 PI)))
    (IF (< A 0)
      (SETQ A (+ A  360.0))
    )
  
    (IF (> A 180)
    
         

      (PROGN
           (SETQ TTT TT1)
           (SETQ TT1 TT2)
           (SETQ TT2 TTT)
           (SETQ A (* (- (ANGLE TT1 APEX) (ANGLE APEX TT2)) (/ 180.0 PI)))
      )
    )
    (IF (< A 0)
      (SETQ A (+ A  360.0))
    )  
    (SETQ TP1DIR (ANGLE TT1 APEX))
 
    (SETQ A1 (FIX A))
    (SETQ A2 (FIX (* (- A A1) 60.0)))
    (SETQ A3 (* (- (* (- A A1) 60.0) A2) 60.0))
    (IF (OR (= A 180) (< A 0.001) (> A 179.999))
        (PROGN
	  (PRINT "*** TOO LESS DIFLECTION ANGLE *****")
          (ERR)
	)  
    )  
    (setq CN (GETstring "\nC.No="))
    (setq R (GETREAL "\nRADIUS (m)="))
    (WHILE (OR  (< R 175) (> R 10000))
        (PRINT "*** TOO SHARP / TOO FLAT RADIUS ****")
	(setq R (GETREAL "\nRADIUS (m)="))       
    )  
    (setq TRL (GETREAL "\nTRASITION CURVE LENGTH (m)="))
    
    (WHILE (OR  (< TRL 20) (> TRL 400))
        (PRINT "***INVALID TRANSITION LENGHT****")
        (setq TRL (GETREAL "\nTRASITION CURVE LENGTH (m)="))
       
    )  
   
    (setq ch 0 ttc1 0)
  
   
    (SETQ TRL1 TRL TRL2 TRL)
    
    (C:TRL)
)

  ;Calculations OF GEOMETRY
(defun c:trl ()
 (SETVAR "OSMODE" 16384)
  (SETQ D (/ 1750.0 R))
                                                             ; TL= RxTAN(a/2)
    (setq TL (ABS
             (* R (/   
                    (SIN (* A 0.5 (/ PI 180.0)))
                    (COS (* A 0.5 (/ PI 180.0)))
                  )
             )
             )     
    )
                                                       ; CL= PixRxA/180
    (SETQ CL (/ (* PI R A) 180.0))
    (SETQ S1 (/ (* TRL1 TRL1) 24.0 R))                    ; SHIFT= (TRL^2)/24R
    (SETQ S2 (/ (* TRL2 TRL2) 24.0 R))
    (SETQ S (/ (* TRL TRL) 24.0 R))

    (* TP1DIR (/ 180 PI) )
  
    (SETQ TP1 (POLAR APEX (+ (- TP1DIR PI) (* 2.0 PI)) TL))
    (SETQ TP2 (POLAR APEX (+ (- TP1DIR  (*  A  (/ PI 180.0))) (* 2.0 PI)) TL))

    (SETQ TTC1 (POLAR APEX (+ (- TP1DIR PI) (* 2.0 PI)) (+ TL (/ TRL1 2.0))))       
    (SETQ TTC2 (POLAR APEX (+ (-  TP1DIR (* A  (/ PI 180.0))) (* 2.0 PI)) (+ TL (/ TRL2 2.0) )))

    (SETQ TCC1 (POLAR TTC1 (+ (- TP1DIR (ATAN (/ (* 4.0 S1) TRL1))) (* 2.0 PI))  TRL1))
    (SETQ TCC2 (POLAR TTC2 (+ (- TP1DIR (- (* (+ A 180.0) (/ PI 180.0)) (ATAN (/ (* 4.0 S2) TRL2)) ))(* 2.0 PI)) TRL2))       

       
              
    
  
 
  ;CURCULAR CURVE WITH SHIFT
    
    (COMMAND "ARC" TCC2 "E" TCC1 "R" (- R 0))
    (SETQ L (SSGET "L") )
    (SETQ CCARC (ENTGET (ENTLAST)))
    
    (COMMAND "MEASURE" L PINT)
  
       

    
  ;TRANSITION CURVE TTC1 TO TCC1
    (SETQ CCL PINT)
    (SETQ CPL TTC1)
  
    (SETQ TRL1PS   (LIST TTC1))
    (COMMAND "POINT" TTC1)
    (COMMAND "TEXT" TTC1 0 (STRCAT "C" CN " ST " ) )
    
    (WHILE (< CCL TRL1 )
        (SETQ CP    (POLAR TTC1
                                                                         ; (30xCHORD^2) / (PIxRxTRL)
                       (+ (- TP1DIR (* (/ (* 30.0 CCL CCL) (* pi  R  TRL1))  (/ PI 180.0))  ) (* 2.0 PI))
                       CCL
                    )
        )
        
        ;(COMMAND "LINE" CPL CP "")
        (SETQ TRL1PS   (APPEND TRL1PS (LIST CP)))
        (COMMAND "POINT" CP)
      (COMMAND "TEXT" CP 0 (STRCAT "C" CN " TR-1 " (RTOS CCL 2 0) ) )
        (SETQ CCL (+ CCL PINT))
        (SETQ CPL CP)
    )
    (SETQ TRL1PS (APPEND TRL1PS (LIST TCC1)))
    (SETQ PTS 0)
    (COMMAND "PLINE")
	      
	     (REPEAT (LENGTH TRL1PS)
	        (COMMAND (NTH PTS TRL1PS))
	        (SETQ PTS (1+ PTS))
	     )  
    	     
    (COMMAND)
    (SETQ TRL1PL (ENTGET (ENTLAST)))

    ;(COMMAND "LINE" CPL TCC1 "")
    (COMMAND "TEXT" TCC1 0 (STRCAT "C" CN " TC " ) )
    ;(COMMAND "POINT" TCC1)
  
  ;TRANSITION CURVE TTC2 TO TCC2
    (SETQ CCL PINT)
    (SETQ CPL TTC2)
    
    (COMMAND "POINT" TTC2)
    (COMMAND "TEXT" TTC2 0 (STRCAT "C" CN " TS " ) )
    (SETQ TRL2PS   (LIST TTC2))
    
    (WHILE (< CCL TRL2 )
        (SETQ CP    (POLAR TTC2
                       (- TP1DIR (- (* (+ A 180.0) (/ PI 180.0)) (* (/ (* 30.0 CCL CCL) (* pi  R  TRL2))  (/ PI 180.0))) )
                       
                       
                       CCL
                    )
        )
    
        ;(COMMAND "LINE" CPL CP "")
        (SETQ TRL2PS   (APPEND TRL2PS (LIST CP)))
        (COMMAND "POINT" CP)
        (COMMAND "TEXT" CP 0 (STRCAT "C" CN " TR-2 " (RTOS CCL 2 0) ) )
        (COMMAND)
        (SETQ CCL (+ CCL PINT))
        (SETQ CPL CP)
    )
    (SETQ TRL2PS (APPEND TRL2PS (LIST TCC2)))
    (COMMAND "TEXT" TCC2 0 (STRCAT "C" CN " CT " ) )
    (SETQ PTS 0)
    (COMMAND "PLINE")
	      
	     (REPEAT (LENGTH TRL2PS)
	        (COMMAND (NTH PTS TRL2PS))
	        (SETQ PTS (1+ PTS))
	     )  
   
    (COMMAND)
    (SETQ TRL2PL (ENTGET (ENTLAST)))
  
   ; (COMMAND "LINE" CPL TCC2 "")
    
    (COMMAND "POINT" TCC2)


  (COMMAND "PEDIT" (CDR (CAR TRL1PL)) "J" (CDR (CAR CCARC)) (CDR (CAR TRL2PL)) "" "")
  ;CURVE DETAILS IN BOX
  
        
         (COMMAND "CIRCLE" TCC1 1)
         (COMMAND "CIRCLE" TCC2 1)
         (COMMAND "CIRCLE" TTC1 1)
         (COMMAND "CIRCLE" TTC2 1)
        
  
    (COMMAND "STYLE" "TRL" "" "" "" "" "" "" )
    (command) 
    (command "mtext"  (polar apex  (+ (ANGLE TP1 TP2) (* 3.0 (/ PI 2.0)) (* PI 2)) 400)
                      "R" (* (+ (ANGLE TP1 TP2) 0) (/ 180.0 PI))
                      "W" 500
                      (STRCAT "             CURVE No = " CN)
                      (STRCAT "               RADIUS = " (RTOS R 2 3) "m")
                      (IF (/= TRL1 TRL2)
                         (STRCAT "    TRANSITION LENGTH = BTC " (RTOS TRL1 2 3) "& ETC " (RTOS TRL2 2 3))
                         (STRCAT "    TRANSITION LENGTH = " (RTOS TRL 2 3) "m")
                      )  
                      (STRCAT "     DIFLECTION ANGLE = "  (RTOS A1 2 0) "%%d" (RTOS  A2 2 0) "'" (RTOS A3 2 0) "''")
                              
                      (IF (/= S1 S2)
                              (STRCAT "                SHIFT = BCC "  (RTOS S1 2 3) "& ECC "  (RTOS S2 2 3) )
                              (STRCAT "                SHIFT = "  (RTOS S 2 3) "m")
                      )  
                      (STRCAT "       TANGENT LENGTH = "  (RTOS TL 2 3) "m")
                      (STRCAT "        CURVE  LENGTH = "  (RTOS CL 2 3) "m")
                      (STRCAT "COMBINED CURVE LENGTH = "  (RTOS (+ CL (+ (/ TRL1 2.0) (/ TRL2 2.0))) 2 3) "m")
                      (STRCAT "CIRCULAR CURVE LENGTH = "  (RTOS (- CL (+ (/ TRL1 2.0) (/ TRL2 2.0))) 2 3) "m")
                             
                      ;(STRCAT "     BEGINING OF T.C. ="  (RTOS (- CH (/ TRL1 2.0)) 2 3) )
                      ;(STRCAT "     BEGINING OF C.C. ="  (RTOS (+ CH (/ TRL1 2.0)) 2 3) )
                      ;(STRCAT "          END OF C.C. ="  (RTOS (+ CH CL (/ TRL2 -2.0)) 2 3) )
                      ;(STRCAT "          END OF T.C. ="  (RTOS (+ CH CL (/ TRL2 2.0)) 2 3) )
                      ""  
    )         
)




(defun RT (RTS RTSN)
  (strcat
    (substr
      "                                                                                                 "
      1
      (- RTSN (strlen RTS))
    ) ;_ end of substr
    RTS
  ) ;_ end of STRCAT
) ;_ end of DEFUN
(defun MID (MID1 MID2)
  (list (/ (+ (car MID1) (car MID2)) 2.0) (/ (+ (cadr MID1) (cadr MID2)) 2.0)) ;_ end of LIST
) ;_ end of DEFUN







