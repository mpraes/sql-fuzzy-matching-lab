-------------------------------------------------------
-- ROUND 1: O JEITO LENTO (Full Table Scan)
-- Aqui nós "proibimos" o banco de usar o índice para simular o caos.
-------------------------------------------------------
BEGIN; -- Inicia uma transação segura
SET LOCAL enable_bitmapscan = OFF; -- Desliga o uso do índice GIN temporariamente
SET LOCAL enable_seqscan = ON;     -- Força a leitura linha por linha

EXPLAIN ANALYZE
SELECT 
    nome_fantasia,
    similarity(nome_fantasia, 'SERVICOS') as score
FROM stg_empresas_import
WHERE 
    nome_fantasia % 'SERVICOS' -- Mesmo usando o operador, forçamos o scan
ORDER BY 
    score DESC;

ROLLBACK; -- Volta as configurações ao normal


-------------------------------------------------------
-- ROUND 2: O JEITO RÁPIDO (GIN Index Scan)
-- Agora deixamos o banco usar a inteligência do índice.
-------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    nome_fantasia,
    similarity(nome_fantasia, 'SERVICOS') as score
FROM stg_empresas_import
WHERE 
    nome_fantasia % 'SERVICOS' -- Aqui ele vai usar o índice idx_empresas_trigram
ORDER BY 
    score DESC;