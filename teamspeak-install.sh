#!/bin/bash
# Script: Instalação Automática TeamSpeak 3 Client
# Atualizado para 2025/2026

# --- Configurações ---
# Verifique a versão mais recente em: https://www.teamspeak.com/en/downloads/
TS_VERSION="3.6.2" 
URL_BASE="https://files.teamspeak-services.com/releases/client/${TS_VERSION}"

# --- Cores ---
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AZUL="\033[1;34m"
NORMAL="\033[m"

# --- 1. Verificação de Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}Erro: Este script precisa ser executado como root.${NORMAL}"
   echo -e "Use: ${VERDE}sudo $0${NORMAL}"
   exit 1
fi

# --- 2. Verificação de Arquitetura ---
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARQUIVO="TeamSpeak3-Client-linux_amd64-${TS_VERSION}.run"
    PASTA_EXTRAIDA="TeamSpeak3-Client-linux_amd64"
else
    echo -e "${VERMELHO}Erro: Arquitetura $ARCH não suportada ou descontinuada pelo TeamSpeak moderno.${NORMAL}"
    exit 1
fi

instalar_teamspeak() {
    clear
    echo -e "${AZUL}========================================${NORMAL}"
    echo -e "${AZUL}   INSTALAÇÃO TEAMSPEAK 3 (v$TS_VERSION)   ${NORMAL}"
    echo -e "${AZUL}========================================${NORMAL}"
    echo
    
    # Verifica se já está instalado
    if [ -d "/opt/teamspeak" ]; then
        echo -e "${VERMELHO}O TeamSpeak já parece estar instalado em /opt/teamspeak.${NORMAL}"
        echo "Remova a pasta antiga antes de continuar ou cancele."
        echo
        read -p "Deseja remover a versão antiga e reinstalar? (s/n) " remove_old
        if [[ "$remove_old" == "s" || "$remove_old" == "S" ]]; then
            rm -rf /opt/teamspeak
            rm -f /usr/bin/teamspeak
            rm -f /usr/share/applications/teamspeak.desktop
        else
            echo "Saindo..."
            exit 0
        fi
    fi

    # Baixando
    echo -e "${AZUL}>>> Baixando TeamSpeak 3...${NORMAL}"
    wget -q --show-progress "$URL_BASE/$ARQUIVO" -O /tmp/$ARQUIVO

    if [ $? -ne 0 ]; then
        echo -e "${VERMELHO}Erro ao baixar o arquivo. Verifique sua internet ou a versão no script.${NORMAL}"
        exit 1
    fi

    # Instalando
    echo -e "${AZUL}>>> Extraindo arquivos...${NORMAL}"
    chmod +x /tmp/$ARQUIVO
    
    # O comando yes é usado para aceitar a licença do instalador .run automaticamente
    cd /tmp
    yes | ./$ARQUIVO > /dev/null

    echo -e "${AZUL}>>> Movendo para /opt/teamspeak...${NORMAL}"
    mv $PASTA_EXTRAIDA /opt/teamspeak

    # Configura permissões (Root é dono dos arquivos, mas usuários podem ler/executar)
    chown -R root:root /opt/teamspeak
    chmod -R 755 /opt/teamspeak

    # Criando link simbólico
    ln -sf /opt/teamspeak/ts3client_runscript.sh /usr/bin/teamspeak

    # Configurando Ícone (Copia o ícone que vem no pacote para o sistema)
    echo -e "${AZUL}>>> Configurando ícone e atalho...${NORMAL}"
    cp /opt/teamspeak/logo-256.png /usr/share/pixmaps/teamspeak.png

    # Criando arquivo .desktop
    cat > /usr/share/applications/teamspeak.desktop <<EOF
[Desktop Entry]
Name=TeamSpeak 3
GenericName=TeamSpeak 3 Client
Comment=Fale com seus amigos e companheiros de equipe
Exec=/usr/bin/teamspeak
Icon=teamspeak
Terminal=false
Type=Application
Categories=Network;Application;
StartupNotify=true
EOF

    # Limpeza
    rm /tmp/$ARQUIVO
    
    echo
    echo -e "${VERDE}>>> Instalação Concluída com Sucesso!${NORMAL}"
    echo -e "Você pode iniciar o TeamSpeak pelo menu de aplicativos ou digitando 'teamspeak' no terminal."
}

# Menu Simples
echo "Este script instalará o TeamSpeak Client v$TS_VERSION"
echo
read -n1 -p "Deseja continuar? (s/n) " escolha
echo
case $escolha in
    s|S) instalar_teamspeak ;;
    *) echo "Operação cancelada."; exit 0 ;;
esac