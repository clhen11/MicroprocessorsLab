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
    
; ---- Original KeyPad_init ----
;KeyPad_init:
;    movlw   0x0F	; 0-3 input, 4-7 outputs
;    movwf   TRISE, A
;    movlw   0xF0
;    movwf    PORTE, A
;    movlw   0x0
;    movwf   TRISD, A
;    clrf    PORTD
;    movlb   0x02
;    bsf	    REPU
;
;
;    clrf    LATE
;
;    movf    PORTE, W
;
;
;
;    return
; ---- End original KeyPad_init ----
    
; ---- Original KeyPad_read (commented out) ----
;KeyPad_read:
;    btfss   PORTE, 0
;    bra	    PORTD_output_0
;    btfsc   PORTE, 1
;    bra	    PORTD_output_1
;    btfsc   PORTE, 2
;    bra	    PORTD_output_2
;    btfsc   PORTE, 3
;    bra	    PORTD_output_3
;    nop
;
;PORTD_output_0:
;    clrf    PORTD
;    bsf	    PORTD, 0
;    return
;PORTD_output_1:
;    clrf    PORTD
;    bsf	    PORTD, 1
;    return
;PORTD_output_2:
;    clrf    PORTD
;    bsf	    PORTD, 2
;    return
;PORTD_output_3:
;    clrf    PORTD
;    bsf	    PORTD, 3
;    return
; ---- End original KeyPad_read ----
    


    
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

; ======== New 4x4 keypad code ========

KeyPad_init:
    movlw   0x0F	; RE0-RE3 inputs (rows), RE4-RE7 outputs (columns)
    movwf   TRISE, A
    movlw   0xF0	; all columns high (idle)
    movwf   LATE, A
    movlw   0x0
    movwf   TRISD, A	; PORTD all outputs (for display)
    clrf    PORTD, A
    movlb   0x02    ; set bsr
    bsf	    REPU	; enable pull-ups on PORTE
    movlb   0x00    ;restore bsr
    movlw   0xF0
    movwf   LATE, A	; restore columns high
    movf    PORTE, W
    return


KeyPad_read:
    ; 4x4 keypad scan on PORTE: RE0-RE3 rows (inputs), RE4-RE7 columns (outputs)
    ; Returns ASCII key in W. If no key pressed, W = 0 and Z flag set.

    ; Column 0 (RE4 low) -> keys: 1, 4, 7, A
    movlw   0xE0
    movwf   LATE, A
    nop
    btfss   PORTE, 0, A
    bra	    KeyPad_C0_R0
    btfss   PORTE, 1, A
    bra	    KeyPad_C0_R1
    btfss   PORTE, 2, A
    bra	    KeyPad_C0_R2
    btfss   PORTE, 3, A
    bra	    KeyPad_C0_R3

    ; Column 1 (RE5 low) -> keys: 2, 5, 8, 0
    movlw   0xD0
    movwf   LATE, A
    nop
    btfss   PORTE, 0, A
    bra	    KeyPad_C1_R0
    btfss   PORTE, 1, A
    bra	    KeyPad_C1_R1
    btfss   PORTE, 2, A
    bra	    KeyPad_C1_R2
    btfss   PORTE, 3, A
    bra	    KeyPad_C1_R3

    ; Column 2 (RE6 low) -> keys: 3, 6, 9, B
    movlw   0xB0
    movwf   LATE, A
    nop
    btfss   PORTE, 0, A
    bra	    KeyPad_C2_R0
    btfss   PORTE, 1, A
    bra	    KeyPad_C2_R1
    btfss   PORTE, 2, A
    bra	    KeyPad_C2_R2
    btfss   PORTE, 3, A
    bra	    KeyPad_C2_R3

    ; Column 3 (RE7 low) -> keys: F, E, D, C
    movlw   0x70
    movwf   LATE, A
    nop
    btfss   PORTE, 0, A
    bra	    KeyPad_C3_R0
    btfss   PORTE, 1, A
    bra	    KeyPad_C3_R1
    btfss   PORTE, 2, A
    bra	    KeyPad_C3_R2
    btfss   PORTE, 3, A
    bra	    KeyPad_C3_R3
    
KeyPad_NoKey:
    movlw   0xF0
    movwf   LATE, A
    movlw   0x00		; no key pressed
    iorlw   0x00		; movlw does NOT set Z! iorlw 0 with W=0 sets Z flag
    return

; Row 0: 1 2 3 F
KeyPad_C0_R0:
    movlw   '1'
    bra	    KeyPad_Return
KeyPad_C1_R0:
    movlw   '2'
    bra	    KeyPad_Return
KeyPad_C2_R0:
    movlw   '3'
    bra	    KeyPad_Return
KeyPad_C3_R0:
    movlw   'F'
    bra	    KeyPad_Return

; Row 1: 4 5 6 E
KeyPad_C0_R1:
    movlw   '4'
    bra	    KeyPad_Return
KeyPad_C1_R1:
    movlw   '5'
    bra	    KeyPad_Return
KeyPad_C2_R1:
    movlw   '6'
    bra	    KeyPad_Return
KeyPad_C3_R1:
    movlw   'E'
    bra	    KeyPad_Return

; Row 2: 7 8 9 D
KeyPad_C0_R2:
    movlw   '7'
    bra	    KeyPad_Return
KeyPad_C1_R2:
    movlw   '8'
    bra	    KeyPad_Return
KeyPad_C2_R2:
    movlw   '9'
    bra	    KeyPad_Return
KeyPad_C3_R2:
    movlw   'D'
    bra	    KeyPad_Return

; Row 3: A 0 B C
KeyPad_C0_R3:
    movlw   'A'
    bra	    KeyPad_Return
KeyPad_C1_R3:
    movlw   '0'
    bra	    KeyPad_Return
KeyPad_C2_R3:
    movlw   'B'
    bra	    KeyPad_Return
KeyPad_C3_R3:
    movlw   'C'
    bra	    KeyPad_Return

KeyPad_Return:
    movwf   PORTD, A		; output ASCII to PORTD
    movwf   KeyPad_counter, A	; save ASCII temporarily
    movlw   0xF0
    movwf   LATE, A		; restore all columns high
    movf    KeyPad_counter, W, A ; restore ASCII to W
    return


