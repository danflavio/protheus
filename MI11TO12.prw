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
	Private lXAppend	:= .F.
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
Static Function fMI11TO12(cXModo,lXPos)
	Local cNomeArq		:= Lower(Alltrim(FunName()))
	Local cXExtensao	:= ".txt"
	Local cXPath		:= "migracao"
	Local cXPathBkp		:= "/"+cXPath+"/"+"backup/*"
	Local cFile			:= ""
	Local cXTab			:= ""
	Local cXTabela		:= ""	
	Local cXError		:= ""
	Local cXErrorApp	:= ""
	Local lXContinua	:= .F.
	Local oXFile		:= NIL
	Local aXAux			:= {}
	Local aXAux2		:= {}
	Local aFiles 		:= {} 
	Local aSizes 		:= {} 	
	Local lRet			:= .T.
	Local nA			:= 0
	Local lXExec		:= .F.
	Local lXAux			:= .F.
	Local xAuxValOld	:= NIL
	Local xAuxValNew	:= NIL
	Default cXModo		:= "XXX"
	Default lXPos		:= .F.		

	// Ajuste de variáveis
	If cXModo == "PRE"
	
		If lXPos
			cFile := cXPath+"\"+cNomeArq+"_pos"+cXExtensao		
		Else
			cFile := cXPath+"\"+cNomeArq+cXExtensao
		EndIf
		
	ElseIf cXModo == "POS"
	
		cFile := cXPath+"\"+cNomeArq+"_pos"+cXExtensao
	
	EndIf
	
	cFile := Alltrim(cFile)
	oXFile := FWFileReader():New(cFile)
		
	// Percorre array de acordo com as tabelas passadas no arquivo .txt
	If cXModo == "PRE" 

		If (oXFile:Open())
		
			aXAux := oXFile:getAllLines()
	
			// Verifica conteúdo do arquivo
			If Empty(aXAux)
				MsgStop('Arquivo vazio.')
				Return(.F.)
			EndIf		
	
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
										If !fDropaTab(cXTab,cXTabela,@cXError)
											Exit
										EndIf
									
									Else
									
										cXError := "Falha ao tentar realizar o backup da tabela "+cXTab
										Exit	
														 		
									EndIf
								
								Else
								
									// Drop de tabela
									If !fDropaTab(cXTab,cXTabela,@cXError)
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
				If lXPos
					MsgInfo("Ajuste de base concluído com sucesso.",cXRotina)				
				Else
					MsgInfo("Ajuste de base concluído com sucesso."+CRLF+CRLF+"Favor executar a rotina MP710TO120",cXRotina)
				EndIf
			EndIf
			
		Else

			MsgStop("Não foi possível abrir o arquivo. ["+Alltrim(Lower(cFile))+"]",cXRotina)

		EndIf
	
	ElseIf cXModo == "POS"

		// Segunda execução, ajustes na estrutura 
		If MsgYesNo("Deseja realizar alterações nos arquivos de estrutura de dados?"+CRLF;
					+"Precisa disponibilizar o arquivo no caminho abaixo:"+CRLF;
					+cFile,cXRotina)
					
			StaticCall(MI11TO12,fMI11TO12,"PRE",.T.)		
		
		EndIf			
	
	
		// Preenche uma série de arrays com informações de arquivos e diretórios
		aDir(cXPathBkp,aFiles,aSizes)
		
		// Pergunta se deseja realizar o append das tabelas
		lXAppend := MsgYesNo("Deseja realizar o APPEND das tabelas que possuem backup na pasta ["+cXPathBkp+"]?")
		
		If !Empty(aFiles)
		
			For nA := 1 to Len(aFiles)
			
				If At(Upper(".dbf"),Upper(aFiles[nA])) > 0
					
					// Captura nome da tabela
					cXTabela := Upper(SubStr(aFiles[nA],1,3))+cEmpAnt+"0"
					cXTab := Upper(SubStr(aFiles[nA],1,3))
					
					If lXAppend
						FWMsgRun(, {|| lXContinua := fApp11To12(cXTab,cXTabela,Alltrim(aFiles[nA]),@cXErrorApp) }, cXRotina, "Realizando append na tabela "+cXTab)
						Iif((!Empty(cXErrorApp)),cXError += cXErrorApp+CRLF,NIL)
						lXExec := .T.
					Else
					
						// Recria a tabela caso não exista
						FWMsgRun(, {|| ChkFile(cXTab) }, cXRotina, "Recriando tabela "+cXTab)
						lXExec := .T.
												
					EndIf

				EndIf 
			
			Next

			// Verifica se rotina foi executada
			If lXExec
			
				// Se existir erro exibe a mensagem
				If !Empty(cXError)
					MsgStop(cXError)
				ElseIf lXAppend
					MsgInfo("Append Finalizado.",cXRotina)
				Else
					MsgInfo("Tabelas Recriadas.",cXRotina)				
				EndIf			
			
			Else
				MsgInfo("Rotina Finalizada.",cXRotina)
			EndIf
		
		Else
		
			MsgStop("Pasta de backup não existe ou está vazia. ["+Alltrim(Lower(cXPathBkp))+"]",cXRotina)
			
		EndIf
		
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


