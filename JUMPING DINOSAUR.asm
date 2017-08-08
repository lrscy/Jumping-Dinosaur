.MODEL SMALL
.386

DATA    SEGMENT
IO_8255A   EQU 230H      ; 8255_PA DATA PORT ADDRESS
IO_8255B   EQU 231H      ; 8255_PB DATA PORT ADDRESS
IO_8255C   EQU 232H      ; 8255_PC DATA PORT ADDRESS
IO_8255COM EQU 233H      ; 8255_COMMAND PORT
IO_8253    EQU 220H      ; 8253_COUNTER0 DATA PORT ADDRESS
IO_8253COM EQU 223H      ; 8253_COMMAND PORT
IN_8259A_2 EQU 20H       ; MOTHERBOARD BUILT 8259_OCW2 PORT ADDRESS
IN_8259A_1 EQU 21H       ; MOTHERBOARD BUILT 8259_OCW1 PORT ADDRESS
IO_DIG     EQU 210H      ; DATA TUBE DATA PORT ADDRESS
IO_DIGCON  EQU 211H      ; DATA TUBE COMMAND PORT ADDRESS
HAHA       DB 0H, 0H
TMP        DB ?
REN        DB 70H, 0EH
BIT_NUM    DB 01H, 02H, 04H, 08H, 10H, 20H, 40H, 80H                                             ; COLUMN BINARY CODE
JUMP       DB 0E1H, 81H, 87H, 81H, 81H, 0E1H, 81H, 81H, 0E1H, 81H, 87H, 81H, 81H, 0E1H, 81H, 81H ; REAL GROUND
SCORE      DB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 67H                                   ; DIG NUM SHOW 0 1 2 3 4 5 6 7 8 9
FMUSIC     DW 1912, 1912, 1275, 1275, 1136, 1136, 1275, 1275, 1432, 1432, 1517, 1517, 1703, 1703, 1912, 1912
LCD_TABLE1 DW 0D0A1H, 0D7E9H, 0B3C9H, 0D4B1H, 0A1C3H, 0A2B0H, 0A2B0H, 0A2B0H                     ; "小组成员："
           DW 0A2B0H, 0C0EEH, 0C8F4H, 0C9ADH, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H                     ; "李若森"
           DW 0A2B0H, 0C9DBH, 0E6C2H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H                     ; "邵媛"
           DW 0A2B0H, 0CBCEH, 0CAC0H, 0C6BDH, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, '$'                ; "宋世平"
LCD_TABLE2 DW 0D1A7H, 0BAC5H, 0A1C3H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H                     ; "学号："
           DW 0A3B1H, 0A3B3H, 0A3B2H, 0A3B8H, 0A3B1H, 0A3B1H, 0A3B3H, 0A3B2H                     ; "13281132"
           DW 0A3B1H, 0A3B3H, 0A3B2H, 0A3B8H, 0A3B1H, 0A3B1H, 0A3B3H, 0A3B9H                     ; "13281139"
           DW 0A3B1H, 0A3B3H, 0A3B2H, 0A3B8H, 0A3B1H, 0A3B0H, 0A3B3H, 0A3B7H, '$'                ; "13281037"
LCD_EMP    DW 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H                     ; EMPTY
           DW 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H
           DW 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H
           DW 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, 0A2B0H, '$'
DATA    ENDS

CODE    SEGMENT
        ASSUME CS:CODE, DS:DATA
 START: MOV AX, DATA
        MOV DS, AX
        MOV DX, IO_8255COM             ; INITIALIZE 8255
        MOV AL, 10000000B              ; 8255 A, B, C PORT ARE OUTPUT, USE MODE 0
        OUT DX, AL
        MOV DX, IO_8253COM             ; INITIALIZE 8253
        MOV AL, 00110110B              ; COUNTER 0 USE MODE 3, PRODUCE A SQUARE WAVE SIGNAL
        OUT DX, AL
        
        CALL LCD                       ; SHOW LCD INFO
        
        MOV TMP, 0                     ; INITIALIZE THE SCORE AND JUMP STATUS
        MOV BX, 0

