; programa de teste
#include<p16f873.inc> ; define o pic a utilizar
	
	; 0X20 é o inicio da memoria usavel nos dados (MD)
	CBLOCK 0X20
		; variavies
		aux
		cont
	ENDC
	
	; indica ao compilador para iniciar para iniciar nesse endereco ( 0 )
	ORG 0 ; o proximo codigo objeto estara no endereco 0 no Prog. Objeto
	NOP ; end. 0
	NOP ; end. 1
	; { ... }
	NOP
	
END