/*/{Protheus.doc} fApp11To12
// Função que realiza o Append nas tabelas
@author danielflavio
@since 14/01/2019
@version 1.0
@return lRet, Append realizado com sucesso ou não
@param cXTab, characters, descricao
@type static function
/*/
Static Function fApp11To12(cXTab,cXTabela,cXTabDbf,cXError)
	Local aXArea	:= GetArea()
	Local cXPath	:= "migracao"
	Local cXDirBkp	:= cXPath+"\backup\"
	Local cXWay		:= cXDirBkp+Lower(cXTabDbf)
	Local aStruct	:= {}
	Local lRet		:= .T.
	Local lXAux		:= .F.
	Local cXOpenTab	:= ""
	Default cXError	:= ""

	// Ajuste de variáveis
	cXError := ""
	
	// Drop de tabela
	If fDropaTab(cXTab,cXTabela,@cXError)	

		// Ajusta variáveis
		cXOpenTab := cXDirBkp+cXTabDbf
		//DBUseArea( .T., "DBFCDXADS", cXDirBkp+cXTabDbf, 'ORIGEM', .F., .F. )
		
		USE &cXOpenTab ALIAS ('ORIGEM') EXCLUSIVE NEW VIA "DBFCDXADS"

		If !NetErr()
		
			COPY TO &cXTabela ALL VIA 'TOPCONN'

			// Fecha tabela origem
			If Select('ORIGEM') > 0
				ORIGEM->(dbCloseArea())
			EndIf
		
			// Fecha Tabela
			If Select(cXTab) > 0
				(cXTab)->(dbCloseArea())
			EndIf
		
			// Abre tabela
			ChkFile(cXTab)
			dbSelectArea(cXTab)
			(cXTab)->(dbCloseArea())
			

		
		Else
		
			cXError := "Nao foi possivel abrir "+cXOpenTab+" em modo EXCLUSIVO."
			lRet := .F.
		
		EndIf
		
	EndIf
	
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
	
		cQuery := "UPDATE "+RetSqlName("ALI")+" SET D_E_L_E_T_='*' WHERE D_E_L_E_T_=' ' AND ALI_FILIAL=' '"
		
		If TcSqlExec(cQuery) < 0
			cXError := "Erro na execução da query "+CRLF+cQuery
			Return(.F.)
		EndIf
		
	EndIf
	
	RestArea(aXArea)
	
Return(.T.)


/*/{Protheus.doc} fDropaTab
// Função para dropar determinada tabela
@author danielflavio
@since 18/01/2019
@version 1.0
@return lXRet, Dropou a tabela ou não
@param cXTab, characters, Ex.: SE1
@param cXTabela, characters, EX.: SE1010
@param cXError, characters, String que recerá retorno da operação de DROP
@type static function
/*/
Static Function fDropaTab(cXTab,cXTabela,cXError)
	Local lXRet := .F.

	// Ajusta variável
	cXError := ""

	If TCCanOpen(cXTabela)

		// Drop de tabela
		If Select(cXTab) > 0
			(cXTab)->(dbCloseArea())
		EndIf	
	
		FWMsgRun(, {|| lXRet := TcDelFile(cXTabela) }, cXRotina, "Dropando tabela "+cXTab)
	
		If !lXRet 
			cXError := "Falha ao apagar "+cXTab+" : "+ TcSqlError()
		EndIf
	
	Else
		
		lXRet := .T.
		
	EndIf	
			
Return lXRet
