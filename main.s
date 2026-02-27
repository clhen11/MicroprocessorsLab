#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte	
extrn	ADC_Setup, ADC_Read

TMR0_PRELOAD_H	EQU 0xF9    ;Preload = 65536 - 1600 = 63936 = 0xF9C0
TMR0_PRELOAD_L	EQU 0xC0

NUM_SAMPLES	EQU 128		; 128 samples x 2 bytes = 256 bytes

psect	udata_acs   ; variables in access RAM
sample_cnt:	ds 1	; sample counter (0-127)
send_cnt:	ds 1	; byte counter for UART send loop

psect	udata_bank4 ; 256-byte buffer in bank 4 (0x400)
adc_buffer:	ds 256	; 128 samples x 2 bytes (low, high)

psect	code, abs
rst:	org 0x0
	goto	setup

setup:
	bcf	CFGS	; point to Flash program memory
	bsf	EEPGD	; access Flash program memory
	call	UART_Setup
	call	ADC_Setup
	goto	start

start:
	; TMR0ON(7)=0, T08BIT(6)=0, T0CS(5)=0, T0SE(4)=0,
	; PSA(3)=1 (bypass prescaler), T0PS(2:0)=000
	movlw	0x08
	movwf	T0CON, A
	lfsr	0, adc_buffer	;Initialise buffer pointer and counter
	clrf	sample_cnt, A

sample_loop:	;collect 128 ADC readings
	movlw	TMR0_PRELOAD_H	; Preload Timer0
	movwf	TMR0H, A
	movlw	TMR0_PRELOAD_L
	movwf	TMR0L, A
	bcf	TMR0IF		; clear overflow flag
	bsf	TMR0ON		; start timer

	call	ADC_Read    ;ADC conversion

	movff	ADRESL, POSTINC0    ;Store 12-bit result
	movff	ADRESH, POSTINC0

wait_tmr:   	;Wait for Timer0 overflow to enforce fixed sample period
	btfss	TMR0IF
	bra	wait_tmr
	bcf	TMR0ON		;stop timer
	incf	sample_cnt, F, A    ; Increment sample counter, check if done
	movlw	NUM_SAMPLES
	cpfseq	sample_cnt, A
	bra	sample_loop	; not yet ? keep sampling

	;Send data over UART
	movlw	0xAA
	call	UART_Transmit_Byte
	movlw	0x55
	call	UART_Transmit_Byte
	movlw	0xFF
	call	UART_Transmit_Byte
	movlw	0xFF
	call	UART_Transmit_Byte  	; Send 256 bytes (128 samples x 2 bytes)
	lfsr	0, adc_buffer
	clrf	send_cnt, A	; 0 -> decfsz loops 256 times
	
send_loop:
	movf	POSTINC0, W, A
	call	UART_Transmit_Byte
	decfsz	send_cnt, F, A
	bra	send_loop
	movlw	0xFE		; End marker: 0xFE, 0xFE
	call	UART_Transmit_Byte
	movlw	0xFE
	call	UART_Transmit_Byte
	
done:
	bra	done

	end	rst