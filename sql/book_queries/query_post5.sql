SELECT 
    nome_fantasia,
    -- O Alvo da comparação
    'SERVICOS' AS alvo,
    -- Calcula a distância
    levenshtein(nome_fantasia, 'SERVICOS') AS distancia_edicao
FROM stg_empresas_import
WHERE 
    nome_fantasia IS NOT NULL 
    -- OTIMIZAÇÃO: Só compara strings que tenham tamanho parecido.
    -- Se "SERVICOS" tem 7 letras, não adianta comparar com strings de 5 ou 20 letras.
    AND LENGTH(nome_fantasia) BETWEEN 9 AND 13
    -- FILTRO DE "QUASE LÁ":
    -- Queremos distância entre 1 (erro leve) e 3 (erro grave).
    -- Distância 0 seria a escrita correta, que não nos interessa agora.
    AND levenshtein(nome_fantasia, 'SERVICOS') BETWEEN 1 AND 4
ORDER BY 
    distancia_edicao ASC, 
    RANDOM()
LIMIT 20;