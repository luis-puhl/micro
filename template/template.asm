#include<p16f873.inc> ; define o pic a utilizar
	__config _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _DEBUG_OFF & _WRT_OFF

	#define	var		0x20
	#define DEBUG					0x1

	ORG 0
	GOTO	start				   ; go to beginning of program
	ORG	 4
	;
	RETFIE

start:
	
	GOTO	$				  ; loop forever


	END
