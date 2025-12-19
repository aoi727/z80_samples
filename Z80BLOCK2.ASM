;=================================
; Z80BLOCK.ASM ver.1.1 2025/12/19
; Scoreの初期化を追加
; BELL を追加
; S-OS / Sharp X1 
; 基本的にS-OS共通だが、文字以外の
; キャラクタを使用しているので
;=================================
        ORG 8000H
;=================================
; init.asm
;=================================
;---------------------------------
; S-OS CALL 
;     NAME EQU ADR  BRK REG
;---------------------------------
PRINT        EQU 1FF4H  ; F PRINT
MSG          EQU 1FE8H  ; F MESSAGE
BELL         EQU 1FC4H  ; AF
GETKY        EQU 1FD0H  ; AF
LOC          EQU 201EH  ; AF LOCATE
HOT          EQU 1FFAH  ; SYSTEM HOT Start
MPRINT       EQU 1FE2H  ; AF DE
PRTHX        EQU 1FC1H  ; AF DEBUG用
PRTHL        EQU 1FBEH  ; AF DEBUG用
SCRN         EQU 201BH  ; AF 指定位置のキャラを取得
;---------------------------------
; 定数
;---------------------------------
CLRS          EQU 0CH   ; 
MAX_X         EQU 20H   ; 32
MAX_Y         EQU 14H   ; 20
BL_H_CNT      EQU 7     ; 横の個数
BL_V_CNT      EQU 2     ; 縦の個数
BLOCK_X0      EQU 03H   ; 左始めX
BLOCK_Y0      EQU 03H   ; BLOCK 上
BLOCK_Y1      EQU 06H   ; BLOCK 下
PAD_Y         EQU 013H        ; PADDLEのY位置固定
SCORE_POS     EQU 0222H
SCORE_POS1    EQU 022AH
MES_POS       EQU 080CH 
REMAIN_BALL_POS EQU 1322H  ; Y:19 X:34
SPEED         EQU 35H
;--- Character ---
CHR_HWALL    EQU 085H 
CHR_VWALL    EQU 086H
CHR_LPAD     EQU 0E6H
CHR_MPAD     EQU 07DH
CHR_RPAD     EQU 0E7H
CHR_BLOCK    EQU 083H
CHR_BALL     EQU 0E0H
CHR_KADO     EQU 0E4H
;---------------------------------
; --- 初期化 ---
;---------------------------------
INIT:
; --- CLS ---
        LD A,CLRS
        CALL PRINT         ; CLS
; --- BALL POS ---
        LD HL,1210H        ; Y X
        LD (BP0),HL
        LD A,-1
        LD (VY),A
        LD (VX),A
; --- 壁 ---
        LD HL,0000H
        LD A,CHR_HWALL         ; 横壁
        CALL HLINE
        LD HL,0000H
        LD A,CHR_VWALL         ; 縦壁
        CALL VLINE
        LD HL,MAX_X        ; 20H
        CALL VLINE
        LD A,CHR_KADO          ; 左上 右上
        LD HL,0000H
        CALL LOC
        CALL PRINT
        LD HL,MAX_X
        CALL LOC
        CALL PRINT
; --- BLOCKS
        LD H,BLOCK_Y0
        CALL DRAW_BLOCKS
        LD H,BLOCK_Y1
        CALL DRAW_BLOCKS
; --- MAP_SET
        CALL INIT_MAP      ; BLOCK_MAPの初期化
; --- PAD 
        CALL DRAW_PAD
; --- Remaining BALL
        LD HL,REMAIN_BALL
        LD (HL),3
; --- BALL
        CALL DRAW_REMAIN_BALL_LABEL
        CALL DRAW_REMAIN_BALL
; --- SCORE
        LD HL,SCORE_POS
        CALL LOC
        CALL MPRINT
        DB 'SCORE : '
        DB 0
; --- SCORE RESET
        LD HL,SCORE_V
        LD A,'0'
        LD B,10
