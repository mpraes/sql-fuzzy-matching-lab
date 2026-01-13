-- #sqlpilulas - Dia 1: Regularização de Strings com Regex
-- Cenário: O campo nome_fantasia está "sujo" com documentos (CPF/CNPJ) concatenados no final.
-- Objetivo: Remover qualquer sequência numérica que esteja no fim da string.

SELECT 
    cnpj_basico,
    uf,
    
    -- O Problema: Nome original com "sujeira" numérica
    nome_fantasia as nome_original,
    
    -- A Solução: Regex para limpar
    -- [0-9]+  -> Busca um ou mais dígitos (0 a 9)
    -- $       -> Garante que eles estejam EXATAMENTE no final do texto
    -- ''      -> Substitui por vazio (remove)
    TRIM(REGEXP_REPLACE(nome_fantasia, '[0-9]+$', '')) as nome_limpo
    
FROM stg_empresas_import
WHERE 
    -- Filtro para o print: Mostrar apenas casos onde o problema existe
    nome_fantasia ~ '[0-9]+$' 
LIMIT 15;