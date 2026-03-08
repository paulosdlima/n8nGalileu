WITH
params AS (
  SELECT
    NULLIF(TRIM(COALESCE('{{ $json.query.diretoria || "" }}', '')), '') AS p_diretoria,
    NULLIF(TRIM(COALESCE('{{ $json.query.setor || "" }}',     '')), '') AS p_setor,
    NULLIF(TRIM(COALESCE('{{ $json.query.ano || "" }}',       '')), '') AS p_ano
),

base AS (
  SELECT
    COALESCE(NULLIF(TRIM(setor_sigla), ''), '(NULL)')                AS setor_sigla,
    COALESCE(NULLIF(TRIM(setor_requisitante_sigla), ''), '(NULL)')  AS setor_requisitante_sigla,
    COALESCE(NULLIF(TRIM(diretoria), ''), '(NULL)')                 AS diretoria,
    COALESCE(NULLIF(TRIM(tipo_exame), ''), '(NULL)')                AS tipo_exame,

    /* CORRIGIDO: normalização conforme os valores reais do dataset */
    CASE
      WHEN UPPER(TRIM(COALESCE(tem_procedimento,''))) IN (
        'SIM','S','TRUE','1','TEM PROCEDIMENTO'
      ) THEN 'TEM PROCEDIMENTO'

      WHEN UPPER(TRIM(COALESCE(tem_procedimento,''))) IN (
        'NAO','NÃO','N','FALSE','0','NAO TEM PROCEDIMENTO','NÃO TEM PROCEDIMENTO'
      ) THEN 'NÃO TEM PROCEDIMENTO'

      WHEN NULLIF(TRIM(COALESCE(tem_procedimento,'')), '') IS NULL THEN '(NULL)'
      ELSE UPPER(TRIM(COALESCE(tem_procedimento,'')))
    END AS tem_procedimento,

    CASE
      WHEN com_requisicao = 'COM REQUISIÇÃO' THEN 'COM REQUISIÇÃO'
      WHEN com_requisicao = 'SEM REQUISIÇÃO' THEN 'SEM REQUISIÇÃO'
      WHEN com_requisicao IS NULL THEN '(NULL)'
      ELSE com_requisicao
    END AS com_requisicao,

    CASE
      WHEN UPPER(TRIM(COALESCE(laudo_entregue,''))) IN ('LAUDO ENTREGUE','ENTREGUE','SIM','S','TRUE','1') THEN 'LAUDO ENTREGUE'
      WHEN UPPER(TRIM(COALESCE(laudo_entregue,''))) IN ('NÃO ENTREGUE','NAO ENTREGUE','N','NÃO','NAO','FALSE','0','') THEN 'NÃO ENTREGUE'
      ELSE 'INDEFINIDO'
    END AS laudo_status,

    data_inclusao::timestamp      AS data_inclusao,
    data_entrega_laudo::timestamp AS data_entrega_laudo,
    data_finalizacao,
    ultima_movimentacao
  FROM public.staging_exames
  WHERE 1=1
),

base_filtrada AS (
  SELECT
    b.*,
    CASE
      WHEN (p.p_ano IS NULL OR p.p_ano ILIKE 'TODOS%') THEN 1
      ELSE CASE
        WHEN EXTRACT(YEAR FROM b.data_inclusao)::text = p.p_ano THEN 1
        ELSE 0
      END
    END AS cont_ano
  FROM base b
  CROSS JOIN params p
  WHERE
    (p.p_diretoria IS NULL OR p.p_diretoria ILIKE 'TODOS%' OR b.diretoria = p.p_diretoria)
    AND
    (p.p_setor IS NULL OR p.p_setor ILIKE 'TODOS%' OR b.setor_sigla = p.p_setor)
    AND
    (
      (p.p_ano IS NULL OR p.p_ano ILIKE 'TODOS%' OR EXTRACT(YEAR FROM b.data_inclusao)::text = p.p_ano)
      OR
      (p.p_ano IS NULL OR p.p_ano ILIKE 'TODOS%' OR (b.data_entrega_laudo IS NOT NULL AND EXTRACT(YEAR FROM b.data_entrega_laudo)::text = p.p_ano))
    )
),