SCL1:
        LD (HL),A
        INC HL
        DJNZ SCL1
        CALL PRT_SCR

; --- WAIT KEY AND MAKE SEED---
        CALL MK_SEED_WKEY

;=================================
; main.asm
;=================================
;*******************************
; MAIN LOOP
;*******************************
MAIN_LOOP:
        CALL  PRT_SCR      ; スコア表示
        CALL  CHK_CLEAR    ; BLOCKの残りがあるか？
        CALL  CAL_KARI_POS ; 次の予定POSを計算(TMPX,TMPY)
        CP    MAX_Y+1        ; 底
        JR NC,MAIN_MISS   ; ★ミス
        CALL  CHK_OBJ      ; 先の座標のオブジェクト
        CALL  ERASE_BALL   ; 前のボールを消す
        CALL  CAL_SEI_POS  ; 新しい座標を確定
        CALL  DRAW_BALL    ; ボールを描く
        CALL  WAITTIME     ; 時間調整
        CALL  GETKY        
        CP  'q'
        JR Z, MAIN_OWARI   ; 強制終了
        CP 'k'
        JP Z, PAD_LEFT  
        CP 'l'
        JP Z, PAD_RIGHT
MAIN1:
        CALL  DRAW_PAD
        JR    MAIN_LOOP
MAIN_MISS:
        JP    MISS_BALL      ; ミス
MAIN_OWARI:
        JP    GAME_END       ; ゲームエンド

;--------------------------------------------------
; CLR_MEN
;--------------------------------------------------
CLR_MEN:
        LD HL,MES_POS
        CALL LOC
        LD DE,CLEAR_MSG
        CALL MSG
CLRML:
        CALL GETKY        ; 押されるまで待つ
        CP 20H            ; SP
        JR Z,RESTART1
        CP 71H            ; q
        JR Z, GAME_END
        JR NZ,CLRML
RESTART1:
        JP INIT

;-------------------------------------------------
; GAME_ENDING
;-------------------------------------------------
GAME_ENDING:
        LD HL,MES_POS
        CALL LOC
        CALL MPRINT
        DB 'GAME OVER!     ',0
KEY_WAIT:
        CALL GETKY
        CP 20H            ; SP
        JP Z,INIT
        CP 71H            ; q
        JR Z, GAME_END
        JR NZ,KEY_WAIT

;-------------------------------------------
; MISS
;-------------------------------------------
MISS_BALL:
        CALL ERASE_BALL   ; 残像処理
        CALL DRAW_REMAIN_BALL_LABEL ;前の残ボール数を消す処理のため
        LD A,(REMAIN_BALL)
        CP 0
        JR Z,GAME_ENDING
        CALL DRAW_REMAIN_BALL_DEC ;残りボールを描画
        CALL SHOW_MISS    ; 表示 MISS
DRAW_NEXT_BALL:
        LD A,(PADDLE_X)
        ADD A,2
        LD L,A
        LD H,PAD_Y-1
        LD (BP0),HL
        LD A,0FFH
        LD (VY),A
        CALL DRAW_BALL
WAITMISS:
        CALL GETKY       ; 押されるまで待つ
        CP 20H            ; SP
        JR Z,RESTART
        CP 71H            ; q
        JR Z, GAME_END
        JR NZ,WAITMISS
RESTART:
        LD B,10
        LD HL,MES_POS
        CALL LOC
ERASE_MES_L:
        LD A,' '
        CALL PRINT
        DJNZ ERASE_MES_L  
        JP MAIN_LOOP
GAME_END:
        LD A,CLRS
        CALL PRINT
        JP HOT
SHOW_MISS:
        LD HL,MES_POS
        CALL LOC
        LD DE,MISS_MSG
        CALL MSG
        RET

;==================================================
; DRAW.ASM
;==================================================
;--------------------------------------
; ERASE_BALL
;--------------------------------------
ERASE_BALL:
        LD HL,(BP0)
        CALL LOC
        LD A,' '
        CALL PRINT
        RET
