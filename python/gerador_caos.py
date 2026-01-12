import argparse
import csv
import logging
import os
import random
import sys
from typing import Dict


DEFAULT_INPUT = 'data/empresas_limpas.csv'
DEFAULT_OUTPUT = 'data/empresas_sujas.csv'
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
        f_valor = float(valor.replace(',', '.'))
    except Exception:
        return valor

    # Randomly choose Brazilian formatting variants
    if random.random() < 0.5:
        # 50%: use comma decimal and dot thousand
        s = f"{f_valor:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
    else:
        # 50%: no thousand separator, comma decimal
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


def aplicar_caos(row: Dict[str, str], probs: Dict[str, float], name_key: str) -> Dict[str, str]:
    nova_row = row.copy()
    # ensure we operate on an existing column (name_key)
    nome = (nova_row.get(name_key, '') or '').strip()

    r = random.random()
    if r < probs.get('append_cpf', 0.20):
        nova_row[name_key] = f"{nome} {gerar_cpf_falso()}" if nome else gerar_cpf_falso()
    else:
        r2 = random.random()
        if r2 < probs.get('typo', 0.10):
            nova_row[name_key] = criar_typo(nome)
        elif r2 < probs.get('typo', 0.20):
            nova_row[name_key] = nome.lower()
        elif r2 < probs.get('typo', 0.25):
            cnpj = nova_row.get('CNPJ BASICO', '') or nova_row.get('CNPJ_BASICO', '') or nova_row.get('CNPJ', '') or gerar_cnpj_falso()
            nova_row[name_key] = f"{cnpj} {nome}".strip()

    # CAPITAL
    if 'CAPITAL' in nova_row:
        nova_row['CAPITAL'] = baguncar_capital(nova_row.get('CAPITAL', ''))

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
        sys.exit(2)

    os.makedirs(os.path.dirname(args.output) or '.', exist_ok=True)

    probs = {'append_cpf': 0.20, 'typo': 0.10}

    # allow very large CSV fields
    try:
        csv.field_size_limit(sys.maxsize)
    except Exception:
        pass

    # open with utf-8, fallback to latin-1 if needed
    # detect encoding by sampling a chunk
    encoding = 'utf-8'
    try:
        with open(args.input, 'rb') as fh:
            sample = fh.read(10000)
            sample.decode('utf-8')
    except Exception:
        encoding = 'latin-1'

    with open(args.input, mode='r', encoding=encoding, errors='strict') as infile:
        # read header line without creating a DictReader that would consume it
        header_line = infile.readline()
        if not header_line:
            logging.error("Input CSV '%s' does not contain a header row or is empty.", args.input)
            sys.exit(3)
        try:
            fieldnames = next(csv.reader([header_line], delimiter=args.delim))
        except Exception:
            logging.error("Falha ao interpretar o cabeçalho CSV de: %s", args.input)
            sys.exit(3)

        with open(args.output, mode='w', encoding='utf-8', newline='') as outfile:
            writer = csv.DictWriter(outfile, fieldnames=fieldnames, delimiter=args.delim, quoting=csv.QUOTE_ALL)
            writer.writeheader()

            # build normalized map to find best name column
            norm_map = {(''.join(ch for ch in f.lower() if ch.isalnum())): f for f in fieldnames}
            preferred = None
            for cand in ('razaosocial', 'nomefantasia', 'nomerazao', 'nome'):
                if cand in norm_map:
                    preferred = norm_map[cand]
                    break
            if not preferred:
                # fallback to first field that contains 'nome' or 'razao'
                for f in fieldnames:
                    lf = f.lower()
                    if 'nome' in lf or 'razao' in lf:
                        preferred = f
                        break
            if not preferred:
                preferred = fieldnames[0]

            def _process(infile_handle):
                nonlocal probs
                # infile_handle is expected to be positioned at the first data row
                rdr = csv.DictReader(infile_handle, fieldnames=fieldnames, delimiter=args.delim)
                c = 0
                for row in rdr:
                    try:
                        row_suja = aplicar_caos(row, probs, preferred)
                        # sanitize row: ensure only expected fieldnames are written
                        out = {k: (row_suja.get(k, '') or '') for k in fieldnames}
                        writer.writerow(out)
                    except Exception as e:
                        # log sparse errors only
                        if c % 10000 == 0:
                            logging.debug('Erro processando linha %d: %s', c + 1, e)
                    c += 1
                    if args.limit and c >= args.limit:
                        break
                return c

            # try processing with the detected encoding; on UnicodeDecodeError, retry with latin-1
            try:
                # infile is currently after the header line, so pass it directly
                count = _process(infile)
            except UnicodeDecodeError:
                logging.warning('Decodificação falhou com %s, tentando latin-1', encoding)
                infile.close()
                with open(args.input, mode='r', encoding='latin-1', errors='replace') as infile_alt:
                    # consume header line in the alternate handle
                    _ = infile_alt.readline()
                    count = _process(infile_alt)

    logging.info('Sucesso! %d linhas processadas e bagunçadas em: %s', count, args.output)

    # validation: ensure output actually contains data rows beyond header
    def validate_output(path: str) -> bool:
        if not os.path.exists(path):
            logging.error('Arquivo de saída não encontrado: %s', path)
            return False
        try:
            size = os.path.getsize(path)
            if size < 32:
                logging.error('Arquivo de saída muito pequeno (%d bytes): %s', size, path)
                return False
            with open(path, 'r', encoding='utf-8', errors='replace') as fh:
                # read header
                header = fh.readline()
                # read next non-empty line
                for _ in range(10):
                    line = fh.readline()
                    if not line:
                        break
                    if line.strip():
                        return True
                logging.error('Arquivo de saída contém apenas o cabeçalho: %s', path)
                return False
        except Exception as e:
            logging.error('Erro validando arquivo de saída: %s', e)
            return False

    ok = validate_output(args.output)
    if not ok:
        logging.error('Validação falhou: o arquivo de saída parece vazio ou inválido')
        sys.exit(4)


if __name__ == '__main__':
    args = parse_args()
    if args.validate_only:
        logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
        # run only validation on the output file
        def _validate_only():
            path = args.output
            if not os.path.exists(path):
                logging.error('Arquivo de saída não encontrado: %s', path)
                sys.exit(2)
            try:
                with open(path, 'r', encoding='utf-8', errors='replace') as fh:
                    header = fh.readline()
                    for _ in range(10):
                        line = fh.readline()
                        if line and line.strip():
                            logging.info('Validação OK: arquivo contém dados além do cabeçalho')
                            sys.exit(0)
                logging.error('Validação falhou: arquivo contém apenas o cabeçalho')
                sys.exit(4)
            except Exception as e:
                logging.error('Erro abrindo arquivo de saída: %s', e)
                sys.exit(3)
        _validate_only()
    else:
        main()