-- O EXPLAIN ANALYZE mostra "como" o banco pensou (Plano de Execução)
EXPLAIN ANALYZE
SELECT 
    nome_fantasia,
    similarity(nome_fantasia, 'SERVICOS') as score
FROM stg_empresas_import
WHERE 
    nome_fantasia IS NOT NULL
    -- O Operador Mágico (%)
    -- Ele busca apenas quem tem similaridade acima do limite (padrão 0.3)
    -- E USA O ÍNDICE GIN!
    AND nome_fantasia % 'SERVICOS'
ORDER BY 
    score DESC;