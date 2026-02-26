;; main.s - Sample ADC at fixed 10 kHz rate and send data over UART
;; For PIC18F87K22 @ 64 MHz (16 MHz crystal + PLL x4)
;;
;; Workflow:
;;   1. Setup ADC and UART
;;   2. Collect 256 x 10-bit ADC samples at 10 kHz using Timer0 polling
;;   3. Send all samples over UART (start marker 0xFF,0xFF then 512 bytes)
;;   4. Halt (or loop to repeat)
    
#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte	; external UART subroutines
extrn	ADC_Setup, ADC_Read		; external ADC subroutines

; ******* Timer0 preload for 10 kHz sample rate *******************
; Fosc = 64 MHz, Timer0 clock = Fosc/4 = 16 MHz (no prescaler)
; Ticks per sample = 16,000,000 / 10,000 = 1,600
; Preload = 65536 - 1600 = 63936 = 0xF9C0
TMR0_PRELOAD_H	EQU 0xF9
TMR0_PRELOAD_L	EQU 0xC0

psect	udata_acs   ; variables in access RAM
sample_cntL:	ds 1	; low byte of sample counter
sample_cntH:	ds 1	; high byte of sample counter
send_cnt:	ds 1	; byte counter for UART send loop
send_page:	ds 1	; page counter for UART send loop

psect	udata_bank4 ; 512-byte buffer at bank 4 (0x400)
adc_buffer:	ds 512	; 256 samples x 2 bytes (low, high)

psect	code, abs
rst:	org 0x0
	goto	setup

; ******* Setup ****************************************************
setup:
	bcf	CFGS	; point to Flash program memory
	bsf	EEPGD	; access Flash program memory
	call	UART_Setup
	call	ADC_Setup
	goto	start

; ******* Main programme *******************************************
start:
	; ---- Configure Timer0: 16-bit, internal Fosc/4, no prescaler ----
	; T0CON bits: TMR0ON(7)=0, T08BIT(6)=0, T0CS(5)=0, T0SE(4)=0,
	;             PSA(3)=1 (bypass prescaler), T0PS(2:0)=000
	movlw	0x08
	movwf	T0CON, A

	; ---- Initialise buffer pointer and counter ----
	lfsr	0, adc_buffer
	clrf	sample_cntL, A
	clrf	sample_cntH, A

	; ---- Sample loop: collect 256 ADC readings ----
sample_loop:
	; Preload Timer0
	movlw	TMR0_PRELOAD_H
	movwf	TMR0H, A
	movlw	TMR0_PRELOAD_L
	movwf	TMR0L, A
	bcf	TMR0IF		; clear overflow flag
	bsf	TMR0ON		; start timer

	; Perform ADC conversion (blocking, ~20 us with Fosc/64)
	call	ADC_Read

	; Store 10-bit result: low byte then high byte
	movff	ADRESL, POSTINC0
	movff	ADRESH, POSTINC0

	; Wait for Timer0 overflow to enforce fixed sample period
wait_tmr:
	btfss	TMR0IF
	bra	wait_tmr
	bcf	TMR0ON		; stop timer

	; Increment 16-bit sample counter
	infsnz	sample_cntL, F, A
	incf	sample_cntH, F, A

	; Check if 256 samples collected (sample_cntH == 1)
	movlw	0x01
	cpfseq	sample_cntH, A
	bra	sample_loop	; not yet ? keep sampling

	; ---- Send data over UART ----
	; Start marker: 0xFF, 0xFF (cannot appear in 10-bit ADC data)
	movlw	0xFF
	call	UART_Transmit_Byte
	movlw	0xFF
	call	UART_Transmit_Byte

	; Send 512 bytes (2 pages of 256 bytes each)
	lfsr	0, adc_buffer
	movlw	2
	movwf	send_page, A
send_outer:
	clrf	send_cnt, A	; 0 -> decfsz loops 256 times
send_inner:
	movf	POSTINC0, W, A
	call	UART_Transmit_Byte
	decfsz	send_cnt, F, A
	bra	send_inner
	decfsz	send_page, F, A
	bra	send_outer

	; End marker: 0xFE, 0xFE
	movlw	0xFE
	call	UART_Transmit_Byte
	movlw	0xFE
	call	UART_Transmit_Byte

	; ---- Done: halt ----
done:
	bra	done

	end	rst