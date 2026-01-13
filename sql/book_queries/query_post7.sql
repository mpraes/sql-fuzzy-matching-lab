SELECT 
    nome_fantasia,
    'AUTO PECAS' AS alvo,
    -- LEVENSHTEIN (Lição 5): Conta trocas de letras.
    -- Se a ordem muda ("PECAS AUTO"), ele acha que tudo mudou.
    -- Resultado: Números altos (RUIM)
    levenshtein(nome_fantasia, 'AUTO PECAS') AS distancia_levenshtein,
    -- TRIGRAM SIMILARITY (Lição 7): Conta pedacinhos compartilhados.
    -- Se a ordem muda, os pedacinhos ainda estão lá!
    -- Resultado: Perto de 1.0 (BOM)
    ROUND(similarity(nome_fantasia, 'AUTO PECAS')::numeric, 2) AS score_trigram
FROM stg_empresas_import
WHERE 
    nome_fantasia IS NOT NULL 
    -- Filtra onde o Trigram acha que é parecido (> 0.3)
    AND similarity(nome_fantasia, 'AUTO PECAS') > 0.3
ORDER BY 
    -- Vamos ordenar pelos casos onde o Trigram ganha (Score alto)
    score_trigram DESC,
    distancia_levenshtein DESC -- E Levenshtein "perde" (Distância alta)
LIMIT 15;