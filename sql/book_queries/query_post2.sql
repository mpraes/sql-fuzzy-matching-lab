-- #sqlpilulas - Dia 2: Limpeza de Pontuação com TRANSLATE
-- Problema: "Sujeira" de formatação (. - /) impede o match exato
-- Solução: Substituir REPLACE aninhado por TRANSLATE (mais rápido e limpo)

SELECT 
    cnpj_basico,
    
    -- Cenário 1: Nome Fantasia com pontuação variada
    nome_fantasia as nome_original,
    -- Remove ponto, traço e barra de uma vez só
    TRANSLATE(nome_fantasia, '.-/', '') as nome_limpo,
    
    -- Cenário 2: CEP (Muitos sistemas salvam com máscara, outros sem)
    cep as cep_original,
    -- Remove ponto, traço e espaço em branco
    TRANSLATE(cep, '.- ', '') as cep_numerico,

    -- Comparação: O jeito "Feio" (Replace aninhado) vs Jeito "Limpo"
    CASE 
        WHEN TRANSLATE(nome_fantasia, '.-/', '') = REPLACE(REPLACE(REPLACE(nome_fantasia, '.', ''), '-', ''), '/', '') 
        THEN 'Mesmo Resultado (Mas código mais limpo)' 
    END as validacao

FROM stg_empresas_import
WHERE nome_fantasia ~ '[.-/]' -- Filtra só quem tem pontuação para o exemplo
LIMIT 10;