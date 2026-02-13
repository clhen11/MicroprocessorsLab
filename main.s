	#include <xc.inc>
	
psect	code, abs
main:
	org 0x0
	goto	setup
	
	org 0x100		    ; Main code starts here at address 0x100
	
SPI_MasterInit: ; Set Clock edge to negative
    bcf CKE2 ; CKE bit in SSP2STAT,
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
    movwf SSP2CON1, A
    ; SDO2 output ; SCK2 output
    bcf TRISD, PORTD_SDO2_POSN, A ; SDO2 output
    bcf TRISD, PORTD_SCK2_POSN, A ; SCK2 output
    return
    
SPI_MasterTransmit: ; Start transmission of data (held in W)
    movwf SSP2BUF, A ; write data to output buffer
    
Wait_Transmit: ; Wait for transmission to complete
    btfss PIR2, 5 ; check interrupt flag to see if data has been sent
    bra Wait_Transmit
    bcf PIR2, 5 ; clear interrupt flag
    return

	; ******* Programme FLASH read Setup Code ****  
setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	SPI_MasterInit
	movlw	0x0
	movwf	TRISE
	
	goto	start
	; ******* My data and where to put it in RAM *
myTable:
	db	'T','h','i','s',' ','i','s',' ','j','u','s','t'
	db	' ','s','o','m','e',' ','d','a','t','a'
	myArray EQU 0x400	; Address in RAM for data
	counter EQU 0x10	; Address of counter variable
	align	2		; ensure alignment of subsequent instructions 

   
    
	; ******* Main programme *********************
start:	
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A	; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A	; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A	; load low byte to TBLPTRL
	movlw	22		; 22 bytes to read
	movwf 	counter, A	; our counter register
loop:
        tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0	
	movf	TABLAT, W, A
	movwf	PORTE, A
	call	SPI_MasterTransmit
	
	decfsz	counter, A	; count down to zero
	bra	loop		; keep going until finished
	
	goto	0
	end	main
