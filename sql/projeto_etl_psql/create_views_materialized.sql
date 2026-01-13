DROP MATERIALIZED VIEW IF EXISTS vw_relatorio_duplicatas;

CREATE MATERIALIZED VIEW vw_relatorio_duplicatas AS
WITH ordenado AS (
    SELECT 
        id_golden,
        nome_padronizado,
        fonetica_primaria,
        -- Pega o próximo registro da lista ordenada foneticamente
        LEAD(nome_padronizado) OVER (
            PARTITION BY fonetica_primaria 
            ORDER BY nome_padronizado
        ) as proximo_nome,
        LEAD(id_golden) OVER (
            PARTITION BY fonetica_primaria 
            ORDER BY nome_padronizado
        ) as proximo_id
    FROM tb_empresas_golden
    WHERE fonetica_primaria IS NOT NULL
)
SELECT 
    id_golden AS id_a,
    nome_padronizado AS empresa_a,
    proximo_id AS id_b,
    proximo_nome AS empresa_b,
    -- Calcula similaridade apenas entre vizinhos
    similarity(nome_padronizado, proximo_nome) AS score
FROM ordenado
WHERE 
    proximo_nome IS NOT NULL
    -- Só traz se forem muito parecidos
    AND similarity(nome_padronizado, proximo_nome) > 0.7;


    SELECT 
    empresa_a,
    empresa_b,
    score -- Se usou a Opção 1 ou 2, o nome da coluna de score pode variar, ajuste aqui
FROM vw_relatorio_duplicatas
ORDER BY score DESC
LIMIT 20;