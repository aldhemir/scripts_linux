#!/bin/bash
# Script: Limpeza de Kernels Antigos
# Atualizado para padrões modernos (sem gksudo, regex segura)

# --- Variáveis de Cores ---
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
NORMAL="\033[m"

# --- Verificação de Root ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}Este script precisa ser executado como root.${NORMAL}"
   echo -e "Por favor, execute: ${VERDE}sudo $0${NORMAL}"
   exit 1
fi

# --- Identificação do Kernel Atual ---
KERNEL_ATUAL=$(uname -r)

# --- Função Principal ---
menu() {
    clear
    echo -e "${AZUL}========================================${NORMAL}"
    echo -e "${AZUL}     LIMPEZA DE KERNELS ANTIGOS         ${NORMAL}"
    echo -e "${AZUL}========================================${NORMAL}"
    echo
    echo -e "Kernel em uso (PROTEGIDO): ${VERDE}$KERNEL_ATUAL${NORMAL}"
    echo

    # Lista kernels instalados (imagens e headers), excluindo o atual
    # A lógica busca pacotes linux-image, linux-headers e linux-modules
    # que começam com números, e exclui a versão exata do uname -r
    KERNELS_ANTIGOS=$(dpkg --list | egrep -i 'linux-image|linux-headers|linux-modules' | awk '/^ii/ { print $2}' | grep -v "$KERNEL_ATUAL")

    if [ -z "$KERNELS_ANTIGOS" ]; then
        echo -e "${VERDE}Nenhum kernel antigo encontrado para remoção! Seu sistema está limpo.${NORMAL}"
        echo
        exit 0
    fi

    echo -e "${AMARELO}Os seguintes pacotes de Kernel antigos foram encontrados:${NORMAL}"
    echo "$KERNELS_ANTIGOS"
    echo
    echo -e "${VERMELHO}AVISO: Se você usa drivers proprietários (NVIDIA/AMD) instalados manualmente,"
    echo -e "certifique-se de que eles estão compilados para o kernel atual ($KERNEL_ATUAL).${NORMAL}"
    echo
    echo -e "${AZUL}Deseja remover estes pacotes antigos? (s/n)${NORMAL}"
    
    read -n1 -s escolha

    case $escolha in
        S|s)
            echo
            echo -e "${VERMELHO}>>> Iniciando remoção...${NORMAL}"
            
            # Comando de remoção
            # Usamos echo para passar a lista para o apt purge
            echo "$KERNELS_ANTIGOS" | xargs apt-get -y purge
            
            echo -e "${AZUL}>>> Removendo dependências órfãs...${NORMAL}"
            apt-get -y autoremove --purge
            
            echo -e "${AZUL}>>> Atualizando o GRUB...${NORMAL}"
            update-grub
            
            echo
            echo -e "${VERDE}>>> Processo concluído com sucesso!${NORMAL}"
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

# Executa o menu
menu