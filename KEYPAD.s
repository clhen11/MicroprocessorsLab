#include <xc.inc>
    
global  KeyPad_init, KeyPad_read

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter: ds  1	    ; reserve 1 byte for variable KeyPad_counter
rows:		ds  1
columns:	ds  1

psect	KeyPad_code,class=CODE
KeyPad_Setup:
    bsf	    SPEN	; enable
    bcf	    SYNC	; synchronous
    bcf	    BRGH	; slow speed
    bsf	    TXEN	; enable transmit
    bcf	    BRG16	; 8-bit generator only
    movlw   103		; gives 9600 Baud rate (actually 9615)
    movwf   SPBRG1, A	; set baud rate
    bsf	    TRISC, PORTC_TX1_POSN, A	; TX1 pin is output on RC6 pin
					; must set TRISC6 to 1
    return
    
KeyPad_init:
    movlw   0x0F	; 0-3 input, 4-7 outputs
    movwf   TRISE, A
    movlw   0xF0
    movwf    PORTE, A
    movlw   0x0
    movwf   TRISD, A
    clrf    PORTD
    movlb   0x02
    bsf	    REPU
    
    
    clrf    LATE
    
    movf    PORTE, W
    
    
    
    return
    
KeyPad_read_col:
    clrf LATE
    
    movwf   0x0F
    movf    TRISE   ;set pins 0-3 to output
    
    call    KeyPad_delay
    
    movf    PORTE, W, A
    movwf   rows, A
    
KeyPad_decode:
    movf    columns, W, A
    xorwf   rows, W, A
    movwf   keys, A
    movwf   PORTD, A
    
test_no_key: 
    movlw   0xFF
    cpfseq  keys
    bra	    test_key_0
    retlw   0x00
   
test_key_0:
    movlw   0xBE
    cpfseq  keys, A
    bra	    test_key_1
    retlw
    
test_key_1:
    movlw   0x77
    cpfseq  keys, A
    bra	    test_key_2
    retlw

test_key_2:
    movlw   0xB7
    cpfseq  keys, A
    bra	    test_key_3
    retlw

    
test_key_3: 
    movlw   0xD7
    cpfseq  keys
    bra	    test_key_4
    retlw   
   
test_key_4:
    movlw   0x7B
    cpfseq  keys, A
    bra	    test_key_5
    retlw
    
test_key_5:
    movlw   0xBB
    cpfseq  keys, A
    bra	    test_key_6
    retlw

test_key_6:
    movlw   0xDB
    cpfseq  keys, A
    bra	    test_key_7
    retlw

test_key_7: 
    movlw   0x7D
    cpfseq  keys
    bra	    test_key_8
    retlw   
   
test_key_8:
    movlw   0xBD
    cpfseq  keys, A
    bra	    test_key_9
    retlw
    
test_key_9:
    movlw   0xDD
    cpfseq  keys, A
    bra	    test_key_A
    retlw

test_key_A:
    movlw   0x7E
    cpfseq  keys, A
    bra	    test_key_B
    retlw

test_key_B: 
    movlw   0xDE
    cpfseq  keys
    bra	    test_key_C
    retlw   
   
test_key_C:
    movlw   0xEE
    cpfseq  keys, A
    bra	    test_key_D
    retlw
    
test_key_D:
    movlw   0xED
    cpfseq  keys, A
    bra	    test_key_E
    retlw

test_key_E:
    movlw   0xEB
    cpfseq  keys, A
    bra	    test_key_F
    retlw

test_key_F:
    movlw   0xE7
    cpfseq  keys, A
    bra	    test_key_F
    retlw


    
    

    


    
KeyPad_Transmit_Message:	    ; Message stored at FSR2, length stored in W
    movwf   KeyPad_counter, A
KeyPad_Loop_message:
    movf    POSTINC2, W, A
    call    KeyPad_Transmit_Byte
    decfsz  KeyPad_counter, A
    bra	    KeyPad_Loop_message
    return

KeyPad_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    KeyPad_Transmit_Byte
    movwf   TXREG1, A
    return
    
    
KeyPad_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


