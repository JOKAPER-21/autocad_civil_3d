(DEFUN C:RESET ()
   (SETQ SF NIL)
   (SETQ IT NIL)
   (SETQ QA1 NIL)
)  
(defun C:BA ()
  ;CHAIN,ITEM  INCLUDED
  (IF (= SF NIL)
    (setq sf 1)
    ;(SETQ SF (GETREAL "SCALE FACTOR="))
  )  
  (IF (= IT NIL)
      (PROGN
       (SETQ CH 0 IT "m" chpp (list 0 0))
      ; (PRINT "---SELECT OBJECTS FOR LAYERS TO BE SWITCHED OFF--")
      ; (SETQ LAYERSS (SSGET))
       
       
      )  
  )
  (setq och ch)
  ;(setq CH (GETREAL1 "\nCHAINAGE =" CH))
  
  
  ;(setq IT (GETSTR1 "\nITEM NAME=" IT))
  ;(setvar "DIMZIN" 3)
  
  (SETQ LAY1 0)
  (if layerss
  
   (REPEAT (SSLENGTH LAYERSS)
               (SETQ LAY1N (CDR (ASSOC 8 (ENTGET (SSNAME   LAYERSS LAY1)))))
               (IF (/= LAY1N (GETVAR "CLAYER"))
                   (PROGN 
                     (COMMAND "LAYER" "OFF" LAY1N "")
                     (COMMAND)
                   )  
               )  
               (SETQ LAY1 (+ LAY1 1))
   )
   
  )
  (COMMAND "LAYER" "OFF" "t_*" "") 
  (command)
  
  (setq OB NIL)
  (print "<<<  Select Unwanted Objects to hide >>>")
  (setq OB (ssget))
  (if OB
    (command "MOVE" OB "" "0,0" "@25<90")
  ) ;_ end of if
  (setq AA NIL)
  (setq A 1)
  
  (while (= AA NIL)
    (setq A (getpoint "\nPlease select a internal Point :"))
    (if (= A NIL)
      (setq AA 1)
      (setq AA (bpoly A))
    ) ;_ end of if
  ) ;_ end of WHILE
  (if (/= A NIL)
    (progn (command "AREA" "E" AA)
           (setq B (getpoint A "\n<<Pick a START point for QTY TEXT>>"))
           (command "LEADER"
                    A
                    B
                    ""
                    (strcat (rtos (setq AREAGG (* (getvar "AREA") SF)) 2 3) " Sq." IT) ; _
  ; end
  ; of
  ; STRCAT
                    ""
           ) ;_ end of COMMAND
           (getvar "AREA")
    ) ;_ end of PROGN
  ) ;_ end of IF
  
  (if OB
    (command "MOVE" OB "" "0,0" "@25<270")
  ) ;_ end of if
 ; (if AA
 ;   (command "erase" AA "")
 ; ) ;_ end of if
  
  (SETQ LAY1 0)
  (if layerss
  (REPEAT (SSLENGTH LAYERSS)
               (SETQ LAY1N (CDR (ASSOC 8 (ENTGET (SSNAME   LAYERSS LAY1)))))
               (IF (/= LAY1N (GETVAR "CLAYER"))
                   (PROGN 
                     (COMMAND "LAYER" "ON" LAY1N "")
                     (COMMAND)
                   )  
               )  
               (SETQ LAY1 (+ LAY1 1))
  )  
  
  )
  (COMMAND "LAYER" "ON" "t_*" "") 
  (command)
  (SETQ QA1 (APPEND QA1 (LIST (LIST CH IT  AREAGG))))
  (print AREAGG)  
  (SETQ AA NIL)
) ;_ end of defun



(defun C:ABS (/ N NN LO AR O FD1)
  (setq FDAN (substr (getvar "dwgname") 1 (- (strlen (getvar "dwgname")) 4))) ;_ end of setq
  (setq PATH1 (getvar "dwgprefix"))
  (setq FD1 (open (strcat PATH1 FDAN ".TXT") "w"))
  (setq N 0)
  (while (nth N QA1)
    (setq LO (nth N QA1))
    
      (setq O (substr (strcat (nth 1 LO) "                     ") 1 15)) 
      (setq AREA (nth 2 LO))
      
      (setq AR (rtos AREA 2 4))
   
      (write-line
        (strcat (substr (strcat (rtos (car LO) 2 3) "                     ") 1 15)
                O
                (substr (strcat AR "                        ") 1 15)
        ) ;_ end of STRCAT
        FD1
      ) ;_ end of WRITE-LINE
    
    (setq N (1+ N))
  ) ;_ end of while
  
  (close FD1)
)

(defun GETREAL1 (MES1 DEFA)
  (if (= DEFA NIL)
    (setq DEFA 0)
  ) ;_ end of IF
  (setq RR1 (getreal (strcat MES1 " <" (rtos DEFA) ">"))) ;_ end of setq
  (if (= RR1 NIL)
    DEFA
    RR1
  ) ;_ end of IF
) ;_ end of defun
(defun GETINT1 (MES1 DEFA)
  (if (= DEFA NIL)
    (setq DEFA 0)
  ) ;_ end of IF
  (setq RR1 (getint (strcat MES1 " <" (rtos DEFA 2 0) ">"))) ;_ end of setq
  (if (= RR1 NIL)
    DEFA
    RR1
  ) ;_ end of IF
) ;_ end of defun

(defun GETSTR1 (MES1 DEFA)
  (if (= DEFA NIL)
    (setq DEFA "")
  ) ;_ end of IF
  (setq RR1 (getstring (strcat MES1 " <" DEFA ">"))) ;_ end of setq
  (if (= RR1 "")
    DEFA
    RR1
  ) ;_ end of IF
) ;_ end of defun
  