#include "protheus.ch"
#include "rwmake.ch" 

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ FTEMACESSO º Autor ³ Daniel Flavio º Data ³  25/09/13      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Função utilizada para verificar se o código usuário do usu-º±±
±±º          ³ ário está contido em determinado parâmetro		  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±± 
±±º Param.   ³ Param 1: Parâmetro (String)                                º±±
±±º          ³ Param 2: Mostra aviso (Booleano)                           º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Diversos - CDA 						  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
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
