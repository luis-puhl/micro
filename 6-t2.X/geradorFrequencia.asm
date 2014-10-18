#include<p16f873a.inc> ; define o pic a utilizar
;       #define	DEBUG
;#define	DEBUG_DELAY
;#define	USE_MINILOOP

	__config _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _DEBUG_OFF & _WRT_OFF

	; 0X20 é o inicio da memoria usavel nos dados (MD)
	CBLOCK 0x20
		; variavies
		aux
		portb_mirror
		; fucoes de serial
		byte_recebido_serial
		byte_enviar_serial
		; funcao delay
		count_l
		count_h
		count_uh
		; funcao pulso
		th
		tl
		th_thresh_hold
		mini_loop
		mini_loop_lenth
		; troca entre th e tl
		counter
		port_b_high_value
		port_b_low_value
		; setup do timer
		TMR0_mirror
	ENDC

	ORG 0
	GOTO	start				   ; go to beginning of program
	ORG	 4
		; INTERRUPCOES :
		; timer
		BANKSEL	INTCON
		BTFSS	INTCON,	T0IF
		GOTO	end_int

		; prepara o timer para a proxima chamada
		;CALL	inicia_timer
;inicia_timer:
		; RECONFIGURA O TMR0
		MOVF	TMR0_mirror, 0
		BANKSEL TMR0
		MOVWF   TMR0

		; DISPARA O TIMER
		BANKSEL INTCON
		BSF	INTCON, T0IE
		; LIMPA AS INTERRUPÇOES
		BCF	INTCON, T0IF

		; BANKSEL 0
		BCF	STATUS, RP0
		BCF	STATUS, RP1
	;RETURN

		
		;BANKSEL	0
		BCF		STATUS,		RP0
		BCF		STATUS,		RP1

		#ifdef DEBUG_DELAY
			MOVLW	0x02
			CALL	delay
		#endif

		#ifdef	USE_MINILOOP
			; se o mini_loop não é zero, finaliza a interrupção
			DECFSZ	mini_loop,	1
				GOTO	end_int
			; reinicia o mini_loop
			MOVF	mini_loop_lenth, 0
			MOVWF	mini_loop
		#endif
		
		MOVF	counter,	0
		#ifdef DEBUG
			CALL	envia_w_serial
		#endif
		DECFSZ	counter,	1
			GOTO	end_int

		BANKSEL	PORTB
		MOVF	PORTB				,0

		;CALL	espera_valor ; espera valor não é preeptivo
espera_valor_int:
		; espera os dados da serial
		MOVF	th, 0						; leitura_serial_asinc faz "MOVWF byte_recebido" caso nao receba nada
		CALL	leitura_serial_asinc
		MOVF	byte_recebido_serial, 0

calcula_valor_int:
		; pega valor de w e testa ele para ser o novo th
		; menor que 78, espera outro
		SUBLW	D'77'
		BTFSC	STATUS, C
			GOTO	aritimetica

		; maior que 124, espera outro
		MOVF	aux, w
		SUBLW	D'124'
		BTFSS	STATUS, C
			GOTO	aritimetica

		; TH = valorRecebido
		; aux = valorRecebido
		MOVF	byte_recebido_serial, 0
		MOVWF	aux
		MOVWF	th
aritimetica_int:
		; faz aritimética
		; 4) Então calcule TL =125-TH

		MOVF	th , 0
		SUBWF	th_thresh_hold,	0	; W= 125-TH
		MOVWF	tl					; TL = W (125-TH)

		; envia th e tl calculados
		#ifdef DEBUG
			MOVLW	0x54	; ascii T
			CALL envia_w_serial
			MOVLW	0x48	; ascii H
			CALL envia_w_serial
			MOVLW	0x00
			CALL envia_w_serial
			MOVF	th, 0
			CALL envia_w_serial

			MOVLW	0x54	; ascii T
			CALL envia_w_serial
			MOVLW	0x4C	; ascii L
			CALL envia_w_serial
			MOVLW	0x00
			CALL envia_w_serial
			MOVF	tl, 0
			CALL envia_w_serial

			MOVLW	0x00
			CALL envia_w_serial
		#endif

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

		GOTO	end_int
