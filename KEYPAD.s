#include <xc.inc>
    
global  KeyPad_init, KeyPad_read

psect   udata_acs   ; reserve data space in access ram
KeyPad_counter: ds  1
rows:           ds  1
columns:        ds  1
keys:           ds  1
col_index:      ds  1
tmp:            ds  1
LCD_cnt_l:      ds  1
LCD_cnt_h:      ds  1

psect	KeyPad_code,class=CODE


KeyPad_init:

    movlw   0x0F   
    movwf   TRISE, A

    ; Start with all columns high
    movlw   0xF0
    movwf   LATE, A

    ; Optional: enable weak pull-ups on rows (device-specific)
    movlb   0x02
    bsf     REPU                ; keep your setting if valid on your PIC

    ; Clear mismatch
    movf    PORTE, W, A

    ; Port D for debug as output
    clrf    PORTD
    movlw   0x00
    movwf   TRISD, A

    return
    
# KeyPad_read_col:
#     clrf LATE
#     
#     movwf   0x0F
#     movf    TRISE   ;set pins 0-3 to output
#     
#     call    KeyPad_delay
#     
#     movf    PORTE, W, A
#     movwf   rows, A
#     
# KeyPad_decode:
#     movf    columns, W, A
#     xorwf   rows, W, A
#     movwf   keys, A
#     movwf   PORTD, A
#     
# test_no_key: 
#     movlw   0xFF
#     cpfseq  keys
#     bra	    test_key_0
#     retlw   0x00
#    
# test_key_0:
#     movlw   0xBE
#     cpfseq  keys, A
#     bra	    test_key_1
#     retlw
#     
# test_key_1:
#     movlw   0x77
#     cpfseq  keys, A
#     bra	    test_key_2
#     retlw
# 
# test_key_2:
#     movlw   0xB7
#     cpfseq  keys, A
#     bra	    test_key_3
#     retlw
# 
#     
# test_key_3: 
#     movlw   0xD7
#     cpfseq  keys
#     bra	    test_key_4
#     retlw   
#    
# test_key_4:
#     movlw   0x7B
#     cpfseq  keys, A
#     bra	    test_key_5
#     retlw
#     
# test_key_5:
#     movlw   0xBB
#     cpfseq  keys, A
#     bra	    test_key_6
#     retlw
# 
# test_key_6:
#     movlw   0xDB
#     cpfseq  keys, A
#     bra	    test_key_7
#     retlw
# 
# test_key_7: 
#     movlw   0x7D
#     cpfseq  keys
#     bra	    test_key_8
#     retlw   
#    
# test_key_8:
#     movlw   0xBD
#     cpfseq  keys, A
#     bra	    test_key_9
#     retlw
#     
# test_key_9:
#     movlw   0xDD
#     cpfseq  keys, A
#     bra	    test_key_A
#     retlw
# 
# test_key_A:
#     movlw   0x7E
#     cpfseq  keys, A
#     bra	    test_key_B
#     retlw
# 
# test_key_B: 
#     movlw   0xDE
#     cpfseq  keys
#     bra	    test_key_C
#     retlw   
#    
# test_key_C:
#     movlw   0xEE
#     cpfseq  keys, A
#     bra	    test_key_D
#     retlw
#     
# test_key_D:
#     movlw   0xED
#     cpfseq  keys, A
#     bra	    test_key_E
#     retlw
# 
# test_key_E:
#     movlw   0xEB
#     cpfseq  keys, A
#     bra	    test_key_F
#     retlw
# 
# test_key_F:
#     movlw   0xE7
#     cpfseq  keys, A
#     bra	    test_key_F
#     retlw
# 
# 
#     
#     
# 
#     
# 
# 
#     
# KeyPad_Transmit_Message:	    ; Message stored at FSR2, length stored in W
#     movwf   KeyPad_counter, A
# KeyPad_Loop_message:
#     movf    POSTINC2, W, A
#     call    KeyPad_Transmit_Byte
#     decfsz  KeyPad_counter, A
#     bra	    KeyPad_Loop_message
#     return
# 
# KeyPad_Transmit_Byte:	    ; Transmits byte stored in W
#     btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
#     bra	    KeyPad_Transmit_Byte
#     movwf   TXREG1, A
#     return
#     
#     
# KeyPad_delay:			; delay routine	4 instruction loop == 250ns	    
# 	movlw 	0x00		; W=0
# lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
# 	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
# 	bc 	lcdlp1		; carry, then loop again
# 	return			; carry reset so return
# 
# 

    
; Drive one column low at a time (RE4..RE7)
KP_col_pattern:
    ; W on entry = col_index (0..3)
    addwf   PCL, F, A
    retlw   0xE0    ; col 0 low
    retlw   0xD0    ; col 1 low
    retlw   0xB0    ; col 2 low
    retlw   0x70    ; col 3 low

