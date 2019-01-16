#include "protheus.ch"
#include "topconn.ch"
#include "rwmake.ch"


/*/{Protheus.doc} MI11TO12
// Função de que auxilia a migração de versão P11 para P12
@author danielflavio
@since 15/01/2019
@version 1.0
@type user function
/*/
User Function MI11TO12()
	Local lXContinua	:= .F.
	Local lPar			:= .F.
	Local oWnd			:= NIL
	Local aSays			:= {}
	Local aButtons		:= {}
	Local cNomeArq		:= Lower(Alltrim(FunName()))
	Local cXExtensao	:= ".txt"
	Local nXOpc			:= 0
	Local aPar			:= {}
	Local aRet			:= {}
	Private lXBackup	:= .F.	
	Private cXRotina	:= "SUA_EMPRESA | Migrador V1.0"	
	
	// Ajusta parâmetros
	aAdd(aPar,{2,"Fazer backup das tabelas" ,"1",{"1-Sim","2-Não"}, 50,".T." , .T.})
	
	// Cria tela para confirmar processamento
	AADD(aSays,OemToAnsi( "Processo para ajustar as tabelas da base de dados para migração de versão." ) )
	AADD(aSays,OemToAnsi( " " ) )
	AADD(aSays,OemToAnsi( "Salve o arquivo "+cNomeArq+cXExtensao+" com o nome das tabelas na pasta " ) )
	AADD(aSays,OemToAnsi( "MIGRACAO dentro do PROTHEUS_DATA." ) )
	AADD(aSays,OemToAnsi( "Informe apenas uma tabela por linha. " ) )
	AADD(aSays,OemToAnsi( "Exemplo: SA1 " ) )
	AADD(aSays,OemToAnsi( " " ) )	
	AADD(aSays,OemToAnsi( " " ) )
	AADD(aSays,OemToAnsi( "Deseja continuar o processamento?" ) )
	aAdd(aButtons, {05, .T.,{|| (lPar := paramBox(aPar,cXRotina,@aRet)) } })		// Parametros	
	AADD(aButtons, {01, .T.,{|o| lXContinua := .T., o:oWnd:End() } } )
	AADD(aButtons, {02, .T.,{|o| o:oWnd:End() }} )
	
	FormBatch(cXRotina, aSays, aButtons)

	// Verificar se Parametros foram preenchidos
	If !lPar

		If lXContinua
			Alert("Os parâmetros da não foram preenchidos corretamente, verifique os parâmetros antes do processamento.")
		EndIf
		
		lXContinua := .F.

	EndIf
	
	// Continua execução da rotina
	If lXContinua
	
		// Ajusta variável de backup
		If SubStr(cValToChar(MV_PAR01),1,1) == "1"
			lXBackup := .T.
		EndIf
	
		nXOpc := Aviso(cXRotina,"Tendo como referência a rotina MP710TO120, informe em que momento você está executando a rotina atual ["+cXRotina+"]",{"DEPOIS","ANTES"},2)
		
		If nXOpc = 2
		
			If MsgYesNo("Executando rotina no modo PRÉ-MIGRAÇÃO, deseja continuar?")
				fMI11TO12('PRE')
			EndIf
		
		ElseIf nXOpc = 1

			If MsgYesNo("Executando rotina no modo PÓS-MIGRAÇÃO, deseja continuar?")
				fMI11TO12('POS')
			EndIf
		
		EndIf
	
	EndIf
	
Return


