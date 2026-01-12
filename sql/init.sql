DROP TABLE IF EXISTS stg_empresas_import;

-- Staging table matches the CSV header produced by python/gerador_caos.py
CREATE TABLE stg_empresas_import (
    cnpj_basico                 TEXT,
    cnpj_ordem                  TEXT,
    cnpj_dv                     TEXT,
    identificador               TEXT,
    nome_fantasia               TEXT,
    situacao_cadastral          TEXT,
    data_situacao_cadastral     TEXT,
    motivo_situacao_cadastral   TEXT,
    nome_da_cidade_no_exterior  TEXT,
    pais                        TEXT,
    data_de_inicio_atividade    TEXT,
    cnae_fiscal_principal       TEXT,
    cnae_fiscal_secundaria      TEXT,
    tipo_de_logradouro          TEXT,
    logradouro                  TEXT,
    numero                      TEXT,
    complemento                 TEXT,
    bairro                      TEXT,
    cep                         TEXT,
    uf                          TEXT,
    municipio                   TEXT
);

-- Use COPY FROM PROGRAM to strip any embedded NULL bytes that would break UTF-8
COPY stg_empresas_import (
    cnpj_basico,
    cnpj_ordem,
    cnpj_dv,
    identificador,
    nome_fantasia,
    situacao_cadastral,
    data_situacao_cadastral,
    motivo_situacao_cadastral,
    nome_da_cidade_no_exterior,
    pais,
    data_de_inicio_atividade,
    cnae_fiscal_principal,
    cnae_fiscal_secundaria,
    tipo_de_logradouro,
    logradouro,
    numero,
    complemento,
    bairro,
    cep,
    uf,
    municipio
)
FROM PROGRAM 'tr "\000" " " < /docker-entrypoint-initdb.d/empresas_sujas.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    QUOTE '"',
    ENCODING 'UTF8'
);

