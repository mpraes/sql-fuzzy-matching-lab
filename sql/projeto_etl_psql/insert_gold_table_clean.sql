INSERT INTO tb_empresas_golden (
    nome_original, 
    nome_padronizado, 
    fonetica_primaria, 
    fonetica_secundaria
)
SELECT 
    nome_fantasia,
    
    -- TRATAMENTO (Limpeza)
    TRIM(REGEXP_REPLACE(
        UPPER(nome_fantasia), 
        '( LTDA| S\.A| S/A| ME| EPP| - ME|\.|,|-|[0-9])', -- Remove sufixos e números do nome padronizado
        '', 
        'g'
    )) AS nome_limpo,
    
    -- ENRIQUECIMENTO FONÉTICO
    dmetaphone(nome_fantasia) AS dm1,
    dmetaphone_alt(nome_fantasia) AS dm2

FROM stg_empresas_import
WHERE 
    -- 1. FILTRO BÁSICO (Existência)
    nome_fantasia IS NOT NULL 
    AND TRIM(nome_fantasia) <> ''
    
    -- 2. FILTRO ANTI-NUMÉRICO/SÍMBOLOS (Obrigatório ter letras)
    -- O regex procura por [A-Z]. Se não tiver nenhuma letra (só nº ou símbolo), descarta.
    AND nome_fantasia ~ '[a-zA-Z]'
    
    -- 3. FILTRO DE TAMANHO MÍNIMO (Evita ruído como "A", "X", "AB")
    -- Nomes de empresas reais geralmente têm mais de 2 letras.
    AND LENGTH(TRIM(nome_fantasia)) > 2;

-- Verificação: Quantos registros foram carregados?
SELECT * FROM tb_empresas_golden order by random() limit 15



-- "A Lixeira": O que o ETL ignorou?
SELECT nome_fantasia, 'Rejeitado por qualidade' as motivo
FROM stg_empresas_import
WHERE 
    nome_fantasia IS NULL 
    OR TRIM(nome_fantasia) = ''
    OR nome_fantasia !~ '[a-zA-Z]' -- Não tem letras
    OR LENGTH(TRIM(nome_fantasia)) <= 2 -- Muito curto
LIMIT 20;