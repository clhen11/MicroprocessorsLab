#include <xc.inc>

global	Mul_16x16   
global ARG1L, ARG1H, ARG2L, ARG2H
global RES0, RES1, RES2, RES3
global  ARG8, ARG24L, ARG24U, ARG24H
global  RES32_0, RES32_1, RES32_2, RES32_3

psect   udata_acs
; Inputs (16-bit): ARG1H:ARG1L, ARG2H:ARG2L
ARG1L:      ds 1
ARG1H:      ds 1
ARG2L:      ds 1
ARG2H:      ds 1

; Outputs (32-bit): RES3:RES2:RES1:RES0 (RES3 = MSB)
RES0:       ds 1
RES1:       ds 1
RES2:       ds 1
RES3:       ds 1	

; 8-bit input
ARG8:       ds 1

; 24-bit input (LSB ? MSB)
ARG24L:     ds 1
ARG24U:     ds 1
ARG24H:     ds 1

; 32-bit result (LSB ? MSB)
RES32_0:    ds 1   ; least significant byte
RES32_1:    ds 1
RES32_2:    ds 1
RES32_3:    ds 1   ; most significant byte
    
psect	mul_code, class=CODE

org 0x0
goto all_tests  

Mul_16x16:   
    MOVF    ARG1L, W
    MULWF   ARG2L ; ARG1L * ARG2L-> PRODH:PRODL
    MOVFF   PRODH, RES1 
    MOVFF   PRODL, RES0 
    
    MOVF    ARG1H, W
    MULWF   ARG2H ; ARG1H * ARG2H->  PRODH:PRODL
    MOVFF   PRODH, RES3 
    MOVFF   PRODL, RES2 
    
    MOVF    ARG1L, W
    MULWF   ARG2H ; ARG1L * ARG2H-> PRODH:PRODL
    MOVF    PRODL, W 
    ADDWF   RES1, F ; Add cross
    MOVF    PRODH, W ; products
    ADDWFC  RES2, F 
    CLRF    WREG 
    ADDWFC  RES3, F 
    
    MOVF    ARG1H, W 
    MULWF   ARG2L ; ARG1H * ARG2L-> PRODH:PRODL
    MOVF    PRODL, W 
    ADDWF   RES1, F ; Add cross
    MOVF    PRODH, W ; products
    ADDWFC  RES2, F 
    CLRF    WREG 
    ADDWFC  RES3, F 
    
    return
    
mul_8x24:
    
    MOVF    ARG8, W
    MULWF   ARG24L
    MOVFF   PRODL, RES32_0
    MOVFF   PRODH, RES32_1

    MOVF    ARG8, W
    MULWF   ARG24U
    MOVF    PRODL, W
    ADDWF   RES32_1, F

    MOVF    PRODH, W
    ADDWFC  RES32_2, F
    CLRF    WREG
    ADDWFC  RES32_3, F

    MOVF    ARG8, W
    MULWF   ARG24H
    MOVF    PRODL, W
    ADDWF   RES32_2, F
    MOVF    PRODH, W
    ADDWFC  RES32_3, F

    return
    
    
    
    
    
all_tests:
    
test_mul_16x16:
    movlw   0xFF        ; ARG1L = 0xFF
    movwf   ARG1L, A
    movlw   0xBD        ; ARG1H = 0xBD
    movwf   ARG1H, A

    movlw   0x34        ; ARG2L = 0x34
    movwf   ARG2L, A
    movlw   0x12        ; ARG2H = 0x12
    movwf   ARG2H, A

    call    Mul_16x16
    
test_mul_8x24:
    
    
    movlw   0xAE        ; ARG8 = 0xAE
    movwf   ARG8, A

    movlw   0x56        ; ARG24L = 0x56
    movwf   ARG24L, A
    movlw   0x34        ; ARG24U = 0x34
    movwf   ARG24U, A
    movlw   0x12        ; ARG24H = 0x12
    movwf   ARG24H, A
    
    call    mul_8x24
    
goto    0x0


end