;--------------------------------------
; DRAW_BALL 破壊 HL A 
;--------------------------------------
DRAW_BALL:
        LD HL,(BP0)
        CALL LOC
        LD A,CHR_BALL
        CALL PRINT
        RET
;--------------------------------------
; PAD
;--------------------------------------
PAD_LEFT:
        CALL ERASE_PAD
        LD A,(PADDLE_X)
        CP 01H
        JP Z,MAIN1
        DEC A
        LD (PADDLE_X),A
        JP MAIN1
PAD_RIGHT:
        CALL ERASE_PAD
        LD A,(PADDLE_X)
        LD C,A
        LD A,(PADDLE_W)
        ADD A,C
        CP MAX_X
        JP Z,MAIN1
        LD A,(PADDLE_X)
        INC A
        LD (PADDLE_X),A
        JP MAIN1

;--------------------------------------
; ERASE_PAD 位置変数から場所取得
; 破壊 HL B
;--------------------------------------
ERASE_PAD:
        LD A,PAD_Y
        LD H,A
        LD A,(PADDLE_X)
        LD L,A
        LD A,(PADDLE_W)
        LD B,A
EP1:    CALL LOC
        LD A,' '
        CALL PRINT
        INC L
        DJNZ EP1
        RET
;--------------------------------------
; DRAW_PAD 位置変数から場所取得
;--------------------------------------
DRAW_PAD:
        LD A,PAD_Y
        LD H,A
        LD A,(PADDLE_X)
        LD L,A
        CALL LOC
        CALL MPRINT
        DB CHR_LPAD,CHR_MPAD,CHR_MPAD,CHR_MPAD,CHR_RPAD,00
        RET

;----------------------
; WALL DRAW HLに最初のYX座標
; H 横  B L 破壊
;----------------------
HLINE:
        LD B,MAX_X
HL1:    CALL LOC
        CALL PRINT
        INC L
        DJNZ HL1
        RET
;----------------------
; WALL DRAW HLに最初のYX座標
; V 縦  B L 破壊
;----------------------
VLINE:
        LD B,MAX_Y
VL1:    CALL LOC
        CALL PRINT
        INC H
        DJNZ VL1
        RET
;---------------------------------
;  ブロック HLにLOCATIONを指定して呼ぶ
;---------------------------------
DRAW_BLOCK:
        CALL LOC
        CALL MPRINT  ; 破壊はDE
        DB CHR_BLOCK
        DB CHR_BLOCK
        DB CHR_BLOCK
        DB 0
        RET
; ---------------------------------------------
; DRAW_BLOCKS
; ---------------------------------------------
DRAW_BLOCKS:
        LD A,BLOCK_X0
        LD L,A
        CALL DRAW_BLOCK
        LD B,6
DBS1:
        LD A,L
        ADD A,4
        LD L,A
        CALL DRAW_BLOCK
        DJNZ DBS1
        RET

; ---------------------------------------------
; LEFT_BALL
; ---------------------------------------------
DRAW_REMAIN_BALL_LABEL:
        LD HL,REMAIN_BALL_POS
        CALL LOC
        CALL MPRINT
        DB 'BALL :           ',0
        RET
DRAW_REMAIN_BALL_DEC:
        LD HL,REMAIN_BALL
        LD A,(HL)
        DEC A
        LD (HL),A
        CP 0
        RET Z
DRAW_REMAIN_BALL:
        LD HL,REMAIN_BALL_POS
        LD BC,8
        ADD HL,BC
        CALL LOC
        LD HL,REMAIN_BALL
        LD B,(HL)
        LD A,CHR_BALL
DLB1:
        CALL PRINT
        DJNZ DLB1
        RET

;--------------------------------
;BLOCK MAP のクリア
;--------------------------------
CLEAR_BLOCK_MAP:
        LD A,L  ; X座標からMAPの位置
        INC A    ; +1
        SRL A    ; /2
        SRL A    ; /4 3なら1 15なら4になる 0スタートではない
        LD B,A
        ; Y座標      
        LD A,H  ; Y座標
        CP BLOCK_Y0
        JR NZ,BM1
        LD HL,BL_MAP0 - 1
        JR BM2
