	#include <xc.inc>
	
psect	code, abs
main:
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100

	; ******* Programme FLASH read Setup Code ****  
setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	goto	start
	; ******* My data and where to put it in RAM *
myTable:
	db	1, 32, 4, 128, 8, 64, 2, 16
	myArray EQU 0x400	; Address in RAM for data
	counter EQU 0x12	; Address of counter variable
	align	2		; ensure alignment of subsequent instructions
	delaycounter EQU 0x13
	; ******* Main programme *********************
bigdelay:
	movlw   0x00 ; W=0
dloop: 
	decf    0x11, f, A ; no carry when 0x00 -> 0xff
	subwfb  0x10, f, A ; no carry when 0x00 -> 0xff
	bc	    dloop ; if carry, then loop again
	return	; carry not set so return
DelayByPortD:
    movlw high(0xFFFF)
    movwf 0x10, A
    movlw low(0xFFFF)
    movwf 0x11, A
    call bigdelay
    decfsz delaycounter, A
    bra DelayByPortD
    return
start:	
	movlw	0xFF
	movwf	TRISD, A    ; Set portD to input
	movlw	0x0
	movwf	TRISC, A	; Set portC to output
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A	; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A	; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A	; load low byte to TBLPTRL
	movlw	8		; 9 bytes to read
	movwf 	counter, A	; our counter register
loop:
        movlw	high(0xFFFF) ; load 16bit number into
	movwf	0x10, A ; FR 0x10
	movlw	low(0xFFFF)
	movwf	0x11, A ; and FR 0x11
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0
	movff	TABLAT, PORTC	   ; move fsr0 to portc
	movff	PORTD, delaycounter
	movf   PORTD, W, A
	bz SetMin
	bra Continue
	SetMin:
	    movlw 0x01
	    movwf delaycounter, A
	Continue:
	call	DelayByPortD
	decfsz	counter, A	; count down to zero
	bra	loop		; keep going until finished
	goto	0
	
	end	main