-- Evidências
SELECT evi.id_evi as ID_Evidencia,

CASE 
	WHEN evi.nro_vestigio_requisitante_evi is not null THEN evi.nro_vestigio_requisitante_evi 
	WHEN evi.nro_vestigio_pol_cientifica_evi is not null THEN evi.nro_vestigio_pol_cientifica_evi 
	ELSE '' END as NUMERO_VESTIGIO ,

evi.nro_vestigio_requisitante_evi as NRO_VESTIGIO_REQUISITANTE, 
evi.nro_vestigio_pol_cientifica_evi as NRO_VESTIGIO_PERICIA , 
--DADOS DA EVIDÊNCIA
evi.data_inclusao_evi as DATA_INCLUSAO,
tipoevi.descricao_tie as TIPO_EVIDENCIA,
--Descrever Resumo do Tipo Evidencia aqui...
CASE WHEN tipoevi.id_tie = 1 THEN  	-- ARMA(0, "Arma"), CARTUCHO(1, "Cartucho"),PROJETIL(2,"Projétil"), OUTROS(3,"Outros"),CARREGADOR(4,"Carregador"),ESTOJO(5,"Estojo"); 
		COALESCE(tipo_armamento.descricao_eati , '') || ' ' || COALESCE( marca_armamento.descricao_eama , '') || ' ' || COALESCE(armamento.modelo_armamento_eva , '') ||  COALESCE( ' Nº Série: ' ||  NULLIF( armamento.numero_serie_eva , '' ) , '') ||  COALESCE( ' Qtde:' ||  armamento.quantidade_eva , '')	
	WHEN tipoevi.id_tie = 2	THEN 
		COALESCE(tipo_dispositivo.descricao_edtt, '') || ' ' || COALESCE( fabricante.descricao_edtf , '') || ' ' || COALESCE( dispositivo.modelo_edt , '')
	WHEN tipoevi.id_tie = 3	THEN 
		COALESCE( tipo_documento.descricao_edot , '') ||  COALESCE( ' Qtde Páginas:' ||  documento.paginas_edo , '')	 ||  COALESCE( ' Qtde Fls:' ||  documento.folhas_edo , '')	
	WHEN tipoevi.id_tie = 4	THEN --'Material Químico/Biológico'
		COALESCE('Tipo: ' || tipo_material.descricao_emti , '') || COALESCE( ' Apresentação:' || apresentacao_material.descricao_emap  , '') 
	WHEN tipoevi.id_tie = 5	THEN --'Veículo'
		COALESCE(tipo_veiculo.descricao_evti , '') || ' ' || COALESCE( marca_veiculo.descricao_evma , '') || ' ' || COALESCE( NULLIF( veiculo.modelo_evv , '' ) , '') ||  COALESCE( ' Placa: ' ||  UPPER ( NULLIF( veiculo.placa_evv , '' ) ) , '')	
	WHEN tipoevi.id_tie = 6	THEN 
		COALESCE(   regexp_replace( objeto.descricao_evo , '[\n\r]+', ' - ', 'g' )  , '')
	WHEN tipoevi.id_tie = 7	THEN --'Arquivo Digital'
		COALESCE(   regexp_replace( arquivo_digital.descricao_arquivo_ead , '[\n\r]+', ' - ', 'g' )  , '') || ' ' || COALESCE(' Suporte: ' || arquivo_digital.tipo_suporte_ead , '') ||  COALESCE( ' Qtde: ' ||  arquivo_digital.quantidade_ead , '')	||  COALESCE( ' Tamanho: ' ||  arquivo_digital.tamanho_ead ||' ' || arquivo_digital.capacidade_unidade_ead , '')	 
	ELSE ''
	END as DESCRICAO_EVIDENCIA,
	
CASE WHEN evi.contraprova_evi = true THEN 'CONTRAPROVA' ELSE '' END   as contra_prova, 
-- LACRE
COALESCE(  lacre.numero_lac , '' ) as NUMERO_LACRE_ATUAL,
COALESCE( tipolacre.descricao_tla , '' ) as TIPO_LACRE_ATUAL,
--tipolacre.sigla_tla as SIGLA_TIPO_LACRE_ATUAL,
-- CUSTÓDIA
COALESCE(  custodia.tipo_custodia_ulc  , '' )  as tipo_custodia,
CASE WHEN custodia.tipo_custodia_ulc = 'SETOR' THEN setcustodia.descricao_set
	WHEN custodia.tipo_custodia_ulc = 'PESSOAL' THEN usucustodia.nome_usu
	WHEN custodia.tipo_custodia_ulc = 'DESCARTE' THEN 'VESTÍGIO DESCARTADO'
	ELSE '' END AS ultima_custodia,

-- OUTROS DADOS DA EVIDÊNCIA
CASE WHEN evi.bloqueado_evi = true THEN 'BLOQUEADO' ELSE '' END as EVIDENCIA_BLOQUEADO,
CASE WHEN evi.sem_cadeia_custodia_evi = true THEN 'SEM CADEIA DE CUSTÓDIA' ELSE 'COM CADEIA DE CUSTÓDIA' END as SEM_CADEIA_CUSTODIA ,

COALESCE(   regexp_replace( evi.motivo_exclusao_evi , '[\n\r]+', ' - ', 'g' )  , '')  as MOTIVO_EXCLUSAO,
COALESCE(   regexp_replace( evi.motivo_descarte_evi , '[\n\r]+', ' - ', 'g' )  , '')  as MOTIVO_DESCARTE,