fase_baixa:
		; reinicia o contador de acordo com a fase
		MOVF	tl, W
		MOVWF	counter

		; configura a saida de acordo com a fase
		MOVF	port_b_low_value, 0
		MOVWF	PORTB

end_int:
	RETFIE

start:
	; inicializa as variaveis

	; counter não deve ser iniciado com zero
	MOVLW	0x01
	MOVWF	counter

	; configura todas as portas RB para output para incicializar PORTB
	MOVLW	0x00
	BANKSEL	TRISB
	MOVWF	TRISB

	MOVLW	0xFF
	BANKSEL	PORTB
	MOVWF	PORTB

	; inicia th e tl com 100
	; apenas th é nessesário mas iniciar todas as variaveis é bom
	MOVLW	d'100'
	MOVWF	th
	MOVWF	tl

	MOVLW	0xFF
	MOVWF	port_b_high_value
	MOVLW	0x00
	MOVWF	port_b_low_value

	MOVLW	d'125'
	MOVWF	th_thresh_hold

	MOVLW	D'100'
	MOVWF	mini_loop_lenth
	MOVWF	mini_loop
	
	; outras configuracoes
	CALL	configura_serial
	CALL	configura_timer

	#ifdef	DEBUG
		MOVLW	0xFF
		CALL	envia_w_serial
		MOVLW	0x00
		CALL	envia_w_serial
	#endif
	
	; o primeiro valor de th deve ser recebido pela serial sincronamente
	; ou seja, a execução é parada até receber algo pela serial
	; os demais são assincronos
	CALL	leitura_serial
	MOVF	byte_recebido_serial, 0
	CALL	calcula_valor

	; inicia o timer
	CALL	inicia_timer

	; fim da rotina principal
	GOTO	$ ;security hold state loop

espera_valor:
		; espera os dados da serial
		MOVF	th, 0						; leitura_serial_asinc faz "MOVWF byte_recebido" caso nao receba nada
		CALL	leitura_serial_asinc
		MOVF	byte_recebido_serial, 0

calcula_valor:
		; pega valor de w e testa ele para ser o novo th
		; menor que 78, espera outro
		SUBLW	D'77'
		BTFSC	STATUS, C
			GOTO	aritimetica

		; maior que 124, espera outro
		MOVF	aux, w
		SUBLW	D'124'
		BTFSS	STATUS, C
			GOTO	aritimetica

		; TH = valorRecebido
		; aux = valorRecebido
		MOVF	byte_recebido_serial, 0
		MOVWF	aux
		MOVWF	th
aritimetica:
		; faz aritimética
		; 4) Então calcule TL =125-TH

		MOVF	th , 0
		SUBWF	th_thresh_hold,	0	; W= 125-TH
		MOVWF	tl					; TL = W (125-TH)

		; envia th e tl calculados
		#ifdef DEBUG
			MOVLW	0x54	; ascii T
			CALL envia_w_serial
			MOVLW	0x48	; ascii H
			CALL envia_w_serial
			MOVLW	0x00
			CALL envia_w_serial
			MOVF	th, 0
			CALL envia_w_serial

			MOVLW	0x54	; ascii T
			CALL envia_w_serial
			MOVLW	0x4C	; ascii L
			CALL envia_w_serial
			MOVLW	0x00
			CALL envia_w_serial
			MOVF	tl, 0
			CALL envia_w_serial

			MOVLW	0x00
			CALL envia_w_serial
		#endif
	RETURN

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

		;BANKSEL	0
		BCF		STATUS,		RP0
		BCF		STATUS,		RP1
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
		;BANKSEL	0
		BCF		STATUS,		RP0
		BCF		STATUS,		RP1
		MOVWF	byte_recebido_serial
	RETURN

leitura_serial_asinc:
		BANKSEL PIR1
		; registrador PIR1 contem as flags individuais de cada uma das
		; interrupcoes perifericas
		; bit RCIF indica se o buffer de entrada esta cheio
		; (entrada serial)
		BTFSS   PIR1,   RCIF			; se bit RCIF do registrador PIR1
										; ou seja, se tem coisa a ler
			GOTO	end_leitura_serial_asinc
		BANKSEL RCREG
		MOVF	RCREG, W				; chegou byte
		;BANKSEL	byte_recebido_serial
