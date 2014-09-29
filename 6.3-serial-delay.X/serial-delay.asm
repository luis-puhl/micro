#include<p16f873.inc> ; define o pic a utilizar
	__config _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _DEBUG_OFF & _WRT_OFF

	; 0X20 é o inicio da memoria usavel nos dados (MD)
	CBLOCK 0X20
		; variavies
		aux
		; fucoes de serial
		byte_recebido_serial
		byte_enviar_serial
		; funcao delay
		count_l
		count_h
		count_uh
	ENDC

	ORG 0
	GOTO	start				   ; go to beginning of program
	ORG	 4
	RETFIE

start:
	; inicializa as variaveis
	MOVLW	0x00
	MOVWF	aux
	MOVWF	byte_recebido_serial
	MOVWF	byte_enviar_serial
	MOVWF	count_l
	MOVWF	count_h
	MOVWF	count_uh

	; outras configuracoes
	CALL	configura_serial

espera_valor:
	MOVLW	0x10
	;MOVWF	byte_enviar_serial
	;CALL	escrita_serial

	CALL	leitura_serial
	MOVF	byte_recebido_serial, 0
	MOVWF	aux

	CALL	delay

	MOVF	aux, 0
	MOVWF	byte_enviar_serial
	CALL	escrita_serial

	GOTO	espera_valor

	GOTO	$ ;security hold state loop

; ------------------------------ SECAO SERIAL -----------------------------
configura_serial:
		; TXSTA: TRANSMIT STATUS AND CONTROL REGISTER (ADDRESS 98h)
		; CSRC: Clock Source Select bit		= 0 (assincrono)
		; TX9: 9-bit Transmit Enable bit	= 0 (sem 9º bit)
		; TXEN: Transmit Enable bit			= 1 (liga o tx)
		; SYNC: USART Mode Select bit		= 0 (assincrono)
		; U-0 :								= 0	(n/a)
		; BRGH: High Baud Rate Select bit	= 1 (High speed)
		; TRMT: Transmit Status bit			= 0 (read-only)
		; TX9D: 9th bit						= 0 (n/a)
		; TXSTA = 0010 0100
		BANKSEL TXSTA
		MOVLW   B'00100100'
		MOVWF   TXSTA

		; RCSTA: RECEIVE STATUS AND CONTROL REGISTER (ADDRESS 18h)
		; SPEN: Serial Port Enable bit			= 1 (enable)
		; RX9: 9-bit Receive Enable bit			= 0 (sem 9º bit)
		; SREN: Single Receive Enable bit		= 0 (N/A)
		; CREN: Continuous Receive Enable bit	= 1 (continuous receive)
		; ADDEN: Address Detect Enable bit		= 0 (N/A)
		; FERR: Framing Error bit				= 0 (read-only)
		; OERR: Overrun Error bit				= 0 (read-only)
		; RX9D: 9th bit of Received Data		= 0 (read-only)
		; RCSTA = 1001 0000
		BANKSEL RCSTA
		MOVLW   B'10010000'
		MOVWF   RCSTA

		; SPBRG = 25
		; calculado para 9600 bps
		BANKSEL SPBRG
		MOVLW   D'25'
		MOVWF   SPBRG
	RETURN
leitura_serial:
		BANKSEL PIR1
		; registrador PIR1 contem as flags individuais de cada uma das
		; interrupcoes perifericas
		; bit RCIF indica se o buffer de entrada esta cheio
		; (entrada serial)
espera_leitura_serial:
		BTFSS   PIR1,   RCIF			; se bit RCIF do registrador PIR1
										; ou seja, se tem coisa a ler
		GOTO	espera_leitura_serial	; nao chegou byte
		BANKSEL RCREG
		MOVF	RCREG, W				; chegou byte
		;BANKSEL	byte_recebido_serial
		BCF		STATUS,		RP0
		BCF		STATUS,		RP1
		MOVWF	byte_recebido_serial
	RETURN
escrita_serial:
		; TXSTA:	transmit status and control register
		; TRMT:	 bit de buffer de escrita cheio
		BANKSEL TXSTA
		; caso ainda nao tenha enviado o que esta no buffer
		; espera o envio (anterior)
espera_escrita_serial:
		;TRMT: Transmit Shift Register Status bit
		;1 = TSR empty
		;0 = TSR full
		BTFSS   TXSTA, TRMT				; TRMT == 1? ;
		GOTO	espera_escrita_serial   ; buffer cheio, espere
		;BANKSEL	byte_enviar_serial
		BCF		STATUS,	RP0
		BCF		STATUS,	RP1
		MOVF	byte_enviar_serial,	W	; pega a variavel
		BANKSEL TXREG
		MOVWF   TXREG					; escreve a variavel para o buffer
	RETURN

; -------------------------------- delay ----------------------------------------
delay:
		MOVWF	count_uh
delay_loop_uh:
		MOVLW	0xff
		MOVWF	count_h
delay_loop_h:
		MOVLW	0xff
		MOVWF	count_l
delay_loop_l:
		DECFSZ	count_l
		GOTO	delay_loop_l
		DECFSZ	count_h
		GOTO	delay_loop_h
		DECFSZ	count_uh
		GOTO	delay_loop_uh
	RETURN

	GOTO	$	; security loop forever
	END