kpis AS (
  SELECT json_build_object(
    'total', SUM((cont_ano = 1)::int),
    'com_requisicao', SUM((com_requisicao = 'COM REQUISIÇÃO' AND cont_ano = 1)::int),
    'sem_requisicao', SUM((cont_ano = 1 AND (com_requisicao <> 'COM REQUISIÇÃO' OR com_requisicao IS NULL OR com_requisicao='(NULL)'))::int),
    'concluidos', SUM((ultima_movimentacao = 'Perícia Concluída' AND cont_ano = 1)::int),
    'nao_concluidos', SUM((ultima_movimentacao <> 'Perícia Concluída' AND cont_ano = 1)::int),
    'em_pausa', SUM((ultima_movimentacao = 'Em pausa' AND cont_ano = 1)::int),
    'laudo_entregue_total', SUM((laudo_status = 'LAUDO ENTREGUE')::int),
    'laudo_entregue_do_periodo', SUM((laudo_status = 'LAUDO ENTREGUE' AND cont_ano = 1)::int),
    'laudo_nao_entregue', SUM((laudo_status = 'NÃO ENTREGUE' AND cont_ano = 1)::int),

    /* CORRIGIDO */
    'tem_procedimento_sim', SUM((tem_procedimento = 'TEM PROCEDIMENTO' AND cont_ano = 1)::int),
    'tem_procedimento_nao', SUM((tem_procedimento = 'NÃO TEM PROCEDIMENTO' AND cont_ano = 1)::int)
  ) AS kpis
  FROM base_filtrada
),

por_setor_top10 AS (
  SELECT json_agg(x ORDER BY x.total DESC) AS por_setor_top10
  FROM (
    SELECT setor_sigla, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY setor_sigla
    ORDER BY total DESC
    LIMIT 10
  ) x
),

por_setor_requisitante AS (
  SELECT json_agg(x ORDER BY x.total DESC) AS por_setor_requisitante
  FROM (
    SELECT setor_requisitante_sigla, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY setor_requisitante_sigla
    ORDER BY total DESC
    LIMIT 15
  ) x
),

por_diretoria AS (
  SELECT json_agg(x ORDER BY x.total DESC) AS por_diretoria
  FROM (
    SELECT diretoria, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY diretoria
    ORDER BY total DESC
  ) x
),

por_laudo_entregue AS (
  SELECT json_agg(x ORDER BY x.total DESC) AS por_laudo_entregue
  FROM (
    SELECT laudo_status AS status, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY laudo_status
    ORDER BY total DESC
  ) x
),

por_com_requisicao AS (
  SELECT json_agg(x ORDER BY x.total DESC) AS por_com_requisicao
  FROM (
    SELECT COALESCE(com_requisicao,'(NULL)') AS com_requisicao, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY COALESCE(com_requisicao,'(NULL)')
    ORDER BY total DESC
  ) x
),

por_mes AS (
  SELECT json_agg(x ORDER BY x.mes) AS por_mes
  FROM (
    SELECT to_char(date_trunc('month', data_inclusao), 'YYYY-MM') AS mes, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
      AND data_inclusao IS NOT NULL
    GROUP BY 1
    ORDER BY 1
  ) x
),

por_mes_diretoria AS (
  SELECT json_agg(x ORDER BY x.diretoria, x.mes) AS por_mes_diretoria
  FROM (
    SELECT diretoria, to_char(date_trunc('month', data_inclusao), 'YYYY-MM') AS mes, COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
      AND data_inclusao IS NOT NULL
    GROUP BY diretoria, 2
    ORDER BY diretoria, 2
  ) x
),

kpis_por_setor AS (
  SELECT json_agg(x ORDER BY x.diretoria, x.setor_sigla) AS kpis_por_setor
  FROM (
    SELECT
      diretoria,
      setor_sigla,
      COUNT(*) AS total,
      SUM((com_requisicao = 'COM REQUISIÇÃO')::int) AS com_requisicao,
      SUM((com_requisicao <> 'COM REQUISIÇÃO' OR com_requisicao IS NULL OR com_requisicao='(NULL)')::int) AS sem_requisicao,
      SUM((ultima_movimentacao = 'Perícia Concluída')::int) AS concluidos,
      SUM((ultima_movimentacao <> 'Perícia Concluída')::int) AS nao_concluidos,
      SUM((laudo_status = 'LAUDO ENTREGUE')::int) AS laudo_entregue,
      SUM((laudo_status = 'NÃO ENTREGUE')::int) AS laudo_nao_entregue,

      /* CORRIGIDO */
      SUM((tem_procedimento = 'TEM PROCEDIMENTO')::int) AS tem_procedimento_sim,
      SUM((tem_procedimento = 'NÃO TEM PROCEDIMENTO')::int) AS tem_procedimento_nao

    FROM base_filtrada
    GROUP BY diretoria, setor_sigla
    ORDER BY diretoria, setor_sigla
  ) x
),

