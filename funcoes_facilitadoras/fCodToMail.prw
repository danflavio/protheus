#include "protheus.ch"
#include "rwmake.ch"

/*/{Protheus.doc} fCodToMail
//TODO Descrição auto-gerada.
@author Daniel Flávio
@since 28/06/2018
@version 1.0

@param [cXMail], caracter, Código de Usuário do Sistema Totvs Protheus ou e-mail
@param [lBackEmpty], lógico, Define se irá retornar vazio caso não encontre um e-mail válido

@return caracter, E-mails separados por ";"

@type function
/*/

User Function fCodToMail(cXMail,lBackEmpty)
	Local aXArea 	:= GetArea()
	Local aXAux		:= {}
	Local cXRet	 	:= ''
	Local nXPos	 	:= 1
	Local nXPos2	:= 0
	Local nXPos3	:= 0
	Local nXPos4	:= 0
	Local cXAux	 	:= ''
	Default lBackEmpty := .T.

	// Ajusta variável
	cXMail := Alltrim(cXMail)
	
	// Validação inicial da string procurando os caracteres de separação
	While SubStr(cXMail,1,1) $ "/|;" .AND. Len(cXMail) > 1
		cXMail := SubStr(cXMail,2)
	EndDo
	
	// Verifica se é e-mail
	If !Empty(cXMail) .AND. ((";" $ cXMail) .OR. ("/" $ cXMail) .OR. ("|" $ cXMail)) // Pode possuir mais de um e-mail ou código

		While nXPos < Len(cXMail)
		
			nXPos2 := At(";",cXMail,nXPos)
			nXPos3 := At("/",cXMail,nXPos)
			nXPos4 := At("|",cXMail,nXPos)
			
			Iif(nXPos2 > 0,Aadd(aXAux,nXPos2),'')
			Iif(nXPos3 > 0,Aadd(aXAux,nXPos3),'')
			Iif(nXPos4 > 0,Aadd(aXAux,nXPos4),'')
			
			If Len(aXAux) > 0
				
				aSort(aXAux,,,{|x,y| x < y })
				cXAux := SubStr(cXMail,nXPos,aXAux[1] - 1)
				
				If "@" $ cXAux
					cXRet += cXAux+";"
				ElseIf Len(cXAux) == 6 .And. !IsAlpha(cXAux)
					cXRet += Alltrim(UsrRetMail(cXAux))+";"
				EndIf
				
				nXPos := aXAux[1] + 1
				aXAux := {}
			
			Else

				cXAux := SubStr(cXMail,nXPos)
				
				If "@" $ cXAux
					cXRet += cXAux+";"
				ElseIf Len(cXAux) == 6 .And. !IsAlpha(cXAux)
					cXRet += Alltrim(UsrRetMail(cXAux))+";"
				EndIf
				
				nXPos := Len(cXMail) + 1

			EndIf
		
		EndDo
	
	ElseIf "@" $ cXMail
		cXRet += cXMail+";"
	ElseIf Len(cXMail) == 6 .And. !IsAlpha(cXMail)
		cXRet := Alltrim(UsrRetMail(cXMail))
	Else
		cXRet := ' '
	EndIf
	
	// Caso não possa retornar vazio
	If !lBackEmpty .AND. Empty(Alltrim(cXRet))
		cXRet := SuperGetMv("CDA_MAIL01",.F.,"seuemail@email.com")
	ElseIf !Empty(Alltrim(cXRet))
		If !SubStr(cXRet,Len(cXRet),1) $ ";"
			cXRet += ";"
		EndIf	
	EndIf

	RestArea(aXArea)
Return cXRet