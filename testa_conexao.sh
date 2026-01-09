#!/bin/bash
# Script: Teste de Conexão e Diagnóstico de Rede
# Atualizado para 2025/2026

# --- Cores ---
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
AZUL="\033[1;34m"
NORMAL="\033[m"

# --- Variáveis de Teste ---
ALVO_DNS="www.google.com.br"
ALVO_IP="8.8.8.8" # Google DNS (Testa se há saída para internet sem depender de nomes)

# --- Função de Animação (Visual) ---
aguarde() {
    echo -ne "${AZUL}Testando conexão... Aguarde ${NORMAL}"
    for i in {1..3}; do
        echo -ne "."
        sleep 0.5
    done
    echo ""
}

# --- Função Principal ---
testar_conexao() {
    clear
    echo -e "${AZUL}========================================${NORMAL}"
    echo -e "${AZUL}      DIAGNÓSTICO DE REDE              ${NORMAL}"
    echo -e "${AZUL}========================================${NORMAL}"
    echo
    
    aguarde

    # Teste 1: Ping via Domínio (Testa DNS + Internet)
    # -c 3: Envia 3 pacotes
    # -W 2: Espera no máximo 2 segundos pela resposta
    if ping -c 3 -W 2 "$ALVO_DNS" &> /dev/null; then
        echo -e "[ ${VERDE}OK${NORMAL} ] Conexão com a Internet (DNS funcionando)."
        echo -e "        Latência média aceitável."
        return 0
    else
        echo -e "[ ${VERMELHO}FALHA${NORMAL} ] Não foi possível conectar a $ALVO_DNS."
        echo -e "          Tentando teste direto via IP..."
        
        # Teste 2: Ping via IP (Testa apenas Rota/Cabo)
        if ping -c 3 -W 2 "$ALVO_IP" &> /dev/null; then
            echo
            echo -e "[ ${AMARELO}ALERTA${NORMAL} ] Conexão IP funciona, mas DNS falhou!"
            echo -e "           Você tem internet, mas não consegue navegar por nomes."
            echo -e "           Sugestão: Verifique seu /etc/resolv.conf ou reinicie o roteador."
        else
            echo
            echo -e "[ ${VERMELHO}CRÍTICO${NORMAL} ] Sem conexão com a Internet."
            echo -e "            Nem via nome, nem via IP. Verifique cabos ou Wi-Fi."
        fi
        return 1
    fi
}

# --- Menu / Loop Principal ---
while true; do
    clear
    echo "Bem-vindo ao Teste de Conexão."
    echo
    read -n1 -p "Iniciar o teste? (s/n): " escolha
    echo

    case $escolha in
        s|S)
            testar_conexao
            ;;
        n|N)
            echo -e "${AZUL}Saindo...${NORMAL}"
            exit 0
            ;;
        *)
            echo "Opção inválida."
            sleep 1
            continue
            ;;
    esac

    # Pergunta se quer repetir após o teste
    echo
    echo -e "${AZUL}----------------------------------------${NORMAL}"
    read -n1 -p "Deseja realizar um novo teste? (s/n): " repetir
    echo
    if [[ "$repetir" != "s" && "$repetir" != "S" ]]; then
        echo -e "${AZUL}Finalizando script.${NORMAL}"
        exit 0
    fi
done