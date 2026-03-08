select * from pericia.tb_evidencia_evi
where id_evi=2728

select * from pericia.tb_usuario_lacre_custodia_ulc
where id_evi_ulc=2728

select tb_evidencia_lacre_evl.id_evi_evl ,tb_lacre_lac.atualizado_em 
from pericia.tb_evidencia_lacre_evl 
inner join pericia.tb_lacre_lac on id_lac = id_lac_evl
where id_evi_evl=2728
tb_lacre_lac.atualizado_em >=  to_timestamp('2025-11-05 14:06:00','YYYY-MM-DD HH24:MI:SS')


select to_timestamp('2025-11-05 14:07:00','YYYY-MM-DD HH24:MI:SS')  , CURRENT_TIMESTAMP , NOW()


update pericia.tb_evidencia_evi set observacoes_evi = 'novo'
where id_evi=2728

--alteracao dos lacres
--alteracao da custodia
--alteracao dos dados
--alteracao descarte
--alteracao vinculacao e desvinculacao do exame

-- pericia.tb_solicitacao_evidencia_soe
ALTER TABLE IF EXISTS pericia.tb_solicitacao_evidencia_soe DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_solicitacao_evidencia_soe
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_solicitacao_evidencia_soe
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();


---
select distinct ( id_evi )
from (
select id_evi as id_evi from pericia.tb_evidencia_evi
where tb_evidencia_evi.atualizado_em >= ${{json}}
union all

select id_evi_ulc as id_evi from pericia.tb_usuario_lacre_custodia_ulc
where tb_usuario_lacre_custodia_ulc.atualizado_em >= to_timestamp('2025-11-05 14:30:00','YYYY-MM-DD HH24:MI:SS')

union all
select tb_evidencia_lacre_evl.id_evi_evl  as id_evi
from pericia.tb_evidencia_lacre_evl 
inner join pericia.tb_lacre_lac on id_lac = id_lac_evl
where tb_lacre_lac.atualizado_em >=  to_timestamp('2025-11-05 14:06:00','YYYY-MM-DD HH24:MI:SS')

union all

select id_evi_soe as id_evi from  pericia.tb_solicitacao_evidencia_soe
where tb_solicitacao_evidencia_soe.atualizado_em >= to_timestamp('2025-11-05 14:30:00','YYYY-MM-DD HH24:MI:SS')
)



