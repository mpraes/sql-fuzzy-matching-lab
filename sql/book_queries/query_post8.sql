WITH metricas AS (
    SELECT 
        nome_fantasia,
        'OFICINA MECANICA' AS alvo,
        
        -- 1. TRIGRAMA (Mantém igual)
        similarity(nome_fantasia, 'OFICINA MECANICA') AS score_trigram,
        
        -- 2. LEVENSHTEIN (Mantém igual)
        GREATEST(0, 1 - (
            levenshtein(nome_fantasia, 'OFICINA MECANICA')::numeric / 
            GREATEST(LENGTH(nome_fantasia), LENGTH('OFICINA MECANICA'))
        )) AS score_levenshtein,
        
        -- 3. FONÉTICO GRADUAL (A Correção!)
        -- Em vez de 0 ou 1, usamos a função DIFFERENCE (0 a 4) e dividimos por 4.
        -- Nota 4 vira 1.0 (100%)
        -- Nota 3 vira 0.75 (75%)
        -- Nota 2 vira 0.50 (50%)
        (DIFFERENCE(nome_fantasia, 'OFICINA MECANICA')::numeric / 4.0) AS score_fonetico_gradual
        
    FROM stg_empresas_import
    WHERE 
        nome_fantasia IS NOT NULL
        -- Filtro amplo para trazer candidatos
        AND similarity(nome_fantasia, 'OFICINA MECANICA') > 0.15
)
SELECT 
    nome_fantasia,
    
    -- Exibindo as parciais para você entender a "justiça" da nota
    ROUND(score_trigram::numeric, 2) AS trgm,
    ROUND(score_levenshtein::numeric, 2) AS lev,
    ROUND(score_fonetico_gradual::numeric, 2) AS sound,
    
    -- O SUPER SCORE (Híbrido)
    ROUND(
        (
            (score_trigram * 0.5) +          -- Peso 50% (Estrutura)
            (score_levenshtein * 0.3) +      -- Peso 30% (Escrita Fina)
            (score_fonetico_gradual * 0.2)   -- Peso 20% (Som)
        ) * 100 
    , 1) AS SUPER_SCORE
    
FROM metricas
ORDER BY 
    SUPER_SCORE DESC,
    nome_fantasia ASC
LIMIT 20;