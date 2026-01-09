#!/bin/bash
# Atualizado em: 2026
# Script de Instalação do Popcorn Time (Community Edition)
# Autor Original: Aldhemir

# --- Cores para saída ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Variáveis de Configuração ---
# NOTA: O Popcorn Time muda de URL frequentemente. Verifique se esta URL está ativa.
# Esta URL abaixo é um exemplo comum de repositório comunitário.
URL_BASE="https://get.popcorntime.app/build" 
INSTALL_DIR="/opt/popcorntime"
BIN_LINK="/usr/bin/popcorntime"
DESKTOP_FILE="/usr/share/applications/popcorntime.desktop"

# --- Verificação de Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado como ROOT (sudo).${NC}"
   echo "Use: sudo ./install_popcorn.sh"
   exit 1
fi

# --- Funções ---

get_desktop_dir() {
    # Tenta descobrir o diretório da área de trabalho independente do idioma
    if [ -f ~/.config/user-dirs.dirs ]; then
        source ~/.config/user-dirs.dirs
        echo "${XDG_DESKTOP_DIR:-$HOME/Desktop}"
    else
        echo "$HOME/Desktop"
    fi
}

check_connection() {
    echo -e "${YELLOW}Verificando conexão com a internet...${NC}"
    if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}Conexão OK.${NC}"
        return 0
    else
        echo -e "${RED}Sem conexão com a internet.${NC}"
        read -p "Deseja tentar novamente? (s/n): " -n 1 escolha
        echo
        case $escolha in
            s|S) check_connection ;;
            *) echo "Saindo..."; exit 1 ;;
        esac
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Instalando dependências necessárias (libnss3, canberra, etc)...${NC}"
    # Dependências comuns para rodar apps Electron/NWjs em Linux moderno
    apt-get update -qq
    apt-get install -y wget tar xz-utils libnss3 libgconf-2-4 libcanberra-gtk-module libxss1
}

download_and_install() {
    check_connection
    install_dependencies

    ARCH=$(uname -m)
    echo -e "${YELLOW}Arquitetura detectada: $ARCH${NC}"

    # Define URL baseada na arquitetura
    if [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="${URL_BASE}/Popcorn-Time-0.4.9-linux64.zip"
        # Nota: Versões mais recentes usam .zip ou .AppImage. Ajustei para .zip que é comum nas builds atuais.
    elif [[ "$ARCH" == "i686" || "$ARCH" == "i386" ]]; then
        DOWNLOAD_URL="${URL_BASE}/Popcorn-Time-0.4.9-linux32.zip"
    else
        echo -e "${RED}Arquitetura $ARCH não suportada oficialmente.${NC}"
        exit 1
    fi

    # Preparar diretório temporário
    TMP_DIR=$(mktemp -d)
    
    echo -e "${YELLOW}Baixando de: $DOWNLOAD_URL${NC}"
    if wget --show-progress -O "$TMP_DIR/popcorn.zip" "$DOWNLOAD_URL"; then
        echo -e "${GREEN}Download concluído.${NC}"
    else
        echo -e "${RED}Falha no download. Verifique a URL ou sua conexão.${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Instalação
    echo "Extraindo arquivos..."
    
    # Remove instalação anterior se existir para evitar conflito
    if [ -d "$INSTALL_DIR" ]; then rm -rf "$INSTALL_DIR"; fi
    
    mkdir -p "$INSTALL_DIR"
    unzip -o "$TMP_DIR/popcorn.zip" -d "$INSTALL_DIR" > /dev/null
    
    # Link simbólico
    ln -sf "$INSTALL_DIR/Popcorn-Time" "$BIN_LINK"

    # Criar atalho no Menu
    echo "Criando atalho..."
    
    # Baixar um ícone se não existir (opcional, mas bom para garantir)
    if [ ! -f "$INSTALL_DIR/src/app/images/icon.png" ]; then
         # Tenta usar o ícone que vem no pacote, se não, baixa um genérico
         wget -q https://upload.wikimedia.org/wikipedia/commons/d/df/Popcorn_Time_logo.png -O "$INSTALL_DIR/icon.png"
         ICON_PATH="$INSTALL_DIR/icon.png"
    else
         ICON_PATH="$INSTALL_DIR/src/app/images/icon.png"
    fi

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=Popcorn Time
Comment=Watch Movies and TV Shows instantly
Exec=$BIN_LINK
Icon=$ICON_PATH
Type=Application
Categories=AudioVideo;Player;Recorder;
Terminal=false
EOF

    chmod +x "$DESKTOP_FILE"

    # Copiar para o Desktop do usuário real (não do root)
    # Detecta o usuário que chamou o sudo
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    # Tenta achar o diretório desktop correto
    if [ -f "$USER_HOME/.config/user-dirs.dirs" ]; then
        source "$USER_HOME/.config/user-dirs.dirs"
        DESKTOP_DIR="${XDG_DESKTOP_DIR:-$USER_HOME/Desktop}"
        # Substitui $HOME pelo caminho real se necessário
        DESKTOP_DIR=${DESKTOP_DIR/"$HOME"/$USER_HOME}
    else
        DESKTOP_DIR="$USER_HOME/Desktop"
    fi

    if [ -d "$DESKTOP_DIR" ]; then
        cp "$DESKTOP_FILE" "$DESKTOP_DIR/"
        chown "$REAL_USER":"$REAL_USER" "$DESKTOP_DIR/popcorntime.desktop"
        chmod +x "$DESKTOP_DIR/popcorntime.desktop"
    fi

    # Limpeza
    rm -rf "$TMP_DIR"
    
    echo
    echo -e "${GREEN}Instalação Concluída com Sucesso!${NC}"
    echo "Você pode digitar 'popcorntime' no terminal ou buscar no menu."
}

remove_app() {
    echo -e "${YELLOW}Removendo Popcorn Time...${NC}"
    
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_LINK"
    rm -f "$DESKTOP_FILE"
    
    # Tenta remover configurações do usuário (requer cuidado pois estamos como root)
    REAL_USER=${SUDO_USER:-$USER}
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    rm -rf "$USER_HOME/.config/Popcorn-Time"
    rm -rf "$USER_HOME/.cache/Popcorn-Time"
    rm -rf "$USER_HOME/.local/share/applications/popcorntime.desktop"
    
    # Tenta remover do Desktop
    if [ -f "$USER_HOME/.config/user-dirs.dirs" ]; then
        source "$USER_HOME/.config/user-dirs.dirs"
        DESKTOP_DIR="${XDG_DESKTOP_DIR:-$USER_HOME/Desktop}"
        DESKTOP_DIR=${DESKTOP_DIR/"$HOME"/$USER_HOME}
        rm -f "$DESKTOP_DIR/popcorntime.desktop"
    fi

    echo -e "${GREEN}Remoção Concluída.${NC}"
}

# --- Menu Principal ---
clear
echo "========================================"
echo "   Instalador Popcorn Time (Unofficial) "
echo "========================================"
echo
echo "1) Instalar / Atualizar"
echo "2) Remover"
echo "3) Sair"
echo
read -p "Escolha uma opção [1-3]: " opcao

case $opcao in
    1)
        download_and_install
        ;;
    2)
        remove_app
        ;;
    3)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida."
        exit 1
        ;;
esac