/*/{Protheus.doc} fMI11TO12
// Função auxiliar
@author danielflavio
@since 14/01/2019
@version 1.0
@param cXModo, characters, Modo da Função
@type static function
/*/
Static Function fMI11TO12(cXModo)
	Local cNomeArq		:= Lower(Alltrim(FunName()))
	Local cXExtensao	:= ".txt"
	Local cXPath		:= "migracao"
	Local cFile			:= ""
	Local cXTab			:= ""
	Local cXTabela		:= ""	
	Local cXError		:= ""
	Local lXContinua	:= .F.
	Local oXFile		:= NIL
	Local aXAux			:= {}
	Local aXAux2		:= {}
	Local lRet			:= .T.
	Local nA			:= 0
	Local xAuxValOld	:= NIL
	Local xAuxValNew	:= NIL
	Default cXModo		:= "XXX"

	// Ajuste de variáveis
	If cXModo == "PRE"
	
		cFile := cXPath+"\"+cNomeArq+cXExtensao
		
	Else
	
		MsgStop("Opção ["+cXModo+"] ainda não implantada.")
		Return(.F.)
		
	EndIf
	
	cFile := Alltrim(cFile)
	oXFile := FWFileReader():New(cFile)
	
	If (oXFile:Open())
	
		aXAux := oXFile:getAllLines()

		// Verifica conteúdo do arquivo
		If Empty(aXAux)
			MsgStop('Arquivo vazio.')
			Return(.F.)
		EndIf
		
		// Percorre array de acordo com as tabelas passadas no arquivo .txt
		If cXModo == "PRE" 
		
			// Primeiramente executa as instruções diretamente na base
			// Baseado na verificação da rotina CheckDupl
			If fSql11To12(@cXError)
				
				// Cria uma nova conexão com um banco de dados SGBD através do DBAccess
				TcLink()
				
				For nA := 1 to Len(aXAux)
					
					// Captura nome da tabela
					cXTabela := Iif((Len(Alltrim(aXAux[nA])) = 3),Upper(Alltrim(aXAux[nA])+cEmpAnt+"0"),Upper(Alltrim(SubStr(aXAux[nA]+Space(6),1,6))))
					cXTab	:= SubStr(cXTabela+Space(3),1,3)
					
					// Verificas se será verificada uma tabela padrão ou estrutura de dados
					If At(";",aXAux[nA]) = 0 
					
						// Verifica se tabela existe
						If !Empty(cXTab) .AND. TCCanOpen(cXTabela)
						
							/*
								Backup e Drop de Tabelas
								Exemplo Arquivo:
								
								SA1
								SE1
								SA2
							*/							
						
							// Verifica se a tabela está em modo exclusivo
							If ChkFile(cXTab,.T.)
							 
							 	// Verifica se a tabela possui registros
								If (cXTab)->(RecCount()) > 0
								
									// Realiza backup da tabela
									If lXBackup
										FWMsgRun(, {|| lXContinua := fBkp11To12(cXTab,cXTabela) }, cXRotina, "Realizando backup da tabela "+cXTab)
									Else
										lXContinua := .T.
									EndIf
								
									If lXContinua
									
										// Drop de tabela
										If Select(cXTab) > 0
											(cXTab)->(dbCloseArea())
										EndIf
										
										If !TcDelFile(cXTabela)
											cXError := "Falha ao apagar "+cXTab+" : "+ TcSqlError()
											Exit
										EndIf					 		
									
									Else
									
										cXError := "Falha ao tentar realizar o backup da tabela "+cXTab
										Exit	
														 		
									EndIf
								
								Else
								
									// Drop de tabela
									If Select(cXTab) > 0
										(cXTab)->(dbCloseArea())
									EndIf
									
									If !TcDelFile(cXTabela)
										cXError := "Falha ao apagar "+cXTab+" : "+ TcSqlError()
									 	Exit
									EndIf
									 		
								EndIf
								 
							Else
								
								cXError := "Reserva de exclusividade na tabela ["+cXTab+"]"
								Exit
								
							EndIf
						
						EndIf
							
					Else
						
						/*
							Ajuste de Estrutura de dados
							Exemplo Arquivo:
							SX3;2;AA1_FONE;X3_TAMANHO;8;10
							
							Estrutura Array
							1 - Tabela
							2 - Índice (Numérico)
							3 - Campo Índice
							4 - Campo que Será alterado
							5 - De
							6 - Para
						*/						
					
						aXAux2 := StrTokArr(aXAux[nA],";")

						// Índice - Função para verificar se a string é numérica
						If !Empty(aXAux2) .AND. IsDigit(aXAux2[2])
						
							DbSelectArea(cXTab)
							DbSetOrder(Val(aXAux2[2]))
							
							If (cXTab)->(DbSeek(aXAux2[3]))
							
								xAuxValOld := NIL
								xAuxValNew := NIL
								
								// Tratamento dos dados
								If ValType((cXTab)->&(aXAux2[4])) == "N"
									xAuxValOld := Val(aXAux2[5])
									xAuxValNew := Val(aXAux2[6]) 
								ElseIf ValType((cXTab)->&(aXAux2[4])) == "D"
									xAuxValOld := StoD(aXAux2[5])
									xAuxValNew := StoD(aXAux2[6]) 								
								EndIf
								
								// Comparação da estrutura
								If Alltrim(cValToChar((cXTab)->&(aXAux2[4]))) == Alltrim(cValToChar(xAuxValOld)) 
								
									RecLock(cXTab,.F.)
										(cXTab)->&(aXAux2[4]) := xAuxValNew
									(cXTab)->(msUnLock())
									
								EndIf
								
							Else
								
								cXError := "Não foi possível atualizar a estrutura de dados. ["+cXTab+"/"+aXAux2[3]+"]"+CRLF
								
							EndIf				
						
						EndIf							
					
					EndIf						
				
				Next
			
			EndIf
			
			// Se existir erro exibe a mensagem
			If !Empty(cXError)
				MsgStop(cXError)
			Else
				MsgInfo("Ajuste de base concluído com sucesso"+CRLF+CRLF+"Favor executar a rotina MP710TO120",cXRotina)
			EndIf
			
		EndIf
	
	Else
	
		MsgStop("Não foi possível abrir o arquivo. ["+Alltrim(Lower(cFile))+"]")
	
	EndIf	