; Small delay (uses LCD_cnt_l / LCD_cnt_h)
KeyPad_delay:
    movlw   0x00
lcdlp1:
    decf    LCD_cnt_l, F, A
    subwfb  LCD_cnt_h, F, A
    bc      lcdlp1
    return

; -------------------------------
; KeyPad_read: returns ASCII of key or 0x00 if none
; -------------------------------
KeyPad_read:
    ; Quick "no key" check using columns=0xF0
    movlw   0xF0
    movwf   columns, A
    movwf   LATE, A
    call    KeyPad_delay
    movf    PORTE, W, A
    andlw   0x0F
    movwf   rows, A
    movf    columns, W, A
    xorwf   rows, W, A          ; W = columns XOR rows
    movwf   keys, A

    movlw   0xFF
    cpfseq  keys, A             ; if keys == 0xFF -> no key
    bra     KP_scan_columns
    retlw   0x00                ; no key pressed

KP_scan_columns:
    clrf    col_index, A

KP_col_loop:
    ; Get column pattern
    movf    col_index, W, A
    call    KP_col_pattern
    movwf   columns, A
    movwf   LATE, A

    call    KeyPad_delay

    ; Read rows (low nibble)
    movf    PORTE, W, A
    andlw   0x0F
    movwf   rows, A

    ; Make signature and show on PORTD (debug)
    movf    columns, W, A
    xorwf   rows, W, A
    movwf   keys, A
    movwf   PORTD, A

    ; Decode using your compare-per-key chain
    call    KeyPad_decode

    ; If decode returned 0x00, try next column
    movwf   tmp, A
    movf    tmp, W, A
    bz      KP_next_col
    return                      ; return ASCII of key in W

KP_next_col:
    incf    col_index, F, A
    movf    col_index, W, A
    xorlw   0x04
    bz      KP_no_match_all
    bra     KP_col_loop

KP_no_match_all:
    retlw   0x00
    

; Input: keys (columns XOR rows)
; Output: W = ASCII of matched key, or 0x00 if no match in this pass
KeyPad_decode:
test_no_key:
    movlw   0xFF
    cpfseq  keys, A
    bra     test_key_0
    retlw   0x00                 ; "no key" here -> treat as no match in this pass

test_key_0:
    movlw   0xBE
    cpfseq  keys, A
    bra     test_key_1
    retlw   '0'                  ; or retlw 0x00 for nibble

test_key_1:
    movlw   0x77
    cpfseq  keys, A
    bra     test_key_2
    retlw   '1'

test_key_2:
    movlw   0xB7
    cpfseq  keys, A
    bra     test_key_3
    retlw   '2'

test_key_3:
    movlw   0xD7
    cpfseq  keys, A
    bra     test_key_4
    retlw   '3'

test_key_4:
    movlw   0x7B
    cpfseq  keys, A
    bra     test_key_5
    retlw   '4'

test_key_5:
    movlw   0xBB
    cpfseq  keys, A
    bra     test_key_6
    retlw   '5'

test_key_6:
    movlw   0xDB
    cpfseq  keys, A
    bra     test_key_7
    retlw   '6'

test_key_7:
    movlw   0x7D
    cpfseq  keys, A
    bra     test_key_8
    retlw   '7'

test_key_8:
    movlw   0xBD
    cpfseq  keys, A
    bra     test_key_9
    retlw   '8'

test_key_9:
    movlw   0xDD
    cpfseq  keys, A
    bra     test_key_A
    retlw   '9'

test_key_A:
    movlw   0x7E
    cpfseq  keys, A
    bra     test_key_B
    retlw   'A'

test_key_B:
    movlw   0xDE
    cpfseq  keys, A
    bra     test_key_C
    retlw   'B'

test_key_C:
    movlw   0xEE
    cpfseq  keys, A
    bra     test_key_D
    retlw   'C'

test_key_D:
    movlw   0xED
    cpfseq  keys, A
    bra     test_key_E
    retlw   'D'

test_key_E:
    movlw   0xEB
    cpfseq  keys, A
    bra     test_key_F
    retlw   'E'

test_key_F:
    movlw   0xE7
    cpfseq  keys, A
    bra     KP_decode_miss
    retlw   'F'

KP_decode_miss:
    retlw   0x00