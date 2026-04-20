import logging
from datetime import datetime
import time
import random
import sys
import argparse
import os

def generate_log_entries(file_path):

    with open(file_path, 'r') as f:
        files = f.read().splitlines()
    
    for file in files:
        file = file.strip()
        
        # Verificar se o arquivo existe
        if not os.path.exists(file):
            raise FileNotFoundError(f"Arquivo de log não encontrado: '{file}'")
        
        # Verificar se é realmente um arquivo (não um diretório)
        if not os.path.isfile(file):
            raise ValueError(f"Caminho não é um arquivo válido: '{file}'")
        
        # Criar um logger separado para cada arquivo
        logger = logging.getLogger(file)
        logger.setLevel(logging.INFO)
        
        # Remover handlers anteriores para evitar duplicação
        logger.handlers.clear()
        
        # Criar handler para o arquivo
        handler = logging.FileHandler(file)
        formatter = logging.Formatter('%(asctime)s level=%(levelname)s app=myapp component=%(component)s %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        components = ["database", "backend"]

        for _ in range(10):
            log_level = logging.INFO if _ % 3 == 0 else logging.WARNING if _ % 3 == 1 else logging.ERROR
            component = random.choice(components)

            print(f"Generating log of type {logging.getLevelName(log_level)} with component {component} in file {file}")

            if log_level == logging.INFO:
                log_message = "Information: Application running normally"
            elif log_level == logging.WARNING:
                log_message = "Warning: Resource usage high"
            else:
                log_message = "Critical error: Database connection lost"

            # Use o logger específico do arquivo com informacao extra do componente
            logger.log(log_level, log_message, extra={"component": component})
            time.sleep(1)  # Sleep for 1 second between entries

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Gera logs em múltiplos arquivos em loop contínuo')
    parser.add_argument('--config', 
                        default='./directories.txt',
                        help='Caminho do arquivo de configuração com lista de arquivos de log')
    parser.add_argument('--interval',
                        type=int,
                        default=30,
                        help='Intervalo em segundos entre cada ciclo de geração de logs (padrão: 30)')
    parser.add_argument('--once',
                        action='store_true',
                        help='Gera logs apenas uma vez (sem loop)')
    
    args = parser.parse_args()
    
    try:
        if args.once:
            # Modo única execução
            print("Gerando logs (modo única execução)...")
            generate_log_entries(args.config)
            print("Concluído!")
        else:
            # Modo loop contínuo
            print(f"Iniciando geração de logs em loop (intervalo: {args.interval}s)...")
            print("Pressione Ctrl+C para parar.")
            cycle = 0
            while True:
                cycle += 1
                print(f"\n--- Ciclo {cycle} ({datetime.now().strftime('%H:%M:%S')}) ---")
                try:
                    generate_log_entries(args.config)
                    print(f"Ciclo {cycle} concluído. Aguardando {args.interval}s...")
                    time.sleep(args.interval)
                except Exception as e:
                    print(f"Erro no ciclo {cycle}: {e}")
                    print(f"Tentando novamente em {args.interval}s...")
                    time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\n\n✓ Geração de logs interrompida pelo usuário")
        sys.exit(0)
    except FileNotFoundError as e:
        print(f"Erro: {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"Erro: {e}")
        sys.exit(1)
    finally:
        logging.shutdown()