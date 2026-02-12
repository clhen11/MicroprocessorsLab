#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here
start:
	clrf	0x06, A	        ; Counter = 0
	
	movlw 	0x00
	movwf	TRISC, A	    ; PORTC all outputs (DAC data bus)
	movwf	TRISD, A	    ; PORTD all outputs (WR* on RD0)

	bsf	    PORTD, 0	    ; WR* HIGH (inactive)

	bra 	test_up

count_up:
	movff 	0x06, PORTC	; Put counter on DAC data bus
	
	bcf	    PORTD, 0	    ; WR* LOW (start write)
	call	delay
	bsf	    PORTD, 0	    ; WR* HIGH (latch on rising edge)

	call	delay
	
	incf	0x06, F, A	; Increment counter
	
test_up:
	movlw   0x63		; 99 decimal
	cpfseq 	0x06, A
	bra 	count_up
	bra 	count_down


count_down:
	movff 	0x06, PORTC
	
	bcf	    PORTD, 0	    ; WR* LOW
	call	delay
	bsf	    PORTD, 0	    ; WR* HIGH (latch)

	call	delay
	
	decf 	0x06, F, A
	
test_down:
	movlw   0x00
	cpfseq 	0x06, A
	bra 	count_down
	goto 	start


delay:
	movlw	0xFF
	movwf	0x07, A
delay_loop:
	decfsz	0x07, F, A
	bra	    delay_loop
	return

	end	main

