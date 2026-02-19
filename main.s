#include <xc.inc>


extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_delay_x4us, LCD_Clear
extrn	KeyPad_init, KeyPad_read
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db  '1','2','3','4','5','6','7','8','9','0','1','2','3','4','5','6','7','8','9','0',0x0a
					; message, plus carriage return
	myTable_l   EQU	22	; length of data
	align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	KeyPad_init	; set up keypad
	call	LCD_Setup	; setup LCD
	bsf TRISJ, 0, A		; set RJ0 to input
	
	goto	start
	
start:
    ; Set LCD cursor to line 1, position 0 
    movlw   0x80            ; line 1, position 0 (0x80 = DDRAM address 0x00)
    call    LCD_Send_Byte_I ; send as instruction
    movlw   10
    call    LCD_delay_x4us  ; wait for LCD to process
    
wait_for_keypad:
	call	KeyPad_read	; scan keypad, ASCII in W (0 if none)
	bz	wait_for_keypad	; no key pressed, keep scanning

	; W now holds the ASCII character of the pressed key
	call	LCD_Send_Byte_D	; display key character on LCD

	movlw	10
	call	LCD_delay_x4us	; small delay for LCD

wait_for_release:
	call	KeyPad_read	; keep scanning
	bnz	wait_for_release	; key still held, wait

	bra	wait_for_keypad	; key released, go scan again

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst
