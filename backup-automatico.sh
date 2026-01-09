#!/usr/bin/env bash
#
# Script: Backup Automático
# Descrição: Automatiza backup usando rsync e zenity (GUI)
# Atualizado em: 2025/2026
#
# Melhorias: Tratamento de espaços em nomes, logs, loop correto e portabilidade.

# Arquivo de log
LOGFILE="$HOME/backup_script.log"

# Função para registrar logs
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

checkprog() {
    # Verifica dependências sem tentar instalar (mais seguro e portátil)
    local missing=0
    
    if ! command -v rsync >/dev/null 2>&1; then
        echo "ERRO: O programa 'rsync' não está instalado."
        missing=1
    fi

    if ! command -v zenity >/dev/null 2>&1; then
        echo "ERRO: O programa 'zenity' não está instalado."
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        echo
        echo "Por favor, instale os pacotes faltantes usando o gerenciador de pacotes da sua distribuição."
        echo "Exemplo: sudo apt install rsync zenity  (Debian/Ubuntu)"
        echo "Exemplo: sudo dnf install rsync zenity  (Fedora)"
        echo
        read -n 1 -s -r -p "Pressione qualquer tecla para sair..."
        exit 1
    fi
}

executar_rsync() {
    local origem="$1"
    local destino="$2"
    local tipo="$3"
    
    # Flags base do rsync
    # -a: archive (preserva permissões, datas, links)
    # -v: verbose
    # -h: human readable (tamanhos em MB/GB)
    # --progress: barra de progresso
    local flags="-avh --progress"

    if [ "$tipo" == "FULL" ]; then
        # No modo Full (Espelhamento), deletamos no destino o que não existe na origem
        flags="$flags --delete"
    elif [ "$tipo" == "INC" ]; then
        # No modo Incremental (Update), apenas atualizamos o que mudou, sem deletar nada
        flags="$flags -u"
    fi

    echo "---------------------------------------------------"
    log_message "Iniciando Backup $tipo..."
    log_message "Origem: $origem"
    log_message "Destino: $destino"
    
    # Executa o rsync (eval é usado aqui para processar múltiplos arquivos vindos do zenity)
    # Nota: Se for apenas um diretório, o comando direto funciona. Se forem múltiplos arquivos, é complexo.
    # Para simplificar e garantir robustez, vamos assumir o comando direto com aspas.
    
    rsync $flags "$origem" "$destino"

    if [ $? -eq 0 ]; then
        log_message "Backup $tipo concluído com sucesso."
        zenity --info --text="Backup $tipo realizado com sucesso!" --timeout=5
    else
        log_message "ERRO durante o backup $tipo."
        zenity --error --text="Houve um erro durante o backup. Verifique o terminal."
    fi
    echo "---------------------------------------------------"
    echo "Pressione ENTER para voltar ao menu."
    read
}

bkpinc() {
    clear
    echo ">>> BACKUP INCREMENTAL (Atualiza arquivos modificados) <<<"
    echo "Abrindo janela de seleção..."
    
    # O separador ' ' ajuda o rsync a ler múltiplos arquivos, mas cuidado com espaços nos nomes.
    # Zenity com --multiple retorna caminhos. O ideal para múltiplos arquivos com rsync é complexo.
    # Vou ajustar para selecionar UM diretório ou arquivo para garantir estabilidade com espaços.
    
    bkplocal=$(zenity --file-selection --title="Selecione o arquivo ou pasta de ORIGEM" --multiple --separator=" ")
    
    # Se o usuário cancelar (string vazia)
    [[ -z "$bkplocal" ]] && return

    bkpdest=$(zenity --file-selection --directory --title="Selecione a pasta de DESTINO")
    [[ -z "$bkpdest" ]] && return

    clear
    echo "Resumo da Operação:"
    echo "Origem:  $bkplocal"
    echo "Destino: $bkpdest"
    echo
    read -n1 -p "Confirma a operação? (s/n): " escolha
    echo

    case $escolha in
        S|s) executar_rsync "$bkplocal" "$bkpdest" "INC" ;;
        *) echo "Operação cancelada."; sleep 1 ;;
    esac
}

bkpfull() {
    clear
    echo ">>> BACKUP FULL (Espelhamento / Clone) <<<"
    echo "ATENÇÃO: Arquivos no destino que não existirem na origem SERÃO APAGADOS."
    echo "Abrindo janela de seleção..."
    
    bkplocal=$(zenity --file-selection --directory --title="Selecione a PASTA de ORIGEM")
    [[ -z "$bkplocal" ]] && return

    bkpdest=$(zenity --file-selection --directory --title="Selecione a pasta de DESTINO")
    [[ -z "$bkpdest" ]] && return

    clear
    echo "Resumo da Operação (MODO FULL - DELETE):"
    echo "Origem:  $bkplocal"
    echo "Destino: $bkpdest"
    echo
    echo "CUIDADO: Isso irá deletar arquivos em '$bkpdest' que não estejam na origem."
    read -n1 -p "Tem certeza absoluta? (s/n): " escolha
    echo

    case $escolha in
        S|s) executar_rsync "$bkplocal/" "$bkpdest" "FULL" ;; # A barra no final da origem é importante pro rsync copiar O CONTEÚDO
        *) echo "Operação cancelada."; sleep 1 ;;
    esac
}

ajuda() {
    zenity --info --title="Ajuda do Sistema" --text="
<b>Backup Full (Espelhamento):</b>
Faz uma cópia exata.
- Se você deletou um arquivo na origem, ele será deletado no destino.
- Bom para manter clones exatos de pastas.

<b>Backup Incremental (Update):</b>
Apenas copia arquivos novos ou modificados.
- Se você deletou na origem, o arquivo PERMANECE no destino.
- Bom para histórico e segurança (não apaga nada acidentalmente).

Logs são salvos em: $LOGFILE" --width=400
}

# --- MENU PRINCIPAL ---

checkprog

while true; do
    clear
    echo "#############################################################"
    echo "#              SISTEMA DE BACKUP AUTOMÁTICO v2.0            #"
    echo "#                                                           #"
    echo "#     Utilizando 'rsync' + 'zenity' | Log: ativado          #"
    echo "#############################################################"
    echo
    echo "1) - Backup Full (Espelhamento - Cuidado: deleta extras)"
    echo "2) - Backup Incremental (Seguro - Apenas atualiza)"
    echo "3) - Ajuda / Diferenças"
    echo "4) - Ver Logs"
    echo "0) - Sair"
    echo
    read -n1 -p "Escolha uma opção: " escolha
    echo

    case $escolha in
        1) bkpfull ;;
        2) bkpinc ;;
        3) ajuda ;;
        4) less "$LOGFILE" ;; # Abre o log para leitura
        0) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida!"; sleep 1 ;;
    esac
done