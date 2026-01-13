SELECT 
    cnpj_basico,
    nome_fantasia AS original,
    TRIM(
        REGEXP_REPLACE(
            nome_fantasia, 
            -- A "Guilhotina": achou o sufixo, corta tudo depois
            '\s+(LTDA|LIMITADA|ME|EPP|MEI|EIRELI|S\.?A\.?|S/A|S\.?C\.?|S/S|SOCIEDADE\s+ANONIMA)\M.*$', 
            '', 
            'gi'
        )
    ) AS nome_normalizado
FROM stg_empresas_import
WHERE 
    -- O FILTRO DE OURO: Só traz o que bate com a regra acima.
    -- Se a empresa for "MERCADO 12345", ela some daqui porque não tem "LTDA".
    nome_fantasia ~* '\s+(LTDA|LIMITADA|ME|EPP|MEI|EIRELI|S\.?A\.?|S/A|S\.?C\.?|S/S|SOCIEDADE\s+ANONIMA)\M'
ORDER BY 
    RANDOM()
LIMIT 20;