end_leitura_serial_asinc:
		BCF		STATUS,		RP0
		BCF		STATUS,		RP1
		MOVWF	byte_recebido_serial
	RETURN

envia_w_serial:
		BCF		STATUS,	RP0
		BCF		STATUS,	RP1
		MOVWF	byte_enviar_serial	; guarda w em byte_enviar_serial
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
; ------------------------------ SECAO TIMER -----------------------------
configura_timer:
		; T = 1ms

		; Fint = 1000 Hz
		; Prescaler = 2:1 (000)
		; TRM0 = 131157

		; Fint = 100 Hz
		; Prescaler = 16:1 (011)
		; TRM0 = 100

		; Fint = 10 Hz
		; Prescaler = 256:1 (111)
		; TRM0 = 158

		; ATIVA O TIMER
		; OPTION_REG: control bits to configure
		;	the TMR0 prescaler/WDT postscaler (single assign-
		;	able register known also as the prescaler), the External
		;	INT Interrupt, TMR0 and the weak pull-ups on PORTB.
		;	(ADDRESS 81h, 181h)
		;
		; RBPU: PORTB Pull-up Enable bit		= 0 (PORTB pull-ups are enabled by individual port latch values)
		; INTEDG: Interrupt Edge Select bit		= 0 (Interrupt on falling edge of RB0/INT pin)
		; T0CS: TMR0 Clock Source Select bit	= 0 (Internal instruction cycle clock CLKOUT)
		; T0SE: TMR0 Source Edge Select bit		= 0 (assincrono)
		; PSA: Prescaler Assignment bit			= 0 (Prescaler is assigned to the Timer0 module)
		; PS2:PS0: Prescaler Rate Select bits	= (1:2)
		; PS2									= 0
		; PS1									= 0
		; PS0									= 0
		BANKSEL OPTION_REG
		MOVLW   B'00000010'
		MOVWF   OPTION_REG

		; FREQUENCIA DE INTERRUPÇAO DO TIMER
		; (1MHz/4)/64[prescaler]
		; -----------------------
		;		(256 - TMR0)
		BANKSEL TMR0
		MOVLW   D'131'
		MOVWF   TMR0

		; BANKSEL 0
		BCF	STATUS, RP0
		BCF	STATUS, RP1
		MOVWF	TMR0_mirror

		; CONFIGURA A INTERRUPÇÃO
		; INTCON: (ADDRESS 0Bh, 8Bh, 10Bh, 18Bh)
		;	enable and flag bits for the
		;	TMR0 register overflow, RB Port change and External
		;	RB0/INT pin interrupts.
		;	NÃO ATIVO A INTERRUPCAO AINDA
		; GIE: Global Interrupt Enable bit				= 1 (Enables all unmasked interrupts)
		; PEIE: Peripheral Interrupt Enable bit			= x
		; T0IE: TMR0 Overflow Interrupt Enable bit		= 1 (Enables the TMR0 interrupt)
		; INTE: RB0/INT External Interrupt Enable bit	= x
		; RBIE: RB Port Change Interrupt Enable bit		= x
		; T0IF: TMR0 Overflow Interrupt Flag bit		= 0
		; INTF: RB0/INT External Interrupt Flag bit		= x (The RB0/INT external interrupt did not occur)
		; RBIF: RB Port Change Interrupt Flag bit		= x (None of the RB7:RB4 pins have changed state)
		; INTCON = 1010 0000
		BANKSEL INTCON
		MOVLW   B'10000000'
		MOVWF   INTCON

		; BANKSEL 0
		BCF	STATUS, RP0
		BCF	STATUS, RP1
	RETURN
inicia_timer:
		; RECONFIGURA O TMR0
		MOVF	TMR0_mirror, 0
		BANKSEL TMR0
		MOVWF   TMR0
		
		; DISPARA O TIMER
		BANKSEL INTCON
		BSF	INTCON, T0IE
		; LIMPA AS INTERRUPÇOES
		BCF	INTCON, T0IF

		; BANKSEL 0
		BCF	STATUS, RP0
		BCF	STATUS, RP1
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