/*
-- DESCARTE
DATA DO DESCARTE
TIPO_DESCARTE
NUMERO DO RECIBO
*/

-- PROCEDIMENTO DA EVIDÊNCIA
caso.numero_prp || '/' || caso.ano_prp as NUMERO_CASO,
 COALESCE(( 
	 SELECT string_agg( '' || soe.id_spp_soe , ' ; ' )  FROM pericia.tb_solicitacao_evidencia_soe soe WHERE soe.id_evi_soe = evi.id_evi  AND soe.data_finalizacao_soe is null
 ), 'NENHUM EXAME VINCULADO' ) as EXAMES_VINCULADOS,
 
COALESCE((
	 SELECT string_agg(  DISTINCT (tpp.sigla_tpp || ' ' ||ppo.numero_ppo) , ' ; ' )  
	 FROM pericia.tb_solicitacao_evidencia_soe soe 
	 INNER JOIN pericia.tb_procedimento_policial_ppo ppo on ppo.id_spp = soe.id_spp_soe
	 INNER JOIN pericia.tb_tipo_procedimento_policial_tpp tpp on ppo.id_tpp = tpp.id_tpp
	 WHERE soe.id_evi_soe = evi.id_evi  AND soe.data_finalizacao_soe is null AND tpp.procedimento_tpp = true	 
 ), 'SEM PROCEDIMENTO' ) as PROCEDIMENTOS_VINCULADOS
 

FROM pericia.tb_evidencia_evi evi
LEFT JOIN pericia.tb_procedimento_pericial_prp caso on caso.id_prp = evi.id_prp_evi
LEFT JOIN pericia.tb_tipo_evidencia_tie tipoevi on tipoevi.id_tie = evi.id_tie_evi
-- Lacre 
LEFT JOIN pericia.tb_evidencia_lacre_evl evilacre on evilacre.id_evi_evl = evi.id_evi AND evilacre.data_finalizacao_evl is null
LEFT JOIN pericia.tb_lacre_lac lacre on evilacre.id_lac_evl = lacre.id_lac 
LEFT JOIN pericia.tb_tipo_lacre_tla tipolacre on tipolacre.id_tla = lacre.id_tla_lac
-- cUSTÓDIA
LEFT JOIN pericia.tb_usuario_lacre_custodia_ulc custodia on custodia.id_evi_ulc = evi.id_evi and custodia.data_finalizacao_ulc is null
LEFT JOIN sistema.tb_usuario_usu usucustodia on usucustodia.id_usu = custodia.id_usu_ulc
LEFT JOIN sistema.tb_setor_set setcustodia on setcustodia.id_set = id_set_ulc

-- DESCRICAO VESTIGIOS
LEFT JOIN pericia.tb_evidencia_objeto_evo objeto on evi.id_evi = objeto.id_evi_evo

LEFT JOIN pericia.tb_evidencia_armamento_eva armamento on evi.id_evi = armamento.id_evi_eva
LEFT JOIN pericia.tb_evidencia_armamento_tipo_eati tipo_armamento on tipo_armamento.id_eati = armamento.id_eati_eva
LEFT JOIN pericia.tb_evidencia_armamento_marca_eama marca_armamento on marca_armamento.id_eama = armamento.id_eama_eva

LEFT JOIN pericia.tb_evidencia_dispositivo_tecnologico_edt dispositivo on evi.id_evi = dispositivo.id_evi_edt
LEFT JOIN pericia.tb_evidencia_dispositivo_tecnologico_tipo_edtt tipo_dispositivo on tipo_dispositivo.id_edtt = dispositivo.id_edtt_edt
LEFT JOIN pericia.tb_evidencia_dispositivo_tecnologico_fabricante_edtf fabricante on  fabricante.id_edtf = dispositivo.id_edtf_edt


LEFT JOIN pericia.tb_evidencia_documento_edo documento on evi.id_evi = documento.id_evi_edo
LEFT JOIN pericia.tb_evidencia_documento_tipo_edot tipo_documento on tipo_documento.id_edot = documento.id_edt_edo

LEFT JOIN pericia.tb_evidencia_material_evm material on evi.id_evi = material.id_evi_evm
LEFT JOIN pericia.tb_evidencia_material_tipo_emti tipo_material on tipo_material.id_emti = material.id_emti_evm
LEFT JOIN pericia.tb_evidencia_material_apresentacao_emap apresentacao_material on apresentacao_material.id_emap = material.id_emap_evm

LEFT JOIN pericia.tb_evidencia_veiculo_evv veiculo on evi.id_evi = veiculo.id_evi_evv
LEFT JOIN pericia.tb_evidencia_veiculo_tipo_evti tipo_veiculo on veiculo.id_evti_evv = tipo_veiculo.id_evti
LEFT JOIN pericia.tb_evidencia_veiculo_marca_evma marca_veiculo on marca_veiculo.id_evma = veiculo.id_evma_evv

LEFT JOIN pericia.tb_evidencia_arquivo_digital_ead arquivo_digital on evi.id_evi = arquivo_digital.id_evi_ead


WHERE 
tipoevi.id_tie <> 0


ORDER BY tipoevi.id_tie ,  evi.id_evi