; programa de teste
#include<p16f873.inc> ; define o pic a utilizar

	; 0X20 é o inicio da memoria usavel nos dados (MD)
	CBLOCK 0X20
		; variavies
		th
		tl
		counter
		port_b_high_value
		port_b_low_value
	ENDC

	; indica ao compilador para iniciar para iniciar nesse endereco ( 0 )
	ORG 0 ; o proximo codigo objeto estara no endereco 0 no Prog. Objeto
	GOTO	start	; go to beginning of program

	; endereco de interrupçoes
	ORG	 4
	;
	RETFIE

start:
	MOVLW	0x01
	MOVWF	counter

	MOVLW	0x00
	BANKSEL	TRISB
	MOVWF	TRISB
	BANKSEL	PORTB
	MOVWF	PORTB

	MOVLW	0x5
	MOVWF	th
	MOVWF	tl

	MOVLW	0xFF
	MOVWF	port_b_high_value
	MOVLW	0x00
	MOVWF	port_b_low_value

; ------------------------------ SECAO PULSOS -----------------------------
pulsos_4:
	DECFSZ	counter,	1
		GOTO pulsos_4_end

	; encotra a fase atual
	MOVF	port_b_low_value,	0	; W = low_value
	SUBWF	PORTB,				0	; W = W - PORTB
	BTFSC	STATUS,				Z	; if PORTB == low_value (Z is SET ?)
		GOTO	fase_alta			; TRUE era BAIXO e agora deve ser ALTO
	GOTO	fase_baixa				; FALSE era ALTO e agora deve ser BAIXO
	
fase_alta:
	; reinicia o contador de acordo com a fase
	MOVF	th, W
	MOVWF	counter

	; configura a saida de acordo com a fase
	MOVF	port_b_high_value, 0
	MOVWF	PORTB

	GOTO pulsos_4_end
fase_baixa:
	; reinicia o contador de acordo com a fase
	MOVF	tl, W
	MOVWF	counter

	; configura a saida de acordo com a fase
	MOVF	port_b_low_value, 0
	MOVWF	PORTB
pulsos_4_end:
	GOTO	pulsos_4

	GOTO	$ ; security loop
END
