;#include <xc.inc>
;	
;global	DAC_Setup, DAC_Int_Hi
;    
;psect	dac_code, class=CODE
;	
;DAC_Int_Hi:	
;	btfss	TMR0IF		; check that this is timer0 interrupt
;	retfie	f		; if not then return
;	incf	LATJ, F, A	; increment PORTD
;
;;	movlw   0xF0
;;	movwf   TMR0H
;;	movlw   0xBE
;;	movwf   TMR0L
;	
;	bcf	TMR0IF		; clear interrupt flag
;	retfie	f		; fast return from interrupt
;
;DAC_Setup:
;	clrf	TRISJ, A	; Set PORTD as all outputs
;	clrf	LATJ, A		; Clear PORTD outputs
;	movlw	10000111B	; Set timer0 to 16-bit, Fosc/4/256
;	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
;	bsf	TMR0IE		; Enable timer0 interrupt
;;	bcf TMR0IF
;	bsf	GIE		; Enable all interrupts
;	return
;	
;	end
    
#include <xc.inc>
	
global	DAC_Setup, DAC_Int_Hi
    
psect	udata_acs		; variables in Access RAM
sine_index: ds	1		; current index into sine table (0-255)

psect	dac_code, class=CODE
	
DAC_Int_Hi:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	; incf	LATJ, F, A	; increment PORTD
	
	; Set TBLPTR = sine_table + sine_index
	movlw	low highword(sine_table)
	movwf	TBLPTRU, A
	movlw	high(sine_table)
	movwf	TBLPTRH, A
	movlw	low(sine_table)
	addwf	sine_index, W, A ; W = low(sine_table) + index
	movwf	TBLPTRL, A	 ; (carry flag preserved through movlw/movwf)
	btfsc	STATUS, 0, A	 ; check carry from addition
	incf	TBLPTRH, F, A	 ; propagate carry to high byte
	
	tblrd*			; read sine value from program memory
	movff	TABLAT, LATJ	; output to DAC on PORTJ
	
	incf	sine_index, F, A ; next sample (wraps 0->255 automatically)
	
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt

DAC_Setup:
	clrf	TRISJ, A	; Set PORTJ as all outputs
	clrf	LATJ, A		; Clear PORTJ outputs
	clrf	sine_index, A	; Start at beginning of sine table
	; With 40MHz Fosc: interrupt rate = 10MHz/256 ~ 39kHz
	; Sine output freq = 39kHz / 256 samples ~ 152 Hz
	movlw	11001000B
	; movlw	10000111B	; Set timer0 to 16-but, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	return

; Sine wave look-up table: 256 entries, 8-bit unsigned (0-255)
psect	sine_tbl, class=CODE
sine_table:
	db	128, 131, 134, 137, 140, 143, 146, 149	; i =   0-  7
	db	152, 155, 158, 162, 165, 167, 170, 173	; i =   8- 15
	db	176, 179, 182, 185, 188, 190, 193, 196	; i =  16- 23
	db	198, 201, 203, 206, 208, 211, 213, 215	; i =  24- 31
	db	218, 220, 222, 224, 226, 228, 230, 232	; i =  32- 39
	db	234, 235, 237, 239, 240, 241, 243, 244	; i =  40- 47
	db	245, 246, 248, 249, 250, 250, 251, 252	; i =  48- 55
	db	253, 253, 254, 254, 254, 255, 255, 255	; i =  56- 63
	db	255, 255, 255, 255, 254, 254, 254, 253	; i =  64- 71
	db	253, 252, 251, 250, 250, 249, 248, 246	; i =  72- 79
	db	245, 244, 243, 241, 240, 239, 237, 235	; i =  80- 87
	db	234, 232, 230, 228, 226, 224, 222, 220	; i =  88- 95
	db	218, 215, 213, 211, 208, 206, 203, 201	; i =  96-103
	db	198, 196, 193, 190, 188, 185, 182, 179	; i = 104-111
	db	176, 173, 170, 167, 165, 162, 158, 155	; i = 112-119
	db	152, 149, 146, 143, 140, 137, 134, 131	; i = 120-127
	db	128, 125, 122, 119, 116, 113, 110, 107	; i = 128-135
	db	104, 101,  98,  94,  91,  89,  86,  83	; i = 136-143
	db	 80,  77,  74,  71,  68,  66,  63,  60	; i = 144-151
	db	 58,  55,  53,  50,  48,  45,  43,  41	; i = 152-159
	db	 38,  36,  34,  32,  30,  28,  26,  24	; i = 160-167
	db	 22,  21,  19,  17,  16,  15,  13,  12	; i = 168-175
	db	 11,  10,   8,   7,   6,   6,   5,   4	; i = 176-183
	db	  3,   3,   2,   2,   2,   1,   1,   1	; i = 184-191
	db	  1,   1,   1,   1,   2,   2,   2,   3	; i = 192-199
	db	  3,   4,   5,   6,   6,   7,   8,  10	; i = 200-207
	db	 11,  12,  13,  15,  16,  17,  19,  21	; i = 208-215
	db	 22,  24,  26,  28,  30,  32,  34,  36	; i = 216-223
	db	 38,  41,  43,  45,  48,  50,  53,  55	; i = 224-231
	db	 58,  60,  63,  66,  68,  71,  74,  77	; i = 232-239
	db	 80,  83,  86,  89,  91,  94,  98, 101	; i = 240-247
	db	104, 107, 110, 113, 116, 119, 122, 125	; i = 248-255
	
	end

