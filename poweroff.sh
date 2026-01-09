#!/bin/bash
# Atualizado
# Funcionalidade: Agenda ou cancela o desligamento do sistema usando Zenity.

# Define o título padrão das janelas
TITLE="Agendador de Desligamento"

# --- Verificação de Root ---
# Verifica se o usuário é root (ID 0). Se não for, tenta reexecutar com sudo/pkexec ou avisa.
if [ "$EUID" -ne 0 ]; then
    zenity --error \
           --title="$TITLE" \
           --text="<b>Acesso Negado!</b>\n\nEste script precisa de permissões de administrador (root) para desligar o sistema.\n\nExecute: <i>sudo $0</i>" \
           --width=300
    exit 1
fi

# --- Funções ---

agendar_desligamento() {
    # 1. Escolher o tempo em minutos
    MINUTOS=$(zenity --scale \
                     --title="$TITLE" \
                     --text="Em quantos minutos deseja desligar o PC?" \
                     --min-value=1 --max-value=120 --value=30 --step=1)

    # Verifica se o usuário cancelou a janela de escala
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # 2. Confirmação do usuário
    zenity --question \
           --title="$TITLE" \
           --text="O sistema será desligado em <b>$MINUTOS minutos</b>.\n\nConfirma o agendamento?" \
           --width=300

    # Se o usuário clicar em Cancelar ou fechar, sai do script
    if [ $? -ne 0 ]; then
        zenity --info --title="$TITLE" --text="Operação cancelada pelo usuário."
        exit 0
    fi

    # 3. Executa o agendamento
    shutdown -h +$MINUTOS &

    # Confirmação final
    if [ $? -eq 0 ]; then
        zenity --info \
               --title="$TITLE" \
               --text="✅ Sucesso!\n\nO computador desligará em $MINUTOS minutos.\nPara cancelar, execute o script novamente e escolha 'Cancelar'." \
               --width=300
    else
        zenity --error --title="$TITLE" --text="Erro ao tentar agendar o desligamento."
    fi
}

cancelar_agendamento() {
    # Tenta cancelar qualquer shutdown pendente
    shutdown -c
    
    if [ $? -eq 0 ]; then
        zenity --info \
               --title="$TITLE" \
               --text="✅ O agendamento de desligamento foi cancelado com sucesso." \
               --width=300
    else
        zenity --warning \
               --title="$TITLE" \
               --text="Não havia nenhum agendamento ativo ou ocorreu um erro." \
               --width=300
    fi
}

# --- Menu Principal ---

OPCAO=$(zenity --list \
               --title="$TITLE" \
               --text="O que você deseja fazer?" \
               --radiolist \
               --column="Escolha" --column="Ação" \
               TRUE "Agendar Desligamento" \
               FALSE "Cancelar Desligamento" \
               --height=250 --width=400)

# Verifica se o usuário cancelou o menu
if [ $? -ne 0 ]; then
    exit 0
fi

# Lógica de decisão
case "$OPCAO" in
    "Agendar Desligamento")
        agendar_desligamento
        ;;
    "Cancelar Desligamento")
        cancelar_agendamento
        ;;
    *)
        exit 1
        ;;
esac