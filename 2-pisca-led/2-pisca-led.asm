; programa de teste
#include<p16f873.inc> ; define o pic a utilizar
	ORG 0
	GOTO	inicio
	; interrupcoes
	ORG		4
	RETFIE ; retorno de interrupcao
	
inicio:
	
	; seleciona o banco de memória 1
	BSF		STATUS,	RP0
	; ou
	BANKSEL	TRISB ; MACRO que automaticamte seleciona o banco certo
	
	; configura a porta B , RB5 = output
	MOVLW	B'11010000' ; 1 = input, 0 = output
	MOVWF	TRISB
	
	; seleciona o banco de memória 0
	BCF		STATUS,	RP0
	
loop:
	; liga o LED
	BSF		PORTB,	RB5 ; liga o bit RB5 da porta B que tem um LED
	
	; delay
	NOP
	NOP
	NOP
	
	; desliga o LED
	BCF		PORTB,	RB5
	
	; delay
	NOP
	NOP
	NOP
	
	; volta o começo para acender o led denovo
	GOTO loop
	
END
