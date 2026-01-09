#!/bin/bash
#   Atualizado em: 2026
#   Script para instalação do stack LAMP (Linux, Apache, MySQL/MariaDB, PHP)
#   Compatível com Debian, Ubuntu, Mint e derivados modernos.
#   https://github.com/aldhemir

# Cores para formatação
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens com status
msg_info() { echo -e "${AZUL}[INFO]${NC} $1"; }
msg_sucesso() { echo -e "${VERDE}[SUCESSO]${NC} $1"; }
msg_aviso() { echo -e "${AMARELO}[AVISO]${NC} $1"; }
msg_erro() { echo -e "${VERMELHO}[ERRO]${NC} $1"; }

# 1. Verifica se o usuário é root
if [[ `id -u` -ne 0 ]]; then
    msg_erro "Este script precisa ser executado como superusuário (root)."
    msg_aviso "Use: sudo ./nome_do_script.sh"
    exit 1
fi

# 2. Verifica gerenciador de pacotes e distro
verificar_distro() {
    if ! which apt > /dev/null; then
        msg_erro "Gerenciador de pacotes 'apt' não encontrado."
        msg_erro "Este script foi feito para Debian/Ubuntu e derivados."
        exit 1
    fi
}

# 3. Teste de conexão (Otimizado)
testar_conexao() {
    msg_info "Verificando conexão com a internet..."
    # Ping reduzido para 3 pacotes para ser mais rápido
    if ping -c 3 google.com > /dev/null 2>&1; then
        msg_sucesso "Conexão OK."
    else
        msg_aviso "Falha na conexão com a internet."
        read -p "Deseja tentar novamente? (s/n): " escolha
        case $escolha in
            s|S) testar_conexao ;; # Recursividade corrigida
            *) msg_erro "Sem internet. Cancelando instalação."; exit 1 ;;
        esac
    fi
}

# 4. Função principal de Instalação
instalar_lamp() {
    clear
    testar_conexao
    
    msg_info "Atualizando lista de repositórios..."
    apt-get update -y > /dev/null

    # --- APACHE ---
    echo "--------------------------------------------------"
    msg_info "Verificando APACHE..."
    if dpkg -s apache2 > /dev/null 2>&1; then
        msg_aviso "Apache2 já está instalado."
    else
        msg_info "Instalando Apache2..."
        apt-get install apache2 -y > /dev/null
        if [ $? -eq 0 ]; then
            msg_sucesso "Apache2 instalado."
            # Abre navegador para testar (usando xdg-open que é universal)
            if which xdg-open > /dev/null; then
                sudo -u $SUDO_USER xdg-open http://localhost > /dev/null 2>&1 &
            fi
        else
            msg_erro "Falha ao instalar Apache2."
        fi
    fi

    # --- DATABASE (MySQL/MariaDB) ---
    echo "--------------------------------------------------"
    msg_info "Verificando Banco de Dados..."
    # Instala o default-mysql-server que puxa o MariaDB ou MySQL dependendo da versão do OS
    if dpkg -s default-mysql-server > /dev/null 2>&1 || dpkg -s mysql-server > /dev/null 2>&1; then
        msg_aviso "Servidor MySQL/MariaDB já está instalado."
    else
        msg_info "Instalando MySQL Server..."
        apt-get install default-mysql-server -y > /dev/null
        msg_sucesso "MySQL instalado."
        msg_aviso "Recomendado rodar 'mysql_secure_installation' manualmente após o script."
    fi

    # --- PHP ---
    echo "--------------------------------------------------"
    msg_info "Verificando PHP..."
    # Instala o PHP atual do repositório (ex: 8.1, 8.2, 8.3) e extensões comuns
    if which php > /dev/null 2>&1; then
        msg_aviso "PHP já está instalado."
        php -v | head -n 1
    else
        msg_info "Instalando PHP e módulos comuns..."
        # Removemos php5 e mcrypt (obsoleto). Adicionamos libapache2-mod-php para integração.
        apt-get install php libapache2-mod-php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip -y > /dev/null
        
        msg_sucesso "PHP instalado."
        
        # Criação do arquivo de teste info.php
        msg_info "Criando arquivo de teste em /var/www/html/info.php"
        echo "<?php phpinfo(); ?>" > /var/www/html/info.php
        
        # Reinicia Apache para carregar PHP
        systemctl restart apache2
        
        if which xdg-open > /dev/null; then
            msg_info "Abrindo página de teste do PHP..."
            sleep 2
            # Executa o browser como o usuário normal, não como root, para evitar problemas de permissão no browser
            if [ -n "$SUDO_USER" ]; then
                sudo -u $SUDO_USER xdg-open http://localhost/info.php > /dev/null 2>&1 &
            else
                xdg-open http://localhost/info.php > /dev/null 2>&1 &
            fi
        fi
    fi

    # --- PHPMYADMIN (Opcional) ---
    # Nota: phpMyAdmin via script pode ser complexo pois pede interação de tela.
    # Deixei comentado para evitar travamentos, mas você pode descomentar.
    # echo "--------------------------------------------------"
    # msg_info "Instalando PhpMyAdmin..."
    # apt-get install phpmyadmin -y
    
    echo "--------------------------------------------------"
    msg_sucesso "Instalação do LAMP concluída!"
    msg_info "Acesse http://localhost/info.php para verificar."
}

# --- MENU PRINCIPAL ---
clear
echo "========================================"
echo "    INSTALADOR LAMP AUTOMATIZADO"
echo "    (Linux, Apache, MySQL, PHP)"
echo "========================================"
echo
msg_aviso "Este script irá instalar os pacotes mais recentes."
echo

read -n1 -p "Deseja prosseguir? (s/n): " escolha
echo # Pula linha
case $escolha in
    s|S) 
        verificar_distro
        instalar_lamp
        ;;
    n|N) 
        msg_info "Saindo do script..."
        exit 0
        ;;
    *) 
        msg_erro "Opção inválida. Saindo."
        exit 1
        ;;
esac