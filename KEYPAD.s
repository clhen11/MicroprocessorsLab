#include <xc.inc>
    
global  KeyPad_init, KeyPad_read

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter

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
    
KeyPad_read:
    btfss   PORTE, 0
    bra	    PORTD_output_0
    btfsc   PORTE, 1
    bra	    PORTD_output_1
    btfsc   PORTE, 2
    bra	    PORTD_output_2
    btfsc   PORTE, 3
    bra	    PORTD_output_3
    nop
    
PORTD_output_0:
    clrf    PORTD
    bsf	    PORTD, 0
    return
PORTD_output_1:
    clrf    PORTD
    bsf	    PORTD, 1
    return
PORTD_output_2:
    clrf    PORTD
    bsf	    PORTD, 2
    return
PORTD_output_3:
    clrf    PORTD
    bsf	    PORTD, 3
    return
    


    
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


