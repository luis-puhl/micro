#include<p16f873.inc> ; define o pic a utilizar
	__config _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _DEBUG_OFF & _WRT_OFF

	#define	var		0x20
	#define DEBUG	0x1
    
    #define	th		0x20

    #define rcreg_l D'77'
	#define rcreg_c1 D'78'
    #define rcreg_c2 D'124'
    #define rcreg_h D'125'

	ORG 0
	GOTO	start	; go to beginning of program
	ORG	 4
	;
	RETFIE

start:
    MOVLW	rcreg_h
    MOVWF	th
    SUBLW	D'77'
	BTFSC	STATUS, C
		GOTO	start
	nop
	MOVF	th, w
	SUBLW	D'124'
	BTFSS	STATUS, C
		GOTO	start
	nop

	MOVLW	0x0
	MOVWF	th

	;GOTO	$		; loop forever

	END
