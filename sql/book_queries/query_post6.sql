SELECT 
    nome_fantasia,
    'COMERCIO' AS termo_alvo,
    -- O Soundex gera o código (ex: C562), o Difference compara os códigos
    SOUNDEX(nome_fantasia) AS soundex_code,
    -- A Métrica: 4 = Som Idêntico, 0 = Som Diferente
    DIFFERENCE(nome_fantasia, 'COMERCIO') AS nota_0_a_4
FROM stg_empresas_import
WHERE 
    nome_fantasia IS NOT NULL
    -- Filtra apenas quem tem som muito parecido (Nota 3 ou 4)
    AND DIFFERENCE(nome_fantasia, 'COMERCIO') >= 3
    -- TRUQUE: Exclui quem escreveu corretamente "COMERCIO"
    -- Assim sobram apenas os erros: "KOMERCIO", "COMÉRCIO", "COMERSSIO"
    AND nome_fantasia NOT ILIKE '%COMERCIO%'
ORDER BY 
    nota_0_a_4 DESC, -- Mostra os "Matches Perfeitos" primeiro
    RANDOM()
LIMIT 20;