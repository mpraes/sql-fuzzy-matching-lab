-- 1. Índice GIN para buscas fuzzy no nome (Lição 10)
CREATE INDEX idx_golden_trigram 
ON tb_empresas_golden 
USING GIN (nome_padronizado gin_trgm_ops);

-- 2. Índices B-Tree normais para buscas exatas pelos códigos fonéticos
CREATE INDEX idx_golden_dm1 ON tb_empresas_golden(fonetica_primaria);
CREATE INDEX idx_golden_dm2 ON tb_empresas_golden(fonetica_secundaria);