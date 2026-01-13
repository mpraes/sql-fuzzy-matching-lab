DROP TABLE IF EXISTS tb_empresas_golden CASCADE;

CREATE TABLE tb_empresas_golden (
    id_golden SERIAL PRIMARY KEY,
    nome_original TEXT,          -- Como veio da origem
    nome_padronizado TEXT,       -- Sem LTDA, S.A, pontuação
    
    -- Metadados de Inteligência (Enrichment)
    fonetica_primaria VARCHAR(10),   -- Double Metaphone 1
    fonetica_secundaria VARCHAR(10), -- Double Metaphone 2
    
    data_processamento TIMESTAMP DEFAULT NOW()
);