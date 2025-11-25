;ASCII CODE for S-OS

	ORG 8000H        

PRINT	EQU 1FF4H	; 一文字出力
PRINTS	EQU 1FF1H	;空白出力
CRLF	EQU 1FEEH	;改行

START:
        LD HL,(TGADR)  ;格納する場所を指定
        LD B,FFH        ;繰り返し回数
        LD A,00H        ;開始
LOOP:
        LD (HL),A       ;00->FFまでを格納
        INC A	
        INC HL          ;格納アドレスを増
        DJNZ  LOOP

INIT:
        LD A,0CH	;CLS
        CALL PRINT
        CALL PRINTS
        CALL PRINTS
        CALL PRINTS
        LD B,10H	;列ヘッダー 
        LD A,'0'
COLH:
        CP 3AH           ;0の次をABCとするため
	JR NZ,COLH3
	LD A,'A'
COLH3:
	CALL PRINT
	CALL PRINTS
	INC A
	DJNZ COLH
	CALL CRLF
	LD B,23H
COLH4:
	LD A,'-'
	CALL PRINT
	DJNZ COLH4
	CALL CRLF

;内容を表示
	LD HL,(TGADR)
	LD DE,10H          ;行数
	LD C,'0'
	LD B,10H           ;ROW
CONT:
	LD A,C             ;行ヘッダ
	CALL PRINT
	LD A,':'           ;区切り
	CALL PRINT
	CALL PRINTS
	INC C
	LD A,C
	CP 3AH
	JR NZ,SKIP1
	LD C,'A'
SKIP1:
	PUSH BC
	LD B,10H           ;COL
CONT2:
	LD A,(HL)
	CP 30H
	JR NC,SKIP2     ;制御文字は空白に置き換え
	LD A,' '
SKIP2:
	CALL PRINT
	CALL PRINTS
	ADD HL,DE	;縦順にするため次の文字は16文字先
	DJNZ CONT2
	CALL CRLF
	LD HL,(TGADR)
	INC HL
	LD (TGADR),HL
	INC C
	POP BC
	DJNZ CONT
	RET
	
TGADR:  DW 0D000H        ;データを置くアドレスを示す
	END

