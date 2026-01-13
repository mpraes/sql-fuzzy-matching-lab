WITH metricas AS (
    SELECT 
        nome_fantasia,
        'OFICINA MECANICA' AS alvo,
        
        -- 1. TRIGRAMA (Retorna Real/Float)
        similarity(nome_fantasia, 'OFICINA MECANICA') AS score_trigram,
        
        -- 2. LEVENSHTEIN (Cálculo resulta em Numeric)
        GREATEST(0, 1 - (
            levenshtein(nome_fantasia, 'OFICINA MECANICA')::numeric / 
            GREATEST(LENGTH(nome_fantasia), LENGTH('OFICINA MECANICA'))
        )) AS score_levenshtein,
        
        -- 3. FONÉTICO GRADUAL (Cálculo resulta em Numeric)
        (DIFFERENCE(nome_fantasia, 'OFICINA MECANICA')::numeric / 4.0) AS score_fonetico_gradual
        
    FROM stg_empresas_import
    WHERE 
        nome_fantasia IS NOT NULL
        AND similarity(nome_fantasia, 'OFICINA MECANICA') > 0.15
)
SELECT 
    nome_fantasia,
    
    -- Visualização das parciais
    ROUND(score_trigram::numeric, 2) AS trgm,
    ROUND(score_levenshtein::numeric, 2) AS lev,
    ROUND(score_fonetico_gradual::numeric, 2) AS sound,
    
    -- O SUPER SCORE FINAL
    -- AQUI ESTAVA O ERRO: Convertemos TUDO para numeric antes de arredondar
    ROUND(
        (
            (score_trigram * 0.5) + 
            (score_levenshtein * 0.3) + 
            (score_fonetico_gradual * 0.2)
        )::numeric * 100 
    , 1) AS SUPER_SCORE
    
FROM metricas
ORDER BY 
    SUPER_SCORE DESC,
    nome_fantasia ASC
LIMIT 20;