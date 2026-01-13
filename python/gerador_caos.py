import argparse
import csv
import logging
import os
import random
import sys
from typing import Dict

# --- AJUSTE CRUCIAL: Caminhos alinhados com o volume do Docker (./dataset) ---
DEFAULT_INPUT = 'dataset/empresas_limpas.csv'
DEFAULT_OUTPUT = 'dataset/empresas_sujas.csv'
DEFAULT_DELIM = ';'

def gerar_cpf_falso(formatted: bool = False) -> str:
    nums = [str(random.randint(0, 9)) for _ in range(11)]
    raw = ''.join(nums)
    if not formatted:
        return raw
    return f"{raw[:3]}.{raw[3:6]}.{raw[6:9]}-{raw[9:]}"

def gerar_cnpj_falso(formatted: bool = False) -> str:
    nums = [str(random.randint(0, 9)) for _ in range(14)]
    raw = ''.join(nums)
    if not formatted:
        return raw
    return f"{raw[:2]}.{raw[2:5]}.{raw[5:8]}/{raw[8:12]}-{raw[12:]}"

def baguncar_capital(valor: str) -> str:
    if not valor:
        return "0,00"
    try:
        # Tenta limpar R$ e espaços antes de converter
        clean_val = valor.replace('R$', '').replace(' ', '')
        f_valor = float(clean_val.replace(',', '.'))
    except Exception:
        return valor # Retorna original se falhar

    # Randomly choose Brazilian formatting variants
    if random.random() < 0.5:
        # 50%: use comma decimal and dot thousand (1.000,00)
        s = f"{f_valor:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    else:
        # 50%: no thousand separator, comma decimal (1000,00)
        s = f"{f_valor:.2f}".replace('.', ',')
    return s

def criar_typo(texto: str) -> str:
    if not texto:
        return texto
    # keep short texts unchanged often
    if len(texto) < 4 and random.random() < 0.7:
        return texto

    ops = ['delete', 'insert', 'swap', 'substitute']
    op = random.choice(ops)
    i = random.randint(0, max(0, len(texto) - 1))

    if op == 'delete' and len(texto) > 1:
        return texto[:i] + texto[i+1:]
    if op == 'insert':
        ch = random.choice('aeiouábcdéfghijklmnopqrstuvxyzw')
        return texto[:i] + ch + texto[i:]
    if op == 'swap' and len(texto) > 1 and i < len(texto) - 1:
        lst = list(texto)
        lst[i], lst[i+1] = lst[i+1], lst[i]
        return ''.join(lst)
    if op == 'substitute':
        ch = random.choice('aeiouábcdéfghijklmnopqrstuvxyzw')
        return texto[:i] + ch + texto[i+1:]
    return texto

def aplicar_caos(row: Dict[str, str], probs: Dict[str, float], name_key: str, capital_key: str) -> Dict[str, str]:
    nova_row = row.copy()
    
    # 1. Bagunça no NOME (Razão Social ou Nome Fantasia)
    nome = (nova_row.get(name_key, '') or '').strip()
    r = random.random()
    
    if r < probs.get('append_cpf', 0.20):
        # Cenário MEI: Nome + CPF no final
        nova_row[name_key] = f"{nome} {gerar_cpf_falso()}" if nome else gerar_cpf_falso()
    else:
        r2 = random.random()
        if r2 < probs.get('typo', 0.10):
            # Erro de digitação
            nova_row[name_key] = criar_typo(nome)
        elif r2 < probs.get('typo', 0.20):
            # Case chaos (tudo minúsculo)
            nova_row[name_key] = nome.lower()
        elif r2 < probs.get('typo', 0.25):
            # Erro de Copiar/Colar: CNPJ no início do nome
            cnpj = nova_row.get('CNPJ BASICO', '') or nova_row.get('CNPJ_BASICO', '') or nova_row.get('CNPJ', '') or gerar_cnpj_falso()
            nova_row[name_key] = f"{cnpj} {nome}".strip()

    # 2. Bagunça no CAPITAL SOCIAL
    if capital_key and capital_key in nova_row:
        nova_row[capital_key] = baguncar_capital(nova_row.get(capital_key, ''))

    return nova_row