; INITIALIZE INTR
        CLI                            ; OFF CUP INTERRUPT
        IN AL, IN_8259A_1              ; SET INTERRUPT MASK WORD(OCW1)
        AND AL, 11011111B              ; IR5 OPEN
        OUT IN_8259A_1, AL
        
        ; LOAD INTERRUPT VECTOR
        PUSH DS
        MOV AX, 0                      ; SET INTERRUPT VECTOR TABLE BASE ADDRESS 0
        MOV DS, AX
        MOV SI, 4 * 35H                ; THE POSITION OF NO.35H INTERRUPT VECTOR IN VECTOR TABLE
        MOV AX, OFFSET INTR            ; THE OFFSET ADDRESS OF INTERRUPT SERVICE ROUTIN
        MOV DS:[SI], AX                ; THE LARGE FIELD LOADED IN NO.35H INTERRUPT VECTOR
        MOV AX, SEG INTR               ; THE SEGMENT ADDRESS OF INTERRUPT SERVICE ROUTINE
        MOV DS:[SI + 2], AX            ; THE HIGH FIELD LOADED IN NO.35H INTERRUPT VECTOR
        POP DS
        STI

        MOV CX, 2FFH
    VI: CALL GVIEW
        CALL DELAYL
        LOOP VI
; MAIN
        MOV BGMN, 0
        CALL LED
        MOV BX, 0                      ; BX FOR COUNTING, BH FOR SCORE, BL FOR MAP
   JM1: CLI                            ; CLOSE THE INTERRUPT TO AVOID MAP CHANGED IN THIS MOMENT
        CALL DELAY2                    ; SHOW MAP
        STI                            ; OPEN THE INTERRUPT TO RECEIVE SINGLE PULSE SIGNAL
        INC BL                         ; LEFT MOVE THE MAP
        CMP BL, 8                      ; MAP LENGTH IS 8
        JNE NXT1
        MOV BL, 0                      ; REFRESH THE MAP
  NXT1: CMP BH, 30                     ; 30 STEPS TO WIN
        JNE NXT2
        MOV BH, 0                      ; CLEAR THE STEP
	MOV TMP, 0                         ; CLEAR THE JUMP STATUS
        CALL PLAYS                     ; PLAY MUSIC FOR WINNER
  NXT2: JMP JM1                        
                                       
INTR    PROC                           
        PUSH AX                        
        CLI                            ; CLOSE THE INTERUPT
        CMP TMP, 0                     ; CHECK THE JUMP STATUS. IF ON THE GROUND THEN JUMP, ELSE NO ACTION
        JNE NXTI1
        MOV TMP, 2
 NXTI1: CALL LED                       ; IF JUMP SUCCESS THEN LED LIGHT
        MOV AL, 00100000B              ; DO NOT SPECIFY THE END MOD OF INTERRUPT
        OUT IN_8259A_2, AL             ; SEND INTERRUPT END COMMAND (OCW2)
        STI                            ; START THE INTERUPT
        POP AX
        IRET
INTR    ENDP
        
DELAY   PROC                           ; DELAY PROGRAM
        PUSH CX
        PUSH DX
        MOV CX, 03FH
    H1: NOP
        LOOP H1
        POP DX
        POP CX
        RET
DELAY  ENDP

DELAY2  PROC
        PUSH CX
        PUSH DX
        
; COLLISION DETECTION
        MOV HAHA, BL
        MOV DI, WORD PTR HAHA
        INC DI
        MOV CL, 0
        MOV CL, JUMP[DI]               ; GET THE OBSTACLE'S POSITON

        CMP TMP, 0                     ; GET THE PLAYER'S POSITION BY JUMP STATUS(VARIBLE TMP) AND DETECT THE COLLISION
        JNE DN21
        AND CL, REN[0]
        JMP DN22
  DN21: AND CL, REN[1]
  DN22: CMP CL, 0
        JE K0
        CALL RED                       ; IF CRASH THEN GAME OVER
        JMP K3

    K0: MOV CX, 130H                   
    K1: CALL DIG                       ; SHOW PLAYER'S SCORE
        CALL GVIEW                     ; REFRESH THE VIEW
        LOOP K1
        
        CMP TMP, 0                     ; PLAYER DROP FROM THE SKY
        JE DN23
        DEC TMP
  DN23: INC BH                         ; INCREASE YOUR SCORE
        PUSH BX
        MOV AX, 0
        MOV AL, BH
        MOV BL, 11                     ; IF SCORE MOD 11 EQUALS ZERO THEN LED LIGHT
        DIV BL
        CMP AH, 0
        JNE K2
        CALL LED
    K2: POP BX
        CMP BH, 30                     ; IF YOU PASS 30 STEPS YOU WIN
        JNE K3
        CALL LED
    K3: POP DX
        POP CX
        RET
DELAY2  ENDP

RED     PROC
        PUSH DX
        PUSH CX                        ; IF YOU DIE THE VIEW GO RED
        MOV CX, 100H
  RLOP: MOV DX, IO_8255A
        MOV AL, 0FFFFFFFFH
        OUT DX, AL
        MOV DX, IO_8255B
        MOV AL, 0FFFFFFFFH
        OUT DX, AL
        LOOP RLOP
        MOV CX, 100H
        CALL PLAYF                     ; PLAY THE MUSIC FOR LOSER
   DIE: CALL DELAYL
        LOOP DIE
        MOV BX, 0                      ; CLEAR THE SCORE AND THE JUMP STATUS
        MOV TMP, 0
        POP CX
        POP DX
        RET
