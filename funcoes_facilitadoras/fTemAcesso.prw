#include "protheus.ch"
#include "rwmake.ch" 

/*/{Protheus.doc} fTemAcesso
//TODO Descrição auto-gerada.
@author Daniel Flávio
@since 25/09/2013
@version 1.0
@param [cXPar], caracter, Parâmetro do Totvs Protheus
@param [lXOpc], lógico, Define se irá mostrar a janela caso usuário não esteja no parâmetro
@return caracter, E-mails separados por ";"
@type function
/*/

User Function fTemAcesso(cXPar,lXOpc)  
	Local aXArea		:= GetArea()
	Local lXContinua	:= .T.
	Local cUsrLogado	:= RetCodUsr()
	Default cXPar		:= ""
	Default lXOpc		:= .T.

	If !Empty(cXPar)
		If GetMv(cXPar,.T.)
			If ValType(GetMv(cXPar))=="C"
				If !cUsrLogado $ GetMv(cXPar)	
					Iif(lXOpc,(MsgStop(Alltrim(UsrRetName(cUsrLogado))+", você não possui permissão para utilizar esta rotina ou acessar este recurso. ["+cXPar+"]","Sem Acesso")),"")
					lXContinua := .F.
				EndIf  
			Else
				Iif(lXOpc,(MsgStop("Tipo de parâmetro informado não pode ser usado na função u_fTemAcesso. Utilize um parâmetro do tipo CARACTER.","Ajuste de Parâmetro")),"")
				lXContinua := .F.		
			EndIf
		Else    
			Iif(lXOpc,(MsgStop("Não foi encontrado o parâmetro que realiza o controle de acesso. ["+cXPar+"]","Criar Parâmetro")),"")
			lXContinua := .F.
		EndIf
	Else
		Iif(lXOpc,(MsgStop("Parâmetro não informado. Ajustar passagem de parâmetros na função FTEMACESSO.","Ajuste de Parâmetro")),"")
		lXContinua := .F.
	EndIf

	RestArea(aXArea)
Return(lXContinua) 