def parse_args():
    p = argparse.ArgumentParser(description='Gerador de "caos" para CSV de empresas')
    p.add_argument('--input', '-i', default=DEFAULT_INPUT)
    p.add_argument('--output', '-o', default=DEFAULT_OUTPUT)
    p.add_argument('--delim', '-d', default=DEFAULT_DELIM)
    p.add_argument('--seed', type=int, default=None, help='Semente aleatória (opcional)')
    p.add_argument('--verbose', '-v', action='store_true')
    p.add_argument('--limit', type=int, default=0, help='Processar no máximo N linhas (0 = sem limite)')
    p.add_argument('--validate-only', action='store_true', help='Somente validar o arquivo de saída existente e sair')
    return p.parse_args()

def main():
    args = parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, format='%(levelname)s: %(message)s')

    if args.seed is not None:
        random.seed(args.seed)

    logging.info(f"Lendo de: {args.input}")

    if not os.path.exists(args.input):
        logging.error("Arquivo de entrada não encontrado: %s", args.input)
        logging.info("DICA: Crie a pasta 'dataset' e coloque um arquivo 'empresas_limpas.csv' dentro dela.")
        sys.exit(2)

    os.makedirs(os.path.dirname(args.output) or '.', exist_ok=True)

    probs = {'append_cpf': 0.20, 'typo': 0.10}

    try:
        csv.field_size_limit(sys.maxsize)
    except Exception:
        pass

    encoding = 'utf-8'
    try:
        with open(args.input, 'rb') as fh:
            sample = fh.read(10000)
            sample.decode('utf-8')
    except Exception:
        encoding = 'latin-1'
    
    logging.info(f"Encoding detectado: {encoding}")

    with open(args.input, mode='r', encoding=encoding, errors='strict') as infile:
        header_line = infile.readline()
        if not header_line:
            logging.error("CSV vazio ou sem header.")
            sys.exit(3)
        try:
            fieldnames = next(csv.reader([header_line], delimiter=args.delim))
        except Exception:
            logging.error("Falha ao interpretar cabeçalho.")
            sys.exit(3)

        with open(args.output, mode='w', encoding='utf-8', newline='') as outfile:
            writer = csv.DictWriter(outfile, fieldnames=fieldnames, delimiter=args.delim, quoting=csv.QUOTE_ALL)
            writer.writeheader()

            norm_map = {(''.join(ch for ch in f.lower() if ch.isalnum())): f for f in fieldnames}
            
            preferred_name = None
            for cand in ('razaosocial', 'nomefantasia', 'nomerazao', 'nome', 'razao'):
                if cand in norm_map:
                    preferred_name = norm_map[cand]
                    break
            if not preferred_name:
                preferred_name = fieldnames[1] if len(fieldnames) > 1 else fieldnames[0]
            
            preferred_capital = None
            for cand in ('capital', 'capitalsocial', 'capitalsocialdaempresa', 'valor', 'capitalizacao'):
                if cand in norm_map:
                    preferred_capital = norm_map[cand]
                    break
            
            logging.info(f"Coluna alvo para nomes: '{preferred_name}'")
            logging.info(f"Coluna alvo para capital: '{preferred_capital}'")

            def _process(infile_handle):
                nonlocal probs
                rdr = csv.DictReader(infile_handle, fieldnames=fieldnames, delimiter=args.delim)
                c = 0
                for row in rdr:
                    try:
                        row_suja = aplicar_caos(row, probs, preferred_name, preferred_capital) # type: ignore
                        out = {k: (row_suja.get(k, '') or '') for k in fieldnames}
                        writer.writerow(out)
                    except Exception as e:
                        if c % 10000 == 0:
                            logging.debug('Erro linha %d: %s', c + 1, e)
                    c += 1
                    if args.limit and c >= args.limit:
                        break
                return c

            try:
                count = _process(infile)
            except UnicodeDecodeError:
                logging.warning('Falha UTF-8 no meio do arquivo, tentando latin-1...')
                infile.close()
                with open(args.input, mode='r', encoding='latin-1', errors='replace') as infile_alt:
                    _ = infile_alt.readline()
                    count = _process(infile_alt)

    logging.info('Sucesso! %d linhas geradas em: %s', count, args.output)

    if not (os.path.exists(args.output) and os.path.getsize(args.output) > 50):
        logging.error("O arquivo de saída parece vazio ou inválido.")
        sys.exit(4)

if __name__ == '__main__':
    main()