RED     ENDP

; SHOW MAP
GVIEW   PROC
        PUSH BX
        PUSH CX
        PUSH DX
        
        MOV HAHA, BL                   ; GET THE PLAYER'S POSITION
        MOV DI, WORD PTR HAHA
        MOV SI, DI
        INC SI
        PUSH SI

        PUSH BX                        ; GET THE PLAYSER'S POSITION
        CMP TMP, 0
        JNE GN11
        MOV BL, REN[0]
        JMP GN12
  GN11: MOV BL, REN[1]
  GN12: OR JUMP[SI], BL                ; ADD THE PLAYER INTO THE MAP
        POP BX
        
        MOV SI, -1
        MOV CX, 8
   JM2: INC SI                         ; SHOW MAP
        
        MOV DX, IO_8255A
        MOV AL, BIT_NUM[SI]
        OUT DX, AL
        MOV DX, IO_8255B
        MOV AL, JUMP[DI]
        OUT DX, AL
        INC DI
        CALL DELAY
        
        LOOP JM2
        
        POP SI                         ; REMOVE THE PLAYER FROM THE MAP
        PUSH BX
        CMP TMP, 0
        JNE GN21
        MOV BL, REN[0]
        JMP GN22
  GN21: MOV BL, REN[1]
  GN22: XOR JUMP[SI], BL
        POP BX
        
        POP DX
        POP CX
        POP BX
        RET
GVIEW   ENDP

DIG     PROC                           ; DIGITAL LED PROGRAM TO SHOW THE SCORE
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        CALL CLO
        MOV CX, 3FH
        
 LOOOP: MOV AX, 0                      ; GET THE LAST NUMBER OF THE SCORE
        MOV AL, BH
        MOV BL, 10
        DIV BL
        MOV BL, AL
        MOV AL, AH
        MOV AH, 0
        MOV DI, AX
        MOV AH, SCORE[DI]
        
        MOV DX, IO_DIG                 ; SHOW THE LAST NUMBER
        MOV AL, AH
        OUT DX, AL
        MOV DX, IO_DIGCON
        MOV AL, 00000001B
        OUT DX, AL
        
        CALL CLO
        
        MOV AX, 0                      ; GET THE MEDIUM NUMBER OF THE SCORE
        MOV AL, BL
        MOV BL, 10
        DIV BL
        MOV BL, AL
        MOV AL, AH
        MOV AH, 0
        MOV DI, AX
        MOV AH, SCORE[DI]
        
        MOV DX, IO_DIG                 ; SHOW THE MEDIUM NUMBER
        MOV AL, AH
        OUT DX, AL
        MOV DX, IO_DIGCON
        MOV AL, 00000010B
        OUT DX, AL
        
        CALL CLO
        
        MOV AX, 0                      ; GET THE MEDIUM NUMBER OF THE SCORE
        MOV AL, BL
        MOV BL, 10
        DIV BL
        MOV BL, AL
        MOV AL, AH
        MOV AH, 0
        MOV DI, AX
        MOV AH, SCORE[DI]
        
        MOV DX, IO_DIG                 ; SHOW THE MEDIUM NUMBER
        MOV AL, AH
        OUT DX, AL
        MOV DX, IO_DIGCON
        MOV AL, 00000100B
        OUT DX, AL
        
        CALL CLO

        LOOP LOOOP
        POP DI
        POP DX
        POP CX
        POP BX
        RET
DIG     ENDP

CLO     PROC                           ; CLEAR THE DIGITAL LED
        MOV DX, IO_DIGCON
        MOV AL, 00000000B
        OUT DX, AL
        RET
CLO     ENDP

LED     PROC                           ; LED PROGRAM
        PUSH DX
        PUSH CX
        PUSH BX
        MOV CX, 8
        MOV BL, 10000000B
   LOP: MOV DX, IO_8255C
        MOV AL, 00000000B              ; CLEAR THE LED
        OUT DX, AL
        MOV DX, IO_8255C
        MOV AL, BL                     ; SHOW THE LIGTHS LIGETED
        OUT DX, AL
        ROR BL, 1
        CALL DELAYL
        LOOP LOP
        MOV DX, IO_8255C
        MOV AL, 00000000B              ; CLEAR THE LED
        OUT DX, AL
        POP BX
        POP CX
        POP DX
        RET
LED     ENDP

