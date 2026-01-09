#!/bin/bash
# Script: Pós-Instalação Debian 12 (Bookworm) e superiores
# Atualizado para padrões modernos (2025/2026)

# --- Variáveis de Cores ---
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
NORMAL="\033[m"

# --- 1. Verificação de Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}Erro: Execute como root.${NORMAL}"
   echo -e "Use: ${VERDE}sudo $0${NORMAL}"
   exit 1
fi

# --- 2. Verificação da Distribuição ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "debian" ]]; then
        echo -e "${VERMELHO}Atenção: Este script foi feito para DEBIAN puro.${NORMAL}"
        echo -e "Seu sistema parece ser: $NAME"
        echo "Pressionar ENTER para continuar por sua conta e risco ou CTRL+C para cancelar."
        read
    fi
else
    echo -e "${VERMELHO}Não foi possível identificar a distribuição.${NORMAL}"
    exit 1
fi

CODENAME=$(lsb_release -sc)

menu() {
    clear
    echo -e "${AZUL}=============================================${NORMAL}"
    echo -e "${AZUL}   PÓS-INSTALAÇÃO DEBIAN ($VERSION_CODENAME)  ${NORMAL}"
    echo -e "${AZUL}=============================================${NORMAL}"
    echo
    echo -e "Programas a instalar:"
    echo -e " - ${VERDE}Essenciais:${NORMAL} Curl, Wget, GPG, Drivers Non-Free"
    echo -e " - ${VERDE}Web:${NORMAL} Google Chrome (Repo Oficial), Firefox ESR"
    echo -e " - ${VERDE}Multimídia:${NORMAL} VLC, Audacious, Codecs (FFmpeg), Fontes MS"
    echo -e " - ${VERDE}Utils:${NORMAL} Java (OpenJDK), 7zip, Bleachbit"
    echo
    echo -e "${AMARELO}Nota: O Flash Player foi removido (obsoleto).${NORMAL}"
    echo
    echo -e "${AZUL}Deseja iniciar a instalação? (s/n)${NORMAL}"
    read -n1 -s escolha

    case $escolha in
        S|s) iniciar_instalacao ;;
        N|n) echo; echo "Saindo..."; exit 0 ;;
        *) menu ;;
    esac
}

configurar_repositorios() {
    echo
    echo -e "${AZUL}>>> Configurando Sources.list (Main Contrib Non-Free)...${NORMAL}"
    
    # Backup da original
    if [ ! -f /etc/apt/sources.list.backup ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
        echo "Backup criado em sources.list.backup"
    fi

    # Configura repositórios oficiais com suporte a firmware proprietário (necessário no Debian 12+)
    cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free non-free-firmware
EOF
}

adicionar_chrome() {
    echo -e "${AZUL}>>> Adicionando repositório do Google Chrome...${NORMAL}"
    # Método moderno (sem apt-key deprecated)
    if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg > /dev/null
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
    fi
}

iniciar_instalacao() {
    configurar_repositorios
    adicionar_chrome

    echo
    echo -e "${AZUL}>>> Atualizando lista de pacotes...${NORMAL}"
    apt update

    echo
    echo -e "${AZUL}>>> Instalando Pacotes...${NORMAL}"