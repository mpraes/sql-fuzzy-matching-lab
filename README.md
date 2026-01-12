# 💊 SQL Pílulas: Laboratório de Data Quality & Fuzzy Matching

Este repositório contém um ambiente completo de Engenharia de Dados focado em limpeza, padronização e deduplicação de dados (**Fuzzy Matching**) utilizando **PostgreSQL**.

O projeto foi desenhado para acompanhar a série de posts **#sqlpilulas** no LinkedIn.

## 🎯 O Objetivo

Simular um cenário real onde recebemos dados "sujos" de cadastro de empresas (CNPJs) e precisamos saneá-los utilizando apenas recursos nativos do banco de dados, sem ferramentas externas de ETL.

Baseado em conceitos do livro *Fuzzy Data Matching with SQL* e adaptado para cenários brasileiros (CNPJ, CPF, Acentuação).

## 🛠️ Stack

- **Banco de Dados:** PostgreSQL 16
- **Infraestrutura:** Docker & Docker Compose
- **Gerador de Dados:** Python 3 (Native libraries)

## 🚀 Como Rodar

### Pré-requisitos
- Docker e Docker Compose instalados
- Python 3.11+ (para gerar o CSV)

### Passo a Passo

#### 1️⃣ Clone o Repositório

```bash
git clone [https://github.com/SEU_USUARIO/sql-fuzzy-lab.git](https://github.com/SEU_USUARIO/sql-fuzzy-lab.git)
cd sql-fuzzy-lab
```

#### 2️⃣ Gere o Caos (CSV Sujo)

Use o script em `python/gerador_caos.py` para gerar dados de teste:

```bash
# Gerar tudo (~4.7M linhas, pode levar alguns minutos)
python3 python/gerador_caos.py --seed 42

# Teste rápido com limite (1.000 linhas)
python3 python/gerador_caos.py --seed 42 --limit 1000

# Validar um CSV já gerado
python3 python/gerador_caos.py --validate-only --output data/empresas_sujas.csv
```

Saída esperada: `data/empresas_sujas.csv` (delimitador `;`, com header)

#### 3️⃣ Suba o Banco de Dados

```bash
docker compose up -d
```

O arquivo `docker-compose.yml` automaticamente:
- Monta `./sql/init.sql` na inicialização do BD
- Carrega `./data/empresas_sujas.csv` via `COPY` com tratamento de encoding

> **Importante:** Gere `data/empresas_sujas.csv` **antes** de `docker compose up`, pois o `init.sql` executa na inicialização.

#### 4️⃣ Conecte-se e Divirta-se 🎉

```bash
Host:       localhost
Port:       5432
User:       admin
Password:   sqlpilulas_pass
Database:   cnpj_lab
```

Teste a conexão:

```bash
docker compose exec -T database psql -U admin -d cnpj_lab -c "SELECT count(*) FROM stg_empresas_import;"
```

## 📚 Tópicos Cobertos

- [x] Infraestrutura como Código (Docker)
- [x] Gerador de Dados Sujos (Python + CSV)
- [x] Carregamento em Staging (PostgreSQL COPY)
- [ ] Padronização de Strings (TRIM, UPPER, UNACCENT)
- [ ] Limpeza de Máscaras e RegEx
- [ ] Algoritmos Fonéticos (Soundex)
- [ ] Distância de Edição (Levenshtein)
- [ ] Deduplicação de Registros

## 🔧 Operações Avançadas

### Recarregar Dados Manualmente

Se precisar recarregar sem recriar o container:

```bash
cat <<'SQL' | docker compose exec -T database psql -U admin -d cnpj_lab
TRUNCATE stg_empresas_import;
COPY stg_empresas_import (
    cnpj_basico, cnpj_ordem, cnpj_dv, identificador, nome_fantasia,
    situacao_cadastral, data_situacao_cadastral, motivo_situacao_cadastral,
    nome_da_cidade_no_exterior, pais, data_de_inicio_atividade,
    cnae_fiscal_principal, cnae_fiscal_secundaria, tipo_de_logradouro,
    logradouro, numero, complemento, bairro, cep, uf, municipio
) FROM PROGRAM 'tr "\000" " " < /docker-entrypoint-initdb.d/empresas_sujas.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', QUOTE '"', ENCODING 'UTF8');
SQL
```

> Nota: O `tr` remove bytes nulos que causariam erro de encoding UTF-8.

### Limpar e Recomeçar

```bash
docker compose down -v
docker compose up -d
```

## 📝 Notas

- A tabela `stg_empresas_import` usa colunas `TEXT` para aceitar dados "sujos"
- Se mudar o caminho do CSV ou delimitador, ajuste `sql/init.sql` e `docker-compose.yml`
- O script Python inclui várias transformações ("caos"): typos, formatações brasileiras, CPF colado, etc.

---

**Desenvolvido para aprender Data Quality e Fuzzy Matching com SQL puro.** 🚀
