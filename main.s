#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
;start:
;	movlw 	0x0
;	movwf	TRISD, A	    ; Port D all outputs
;	bra 	test_up
;count_up:
;	movff 	0x06, PORTD
;	incf 	0x06, W, A
;test_up:
;	movwf	0x06, A	    ; Test for end of loop condition
;	movlw   0xFF
;	cpfsgt 	0x06, A
;	bra 	count_up		    ; Not yet finished goto start of loop again
;	goto   
;	goto 	0x0		    ; Re-run program from start
;
;	
;	
;
;	end	main

    
    start:
    ; PORTC = outputs (DAC data)
    movlw   0x00
    movwf   TRISC, A

    ; RD0 = output (WR*)
    movlw   0xFE        ; RD0 output, rest input
    movwf   TRISD, A

    bsf     LATD, 0, A  ; WR* = HIGH (inactive)

    clrf    0x20, A     ; Counter = 0

main_loop:

; ==================
; COUNT UP
; ==================
count_up:
    movf    0x20, W, A
    movwf   LATC, A     ; Send to DAC

    ; Pulse WR*
    bcf     LATD, 0, A
    nop
    nop
    bsf     LATD, 0, A

    incf    0x20, F, A
    movlw   0xFF
    cpfseq  0x20, A
    bra     count_up

; ==================
; COUNT DOWN
; ==================
count_down:
    movf    0x20, W, A
    movwf   LATC, A

    ; Pulse WR*
    bcf     LATD, 0, A
    nop
    nop
    bsf     LATD, 0, A

    decf    0x20, F, A
    movlw   0x00
    cpfseq  0x20, A
    bra     count_down

    bra     main_loop
