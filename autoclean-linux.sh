#!/bin/bash
#
# AutoClean Linux v2.0
# Otimizado para distribuições baseadas em Debian (Ubuntu, Mint) e RHEL (Fedora)
# Melhorias: Segurança, Logs do Systemd, Snap, Flatpak e remoção de obsoletos.
#

# Definição de Cores
VERDE="\033[1;32m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
NORMAL="\033[m"

# Cabeçalho
header() {
    clear
    echo -e "${AZUL}#############################################${NORMAL}"
    echo -e "${AZUL}#          AUTOCLEAN LINUX v2.0             #${NORMAL}"
    echo -e "${AZUL}#############################################${NORMAL}"
    echo
}

# Verificação de Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}Este script precisa ser executado como ROOT.${NORMAL}"
   echo "Use: sudo ./$0"
   exit 1
fi

# Função para limpeza de Logs do Systemd (Funciona em quase todas as distros modernas)
clean_systemd_logs() {
    echo -e "${AMARELO}[*] Verificando Logs do Systemd (Journalctl)...${NORMAL}"
    # Mantém apenas os últimos 2 dias de logs para economizar espaço
    journalctl --vacuum-time=2d
    echo -e "${VERDE}Logs antigos removidos.${NORMAL}"
    echo "--------------------------------------------"
}

# Função para limpeza de Caches de Usuário (Mais seguro que varrer a home toda)
clean_user_cache() {
    echo -e "${AMARELO}[*] Limpando Cache de Usuários (.cache)...${NORMAL}"
    # Limpa o cache do usuário que invocou o sudo
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        if [ -d "$USER_HOME/.cache" ]; then
            echo "Limpando cache de $SUDO_USER..."
            rm -rf "$USER_HOME/.cache/thumbnails/*"
            # Adicione outras pastas de cache seguras aqui se desejar
        fi
    fi
    echo -e "${VERDE}Cache de miniaturas limpo.${NORMAL}"
    echo "--------------------------------------------"
}

# Função para limpar Snap e Flatpak (Comuns hoje em dia)
clean_modern_packages() {
    if command -v snap &> /dev/null; then
        echo -e "${AMARELO}[*] Removendo versões antigas de pacotes SNAP...${NORMAL}"
        # Script one-liner para remover revisões antigas de snaps desativados
        set -eu
        snap list --all | awk '/disabled/{print $1, $3}' |
            while read snapname revision; do
                snap remove "$snapname" --revision="$revision"
            done
        echo -e "${VERDE}Snaps antigos removidos.${NORMAL}"
    fi

    if command -v flatpak &> /dev/null; then
        echo -e "${AMARELO}[*] Removendo runtimes FLATPAK não utilizados...${NORMAL}"
        flatpak uninstall --unused -y
        echo -e "${VERDE}Flatpaks limpos.${NORMAL}"
    fi
    echo "--------------------------------------------"
}

# Limpeza para DNF (Fedora/RHEL)
cleaning_rpm() {
    echo -e "${VERDE}Iniciando limpeza para sistemas baseados em RPM (DNF)${NORMAL}"
    
    echo "Limpando metadados e cache do DNF..."
    dnf clean all
    
    echo "Removendo pacotes órfãos/não utilizados..."
    dnf autoremove -y
    
    clean_systemd_logs
    clean_modern_packages
    clean_user_cache
}

# Limpeza para APT (Debian/Ubuntu/Mint)
cleaning_apt() {
    echo -e "${VERDE}Iniciando limpeza para sistemas baseados em APT (Debian/Ubuntu)${NORMAL}"

    # Tenta corrigir dependências quebradas antes de começar
    dpkg --configure -a --force-confold

    echo "Limpando cache local de pacotes..."
    apt-get clean -y
    
    echo "Removendo pacotes antigos (autoremove)..."
    apt-get autoremove -y --purge

    echo "Removendo arquivos de configuração de pacotes desinstalados..."
    # Comando complexo mas seguro para remover restos de configs
    dpkg -l | grep '^rc' | awk '{print $2}' | xargs -r dpkg --purge

    echo "Esvaziando a Lixeira do usuário root e sudo..."
    rm -rf /root/.local/share/Trash/*
    if [ -n "$SUDO_USER" ]; then
         USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
         rm -rf "$USER_HOME/.local/share/Trash/*"
    fi
    
    clean_systemd_logs
    clean_modern_packages
    clean_user_cache
}

# Detecta o Gerenciador de Pacotes
detect_and_run() {
    if command -v apt-get &> /dev/null; then
        cleaning_apt
    elif command -v dnf &> /dev/null; then
        cleaning_rpm
    else
        echo -e "${VERMELHO}Não foi possível detectar um gerenciador de pacotes suportado (apt ou dnf).${NORMAL}"
        exit 1
    fi
}

# --- Fluxo Principal ---
header
echo -e "Este script irá remover:"
echo -e " - Caches do sistema (APT/DNF)"
echo -e " - Pacotes órfãos e dependências não utilizadas"
echo -e " - Logs antigos do sistema (Journalctl)"
echo -e " - Versões antigas de Snaps e Flatpaks"
echo -e " - Cache de miniaturas e Lixeira"
echo
read -p "Deseja continuar? (s/n): " -n 1 escolha
echo

case $escolha in
    s|S)
        detect_and_run
        echo
        echo -e "${AZUL}#############################################${NORMAL}"
        echo -e "${VERDE}       LIMPEZA CONCLUÍDA COM SUCESSO!        ${NORMAL}"
        echo -e "${AZUL}#############################################${NORMAL}"
        ;;
    *)
        echo -e "${AMARELO}Operação cancelada pelo usuário.${NORMAL}"
        exit 0
        ;;
esac