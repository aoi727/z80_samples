;  BLOCK 01 S-OS

	ORG 8000H

PRINT:	EQU 1FF4H  ;One Chara Print
MSG:	EQU 1FE8H  ;String Print
GETKEY:	EQU 1FD0H  ;Get Key
BELL:	EQU 1FC4H  ;BELL
PRTHX:	EQU 1FC1H  ;Print Areg(HEX)
PRTHL:  EQU 1FBEH  ;Print HLreg(HEX)
LOC:	EQU 201EH  ;H=Y L=X
PRINTS  EQU 1FF1H  ;PRINT SP
LTNL    EQU 1FEEH  ;CR

;初期設定

START:
	LD A,0CH
	CALL PRINT  ;CLS

	LD HL,0000H
	LD A,'#'
	CALL HLINE

	LD HL,1300H
	CALL HLINE

	LD HL,0000H
	CALL VLINE

	LD HL,0026H
	CALL VLINE
        LD HL,(BP0)
        CALL LOC
        LD A,'@'
	CALL PRINT

WAITSP:
	CALL GETKEY ;Waiting SPC KEY
	CP 20H
	JR NZ,WAITSP

MAIN:
        ; 以前の＠を消す
        LD HL,(BP0)
        CALL LOC
        LD A,' '
        CALL PRINT

        ; 位置更新
        CALL MOVE_BALL

        ; 新しい＠を描画
        LD HL,(BP0)
        CALL LOC
        LD A,'@'
        CALL PRINT

        ; スピード調整
        CALL WAITTIME

        ; 終了キー判定
        CALL GETKEY
        CP 61H         ; 'a'
        JR Z,OWARI

        JR MAIN

OWARI:	
        RET

MOVE_BALL:
        LD HL,(BP0)

        ; ---- X方向 ----
        LD A,L
        LD E,A           ; 現在X保存
        LD A,(VX)
        ADD A,E          ; 次X = L + VX

        CP 0
        JR Z,FLIPX
        CP 26H
        JR Z,FLIPX
        JR XOK

FLIPX:
        CALL FLIP_VX

XOK:
        LD A,(VX)
        ADD A,L
        LD L,A

        ; ---- Y方向 ----
        LD A,H
        LD E,A           ; 現在Y保存
        LD A,(VY)
        ADD A,E          ; 次Y

        CP 0
        JR Z,FLIPY
        CP 13H
        JR Z,FLIPY
        JR YOK

FLIPY:
        CALL FLIP_VY

YOK:
        LD A,(VY)
        ADD A,H
        LD H,A

        LD (BP0),HL
        RET

FLIP_VX:
        LD A,(VX)
        NEG
        LD (VX),A
        RET

FLIP_VY:
        LD A,(VY)
        NEG
        LD (VY),A
        RET


WAITTIME:
        LD B,10H
WT1:
        LD C,0FFH
WT2:
        DEC C
        JR NZ,WT2
        DJNZ WT1
        RET

VLINE:
	LD B,14H
LOOPV:	
        CALL LOC
	CALL PRINT
	INC H
	DJNZ LOOPV
	RET
HLINE:
	LD B,27H
LOOPH:	
        CALL LOC
	CALL PRINT
	INC L
	DJNZ LOOPH
	RET


VX: DB 1     ; X方向速度 (+1 or -1)
VY: DB 1     ; Y方向速度 (+1 or -1)
BP0: DW 1005H ; 初期位置 (Y=10h, X=05h)

