#!/bin/bash
# ------------------------------------------------------------------
# Atualizado: 2026
# Descrição: Script de otimização para Debian/Ubuntu e derivados.
# Melhorias: Gestão de SWAP, Cache, Preload, Limpeza e SSD Trim.
# Autor Original: Aldhemir
# ------------------------------------------------------------------

# Cores para facilitar a leitura
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verifica se é ROOT
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Erro: Este script precisa ser executado como root.${NC}"
   echo "Use: sudo ./$0"
   exit 1
fi

# 2. Função para aplicar configurações no sysctl (SWAP e Cache)
apply_sysctl() {
    local key="$1"
    local value="$2"
    local file="/etc/sysctl.conf"

    echo -n "Configurando $key para $value... "
    
    # Aplica na sessão atual
    sysctl -w "$key=$value" > /dev/null 2>&1

    # Persiste no arquivo (evita duplicatas)
    if grep -q "^$key" "$file"; then
        # Se existe, substitui o valor
        sed -i "s/^$key.*/$key = $value/" "$file"
    else
        # Se não existe, adiciona no final
        echo "$key = $value" >> "$file"
    fi
    echo -e "${GREEN}[OK]${NC}"
}

optimize_memory() {
    echo -e "\n${YELLOW}>>> Otimizando Gerenciamento de Memória e Disco...${NC}"
    
    # Diminui a tendência de usar SWAP (Ideal para desktops com 8GB+ RAM)
    # Padrão é 60. 10 faz o sistema usar RAM ao máximo antes de ir pro disco.
    apply_sysctl "vm.swappiness" "10"

    # Melhora a gestão de cache de arquivos (inode/dentry)
    # Padrão é 100. 50 retém o cache por mais tempo, melhorando responsividade.
    apply_sysctl "vm.vfs_cache_pressure" "50"

    # Define quando começar a gravar dados da RAM para o disco
    apply_sysctl "vm.dirty_background_ratio" "5"
    apply_sysctl "vm.dirty_ratio" "10"
}

# 3. Instalação e Configuração do Preload
setup_preload() {
    echo -e "\n${YELLOW}>>> Verificando PRELOAD...${NC}"
    
    if command -v preload >/dev/null; then
        echo -e "Preload já está instalado. ${GREEN}[OK]${NC}"
    else
        echo "Instalando Preload (monitora apps usados e carrega na RAM)..."
        apt-get update > /dev/null
        apt-get install preload -y > /dev/null
        if [ $? -eq 0 ]; then
             echo -e "Preload instalado com sucesso. ${GREEN}[OK]${NC}"
        else
             echo -e "${RED}Falha ao instalar Preload.${NC}"
        fi
    fi
    
    # Verifica se o serviço está rodando
    if systemctl is-active --quiet preload; then
        echo -e "Serviço Preload está rodando. ${GREEN}[OK]${NC}"
    else
        systemctl enable --now preload
    fi
}

# 4. Limpeza do Sistema
system_cleanup() {
    echo -e "\n${YELLOW}>>> Realizando Limpeza do Sistema...${NC}"
    
    echo "Removendo pacotes órfãos (autoremove)..."
    apt-get autoremove -y > /dev/null
    
    echo "Limpando cache do APT (clean)..."
    apt-get clean
    
    echo "Limpando cache de thumbnails..."
    rm -rf /home/*/.cache/thumbnails/* 2>/dev/null
    rm -rf /root/.cache/thumbnails/* 2>/dev/null
    
    # Se houver logs antigos do journald ocupando muito espaço
    echo "Limitando logs do sistema a 100MB..."
    journalctl --vacuum-size=100M > /dev/null 2>&1

    echo -e "Limpeza concluída. ${GREEN}[OK]${NC}"
}

# 5. Otimização SSD (Fstrim)
optimize_ssd() {
    echo -e "\n${YELLOW}>>> Otimizando SSD (Trim)...${NC}"
    # Só roda se fstrim existir
    if command -v fstrim >/dev/null; then
        fstrim -av
        echo -e "Trim executado em todos os pontos de montagem. ${GREEN}[OK]${NC}"
    else
        echo "Comando fstrim não encontrado (talvez você não use SSD ou esteja em VM)."
    fi
}

# --- MENU PRINCIPAL ---
clear
echo "#################################################"
echo "#     Script de Otimização Linux (2026)         #"
echo "#################################################"
echo

read -p "Deseja iniciar a otimização? (s/n): " escolha

case $escolha in
    s|S)
        optimize_memory
        setup_preload
        system_cleanup
        optimize_ssd
        
        echo -e "\n${GREEN}#################################################${NC}"
        echo -e "${GREEN}#      Otimização finalizada com sucesso!       #${NC}"
        echo -e "${GREEN}#################################################${NC}"
        echo "Recomenda-se reiniciar o computador para aplicar todas as mudanças."
        ;;
    n|N)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida."
        exit 1
        ;;
esac