por_tipo_exame_setor AS (
  SELECT json_agg(x ORDER BY x.setor_sigla, x.total DESC) AS por_tipo_exame_setor
  FROM (
    SELECT
      setor_sigla,
      tipo_exame,
      COUNT(*) AS total
    FROM base_filtrada
    WHERE cont_ano = 1
    GROUP BY setor_sigla, tipo_exame
    ORDER BY setor_sigla, total DESC
  ) x
),

limites_meses AS (
  SELECT
    MIN(date_trunc('month', COALESCE(data_inclusao, data_entrega_laudo))) AS min_mes,
    MAX(date_trunc('month', COALESCE(data_inclusao, data_entrega_laudo))) AS max_mes
  FROM base_filtrada
  WHERE cont_ano = 1
),

meses AS (
  SELECT generate_series(min_mes, max_mes, interval '1 month')::date AS mes_dt
  FROM limites_meses
  WHERE min_mes IS NOT NULL AND max_mes IS NOT NULL
),

entradas_mes AS (
  SELECT
    date_trunc('month', data_inclusao)::date AS mes_dt,
    COUNT(*)::int AS entradas
  FROM base_filtrada
  WHERE cont_ano = 1
    AND data_inclusao IS NOT NULL
  GROUP BY 1
),

entregues_mes AS (
  SELECT
    date_trunc('month', data_entrega_laudo)::date AS mes_dt,
    COUNT(*)::int AS entregues
  FROM base_filtrada
  WHERE cont_ano = 1
    AND data_entrega_laudo IS NOT NULL
    AND laudo_status = 'LAUDO ENTREGUE'
  GROUP BY 1
),

serie_fluxo AS (
  SELECT
    m.mes_dt,
    COALESCE(e.entradas, 0)  AS entradas,
    COALESCE(s.entregues, 0) AS entregues
  FROM meses m
  LEFT JOIN entradas_mes e USING (mes_dt)
  LEFT JOIN entregues_mes s USING (mes_dt)
),

fluxo_calc AS (
  SELECT
    mes_dt,
    entradas,
    entregues,
    SUM(entradas - entregues) OVER (
      ORDER BY mes_dt
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::int AS backlog_pendente
  FROM serie_fluxo
),

por_mes_fluxo AS (
  SELECT json_agg(
    json_build_object(
      'mes', to_char(mes_dt, 'YYYY-MM'),
      'entradas', entradas,
      'entregues', entregues,
      'backlog_pendente', backlog_pendente
    )
    ORDER BY mes_dt
  ) AS por_mes_fluxo
  FROM fluxo_calc
)

SELECT
  (SELECT kpis FROM kpis) AS kpis,
  COALESCE((SELECT por_setor_top10 FROM por_setor_top10), '[]'::json) AS por_setor_top10,
  COALESCE((SELECT por_setor_requisitante FROM por_setor_requisitante), '[]'::json) AS por_setor_requisitante,
  COALESCE((SELECT por_diretoria FROM por_diretoria), '[]'::json) AS por_diretoria,
  COALESCE((SELECT por_laudo_entregue FROM por_laudo_entregue), '[]'::json) AS por_laudo_entregue,
  COALESCE((SELECT por_com_requisicao FROM por_com_requisicao), '[]'::json) AS por_com_requisicao,
  COALESCE((SELECT por_mes FROM por_mes), '[]'::json) AS por_mes,
  COALESCE((SELECT por_mes_diretoria FROM por_mes_diretoria), '[]'::json) AS por_mes_diretoria,
  COALESCE((SELECT kpis_por_setor FROM kpis_por_setor), '[]'::json) AS kpis_por_setor,
  COALESCE((SELECT por_tipo_exame_setor FROM por_tipo_exame_setor), '[]'::json) AS por_tipo_exame_setor,
  COALESCE((SELECT por_mes_fluxo FROM por_mes_fluxo), '[]'::json) AS por_mes_fluxo;