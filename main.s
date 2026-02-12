#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here
start:
	clrf	0x06, A	    ; Counter = 0
	movlw 	0x00
	movwf	TRISD, A	; Port D all outputs
	movwf	TRISC, A	; Port C all outputs
	bra 	test_up

count_up:
	movff 	0x06, PORTC	; Output counter to PORTC
	incf	0x06, F, A	; Increment counter (store back in file!)
	
test_up:
	movlw   0x63		; 99 decimal
	cpfseq 	0x06, A		; Skip next if 0x06 == 0x63
	bra 	count_up	; Not 99 yet ? keep counting up
	bra 	count_down	; Reached 99 ? start counting down


count_down:
	movff 	0x06, PORTC	; Output counter
	decf 	0x06, F, A	; Decrement counter
	
test_down:
	movlw   0x00
	cpfseq 	0x06, A		; Skip if counter == 0
	bra 	count_down	; Not zero yet ? keep counting down
	goto 	start		; Reached 0 ? restart whole cycle


	end	main
