;; main.s - Sample ADC at fixed 10 kHz rate and send data over UART
;; For PIC18F87K22 @ 64 MHz (16 MHz crystal + PLL x4)
;;
;; Workflow:
;;   1. Setup ADC and UART
;;   2. Collect 128 x 10-bit ADC samples at 10 kHz using Timer0 polling
;;   3. Send all samples over UART (start marker 0xFF,0xFF then 256 bytes)
;;   4. Halt (or loop to repeat)
;;
;; 128 samples at 10 kHz = 12.8 ms capture window (~12.8 cycles of 1 kHz)
    
#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte	; external UART subroutines
extrn	ADC_Setup, ADC_Read		; external ADC subroutines

; ******* Timer0 preload for 10 kHz sample rate *******************
; Fosc = 64 MHz, Timer0 clock = Fosc/4 = 16 MHz (no prescaler)
; Ticks per sample = 16,000,000 / 10,000 = 1,600
; Preload = 65536 - 1600 = 63936 = 0xF9C0
TMR0_PRELOAD_H	EQU 0xF9
TMR0_PRELOAD_L	EQU 0xC0

NUM_SAMPLES	EQU 128		; 128 samples x 2 bytes = 256 bytes (fits in 1 bank)

psect	udata_acs   ; variables in access RAM
sample_cnt:	ds 1	; sample counter (0-127)
send_cnt:	ds 1	; byte counter for UART send loop

psect	udata_bank4 ; 256-byte buffer in bank 4 (0x400)
adc_buffer:	ds 256	; 128 samples x 2 bytes (low, high)

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
	clrf	sample_cnt, A

	; ---- Sample loop: collect 128 ADC readings ----
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

	; Increment sample counter, check if done
	incf	sample_cnt, F, A
	movlw	NUM_SAMPLES
	cpfseq	sample_cnt, A
	bra	sample_loop	; not yet ? keep sampling

	; ---- Send data over UART ----
	; Preamble: 0xAA, 0x55, 0xFF, 0xFF
	; 0xAA 0x55 breaks any false match from idle-line 0xFF bytes
	movlw	0xAA
	call	UART_Transmit_Byte
	movlw	0x55
	call	UART_Transmit_Byte
	movlw	0xFF
	call	UART_Transmit_Byte
	movlw	0xFF
	call	UART_Transmit_Byte

	; Send 256 bytes (128 samples x 2 bytes)
	lfsr	0, adc_buffer
	clrf	send_cnt, A	; 0 -> decfsz loops 256 times
send_loop:
	movf	POSTINC0, W, A
	call	UART_Transmit_Byte
	decfsz	send_cnt, F, A
	bra	send_loop

	; End marker: 0xFE, 0xFE
	movlw	0xFE
	call	UART_Transmit_Byte
	movlw	0xFE
	call	UART_Transmit_Byte

	; ---- Done: halt ----
done:
	bra	done

	end	rst