Return lRet


/*/{Protheus.doc} fBkp11To12
// Função que realiza backup de determinada tabela
@author danielflavio
@since 14/01/2019
@version 1.0
@return lRet, Backup realizado com sucess ou não
@param cXTab, characters, descricao
@type static function
/*/
Static Function fBkp11To12(cXTab,cXTabela)
	Local aXArea	:= GetArea()
	Local cXPath	:= "migracao"
	Local cXDirBkp	:= cXPath+"\backup\"
	Local cXNomeArq	:= Lower(cXTabela)
	Local cXWay		:= cXDirBkp+cXNomeArq
	Local aStruct	:= {}
	Local lRet		:= .T.
	
	dbSelectArea(cXTab)
	aStruct := (cXTab)->(dbStruct())
	dbCreate( cXWay, aStruct, "DBFCDXADS" )

	dbSelectArea(cXTab)
	COPY TO &cXWay VIA "DBFCDXADS"

	RestArea(aXArea)
Return lRet


/*/{Protheus.doc} fSql11To12
// Função para executar updates diretamente na base
@author danielflavio
@since 14/01/2019
@version 1.0
@return .T., Allways True
@param cXError, characters, descricao
@type function
/*/
Static Function fSql11To12(cXError)
	Local aXArea 	:= GetArea()
	Local cQuery	:= ""
	
	// Insira aqui os updates que devem ser executados diretamente
	
	// Exemplo: Limpando registros vazios na ALI010
	If TCCanOpen(RetSqlName("ALI"))
	
		cQuery := "UPDATE "+RetSqlName('ALI')+" SET D_E_L_E_T_='*' WHERE D_E_L_E_T_=' ' AND ALI_FILIAL=' '"
		
		If TcSqlExec(cQuery) < 0
			cXError := "Erro na execução da query "+CRLF+cQuery
			Return(.F.)
		EndIf
		
	EndIf
	RestArea(aXArea)
	
Return(.T.)
