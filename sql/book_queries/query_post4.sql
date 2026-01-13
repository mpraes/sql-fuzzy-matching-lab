CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

SELECT 
    -- O Código Fonético (A "Assinatura de Voz" da palavra)
    METAPHONE(nome_fantasia, 6) AS codigo_fonetico,
    
    -- Quantas variações de escrita existem para esse mesmo som?
    COUNT(DISTINCT nome_fantasia) AS qtd_variacoes,
    
    -- A lista visual das variações (O "Ouro" do post)
    STRING_AGG(DISTINCT nome_fantasia, '  -  ') AS variacoes_agrupadas

FROM stg_empresas_import
WHERE 
    nome_fantasia IS NOT NULL 
    AND nome_fantasia <> ''
    -- Filtro para garantir que só veremos grupos com nomes REAIS (com letras)
    AND nome_fantasia ~ '[[:alpha:]]'
GROUP BY 
    METAPHONE(nome_fantasia, 6)
HAVING 
    -- A Mágica: Só me mostre grupos onde existem pelo menos 2 formas DIFERENTES de escrever
    COUNT(DISTINCT nome_fantasia) > 1
ORDER BY 
    RANDOM() -- Aleatório para pegar exemplos variados
LIMIT 20;