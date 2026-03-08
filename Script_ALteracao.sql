CREATE OR REPLACE FUNCTION atualiza_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- pericia.tb_evidencia_evi
ALTER TABLE IF EXISTS pericia.tb_evidencia_evi DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_evidencia_evi
ADD COLUMN atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_evidencia_evi
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();


-- pericia.tb_usuario_lacre_custodia_ulc
ALTER TABLE IF EXISTS pericia.tb_usuario_lacre_custodia_ulc DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_usuario_lacre_custodia_ulc
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_usuario_lacre_custodia_ulc
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();

-- pericia.tb_lacre_lac
ALTER TABLE IF EXISTS pericia.tb_lacre_lac DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_lacre_lac
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_lacre_lac
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();

-- pericia.tb_solicitacao_evidencia_soe
ALTER TABLE IF EXISTS pericia.tb_solicitacao_evidencia_soe DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_solicitacao_evidencia_soe
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_solicitacao_evidencia_soe
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();


-- pericia.tb_solicitacao_procedimento_pericial_spp
ALTER TABLE IF EXISTS pericia.tb_solicitacao_procedimento_pericial_spp DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_solicitacao_procedimento_pericial_spp
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_solicitacao_procedimento_pericial_spp
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();

-- pericia.tb_solicitacao_tramitacao_sot

ALTER TABLE IF EXISTS pericia.tb_solicitacao_tramitacao_sot DROP COLUMN IF EXISTS atualizado_em;
ALTER TABLE pericia.tb_solicitacao_tramitacao_sot
ADD COLUMN atualizado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

CREATE TRIGGER trg_atualiza_timestamp
BEFORE UPDATE ON pericia.tb_solicitacao_tramitacao_sot
FOR EACH ROW
EXECUTE FUNCTION atualiza_timestamp();