BM1:
        LD HL,BL_MAP1 - 1
BM2:
        INC HL
        DJNZ BM2
        LD (HL),0
        RET

;==================================================
; PROCEDURE.ASM
;==================================================
;--------------------------------
; 起動時に1回だけ呼ぶ
; HL A BC DE 破壊
;--------------------------------
MK_SEED_WKEY:
        LD HL,MES_POS
        CALL LOC
        LD DE,HAK_MSG
        CALL MSG
        LD HL,0
        ; キーが押されるまで無限ループでカウンタを増やす
WAIT_LOOP:
        INC HL                    ; 
        CALL GETKY               ; キー取得
        CP ' '                    ; SPキーが押された？
        JR NZ,WAIT_LOOP           ; 押されてなければループ続行
        ; HL が 0 にならないよう保険
        LD A,H
        OR L
        JR NZ,SEED_OK
        LD HL,12345               ; 0だったら適当な値に強制
SEED_OK:
        LD (XRND+1),HL            ; XRNDのシードにセット
        LD HL,080CH
        CALL LOC
        LD DE,HAK_MSG_ER
        CALL MSG
        RET

;--------------------------------
; 乱数が必要な時
; 破壊 A 戻り値 HL 
;--------------------------------
XRND:
        LD HL,1
        LD A,L
        RRA
        XOR H
        LD H,A          ; ← ここでHが更新される
        RRA             ; ← Aは「前のXOR結果」のまま回転 → 正しい！
        XOR H
        LD H,A
        LD (XRND+1),HL
        RET

ADD_100:
    LD HL,SCORE_V + 7
ASL1:
    LD A,(HL)
    CP '9'
    JR NZ,NO_UP
    LD A,'0'
    LD (HL),A
    DEC HL
    JR ASL1
NO_UP:
    INC A
    LD (HL),A
    RET
;--------------------------
; スコアの表示
;--------------------------
PRT_SCR:
    LD B,10
    LD HL,SCORE_V
    LD DE,SCORE_P
PSL1:
    LD A,(HL)
    LD (DE),A
    INC HL
    INC DE
    DJNZ PSL1
    LD B,9
    LD HL,SCORE_P
PSL2:
    LD A,(HL)
    CP '0'
    JR NZ,NOT_0
    LD (HL),'_'
    INC HL
    DJNZ PSL2 
NOT_0:
    LD HL,SCORE_POS1
    CALL LOC
    LD DE,SCORE_P
    CALL MSG
    RET 
;-----------------------------------
; SPEED 調整
;-----------------------------------
WAITTIME:
        LD B,SPEED     ;
WT1:    LD C,0FFH
WT2:    DEC C
        JR NZ,WT2
        DJNZ WT1
        RET

;CALC.ASM
;--------------------------------
; チェッククリア
;--------------------------------
CHK_CLEAR:
        LD HL,BL_MAP0
        LD B,14
        LD C,0
CCL:
        LD A,(HL)
        CP 1
        JR Z ,NOT_CLEAR
        INC HL
        DJNZ CCL
        JP CLR_MEN
NOT_CLEAR:
        RET

;--------------------------------
;  BLOCK_MAP INIT
;--------------------------------
INIT_MAP:
        LD HL,BL_MAP0
        LD B,14
        LD A,1
IML:
        LD (HL),A
        INC HL
        DJNZ IML
        RET
;--------------------------------
; 次のボールPOS （仮）
;--------------------------------
CAL_KARI_POS:
; --- 現在の座標
        LD HL,(BP0)  ;BALL前の位置
        LD A,L
        LD (CURX),A
        LD A,H
        LD (CURY),A
; --- 次の予定座標
        LD A,(VX)
        ADD A,L
        LD (TMPX),A
        LD A,(VY)
        ADD A,H
        LD (TMPY),A
        RET

