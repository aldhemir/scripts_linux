# 🐧 Linux Automation Suite

<div align="center">

![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

**Uma coleção de scripts Bash modernizados para administração de sistemas, automação de tarefas e diagnósticos de rede.**

</div>

---

## 📋 Sobre o Projeto

Este repositório contém utilitários essenciais para **Debian, Ubuntu e Linux Mint**. Os scripts, originalmente criados em 2015, foram **totalmente refatorados** para atender aos padrões de segurança e desempenho de **2025/2026**.

### O que mudou na versão atual?
* **Adeus SysVinit, Olá Systemd:** Scripts de serviço agora usam nativamente o `systemctl`.
* **Segurança:** Remoção de execuções perigosas como root em diretórios de usuário.
* **Compatibilidade:** Suporte para Debian 12 (Bookworm), Ubuntu 22.04/24.04 LTS e Mint 21+.
* **Limpeza de Código:** Remoção de dependências obsoletas (gksudo, chkconfig, flash player).

---

## ⚙️ Instalação e Preparação

Para utilizar qualquer script desta suíte, clone o repositório e dê permissão de execução:

```bash
# 1. Clone o repositório
git clone [gh repo clone aldhemir/scripts_linux](https://github.com/aldhemir/scripts_linux.git)

# 2. Entre na pasta
cd scripts_linux

# 3. Dê permissão de execução para todos os scripts
chmod +x *.sh

```

---

## 📂 Documentação dos Scripts

### 1. Limpeza de Kernel (`limpa-kernel.sh`)

Remove versões antigas do Kernel Linux para liberar espaço em disco, mantendo **apenas** a versão que está em uso atualmente.

* **Segurança:** Protege o kernel atual contra remoção acidental.
* **Drivers:** Exibe alertas para usuários de Nvidia/AMD.
* **Uso:**
```bash
sudo ./limpa-kernel.sh

```



### 2. Gerenciador de VMs VirtualBox (`vbox-manager.sh`)

Uma solução "Tudo em Um" para transformar Máquinas Virtuais em serviços do sistema.

* **Automação:** Cria arquivos `.service` do Systemd automaticamente.
* **Headless:** Inicia VMs em segundo plano (sem interface) no boot.
* **Safe Stop:** Salva o estado da VM (hiberna) quando o PC é desligado.
* **Uso:**
```bash
sudo ./vbox-manager.sh

```



### 3. Reset de Interface Gráfica (`reset-desktop.sh`)

Restaura as configurações de aparência, ícones e painéis para o padrão de fábrica.

* **Inteligente:** Detecta automaticamente se você usa **GNOME** ou **Unity**.
* **Seguro:** Não apaga arquivos pessoais, apenas configurações visuais (`dconf`).
* **Uso:** (Não execute como root!)
```bash
./reset-desktop.sh

```



### 4. Diagnóstico de Rede (`teste-rede.sh`)

Ferramenta rápida para verificar conectividade.

* **Diferencial:** Consegue distinguir se o problema é **Queda Total** ou apenas **Falha de DNS**.
* **Visual:** Barra de progresso e feedback colorido.
* **Uso:**
```bash
./teste-rede.sh

```



### 5. Extrator de PDF para CSV (`extrair-pdf.sh`)

Varre uma pasta de PDFs e extrai dados específicos (Nome, Email, Endereço, etc) para um relatório.

* **Formato:** Gera um arquivo `.csv` compatível com Excel/LibreOffice (separador `;`).
* **Dependência:** Instala automaticamente `poppler-utils` se necessário.
* **Uso:**
```bash
./extrair-pdf.sh

```



### 6. Instalador TeamSpeak 3 (`install-teamspeak.sh`)

Baixa e instala a versão mais recente do cliente TeamSpeak.

* **Correções:** Cria atalhos no menu de aplicativos e instala o ícone corretamente.
* **Licença:** Aceita automaticamente os termos de licença dos instaladores modernos.
* **Uso:**
```bash
sudo ./install-teamspeak.sh

```



### 7. Pós-Instalação Debian 12 (`pos-install-debian.sh`)

Script completo para configurar um Debian recém-instalado.

* **Repositórios:** Configura `contrib`, `non-free` e `non-free-firmware`.
* **Softwares:** Instala Chrome, Firefox ESR, VLC, Codecs, Java (OpenJDK) e Fontes Microsoft.
* **Uso:**
```bash
sudo ./pos-install-debian.sh

```



---

## ⚠️ Requisitos do Sistema

| SO Suportado | Versões Recomendadas |
| --- | --- |
| **Ubuntu** | 20.04, 22.04, 24.04 LTS |
| **Debian** | 11 (Bullseye), 12 (Bookworm) |
| **Linux Mint** | 20, 21, 22 |

> **Nota:** Alguns scripts requerem pacotes básicos como `curl`, `wget` ou `dconf-cli`. Os próprios scripts tentarão alertar ou instalar se faltar algo.

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Se você tiver uma melhoria ou correção:

1. Faça um Fork do projeto.
2. Crie uma Branch (`git checkout -b feature/MinhaMelhoria`).
3. Faça o Commit (`git commit -m 'Adicionei tal recurso'`).
4. Faça o Push (`git push origin feature/MinhaMelhoria`).
5. Abra um Pull Request.

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT - sinta-se livre para modificar e distribuir.

<p align="center">
<sub>Desenvolvido com ❤️ e Shell Script</sub>
</p>