DELAYL  PROC                           ; DELAY FOR THE LED
        PUSH CX
        MOV CX, 1FFFH
    L1: NOP
        LOOP L1
        POP CX
        RET
DELAYL  ENDP

PLAYS   PROC                           ; WINNER SONG PLAYING PROGRAM
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV CX, 16                     ; SET THE MUSICAL NOTE TO PLAY
        MOV DI, -2                     ; SET THE INITIALIZEIAL POSITION TO PLAY
 PSLOP: INC DI
        INC DI
        MOV AX, FMUSIC[DI]
        CALL BEEP                      ; PLAY THE MUSICIAL NOTE
        PUSH CX
        MOV CX, 10
 SDLOP: CALL DELAYL                    ; WAIT THE NOTE PLAYING
        LOOP SDLOP
        POP CX
        CALL PAUSE                     ; STOP PLAYING THE NOTE
        LOOP PSLOP
        POP DX
        POP CX
        POP BX
        POP AX
        RET
PLAYS   ENDP

PLAYF   PROC                           ; LOSER SONG PLAYING PROGRAM
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV CX, 12                     ; SET THE MUSICAL NOTE TO PLAY
        MOV DI, 6                      ; SET THE INITIALIZEIAL POSITION TO PLAY
 PFLOP: INC DI
        INC DI
        MOV AX, FMUSIC[DI]
        CALL BEEP                      ; PLAY THE MUSICIAL NOTE
        PUSH CX
        MOV CX, 10
 FDLOP: CALL DELAYL                    ; WAIT THE NOTE PLAYING
        LOOP FDLOP
        POP CX
        CALL PAUSE                     ; STOP PLAYING THE NOTE
        LOOP PFLOP
        POP DX
        POP CX
        POP BX
        POP AX
        RET
PLAYF   ENDP

PAUSE   PROC                           ; STOP PLAYING THE NOTE
        PUSH AX
        PUSH DX
        MOV DX, IO_8253COM             ; INITIALIZE 8253
        MOV AL, 00111000B              ; COUNTER 0 USE MODE 4, GENERATING A NEGATIVE PULSE SIGNAL
        OUT DX, AL
        CALL DELAYL
        MOV DX, IO_8253COM             ; INITIALIZE 8253
        MOV AL, 00110110B              ; COUNTER 0 USE MODE 3, PRODUCE A SQUARE WAVE SIGNAL
        OUT DX, AL
        POP DX
        POP AX
        RET
PAUSE   ENDP

BEEP    PROC                           ; PLAY ONE MUSICIAL NOTE
        PUSH AX                        ; THE REGISTER AX MEMORY THE INITIAL COUNT OF CYCLE COUNT
                                       ; NAMELY THE RATIO OF INPUT SIGNAL FREQUENCY AND THE OUTPUT SIGNAL FREQUNCY OF 8253
        PUSH DX
        MOV DX, IO_8253
        OUT DX, AL                     ; SEND LOW BYTE FIRST
        MOV AL, AH                     ; TAKE HIGH BYTE TO REGISTER AL
        OUT DX, AL                     ; SEND HIGH BYTE SECOND
        POP DX
        POP AX
        RET
BEEP    ENDP

LCD     PROC                           ; LCD DISPLAY PROGRAM
        PUSH DX
        PUSH CX
        PUSH AX
        MOV AH, 09H                    ; CALL THE 9TH COMMAND FOR LCD
        MOV DX, OFFSET LCD_TABLE1      ; GIVE LCD THE STRING TO DISPLAY
        INT 21H
        MOV CX, 100
 LCDD1: CALL DELAYL
        LOOP LCDD1
        MOV AH, 09H
        MOV DX, OFFSET LCD_EMP         ; CLEAR THE LCD SCREEN
        INT 21H
        MOV AH, 09H
        MOV DX, OFFSET LCD_TABLE2      ; GIVE LCD THE STRING TO DISPLAY
        INT 21H
        MOV CX, 100
 LCDD2: CALL DELAYL
        LOOP LCDD2
        MOV AH, 09H
        MOV DX, OFFSET LCD_EMP         ; CLEAR THE LCD SCREEN
        INT 21H
        POP AX
        POP CX
        POP DX
        RET
LCD     ENDP

DELAYG  PROC                           ; DELAY FOR THE LED
        PUSH CX
        MOV CX, 700
    G1: NOP
        LOOP G1
        POP CX
        RET
DELAYG  ENDP

; TEST PROGRAM TO SHOW THE VARIBLE ON LED IN PROGRAM
MTEST   PROC                           ; SHOW THE BL ON THE LED
        MOV DX, IO_8255C
        MOV AL, BL
        OUT DX, AL
        CALL DELAY
        RET
MTEST   ENDP

CODE    ENDS
        END START
