#!/bin/bash
# Script: Extrator de Dados de PDF para CSV
# Dependência: poppler-utils (pdftotext)

# --- Cores ---
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
NORMAL="\033[m"

# --- 1. Verificação de Dependências ---
if ! command -v pdftotext &> /dev/null; then
    echo -e "${VERMELHO}Erro: O comando 'pdftotext' não foi encontrado.${NORMAL}"
    echo -e "Instale-o rodando: ${VERDE}sudo apt install poppler-utils${NORMAL}"
    exit 1
fi

# --- 2. Preparação ---
ARQUIVO_SAIDA="relatorio_final.csv"
echo -e "${AMARELO}Iniciando extração...${NORMAL}"

# Cria o cabeçalho do CSV
# O separador é ponto e vírgula (;) para funcionar bem no Excel em PT-BR
echo "Arquivo;Dados Extraídos" > "$ARQUIVO_SAIDA"

# Verifica se existem PDFs
count_files=$(ls -1 *.pdf 2>/dev/null | wc -l)
if [ "$count_files" -eq 0 ]; then
    echo -e "${VERMELHO}Nenhum arquivo .pdf encontrado neste diretório.${NORMAL}"
    exit 0
fi

# --- 3. Processamento ---
for pdf in *.pdf; do
    echo -e "Processando: ${VERDE}$pdf${NORMAL}"
    
    # a) Extrai texto do PDF para um arquivo temporário oculto
    # A flag -layout tenta manter a formatação visual original
    pdftotext -layout "$pdf" .temp_text.txt
    
    # b) Filtra os dados, remove quebras de linha e limpa espaços extras
    # O comando tr '\n' '|' troca a quebra de linha por um pipe (|) para ficar tudo numa linha só
    DADOS=$(grep -E -i "Nome:|Endereço:|CEP:|Cidade:|E-mail:|Telefone:" .temp_text.txt | sed 's/  */ /g' | tr '\n' ' | ')
    
    # c) Salva no CSV (Nome do Arquivo + Ponto e Vírgula + Dados)
    echo "$pdf;$DADOS" >> "$ARQUIVO_SAIDA"
    
done

# --- 4. Limpeza e Finalização ---
rm -f .temp_text.txt
echo
echo -e "${VERDE}Sucesso!${NORMAL}"
echo -e "Os dados foram salvos em: ${AMARELO}$ARQUIVO_SAIDA${NORMAL}"