#!/bin/bash
# Script: Criador de Serviço Systemd para VirtualBox
# Atualizado para 2025/2026 - Usa Systemd e VBoxManage

# --- Cores ---
VERDE="\033[1;32m"
VERMELHO="\033[1;31m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
NORMAL="\033[m"

# --- 1. Verificação de Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}Erro: Este script precisa configurar serviços do sistema.${NORMAL}"
   echo -e "Execute como root: ${VERDE}sudo $0${NORMAL}"
   exit 1
fi

# --- 2. Verifica Instalação do VirtualBox ---
if ! command -v VBoxManage &> /dev/null; then
    echo -e "${VERMELHO}Erro: VirtualBox não encontrado.${NORMAL}"
    echo "Instale o VirtualBox antes de prosseguir."
    exit 1
fi

menu() {
    clear
    echo -e "${AZUL}=========================================${NORMAL}"
    echo -e "${AZUL}   VIRTUALBOX AUTOSTART (SYSTEMD)        ${NORMAL}"
    echo -e "${AZUL}=========================================${NORMAL}"
    echo
    echo -e "Este script transformará uma VM em um serviço do sistema."
    echo -e "Ela iniciará automaticamente no boot (modo headless)."
    echo

    # --- Coleta de Dados ---
    
    # 1. Nome do Usuário Dono da VM
    echo -e "${AMARELO}Passo 1: Quem é o usuário dono da VM?${NORMAL}"
    echo "Geralmente é o seu usuário comum (ex: 'ubuntu', 'joao')."
    echo "Não use 'root' a menos que tenha criado a VM como root."
    read -p "Usuário Linux: " VM_USER

    if ! id "$VM_USER" &>/dev/null; then
        echo -e "${VERMELHO}Usuário '$VM_USER' não existe.${NORMAL}"
        exit 1
    fi

    echo
    echo -e "${AMARELO}Passo 2: Qual o nome da VM?${NORMAL}"
    echo "Lista de VMs do usuário $VM_USER:"
    echo "-----------------------------------"
    # Lista as VMs do usuário especificado para facilitar
    sudo -u "$VM_USER" VBoxManage list vms | awk '{print $1}' | sed 's/"//g'
    echo "-----------------------------------"
    echo
    read -p "Digite o nome EXATO da VM (entre aspas se tiver espaço): " VM_NAME
    
    # Remove aspas se o usuário digitar
    VM_NAME=$(echo "$VM_NAME" | sed 's/"//g')

    # Verifica se a VM existe
    if ! sudo -u "$VM_USER" VBoxManage showvminfo "$VM_NAME" &> /dev/null; then
        echo -e "${VERMELHO}Erro: A VM '$VM_NAME' não foi encontrada para o usuário '$VM_USER'.${NORMAL}"
        exit 1
    fi

    echo
    echo -e "Configuração:"
    echo -e "VM: ${VERDE}$VM_NAME${NORMAL}"
    echo -e "Usuário: ${VERDE}$VM_USER${NORMAL}"
    echo
    read -n1 -p "Confirma a criação do serviço? (s/n) " confirma
    if [[ "$confirma" != "s" && "$confirma" != "S" ]]; then
        echo "Cancelado."
        exit 0
    fi

    criar_servico
}

criar_servico() {
    # Nome do arquivo de serviço (sanitize remove espaços para o nome do arquivo)
    SERVICE_NAME="vbox-$(echo "$VM_NAME" | tr ' ' '_')"
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    echo
    echo -e "${AZUL}>>> Criando arquivo $SERVICE_FILE ...${NORMAL}"

    # Criação do arquivo Unit do Systemd
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=VirtualBox VM Service: $VM_NAME
After=network.target virtualbox.service
Requires=virtualbox.service

[Service]
User=$VM_USER
Group=$VM_USER
Type=forking
Restart=no
TimeoutSec=5min
# Inicia a VM em modo Headless (sem interface gráfica)
ExecStart=/usr/bin/VBoxManage startvm "$VM_NAME" --type headless
# Ao parar o serviço, salva o estado (hiberna) em vez de desligar forçado
ExecStop=/usr/bin/VBoxManage controlvm "$VM_NAME" savestate

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${AZUL}>>> Ativando o serviço...${NORMAL}"
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service"
    
    echo -e "${AZUL}>>> Iniciando a VM para teste...${NORMAL}"
    systemctl start "${SERVICE_NAME}.service"

    echo
    echo -e "${VERDE}Sucesso! A VM '$VM_NAME' agora é um serviço.${NORMAL}"
    echo "Comandos para gerenciar:"
    echo "  Parar:    sudo systemctl stop $SERVICE_NAME"
    echo "  Iniciar:  sudo systemctl start $SERVICE_NAME"
    echo "  Status:   sudo systemctl status $SERVICE_NAME"
}

# Executa
menu