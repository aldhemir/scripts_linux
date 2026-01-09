#!/bin/bash
# Script: Reset Seguro de Interface Gráfica (GNOME/Unity)
# Atualizado para 2025/2026 - Compatível com Ubuntu Moderno

# --- Variáveis de Cores ---
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
NORMAL="\033[m"

# --- 1. Verificação de Segurança (NÃO RODAR COMO ROOT) ---
if [[ $EUID -eq 0 ]]; then
   echo -e "${VERMELHO}ERRO CRÍTICO: Não execute este script como SUDO/ROOT!${NORMAL}"
   echo -e "As configurações de interface pertencem ao seu usuário comum."
   echo -e "Execute apenas: ${VERDE}./$0${NORMAL}"
   exit 1
fi

# --- 2. Identificação do Ambiente Gráfico ---
# Detecta se é GNOME (Ubuntu padrão) ou Unity (Ubuntu Unity Remix / Antigo)
AMBIENTE_ATUAL=$XDG_CURRENT_DESKTOP

menu() {
    clear
    echo -e "${AZUL}==============================================${NORMAL}"
    echo -e "${AZUL}     RESTAURAÇÃO DE INTERFACE GRÁFICA         ${NORMAL}"
    echo -e "${AZUL}==============================================${NORMAL}"
    echo
    echo -e "Ambiente detectado: ${AMARELO}$AMBIENTE_ATUAL${NORMAL}"
    echo
    echo -e "${VERMELHO}ATENÇÃO: Isso irá restaurar painéis, ícones, fontes e atalhos"
    echo -e "para o padrão de fábrica do Ubuntu.${NORMAL}"
    echo -e "Seus arquivos pessoais (Documentos, Fotos) NÃO serão afetados."
    echo
    echo -e "${AZUL}Deseja continuar? (s/n)${NORMAL}"

    read -n1 -s escolha

    case $escolha in
        S|s)
            reset_interface
            ;;
        N|n)
            echo
            echo -e "${AZUL}Operação Cancelada.${NORMAL}"
            exit 0
            ;;
        *)
            echo
            echo -e "${VERMELHO}Opção inválida.${NORMAL}"
            sleep 1
            menu
            ;;
    esac
}

reset_interface() {
    echo
    echo -e "${AMARELO}>>> Fechando configurações abertas...${NORMAL}"
    
    # Verifica se dconf-cli está instalado (geralmente já vem no Ubuntu)
    if ! command -v dconf &> /dev/null; then
        echo -e "${VERMELHO}Ferramenta dconf não encontrada. Tentando instalar...${NORMAL}"
        # Aqui precisamos de sudo apenas para instalar, caso falte
        sudo apt-get install dconf-cli -y
    fi

    echo -e "${VERDE}>>> Restaurando configurações...${NORMAL}"

    # Lógica baseada no ambiente detectado
    if [[ "$AMBIENTE_ATUAL" == *"GNOME"* || "$AMBIENTE_ATUAL" == *"ubuntu:GNOME"* ]]; then
        # Reset para GNOME (Ubuntu 20.04, 22.04, 24.04+)
        dconf reset -f /org/gnome/
        dconf reset -f /org/gnome/shell/
        dconf reset -f /org/gnome/desktop/
        
        # Opcional: Resetar extensões se estiverem bugadas
        # dconf reset -f /org/gnome/shell/extensions/
        
        echo -e "${VERDE}>>> Configurações do GNOME restauradas.${NORMAL}"
        
    elif [[ "$AMBIENTE_ATUAL" == *"Unity"* ]]; then
        # Reset para Unity (Ubuntu 16.04 ou Unity Remix)
        dconf reset -f /org/compiz/
        setsid unity
        
        echo -e "${VERDE}>>> Configurações do Unity restauradas.${NORMAL}"
    else
        echo -e "${VERMELHO}Ambiente não reconhecido ou não suportado automaticamente: $AMBIENTE_ATUAL${NORMAL}"
        echo "O script tentará um reset genérico do dconf."
        dconf reset -f /
    fi

    echo
    echo -e "${AZUL}>>> Processo finalizado.${NORMAL}"
    echo -e "${AMARELO}É ALTAMENTE recomendável fazer Logout ou Reiniciar agora para aplicar as mudanças.${NORMAL}"
    echo -e "Deseja reiniciar o computador agora? (s/n)"
    
    read -n1 -s reiniciar
    if [[ "$reiniciar" == "s" || "$reiniciar" == "S" ]]; then
        sudo reboot
    else
        echo
        echo -e "Ok. As alterações podem não aparecer até o próximo login."
    fi
}

menu