;--------------------------------
; 次のボールPOS （正）
;--------------------------------
CAL_SEI_POS:
        LD HL,(BP0)
        LD A,(VX)
        ADD A,L
        LD L,A      ;新しいXの位置L
        ; --- Y確定 ---
        LD A,(VY)
        ADD A,H
        LD H,A
        LD (BP0),HL  
        RET

;--------------------------------
; 障害物チェック
;--------------------------------
CHK_OBJ:
        LD A,(TMPY)
        LD H,A
        LD A,(TMPX)
        LD L,A
        CALL SCRN    ; SYS CALL
        CP CHR_LPAD
        JR Z,PAD_L
        CP CHR_MPAD
        JR Z,PAD_M
        CP CHR_RPAD
        JR Z,PAD_R
        CP CHR_VWALL
        JR Z,VWALL1
        CP CHR_HWALL
        JR Z,HWALL1
        CP CHR_BLOCK
        JR Z,BLOCK1
        CP CHR_KADO
        JR Z,KADO1
CHK_OBJ_EXIT:
        RET
;--------------------------------
; PAD1
;--------------------------------
PAD_L:
        LD A,-1
        LD (VX),A
        LD A,(TMPX)
        CP 0
        JR NZ,PAD_L1
        LD A,1
        LD A,(TMPX)
PAD_L1:
        CALL FLIP_VY
        RET
PAD_M:
        CALL FLIP_VY
        CALL FLIP_VX
        RET
PAD_R:
        LD A,1
        LD (VX),A
        LD A,(TMPX)
        CP 0
        JR NZ,PAD_R1
        LD A,1
        LD A,(TMPX)
PAD_R1:
        CALL FLIP_VY
        RET
;--------------------------------
; VWALL1
;--------------------------------
VWALL1:
        CALL FLIP_VX
        RET
;--------------------------------
; HWALL1
;--------------------------------
HWALL1:
        CALL FLIP_VY
        RET
;--------------------------------
; BLOCK1
;--------------------------------
BLOCK1:         ; ヒットされたブロックの左端の位置を取得してブロックを消す
        CALL BELL
        LD A,L  ; (X)
        DEC A   ;
        DEC A   ; X-2
        SRL A   ; /2
        SRL A   ; /2
        SLA A   ; *2
        SLA A   ; *2
        INC A
        INC A
        INC A
        LD L,A
        LD A,(TMPY)
        LD H,A
        PUSH HL
        CALL CLEAR_BLOCK_MAP
        POP HL
        CALL LOC
        CALL MPRINT
        DB '   ',0
        CALL FLIP_VY
        PUSH DE
        PUSH HL
        CALL ADD_100
        POP HL
        POP DE
        RET
KADO1:
        CALL FLIP_VX
        CALL FLIP_VY
        RET

;--------------------------------
;横反転  Aのみ使用
;--------------------------------
FLIP_VX:
        LD A,(VX)
        NEG
        LD (VX),A
        RET
;--------------------------------
;縦反転  Aのみ使用
;--------------------------------
FLIP_VY:
        LD A,(VY)
        NEG
        LD (VY),A
        RET

;==================================================
; VAR.ASM
; WORK AREA
;==================================================
BP0:      DW 0000H  ;INIT でセットされる
REMAIN_BALL DB 3
SCORE_V:
    DB '0000000000',0DH
SCORE_P:
    DB '0000000000',0DH

BL_MAP0    DB 1,1,1,1,1,1,1  ;ROW0*7COL
BL_MAP1    DB 1,1,1,1,1,1,1  ;ROW1*7COL

VX:       DB 1
VY:       DB 0FFH
PADDLE_X: DB 0EH
PADDLE_W: DB 05H
CURX:     DB 0
CURY:     DB 0
TMPX:	  DB 0
TMPY:     DB 0
MISS_MSG: DB ' MISS ',0DH
CLEAR_MSG: DB ' CLEAR!!! ',0DH
HAK_MSG:     DB 'HIT ANY KEY',0DH
HAK_MSG_ER:  DB '               ',0DH
