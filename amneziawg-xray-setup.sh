#!/usr/bin/env bash
#=====================================================================
#  AmneziaWG 3.1 - Instalador / Configurador com menu
#  Painel: myceliummesh/amneziawg-ui  |  Debian 11+/Ubuntu 20.04+
#  Versão do script: 1.0
#
#  Uso:   sudo bash amneziawg-setup.sh          (menu interativo)
#         sudo bash amneziawg-setup.sh --full   (instalação completa guiada)
#         sudo bash amneziawg-setup.sh --version  (mostra a versão)
#=====================================================================
set -u

CONF_FILE="/etc/awg-setup.conf"
WL_FILE="/etc/awg-ssh-whitelist.txt"
APT_UPDATED=0
LANG_UI="${LANG_UI:-pt}"
SCRIPT_VERSION="1.1"

if [ -t 1 ]; then
  R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; C=$'\e[36m'; W=$'\e[1m'; N=$'\e[0m'
else
  R=""; G=""; Y=""; B=""; C=""; W=""; N=""
fi

# Saída visual padronizada (sem alterar as rotinas de instalação).
info() { echo -e "${C}[i]${N}  $*"; }
ok()   { echo -e "${G}[✓]${N}  $*"; }
warn() { echo -e "${Y}[!]${N}  $*"; }
err()  { echo -e "${R}[✗]${N}  $*" >&2; }
die()  { err "$*"; exit 1; }

ui_banner() {
  echo -e "${C}${W}"
  cat <<'EOF'
    _                        _          _       _    ____  _       _
   / \   _ __ ___  _ __   ___| |_  ___  (_) __ _| |  / ___|| |_ ___| |__
  / _ \ | '_ ` _ \| '_ \ / _ \ __|/ _ \ |/ _` | |  \___ \| __/ __| '_ \
 / ___ \| | | | | | | | |  __/ |_|  __/ | (_| | |   ___) | || (__| | | |
/_/   \_\_| |_| |_|_| |_|\___|\__|\___|_|\__,_|_|  |____/ \__\___|_| |_|
EOF
  echo -e "${N}${B}                 VPN installer & configuration manager${N}"
}

ui_section() {
  local title="$1"
  echo -e "\n${B}${W}┌─ ${title}${N}"
  echo -e "${B}└$(printf '─%.0s' {1..58})${N}"
}

ui_stage() {
  local current="$1" total="$2" label="$3"
  echo -e "\n${C}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo -e "${C}${W}  ETAPA ${current}/${total}  ${N}${W}${label}${N}"
  echo -e "${C}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
}

#---------------------------------------------------------------------
# i18n (pt/en) — dicionário compacto; fallback para pt
#---------------------------------------------------------------------
t() {
  local k="$1"
  case "$LANG_UI:$k" in
    pt:menu_title) echo "AmneziaWG 3.1 - Configuração completa";;
    en:menu_title) echo "AmneziaWG 3.1 - Full setup";;
    pt:menu_opt1) echo "  1) Configurar (domínio, e-mail, portas, usuário, senha, IP admin)";;
    en:menu_opt1) echo "  1) Configure (domain, email, ports, user, password, admin IP)";;
    pt:menu_opt2) echo "  2) INSTALAÇÃO COMPLETA (guiada)";;
    en:menu_opt2) echo "  2) FULL INSTALL (guided)";;
    pt:menu_opt3) echo "  3) Sistema + Firewall (Docker, sysctl, UFW)";;
    en:menu_opt3) echo "  3) System + Firewall (Docker, sysctl, UFW)";;
    pt:menu_opt4) echo "  4) Implantar AmneziaWG (Docker)";;
    en:menu_opt4) echo "  4) Deploy AmneziaWG (Docker)";;
    pt:menu_opt5) echo "  5) Nginx + SSL + Fail2Ban (web + proteção)";;
    en:menu_opt5) echo "  5) Nginx + SSL + Fail2Ban (web + protection)";;
    pt:menu_opt6) echo "  6) SSH (porta + endurecimento + geo-block Brasil opcional)";;
    en:menu_opt6) echo "  6) SSH (port + hardening + optional Brazil geo-block)";;
    pt:menu_opt7) echo "  7) Manutenção + Status (timers, updates, verificação)";;
    en:menu_opt7) echo "  7) Maintenance + Status (timers, updates, check)";;
    pt:menu_opt8) echo "  8) Opções avançadas (idioma / apagar tudo / ofuscação)";;
    en:menu_opt8) echo "  8) Advanced options (language / wipe all / obfuscation)";;
    pt:menu_opt9) echo "  9) Sair";;
    en:menu_opt9) echo "  9) Exit";;
    pt:menu_hint) echo " Cada opção é independente. A opção 4 exige Docker (opção 3) e senha (opção 1).";;
    en:menu_hint) echo " Each option is independent. Option 4 needs Docker (option 3) and password (option 1).";;
    pt:adv_title) echo "Opções avançadas";;
    en:adv_title) echo "Advanced options";;
    pt:adv_opt1) echo "  1) Idioma / Language";;
    en:adv_opt1) echo "  1) Idioma / Language";;
    pt:adv_opt2) echo "  2) Apagar container + limpeza";;
    en:adv_opt2) echo "  2) Remove container + cleanup";;
    pt:adv_opt3) echo "  3) Guia de ofuscação";;
    en:adv_opt3) echo "  3) Obfuscation guide";;
    pt:adv_opt0) echo "  0) Voltar";;
    en:adv_opt0) echo "  0) Back";;
    pt:pass_prompt) echo "Senha do painel web (mín. 12 caracteres)";;
    en:pass_prompt) echo "Web panel password (min. 12 chars)";;
    pt:pass_repeat) echo "Repita a senha";;
    en:pass_repeat) echo "Repeat password";;
    pt:pass_mismatch) echo "As senhas não conferem.";;
    en:pass_mismatch) echo "Passwords do not match.";;
    pt:pass_short) echo "Use pelo menos 12 caracteres.";;
    en:pass_short) echo "Use at least 12 characters.";;
    pt:pass_saved) echo "Hash base64(sha256) da senha salvo.";;
    en:pass_saved) echo "Password base64(sha256) hash saved.";;
    pt:err_invalid_domain_conf) echo "Domínio inválido em";;
    en:err_invalid_domain_conf) echo "Invalid domain in";;
    pt:err_invalid_ports) echo "Uma ou mais portas configuradas são inválidas.";;
    en:err_invalid_ports) echo "One or more configured ports are invalid.";;
    pt:err_port_conflict) echo "Portas conflitantes: SSH/painel não podem usar 80/443 nem compartilhar a mesma porta TCP.";;
    en:err_port_conflict) echo "Conflicting ports: SSH/panel cannot use 80/443 nor share the same TCP port.";;
    pt:err_invalid_install_dir) echo "INSTALL_DIR deve ser caminho absoluto simples, sem espaços nem segmentos .. .";;
    en:err_invalid_install_dir) echo "INSTALL_DIR must be a simple absolute path, no spaces or .. segments.";;
    pt:err_invalid_panel_user) echo "PANEL_USER inválido em";;
    en:err_invalid_panel_user) echo "Invalid PANEL_USER in";;
    pt:err_invalid_pass_hash) echo "PANEL_PASS_HASH não parece base64 válido.";;
    en:err_invalid_pass_hash) echo "PANEL_PASS_HASH does not look like valid base64.";;
    pt:remove_title) echo "Remover AmneziaWG e configuração";;
    en:remove_title) echo "Remove AmneziaWG and configuration";;
    pt:remove_warn) echo "Isto removerá container, config, site Nginx, Fail2Ban e timers. Continuar?";;
    en:remove_warn) echo "This will remove container, config, Nginx site, Fail2Ban and timers. Continue?";;
    pt:remove_confirm) echo "Digite APAGAR para confirmar";;
    en:remove_confirm) echo "Type DELETE to confirm";;
    pt:remove_type_word) echo "APAGAR";;
    en:remove_type_word) echo "DELETE";;
    pt:remove_done) echo "Remoção concluída.";;
    en:remove_done) echo "Removal completed.";;
    pt:remove_kept) echo "Mantidos: docker, nginx, ufw, fail2ban (pacotes), sysctl, contas Let's Encrypt, chaves SSH.";;
    en:remove_kept) echo "Kept: docker, nginx, ufw, fail2ban (packages), sysctl, Let's Encrypt accounts, SSH keys.";;
    pt:remove_data_q) echo "Apagar também os dados do painel em";;
    en:remove_data_q) echo "Also delete panel data in";;
    pt:remove_cert_q) echo "Apagar também o certificado Let's Encrypt de";;
    en:remove_cert_q) echo "Also delete Let's Encrypt certificate for";;
    pt:pause) echo "Pressione ENTER para continuar...";;
    en:pause) echo "Press ENTER to continue...";;
    pt:prompt_domain) echo "Domínio público do painel (ex.: vpn.exemplo.com)";;
    en:prompt_domain) echo "Public panel domain (e.g. vpn.example.com)";;
    pt:prompt_email) echo "E-mail para o Let's Encrypt";;
    en:prompt_email) echo "Email for Let's Encrypt";;
    pt:prompt_ssh_port) echo "Porta SSH nova";;
    en:prompt_ssh_port) echo "New SSH port";;
    pt:prompt_vpn_port) echo "Porta VPN (UDP)";;
    en:prompt_vpn_port) echo "VPN port (UDP)";;
    pt:prompt_panel_port) echo "Porta do painel web (TCP, só localhost)";;
    en:prompt_panel_port) echo "Web panel port (TCP, localhost only)";;
    pt:prompt_panel_user) echo "Usuário do painel";;
    en:prompt_panel_user) echo "Panel username";;
    pt:prompt_install_dir) echo "Diretório de instalação";;
    en:prompt_install_dir) echo "Install directory";;
    pt:prompt_admin_ip) echo "Seu IP IPv4/CIDR atual (Fail2Ban e whitelist do geo-block; vazio se não quiser definir)";;
    en:prompt_admin_ip) echo "Your current IPv4/CIDR (Fail2Ban and geo-block whitelist; empty to skip)";;
    pt:invalid_domain) echo "Domínio inválido (use um hostname, sem protocolo ou caminho).";;
    en:invalid_domain) echo "Invalid domain (use a hostname, no protocol or path).";;
    pt:invalid_port) echo "Porta inválida.";;
    en:invalid_port) echo "Invalid port.";;
    pt:port_conflict) echo "A porta do painel não pode coincidir com a porta SSH nem usar 80/443; SSH também não pode usar 80/443.";;
    en:port_conflict) echo "Panel port cannot match SSH port or use 80/443; SSH also cannot use 80/443.";;
    pt:invalid_user) echo "Usuário inválido: use letras, números, ponto, hífen, underscore ou @.";;
    en:invalid_user) echo "Invalid username: use letters, numbers, dot, hyphen, underscore or @.";;
    pt:invalid_dir) echo "Use um caminho absoluto com letras, números, ponto, underscore, hífen ou barra; sem segmentos .. .";;
    en:invalid_dir) echo "Use an absolute path with letters, numbers, dot, underscore, hyphen or slash; no .. segments.";;
    pt:invalid_ip) echo "Informe um IPv4/CIDR válido ou deixe vazio. O geo-block só aceita IPv4.";;
    en:invalid_ip) echo "Enter a valid IPv4/CIDR or leave empty. Geo-block only accepts IPv4.";;
    pt:conf_saved) echo "Configuração salva em";;
    en:conf_saved) echo "Configuration saved to";;
    pt:domain_not_set) echo "Domínio não configurado. Rode a opção 1 (Configurar).";;
    en:domain_not_set) echo "Domain not configured. Run option 1 (Configure).";;
    pt:need_root) echo "Execute como root (sudo).";;
    en:need_root) echo "Run as root (sudo).";;
    pt:need_debian) echo "Este script suporta apenas Debian/Ubuntu.";;
    en:need_debian) echo "This script supports Debian/Ubuntu only.";;
    pt:lang_pt) echo "Idioma: Português";;
    en:lang_pt) echo "Language: Português";;
    pt:lang_en) echo "Idioma: English";;
    en:lang_en) echo "Language: English";;
    pt:pass_already) echo "Senha do painel já definida. Trocar agora?";;
    en:pass_already) echo "Panel password already set. Change it now?";;
    pt:option) echo "Opção";;
    en:option) echo "Option";;
    pt:invalid_option) echo "Opção inválida.";;
    en:invalid_option) echo "Invalid option.";;
    pt:invalid_email) echo "E-mail parece inválido (esperado usuario@dominio.tld).";;
    en:invalid_email) echo "Email looks invalid (expected user@domain.tld).";;
    *)
      case "pt:$k" in
        pt:menu_title) echo "AmneziaWG 3.1 - Configuração completa";;
        pt:pause) echo "Pressione ENTER para continuar...";;
        *) echo "$k";;
      esac
      ;;
  esac
}

pause() { read -rp "$(t pause) " _; }

confirm() { # confirm "pergunta" [y|n]
  local p="$1" d="${2:-n}" a hint
  [ "$d" = "y" ] && hint="S/n" || hint="s/N"
  read -rp "$p [$hint]: " a
  a="${a:-$d}"
  case "${a,,}" in s|y|sim|yes) return 0 ;; *) return 1 ;; esac
}

ask() { # ask "Prompt" VAR default
  local prompt="$1" var="$2" def="${3:-}" val
  read -rp "$prompt [$def]: " val
  printf -v "$var" '%s' "${val:-$def}"
}

valid_port() { [[ "${1:-}" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; }
valid_domain() { [[ "${1:-}" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$ ]]; }
valid_ipv4_or_cidr() {
  local value="${1:-}" ip prefix octet
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]] || return 1
  ip="${value%%/*}"; prefix="${value#*/}"
  IFS=. read -r -a octet <<< "$ip"
  for ip in "${octet[@]}"; do (( 10#$ip <= 255 )) || return 1; done
  [[ "$value" != */* ]] || (( 10#$prefix <= 32 ))
}
ask_allow_empty() { # ask_allow_empty "Prompt" VAR
  local prompt="$1" var="$2" val
  read -rp "$prompt (vazio para limpar): " val
  printf -v "$var" '%s' "$val"
}

#---------------------------------------------------------------------
# Verificações iniciais
#---------------------------------------------------------------------
# --version antes de exigir root (útil em CI / documentação)
case "${1:-}" in
  --version|-v) echo "amneziawg-setup v${SCRIPT_VERSION}"; exit 0 ;;
esac
[ "$(id -u)" -eq 0 ] || die "$(t need_root)"
[ -f /etc/debian_version ] || die "$(t need_debian)"

apt_update() {
  [ "$APT_UPDATED" = 1 ] && return 0
  apt-get update -y && APT_UPDATED=1
}
pkg() { apt_update || return 1; DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }

#---------------------------------------------------------------------
# Configuração persistente
#---------------------------------------------------------------------
load_conf() {
  # shellcheck disable=SC1090
  [ -f "$CONF_FILE" ] && . "$CONF_FILE"
  DOMAIN="${DOMAIN:-}"
  EMAIL="${EMAIL:-}"
  SSH_PORT="${SSH_PORT:-49152}"
  VPN_PORT="${VPN_PORT:-54844}"
  PANEL_PORT="${PANEL_PORT:-54845}"
  PANEL_USER="${PANEL_USER:-admin}"
  PANEL_PASS_HASH="${PANEL_PASS_HASH:-}"
  INSTALL_DIR="${INSTALL_DIR:-/opt/amneziawg}"
  LANG_UI="${LANG_UI:-pt}"
  case "$LANG_UI" in pt|en) ;; *) LANG_UI=pt ;; esac
  # SSH_CLIENT is not guaranteed to exist (for example, console/cloud-init runs).
  XRAY_PORT="${XRAY_PORT:-8443}"
  XRAY_TARGET="${XRAY_TARGET:-www.microsoft.com}"
  XRAY_SNI="${XRAY_SNI:-www.microsoft.com}"
  ADMIN_IP="${ADMIN_IP:-$(printf '%s' "${SSH_CLIENT-}" | awk '{print $1}') }"
  ADMIN_IP="${ADMIN_IP% }"
}

save_conf() {
  cat > "$CONF_FILE" <<EOF
DOMAIN=$(printf %q "$DOMAIN")
EMAIL=$(printf %q "$EMAIL")
SSH_PORT=$(printf %q "$SSH_PORT")
VPN_PORT=$(printf %q "$VPN_PORT")
PANEL_PORT=$(printf %q "$PANEL_PORT")
PANEL_USER=$(printf %q "$PANEL_USER")
PANEL_PASS_HASH=$(printf %q "$PANEL_PASS_HASH")
INSTALL_DIR=$(printf %q "$INSTALL_DIR")
ADMIN_IP=$(printf %q "$ADMIN_IP")
LANG_UI=$(printf %q "$LANG_UI")
XRAY_PORT=$(printf %q "$XRAY_PORT")
XRAY_TARGET=$(printf %q "$XRAY_TARGET")
XRAY_SNI=$(printf %q "$XRAY_SNI")
EOF
  chmod 600 "$CONF_FILE"
}

toggle_lang() {
  if [ "$LANG_UI" = "pt" ]; then
    LANG_UI="en"; save_conf; ok "$(t lang_en)"
  else
    LANG_UI="pt"; save_conf; ok "$(t lang_pt)"
  fi
}

step_config() {
  echo -e "\n${W}== Configurar variáveis ==${N}"
  local d_domain d_email d_ssh d_vpn d_panel d_user d_dir d_ip

  d_domain="$DOMAIN"
  while :; do
    ask "$(t prompt_domain)" d_domain "$d_domain"
    valid_domain "$d_domain" && break
    warn "$(t invalid_domain)"
  done

  d_email="$EMAIL"
  ask_allow_empty "$(t prompt_email)" d_email
  if [ -n "$d_email" ] && ! [[ "$d_email" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
    warn "$(t invalid_email)"
  fi

  d_ssh="$SSH_PORT"
  while :; do
    ask "$(t prompt_ssh_port)" d_ssh "$d_ssh"
    valid_port "$d_ssh" && break
    warn "$(t invalid_port)"
  done

  d_vpn="$VPN_PORT"
  while :; do
    ask "$(t prompt_vpn_port)" d_vpn "$d_vpn"
    valid_port "$d_vpn" && break
    warn "$(t invalid_port)"
  done

  d_panel="$PANEL_PORT"
  while :; do
    ask "$(t prompt_panel_port)" d_panel "$d_panel"
    valid_port "$d_panel" && break
    warn "$(t invalid_port)"
  done

  # Loop único e claro: portas válidas, distintas, nenhuma em 80/443
  while :; do
    if valid_port "$d_ssh" && valid_port "$d_panel" \
       && [ "$d_panel" != "$d_ssh" ] \
       && [ "$d_panel" != 80 ] && [ "$d_panel" != 443 ] \
       && [ "$d_ssh" != 80 ] && [ "$d_ssh" != 443 ]; then
      break
    fi
    warn "$(t port_conflict)"
    ask "$(t prompt_ssh_port)" d_ssh "$d_ssh"
    ask "$(t prompt_panel_port)" d_panel "$d_panel"
  done

  d_user="$PANEL_USER"
  while :; do
    ask "$(t prompt_panel_user)" d_user "$d_user"
    [[ "$d_user" =~ ^[A-Za-z0-9_.@-]+$ ]] && break
    warn "$(t invalid_user)"
  done

  d_dir="$INSTALL_DIR"
  while :; do
    ask "$(t prompt_install_dir)" d_dir "$d_dir"
    [[ "$d_dir" =~ ^/[A-Za-z0-9_./-]+$ && "$d_dir" != *'/../'* && "$d_dir" != */.. ]] && break
    warn "$(t invalid_dir)"
  done

  d_ip="$ADMIN_IP"
  while :; do
    ask "$(t prompt_admin_ip)" d_ip "$d_ip"
    { [ -z "$d_ip" ] || valid_ipv4_or_cidr "$d_ip"; } && break
    warn "$(t invalid_ip)"
  done

  # Só agora commit atômico nos globais + save
  DOMAIN="$d_domain"
  EMAIL="$d_email"
  SSH_PORT="$d_ssh"
  VPN_PORT="$d_vpn"
  PANEL_PORT="$d_panel"
  PANEL_USER="$d_user"
  INSTALL_DIR="$d_dir"
  ADMIN_IP="$d_ip"
  save_conf
  ok "$(t conf_saved) $CONF_FILE"

  # Senha do painel: pedir se ausente; se existir, oferecer troca
  if [ -z "$PANEL_PASS_HASH" ]; then
    set_panel_password
  else
    if confirm "$(t pass_already)" n; then
      set_panel_password
    fi
  fi
}
ensure_config() {
  load_conf
  [ -f "$CONF_FILE" ] || step_config
  if [ -z "$DOMAIN" ]; then
    err "$(t domain_not_set)"
    return 1
  fi
  valid_domain "$DOMAIN" || { err "$(t err_invalid_domain_conf) $CONF_FILE: $DOMAIN"; return 1; }
  if ! valid_port "$SSH_PORT" || ! valid_port "$VPN_PORT" || ! valid_port "$PANEL_PORT"; then
    err "$(t err_invalid_ports)"
    return 1
  fi
  [[ "$SSH_PORT" != 80 && "$SSH_PORT" != 443 && "$PANEL_PORT" != 80 && "$PANEL_PORT" != 443 && "$PANEL_PORT" != "$SSH_PORT" ]] || { err "$(t err_port_conflict)"; return 1; }
  if ! valid_port "$XRAY_PORT" || [ "$XRAY_PORT" = 80 ] || [ "$XRAY_PORT" = 443 ] || [ "$XRAY_PORT" = "$SSH_PORT" ] || [ "$XRAY_PORT" = "$PANEL_PORT" ]; then
    err "Porta XRAY_PORT inválida ou conflitante em $CONF_FILE."
    return 1
  fi
  [[ "$INSTALL_DIR" =~ ^/[A-Za-z0-9_./-]+$ && "$INSTALL_DIR" != *'/../'* && "$INSTALL_DIR" != */.. ]] || { err "$(t err_invalid_install_dir)"; return 1; }
  [[ "$PANEL_USER" =~ ^[A-Za-z0-9_.@-]+$ ]] || { err "$(t err_invalid_panel_user) $CONF_FILE."; return 1; }
  if [ -n "$PANEL_PASS_HASH" ]; then [[ "$PANEL_PASS_HASH" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] || { err "$(t err_invalid_pass_hash)"; return 1; }; fi
}

dc() {
  if docker compose version >/dev/null 2>&1; then docker compose "$@"; else docker-compose "$@"; fi
}

current_ssh_ports() {
  local p
  p=$(sshd -T 2>/dev/null | awk '/^port /{print $2}')
  echo "${p:-22}"
}

#---------------------------------------------------------------------
# 1) Sistema, Docker e sysctl
#---------------------------------------------------------------------
install_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    info "Instalando Docker (script oficial get.docker.com)..."
    pkg ca-certificates curl
    curl -fsSL https://get.docker.com | sh || { err "Falha ao instalar Docker."; return 1; }
  fi
  systemctl enable --now docker
  if ! docker compose version >/dev/null 2>&1; then
    pkg docker-compose-plugin || pkg docker-compose-v2 || pkg docker-compose
  fi
}

step_system() {
  ensure_config || return 1
  echo -e "\n${W}== Preparar sistema ==${N}"
  apt_update || return 1

  # Upgrade global é intrusivo (pode reiniciar serviços e afetar módulos já configurados).
  # Torna-se opcional e explícito.
  if confirm "Rodar 'apt-get upgrade -y' agora? (pode reiniciar serviços)" n; then
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  else
    info "Upgrade global ignorado. Apenas dependências mínimas serão instaladas."
  fi

  pkg ca-certificates curl openssl iproute2

  if ! command -v docker >/dev/null 2>&1; then
    info "Docker não encontrado, instalando..."
    install_docker || return 1
  else
    info "Docker já presente, garantindo serviço ativo (sem reinstalar)."
    systemctl enable --now docker
    if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
      pkg docker-compose-plugin || pkg docker-compose-v2 || pkg docker-compose
    fi
  fi

  info "Aplicando sysctl (forwarding, BBR, endurecimento de rede)..."
  modprobe tcp_bbr 2>/dev/null || true
  {
    echo "# Gerado por awg-setup"
    echo "net.ipv4.ip_forward = 1"
    echo "net.ipv6.conf.all.forwarding = 1"
    echo "net.ipv4.tcp_syncookies = 1"
    echo "net.ipv4.conf.all.rp_filter = 2"
    echo "net.ipv4.conf.default.rp_filter = 2"
    echo "net.ipv4.conf.all.accept_redirects = 0"
    echo "net.ipv4.conf.default.accept_redirects = 0"
    echo "net.ipv6.conf.all.accept_redirects = 0"
    echo "net.ipv4.conf.all.send_redirects = 0"
    echo "net.ipv4.icmp_echo_ignore_broadcasts = 1"
    echo "net.core.rmem_max = 4194304"
    echo "net.core.wmem_max = 4194304"
    if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
      echo "net.core.default_qdisc = fq"
      echo "net.ipv4.tcp_congestion_control = bbr"
    fi
  } > /etc/sysctl.d/99-awg.conf
  if ! sysctl --system >/dev/null; then
    err "Falha ao aplicar sysctl; revise /etc/sysctl.d/99-awg.conf e os logs do kernel."
    return 1
  fi
  ok "Sistema preparado."
}

#---------------------------------------------------------------------
# 2) Firewall (UFW)
#---------------------------------------------------------------------
step_firewall() {
  ensure_config || return 1
  echo -e "\n${W}== Firewall (UFW) ==${N}"
  pkg ufw || return 1
  local p
  # Libera as portas SSH em uso agora + a nova, para não perder o acesso
  for p in $(current_ssh_ports) "$SSH_PORT"; do
    ufw allow "$p"/tcp comment 'SSH' >/dev/null
  done
  ufw default deny incoming >/dev/null
  ufw default allow outgoing >/dev/null
  ufw allow 80/tcp  comment 'HTTP (ACME)' >/dev/null
  ufw allow 443/tcp comment 'HTTPS painel' >/dev/null
  ufw allow "$VPN_PORT"/udp comment 'AmneziaWG' >/dev/null
  if command -v xray >/dev/null 2>&1 || [ -x /usr/local/bin/xray ]; then
    ufw allow "$XRAY_PORT"/tcp comment 'Xray VLESS REALITY' >/dev/null
  fi
  # Default-deny forwarded traffic. Docker maintains its own explicit forwarding
  # chains for published ports and container egress; do not globally ACCEPT all
  # forwarded traffic just to make the VPN work.
  if grep -q '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw; then
    sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="DROP"/' /etc/default/ufw
  else
    printf '\nDEFAULT_FORWARD_POLICY="DROP"\n' >> /etc/default/ufw
  fi
  ufw --force enable
  info "DEFAULT_FORWARD_POLICY=DROP: o container AmneziaWG precisa fazer NAT interno (responsabilidade da imagem). Se clientes VPN não navegarem, verifique iptables dentro do container."
  ufw reload
  ok "UFW ativo."
  ufw status numbered
}

#---------------------------------------------------------------------
# 3) AmneziaWG (Docker)
#---------------------------------------------------------------------
hash_password() {
  printf '%s' "$1" | openssl dgst -binary -sha256 | base64 -w0
}

set_panel_password() {
  local p1 p2 old
  while :; do
    read -rsp "$(t pass_prompt): " p1; echo
    read -rsp "$(t pass_repeat): " p2; echo
    [ "$p1" = "$p2" ] || { warn "$(t pass_mismatch)"; continue; }
    [ "${#p1}" -ge 12 ] || { warn "$(t pass_short)"; continue; }
    break
  done
  old="$PANEL_PASS_HASH"
  PANEL_PASS_HASH="$(hash_password "$p1")"
  [ "$PANEL_PASS_HASH" = "$old" ] || save_conf
  ok "$(t pass_saved)"
}

write_compose() {
  mkdir -p "$INSTALL_DIR/data"
  cat > "$INSTALL_DIR/docker-compose.yml" <<EOF
services:
  app:
    image: myceliummesh/amneziawg-ui:latest
    container_name: amneziawg-ui
    restart: unless-stopped
    ports:
      # Painel exposto só em localhost: acesso externo apenas via Nginx (HTTPS)
      - "127.0.0.1:${PANEL_PORT}:${PANEL_PORT}/tcp"
      - "${VPN_PORT}:${VPN_PORT}/udp"
    environment:
      WEB_UI_PORT: "${PANEL_PORT}"
      DEFAULT_PORT: "${VPN_PORT}"
      WEB_UI_USER: "${PANEL_USER}"
      WEB_UI_PASSWORD: "${PANEL_PASS_HASH}"
    volumes:
      - ${INSTALL_DIR}/data:/etc/amnezia
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    devices:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=0
      - net.ipv6.conf.all.forwarding=1
      - net.ipv6.conf.default.forwarding=1
EOF
  chmod 640 "$INSTALL_DIR/docker-compose.yml"
}

step_deploy() {
  ensure_config || return 1
  echo -e "\n${W}== Implantar AmneziaWG ==${N}"

  # Verificação passiva: NÃO instala, NÃO ativa, NÃO reinicia o Docker.
  if ! command -v docker >/dev/null 2>&1; then
    err "Docker não encontrado. Rode a opção 3 (Sistema + Firewall) primeiro."
    return 1
  fi
  if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
    err "docker compose não encontrado. Rode a opção 3 (Sistema + Firewall) primeiro."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    err "O daemon do Docker não está acessível. Verifique o serviço manualmente."
    return 1
  fi

  # /dev/net/tun obrigatório para a VPN
  if [ ! -c /dev/net/tun ]; then
    info "Dispositivo /dev/net/tun ausente; tentando carregar o módulo tun..."
    modprobe tun 2>/dev/null || true
  fi
  if [ ! -c /dev/net/tun ]; then
    err "módulo tun indisponível; habilite no host antes de implantar"
    return 1
  fi

  # Senha deve ter sido configurada antes (opção 1 ou 8).
  if [ -z "$PANEL_PASS_HASH" ]; then
    err "Senha do painel não configurada. Rode a opção 1 (Configurar) primeiro."
    return 1
  fi

  write_compose
  (cd "$INSTALL_DIR" && dc config -q && dc pull && dc up -d) || { err "Falha na validação do Compose ou ao subir o container."; return 1; }
  local i=0
  while [ "$i" -lt 30 ]; do
    docker inspect -f '{{.State.Running}}' amneziawg-ui 2>/dev/null | grep -qx true && break
    sleep 1
    i=$((i+1))
  done
  if ! docker inspect -f '{{.State.Running}}' amneziawg-ui 2>/dev/null | grep -qx true; then
    err "O container não está em execução. Logs recentes:"
    docker logs --tail 80 amneziawg-ui 2>&1 || true
    return 1
  fi
  if grep -q '^DEFAULT_FORWARD_POLICY="DROP"' /etc/default/ufw 2>/dev/null; then
    warn "UFW com forward DROP: se clientes VPN não tiverem internet, verifique NAT dentro do container."
  fi
  docker ps --filter name=amneziawg-ui
  docker logs --tail 25 amneziawg-ui 2>&1
  local http_code
  http_code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:${PANEL_PORT}/" 2>/dev/null || true)
  case "$http_code" in
    2??|3??|401|403) ok "Container em execução e painel respondendo localmente (HTTP ${http_code}): http://127.0.0.1:${PANEL_PORT}" ;;
    *) warn "Container em execução, mas o painel não respondeu com HTTP esperado (código: ${http_code:-sem resposta}) na porta ${PANEL_PORT}. Confira os logs e WEB_UI_PORT." ;;
  esac
  warn "Se o login falhar, confira o formato de WEB_UI_PASSWORD na documentação da imagem."
}

#---------------------------------------------------------------------
# 4) SSH: porta nova + endurecimento
#---------------------------------------------------------------------
step_ssh() {
  ensure_config || return 1
  echo -e "\n${W}== SSH: porta ${SSH_PORT} e endurecimento ==${N}"
  pkg openssh-server || return 1

  local conf=/etc/ssh/sshd_config hard=/etc/ssh/sshd_config.d/00-awg-hardening.conf
  local old_hard="" old_main="" had_hard=0 pw_line=""
  if command -v ufw >/dev/null 2>&1 && ! ufw status 2>/dev/null | grep -qE "^${SSH_PORT}/tcp[[:space:]]+ALLOW"; then
    warn "A porta ${SSH_PORT}/tcp NÃO está liberada no UFW. Rode a opção 3 (Sistema + Firewall) antes de encerrar a sessão atual."
  fi

  mkdir -p /etc/ssh/sshd_config.d
  [ -f "$conf" ] || { err "Arquivo $conf não encontrado."; return 1; }
  old_main=$(cat "$conf")
  if [ -f "$hard" ]; then had_hard=1; old_hard=$(cat "$hard"); fi

  # OpenSSH uses the first obtained value for many directives. Ensure the
  # include is first so the dedicated override actually takes effect.
  if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$conf"; then
    { printf 'Include /etc/ssh/sshd_config.d/*.conf\n'; cat "$conf"; } > "${conf}.awg-tmp" || return 1
    cat "${conf}.awg-tmp" > "$conf" && rm -f "${conf}.awg-tmp"
  elif ! head -n 1 "$conf" | grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf'; then
    # Existing Include later in the file can cause the main Port to win.
    sed -i '/^[[:space:]]*Include[[:space:]]\+\/etc\/ssh\/sshd_config\.d\/\*\.conf/d' "$conf"
    { printf 'Include /etc/ssh/sshd_config.d/*.conf\n'; cat "$conf"; } > "${conf}.awg-tmp" || return 1
    cat "${conf}.awg-tmp" > "$conf" && rm -f "${conf}.awg-tmp"
  fi

  if [ -s /root/.ssh/authorized_keys ]; then
    if confirm "Chave SSH encontrada em /root/.ssh/authorized_keys. Desativar login por senha?" n; then
      pw_line="PasswordAuthentication no"
    else
      pw_line="PasswordAuthentication yes"
    fi
  else
    warn "Sem chave em /root/.ssh/authorized_keys: PermitRootLogin prohibit-password impede login root por senha."
    if ! confirm "Você NÃO tem chave SSH. Root ficará sem login por senha. Tem CERTEZA que quer continuar?" n; then
      err "Abortado: configure uma chave SSH em /root/.ssh/authorized_keys antes de endurecer o SSH."
      return 1
    fi
    pw_line="PasswordAuthentication yes"
  fi

  cat > "$hard" <<EOF
Port ${SSH_PORT}
PermitRootLogin prohibit-password
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
${pw_line}
EOF

  if ! sshd -t; then
    err "Configuração SSH inválida; restaurando os arquivos alterados."
    printf '%s\n' "$old_main" > "$conf"
    if [ "$had_hard" = 1 ]; then printf '%s\n' "$old_hard" > "$hard"; else rm -f "$hard"; fi
    return 1
  fi

  # If socket activation is used, switch to the service only after validation.
  if systemctl is-active --quiet ssh.socket 2>/dev/null; then
    systemctl disable --now ssh.socket || true
    systemctl enable ssh.service >/dev/null 2>&1 || true
  fi
  if ! (systemctl restart ssh 2>/dev/null || systemctl restart sshd); then
    err "Não foi possível reiniciar o SSH; restaurando a configuração anterior."
    printf '%s\n' "$old_main" > "$conf"
    if [ "$had_hard" = 1 ]; then printf '%s\n' "$old_hard" > "$hard"; else rm -f "$hard"; fi
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
    return 1
  fi

  sleep 2
  if ! ss -H -ltn | awk '{print $4}' | grep -Eq "(^|:)${SSH_PORT}$"; then
    err "sshd não está escutando na porta ${SSH_PORT}; restaurando a configuração anterior."
    printf '%s\n' "$old_main" > "$conf"
    if [ "$had_hard" = 1 ]; then printf '%s\n' "$old_hard" > "$hard"; else rm -f "$hard"; fi
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
    return 1
  fi

  ok "sshd escutando na porta ${SSH_PORT}."
  warn "Mantenha esta sessão aberta. Em OUTRO terminal teste: ssh -p ${SSH_PORT} root@$(hostname -I | awk '{print $1}')"
  warn "Após validar, rode a opção 3 para liberar a nova porta. A porta antiga não é removida automaticamente."
}

#---------------------------------------------------------------------
# 5) Fail2Ban
#---------------------------------------------------------------------
step_fail2ban() {
  ensure_config || return 1
  echo -e "\n${W}== Fail2Ban ==${N}"
  pkg fail2ban || return 1
  # python3-systemd: necessário em alguns backends systemd do Fail2Ban
  pkg python3-systemd >/dev/null 2>&1 || true

  local ssh_backend="auto"
  if python3 -c 'import systemd' 2>/dev/null; then
    ssh_backend="systemd"
  else
    warn "python3-systemd indisponível; jail [sshd] usará backend=auto (em vez de systemd)."
  fi

  # Log do Nginx: cria vazio para o Fail2Ban não falhar na validação.
  # As jails nginx-* só terão efeito após o Nginx estar ativo.
  local nginx_present=0
  if command -v nginx >/dev/null 2>&1; then
    nginx_present=1
  fi
  mkdir -p /var/log/nginx
  [ -f /var/log/nginx/access.log ] || touch /var/log/nginx/access.log

  local ign="127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12"
  if [ -n "$ADMIN_IP" ]; then
    if valid_ipv4_or_cidr "$ADMIN_IP"; then ign="$ign $ADMIN_IP"; else warn "ADMIN_IP inválido; não será incluído no ignoreip do Fail2Ban."; fi
  fi

  # Obs.: o Nginx roda no HOST, então o tráfego passa pela cadeia INPUT
  # (a cadeia DOCKER-USER só filtra tráfego encaminhado a containers).
  cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
ignoreip = ${ign}
backend = auto

[sshd]
enabled = true
port = ${SSH_PORT}
backend = ${ssh_backend}
maxretry = 3
bantime = 30m

[nginx-4xx]
enabled = true
port = http,https
filter = nginx-4xx
logpath = /var/log/nginx/access.log
maxretry = 15
bantime = 15m

[nginx-auth]
enabled = true
port = http,https
filter = nginx-auth
logpath = /var/log/nginx/access.log
maxretry = 3
bantime = 1h

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 24h

[nginx-exploit]
enabled = true
port = http,https
filter = nginx-exploit
logpath = /var/log/nginx/access.log
maxretry = 1
bantime = 48h

# Reincidentes: banimento longo em todas as portas
[recidive]
enabled = true
logpath = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime = 1w
findtime = 1d
maxretry = 3
EOF

  cat > /etc/fail2ban/filter.d/nginx-4xx.conf <<'EOF'
[Definition]
failregex = ^<HOST> - \S+ \[[^\]]+\] "[^"]*" 4\d\d \d+
ignoreregex =
EOF

  cat > /etc/fail2ban/filter.d/nginx-auth.conf <<'EOF'
[Definition]
failregex = ^<HOST> - \S+ \[[^\]]+\] "[^"]*" (?:401|403) \d+
ignoreregex =
EOF

  cat > /etc/fail2ban/filter.d/nginx-botsearch.conf <<'EOF'
[Definition]
failregex = ^<HOST> - \S+ \[[^\]]+\] "[A-Z]+ [^"]*(?:wp-login|wp-admin|wp-content|wp-includes|xmlrpc\.php|phpmyadmin|phpMyAdmin|/pma/|\.env|\.git/|\.aws|\.ssh|cgi-bin|boaform|HNAP1|actuator|vendor/phpunit|shell\.php|setup\.php|config\.php|admin\.php)[^"]*"
ignoreregex =
EOF

  cat > /etc/fail2ban/filter.d/nginx-exploit.conf <<'EOF'
[Definition]
failregex = ^<HOST> - \S+ \[[^\]]+\] "[^"]*(?:\.\./|%2[eE]%2[eE]|/etc/passwd|/bin/(?:ba)?sh|[uU][nN][iI][oO][nN](?:%20|\+| )+[sS][eE][lL][eE][cC][tT]|<script|\$\{jndi|base64_decode|eval\(|\\x[0-9A-Fa-f]{2})[^"]*"
ignoreregex =
EOF

  chmod 644 /etc/fail2ban/jail.local /etc/fail2ban/filter.d/nginx-*.conf
  if ! fail2ban-client -t >/dev/null 2>&1; then
    err "Configuração do Fail2Ban inválida:"; fail2ban-client -t; return 1
  fi
  systemctl enable fail2ban >/dev/null 2>&1 || return 1
  if ! systemctl restart fail2ban; then err "Falha ao reiniciar Fail2Ban."; return 1; fi
  sleep 2
  if ! fail2ban-client ping >/dev/null 2>&1; then err "Fail2Ban não respondeu após reiniciar."; return 1; fi
  fail2ban-client status
  ok "Fail2Ban ativo (jails: sshd, nginx-4xx, nginx-auth, nginx-botsearch, nginx-exploit, recidive)."
  if [ "$nginx_present" = 0 ]; then
    warn "Nginx não detectado. As jails nginx-* só terão efeito após configurar o Nginx (opção 5)."
  fi
}

#---------------------------------------------------------------------
# 6) Nginx + SSL + headers de segurança
#---------------------------------------------------------------------
step_nginx() {
  ensure_config || return 1
  echo -e "\n${W}== Nginx + Let's Encrypt ==${N}"
  pkg nginx certbot curl || return 1

  # DNS aponta para esta VPS?
  valid_domain "$DOMAIN" || { err "Domínio inválido: $DOMAIN"; return 1; }
  local pub res pub6 res6
  pub=$(curl -4fsS --max-time 8 https://api.ipify.org 2>/dev/null || curl -4fsS --max-time 8 https://ifconfig.me 2>/dev/null || true)
  res=$(getent ahostsv4 "$DOMAIN" | awk 'NR==1{print $1}')
  pub6=$(curl -6fsS --max-time 8 https://api64.ipify.org 2>/dev/null || true)
  res6=$(getent ahostsv6 "$DOMAIN" | awk 'NR==1{print $1}')
  info "IPv4 público: ${pub:-desconhecido} | DNS A: ${res:-nada}"
  [ -z "$res6" ] || info "IPv6 público: ${pub6:-indisponível} | DNS AAAA: ${res6}"
  if [ -z "$res" ] || [ -z "$pub" ] || [ "$res" != "$pub" ]; then
    warn "O registro A não corresponde ao IPv4 público da VPS."
    confirm "Continuar mesmo assim?" n || return 1
  fi
  if [ -n "$res6" ] && { [ -z "$pub6" ] || [ "$res6" != "$pub6" ]; }; then
    warn "Existe um registro AAAA que não corresponde ao IPv6 público detectado; isso pode quebrar o ACME/acesso IPv6."
    confirm "Continuar mesmo assim?" n || return 1
  fi

  local ver
  ver=$(nginx -v 2>&1 | sed 's/.*\///')

  # Arquivo global (contexto http): sem versão, rate limit e map do WebSocket
  cat > /etc/nginx/conf.d/00-awg-security.conf <<'EOF'
server_tokens off;
limit_req_zone $binary_remote_addr zone=awgui:10m rate=10r/s;
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
EOF

  mkdir -p /var/www/html
  rm -f /etc/nginx/sites-enabled/default

  # Fase 1: só HTTP (desafio ACME)
  cat > /etc/nginx/sites-available/amneziawg-ui <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    return 444;
}
server {
    listen 80;
    server_name __DOMAIN__;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://$host$request_uri; }
}
EOF
  sed -i "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/amneziawg-ui
  ln -sf /etc/nginx/sites-available/amneziawg-ui /etc/nginx/sites-enabled/
  nginx -t || return 1
  systemctl enable --now nginx >/dev/null 2>&1
  systemctl reload nginx

  if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    local -a mail_opt
    if [ -n "$EMAIL" ]; then mail_opt=(-m "$EMAIL"); else mail_opt=(--register-unsafely-without-email); fi
    certbot certonly --webroot -w /var/www/html -d "$DOMAIN" \
      --non-interactive --agree-tos "${mail_opt[@]}" || { err "Falha ao emitir o certificado."; return 1; }
  else
    if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" ] || ! openssl x509 -in "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" -noout -checkend 0 >/dev/null 2>&1; then
      warn "O certificado existente está incompleto ou expirado; tentando renovar/reemitir."
      local -a renewal_mail_opt
      if [ -n "$EMAIL" ]; then renewal_mail_opt=(-m "$EMAIL"); else renewal_mail_opt=(--register-unsafely-without-email); fi
      certbot certonly --webroot -w /var/www/html -d "$DOMAIN" --non-interactive --agree-tos \
        "${renewal_mail_opt[@]}" || { err "Falha ao renovar/reemitir o certificado."; return 1; }
    else
      info "Certificado existente e ainda válido, reaproveitando."
    fi
  fi
  mkdir -p /etc/letsencrypt/renewal-hooks/deploy
  printf '#!/bin/sh\nsystemctl reload nginx\n' > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
  chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

  # Sintaxe do HTTP/2 depende da versão (>= 1.25.1 usa "http2 on;")
  local listen443 http2line=""
  if [ "$(printf '%s\n1.25.1\n' "$ver" | sort -V | head -1)" = "1.25.1" ]; then
    listen443="listen 443 ssl;"; http2line="http2 on;"
  else
    listen443="listen 443 ssl http2;"
  fi

  # Fase 2: configuração final
  cat > /etc/nginx/sites-available/amneziawg-ui <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    return 444;
}

server {
    listen 443 ssl default_server;
    server_name _;
    ssl_certificate     /etc/letsencrypt/live/__DOMAIN__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__DOMAIN__/privkey.pem;
    return 444;
}

server {
    listen 80;
    server_name __DOMAIN__;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://$host$request_uri; }
}

server {
    __LISTEN443__
    __HTTP2__
    server_name __DOMAIN__;

    ssl_certificate     /etc/letsencrypt/live/__DOMAIN__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__DOMAIN__/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/__DOMAIN__/chain.pem;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'; frame-ancestors 'none';" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Resource-Policy "same-origin" always;
    # COEP: require-corp descomente se o painel for 100% self-hosted
    # add_header Cross-Origin-Embedder-Policy "require-corp" always;

    location / {
        limit_req zone=awgui burst=40 nodelay;
        proxy_pass http://127.0.0.1:__PANEL_PORT__;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
EOF
  sed -i \
    -e "s|__DOMAIN__|${DOMAIN}|g" \
    -e "s|__PANEL_PORT__|${PANEL_PORT}|g" \
    -e "s|__LISTEN443__|${listen443}|g" \
    -e "s|__HTTP2__|${http2line}|g" \
    /etc/nginx/sites-available/amneziawg-ui

  if nginx -t; then
    systemctl reload nginx
    ok "Nginx configurado: https://${DOMAIN}"
  else
    err "nginx -t falhou. Verifique /etc/nginx/sites-available/amneziawg-ui"
    return 1
  fi
}

#---------------------------------------------------------------------
# 7) Restrição geográfica do SSH (somente Brasil) - opcional
#---------------------------------------------------------------------
step_geoblock() {
  ensure_config || return 1
  echo -e "\n${W}== Restrição geográfica do SSH (Brasil) ==${N}"
  warn "RISCO DE BLOQUEIO: se o seu IP não for brasileiro nem estiver na whitelist, você perde o SSH."
  warn "Regra só para IPv4 e só para conexões NOVAS. Fail-open: se a lista não baixar, nada é bloqueado."
  confirm "Continuar?" n || return 0
  pkg ipset iptables curl || return 1

  while [ -z "$ADMIN_IP" ] || ! valid_ipv4_or_cidr "$ADMIN_IP"; do
    ask "IP IPv4/CIDR para whitelist (obrigatório para reduzir risco de bloqueio)" ADMIN_IP ""
    if [ -n "$ADMIN_IP" ] && ! valid_ipv4_or_cidr "$ADMIN_IP"; then warn "IPv4/CIDR inválido."; fi
  done
  touch "$WL_FILE"
  [ -n "$ADMIN_IP" ] && ! grep -qxF "$ADMIN_IP" "$WL_FILE" && echo "$ADMIN_IP" >> "$WL_FILE"
  info "Whitelist em $WL_FILE (um IP/CIDR por linha)."

  cat > /usr/local/bin/update-br-ips.sh <<'EOF'
#!/usr/bin/env bash
# Atualiza o ipset br_ips e garante a regra de SSH restrito ao Brasil
set -u
set -o pipefail
[ -f /etc/awg-setup.conf ] && . /etc/awg-setup.conf
SSH_PORT="${SSH_PORT:-49152}"
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
  logger -t awg-geo "SSH_PORT inválido; abortando"
  exit 1
fi
SET=br_ips
URL="https://www.ipdeny.com/ipblocks/data/countries/br.zone"
WL=/etc/awg-ssh-whitelist.txt
tmp=$(mktemp)
restore_file=$(mktemp)
trap 'rm -f "$tmp" "$restore_file"' EXIT

if ! curl -fsS --max-time 60 -o "$tmp" "$URL" || [ "$(wc -l < "$tmp")" -lt 100 ]; then
  logger -t awg-geo "Falha ao baixar lista BR; mantendo estado atual"
  exit 1
fi
valid_ipv4_cidr() {
  local value="${1:-}" ip prefix octet
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]] || return 1
  ip="${value%%/*}"; prefix="${value#*/}"
  IFS=. read -r -a octets <<< "$ip"
  for octet in "${octets[@]}"; do (( 10#$octet <= 255 )) || return 1; done
  [[ "$value" != */* ]] || (( 10#$prefix <= 32 ))
}
# Validate every downloaded network before touching the active set.
while IFS= read -r network; do
  valid_ipv4_cidr "$network" || { logger -t awg-geo "Lista BR contém rede inválida: $network"; exit 1; }
done < "$tmp"
# Validate whitelist entries rather than silently feeding malformed values to ipset.
if [ -f "$WL" ]; then
  while IFS= read -r entry || [ -n "$entry" ]; do
    [[ -z "$entry" || "$entry" =~ ^[[:space:]]*# ]] && continue
    valid_ipv4_cidr "$entry" || { logger -t awg-geo "Whitelist contém entrada inválida: $entry"; exit 1; }
  done < "$WL"
fi
ipset create "$SET" hash:net -exist
# Build a new set and only swap after the entire restore succeeds.
{
  echo "create ${SET}_new hash:net -exist"
  echo "flush ${SET}_new"
  sed "s/^/add ${SET}_new /" "$tmp"
  if [ -f "$WL" ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$WL" | sed "s/^/add ${SET}_new /"
  fi
} > "$restore_file"
if ! ipset restore -exist < "$restore_file"; then
  ipset destroy "${SET}_new" 2>/dev/null || true
  logger -t awg-geo "Falha ao montar lista temporária; conjunto ativo mantido"
  exit 1
fi
if ! ipset swap "${SET}_new" "$SET"; then
  ipset destroy "${SET}_new" 2>/dev/null || true
  logger -t awg-geo "Falha ao trocar conjunto; conjunto ativo mantido"
  exit 1
fi
ipset destroy "${SET}_new" || exit 1
RULE=(INPUT -p tcp --dport "$SSH_PORT" -m conntrack --ctstate NEW -m set ! --match-set "$SET" src -j DROP)
iptables -C "${RULE[@]}" 2>/dev/null || iptables -I "${RULE[@]}" || exit 1
# Remove stale geo-block rules for former SSH ports only after the current rule exists.
while IFS= read -r rule; do
  [[ "$rule" == *"--dport $SSH_PORT "* ]] && continue
  rule=${rule#-A INPUT }
  read -r -a rule_args <<< "$rule"
  iptables -D INPUT "${rule_args[@]}" 2>/dev/null || true
done < <(iptables -S INPUT 2>/dev/null | grep -F -- "--match-set $SET src" || true)
logger -t awg-geo "Lista BR atualizada ($(ipset list "$SET" -terse | awk '/Number of entries/{print $4}') entradas)"
EOF
  chmod 755 /usr/local/bin/update-br-ips.sh

  cat > /etc/systemd/system/awg-geo-ssh.service <<'EOF'
[Unit]
Description=Atualiza lista de IPs BR e regra de SSH
After=network-online.target ufw.service
Wants=network-online.target

[Service]
Type=oneshot
TimeoutStartSec=90
ExecStart=/usr/local/bin/update-br-ips.sh
EOF
  cat > /etc/systemd/system/awg-geo-ssh.timer <<'EOF'
[Unit]
Description=Atualização diária da lista de IPs BR

[Timer]
OnBootSec=15s
OnUnitActiveSec=1d
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload

  if /usr/local/bin/update-br-ips.sh; then
    if [[ "$ADMIN_IP" == */* ]]; then
      info "Whitelist contém CIDR $ADMIN_IP — verifique manualmente que seu IP está coberto."
    elif [ -n "$ADMIN_IP" ] && ipset test br_ips "$ADMIN_IP" 2>/dev/null; then
      ok "Seu IP ($ADMIN_IP) está liberado."
    else
      warn "Não consegui confirmar que seu IP está liberado. Teste em outro terminal ANTES de sair."
    fi
    systemctl enable --now awg-geo-ssh.timer
    ok "Geo-block ativo (timer diário + no boot)."
  else
    err "Falha ao baixar a lista; geo-block NÃO foi ativado."
  fi
}

step_geoblock_off() {
  systemctl disable --now awg-geo-ssh.timer 2>/dev/null || true
  # Remove every INPUT rule that references this set, even if SSH_PORT changed.
  local line
  while IFS= read -r line; do
    line=${line#-A INPUT }
    # Convert the rule specification to positional arguments without eval.
    read -r -a _rule <<< "$line"
    iptables -D INPUT "${_rule[@]}" 2>/dev/null || true
  done < <(iptables -S INPUT 2>/dev/null | grep -F -- '--match-set br_ips src' || true)
  ipset destroy br_ips 2>/dev/null || true
  ipset destroy br_ips_new 2>/dev/null || true
  ok "Geo-block desativado."
}

#---------------------------------------------------------------------
# 8) Manutenção e atualizações automáticas
#---------------------------------------------------------------------
step_maintenance() {
  ensure_config || return 1
  echo -e "\n${W}== Manutenção automática ==${N}"
  local upd="no"
  confirm "Atualizar a imagem do container automaticamente toda semana? (tag :latest pode trazer mudanças)" n && upd="yes"

  cat > /usr/local/bin/awg-maintenance.sh <<EOF
#!/usr/bin/env bash
set -u
LOG=/var/log/awg-maintenance.log
exec >>"\$LOG" 2>&1
set -o pipefail
echo "=== \$(date -Is) ==="
compose() { if docker compose version >/dev/null 2>&1; then docker compose "\$@"; elif command -v docker-compose >/dev/null 2>&1; then docker-compose "\$@"; else return 127; fi; }
if [ "$upd" = "yes" ]; then
  if cd "$INSTALL_DIR" && compose pull && compose up -d; then
    sleep 5
    if docker inspect -f '{{.State.Running}}' amneziawg-ui 2>/dev/null | grep -qx true; then
      echo "Container atualizado e em execução."
    else
      echo "ERRO: container não está em execução após atualização." >&2
      exit 1
    fi
  else
    echo "ERRO: atualização da imagem/compose falhou; limpeza de imagens ignorada." >&2
    exit 1
  fi
fi
docker image prune -f || echo "AVISO: docker image prune falhou." >&2
apt-get -y autoremove --purge || echo "AVISO: apt autoremove falhou." >&2
apt-get -y clean || echo "AVISO: apt clean falhou." >&2
journalctl --vacuum-time=14d || echo "AVISO: limpeza do journal falhou." >&2
fail2ban-client status 2>/dev/null | tail -n 3 || true
EOF
  chmod 755 /usr/local/bin/awg-maintenance.sh

  cat > /etc/systemd/system/awg-maintenance.service <<'EOF'
[Unit]
Description=Manutenção AmneziaWG

[Service]
Type=oneshot
ExecStart=/usr/local/bin/awg-maintenance.sh
EOF
  cat > /etc/systemd/system/awg-maintenance.timer <<'EOF'
[Unit]
Description=Manutenção semanal AmneziaWG

[Timer]
OnCalendar=Sun *-*-* 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
  cat > /etc/logrotate.d/awg-maintenance <<'EOF'
/var/log/awg-maintenance.log {
    monthly
    rotate 3
    compress
    missingok
    notifempty
}
EOF
  systemctl daemon-reload
  systemctl enable --now awg-maintenance.timer

  if confirm "Ativar atualizações automáticas de segurança do sistema (unattended-upgrades, sem reboot automático)?" y; then
    pkg unattended-upgrades || return 1
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
    ok "unattended-upgrades ativo."
  fi
  ok "Manutenção agendada (domingo 04:00)."
}

#---------------------------------------------------------------------
# 9) Parâmetros de ofuscação AmneziaWG 3.1
#---------------------------------------------------------------------
step_awg_params() {
  echo -e "\n${W}== Guia de ofuscação (AmneziaWG 3.1) ==${N}"
  cat <<EOF
${W}Prioridade 1 - I1 (pacote de assinatura):${N}
  A DPI costuma julgar a conexão pelo primeiro pacote. Se o servidor for
  bloqueado, troque primeiro o I1 (disfarce de QUIC tem a melhor taxa de
  sucesso; DNS é a alternativa). No painel, regenere ou personalize o I1.

${W}Prioridade 2 - Pacotes de lixo:${N}
  Jc (quantidade): 4 a 8 (valores altos parecem anormais)
  Jmin/Jmax: 64 a 512, com Jmax abaixo do MTU (1280)

${W}Erros a evitar:${N}
  - S1 + 56 não pode ser igual a S2
  - H1 a H4 não podem ser 1, 2, 3, 4 (reservados do WireGuard)
  - Faixas de H1 a H4 não podem se sobrepor
  - Use o cliente AmneziaVPN/AmneziaWG, não o WireGuard oficial

${W}Valores sugeridos agora (aleatórios, respeitando as regras acima):${N}
EOF
  local jc jmin jmax s1 s2 q i lo hi start end
  jc=$(shuf -i 4-8 -n1)
  jmin=$(shuf -i 64-128 -n1)
  jmax=$(shuf -i 256-512 -n1)
  s1=$(shuf -i 15-150 -n1)
  while :; do s2=$(shuf -i 15-150 -n1); [ $((s1 + 56)) -ne "$s2" ] && break; done
  echo "  Jc=$jc  Jmin=$jmin  Jmax=$jmax"
  echo "  S1=$s1  S2=$s2   (S1+56=$((s1 + 56)) != S2)"
  q=1073741823
  for i in 0 1 2 3; do
    lo=$((i * q + 5)); hi=$(((i + 1) * q - 200000))
    start=$(shuf -i "$lo-$hi" -n1)
    end=$((start + $(shuf -i 1000-100000 -n1)))
    echo "  H$((i + 1))=${start}-${end}   (valor único, se o painel não aceitar faixa: ${start})"
  done
  echo
  info "Estes valores são só um ponto de partida; o painel também gera os seus. O servidor e todos os clientes precisam usar os MESMOS parâmetros."
}

#---------------------------------------------------------------------
# Xray VLESS + REALITY (instalação independente do AmneziaWG)
#---------------------------------------------------------------------
XRAY_INSTALL_URL="https://github.com/XTLS/Xray-install/raw/main/install-release.sh"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_CLIENT_FILE="/root/xray-vless-reality.txt"

xray_install_core() {
  local installer
  installer=$(mktemp /tmp/xray-install.XXXXXX.sh) || return 1
  info "Baixando instalador oficial XTLS/Xray-install..."
  if ! curl -fsSL --retry 3 --connect-timeout 15 "$XRAY_INSTALL_URL" -o "$installer"; then
    rm -f "$installer"
    err "Não foi possível baixar o instalador oficial do Xray."
    return 1
  fi
  if ! bash "$installer" install --manually-restart-later; then
    rm -f "$installer"
    err "Falha na instalação do Xray-core."
    return 1
  fi
  rm -f "$installer"
  command -v xray >/dev/null 2>&1 || [ -x /usr/local/bin/xray ] || {
    err "Instalador terminou, mas o binário Xray não foi encontrado."
    return 1
  }
  ok "Xray-core instalado/atualizado pelo instalador oficial."
}

step_xray_install() {
  ensure_config || return 1
  local port target sni uuid key_output private_key public_key short_id tmp_config tmp_client
  echo -e "\n${W}== Xray VLESS + REALITY ==${N}"
  echo "Este serviço é independente do AmneziaWG e usará TCP."
  port="$XRAY_PORT"
  while :; do
    ask "Porta TCP do Xray (padrão 8443; 443 está reservado ao Nginx)" port "$port"
    if ! valid_port "$port" || [ "$port" = 80 ] || [ "$port" = 443 ] || [ "$port" = "$SSH_PORT" ] || [ "$port" = "$PANEL_PORT" ]; then
      warn "Porta inválida ou conflitante com HTTP/HTTPS, SSH ou painel."
      continue
    fi
    break
  done
  target="$XRAY_TARGET"
  while :; do
    ask "Host de destino REALITY (sem :porta; TLS 1.3 e HTTP/2)" target "$target"
    valid_domain "$target" && break
    warn "Informe um hostname válido, sem protocolo, caminho ou porta."
  done
  sni="$XRAY_SNI"
  while :; do
    ask "ServerName/SNI aceito pelo host de destino" sni "$sni"
    valid_domain "$sni" && break
    warn "Informe um hostname válido."
  done

  if ! getent ahosts "$target" >/dev/null 2>&1; then
    err "O host de destino não resolve via DNS: $target"
    return 1
  fi
  if ! timeout 8 bash -c ':</dev/tcp/$1/443' _ "$target" 2>/dev/null; then
    err "Não foi possível alcançar ${target}:443 a partir desta VPS."
    return 1
  fi
  systemctl stop xray 2>/dev/null || true
  if ss -ltnH "sport = :${port}" 2>/dev/null | grep -q .; then
    err "A porta TCP ${port} já está em uso por outro serviço."
    return 1
  fi

  pkg ca-certificates curl openssl iproute2 || return 1
  xray_install_core || return 1
  uuid=$(xray uuid 2>/dev/null) || { err "Falha ao gerar UUID."; return 1; }
  key_output=$(xray x25519 2>/dev/null) || { err "Falha ao gerar chaves REALITY."; return 1; }
  private_key=$(printf '%s\n' "$key_output" | awk -F': *' '/^(PrivateKey|Private key):/{print $2; exit}')
  public_key=$(printf '%s\n' "$key_output" | awk -F': *' '/^(Password|PublicKey|Public key):/{print $2; exit}')
  if [ -z "$private_key" ] || [ -z "$public_key" ] || ! [[ "$uuid" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    err "Não foi possível interpretar a saída de 'xray x25519' ou 'xray uuid'."
    return 1
  fi
  short_id=$(openssl rand -hex 8) || return 1

  mkdir -p /usr/local/etc/xray || return 1
  if getent group xray >/dev/null 2>&1; then
    chown root:xray /usr/local/etc/xray
    chmod 750 /usr/local/etc/xray
  fi
  tmp_config=$(mktemp /usr/local/etc/xray/config.XXXXXX) || return 1
  cat > "$tmp_config" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${uuid}", "flow": "xtls-rprx-vision" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "target": "${target}:443",
          "xver": 0,
          "serverNames": ["${sni}"],
          "privateKey": "${private_key}",
          "shortIds": ["${short_id}"]
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ]
}
EOF
  chmod 640 "$tmp_config"
  if getent group xray >/dev/null 2>&1; then chown root:xray "$tmp_config"; fi
  if ! xray run -test -config "$tmp_config" 2>/dev/null \
     && ! xray -test -config "$tmp_config" 2>/dev/null; then
    rm -f "$tmp_config"
    systemctl start xray 2>/dev/null || true
    err "A validação da configuração do Xray falhou; configuração anterior preservada."
    return 1
  fi
  if ! mv -f "$tmp_config" "$XRAY_CONFIG"; then
    rm -f "$tmp_config"
    err "Não foi possível instalar a configuração do Xray."
    return 1
  fi
  chmod 640 "$XRAY_CONFIG"
  if getent group xray >/dev/null 2>&1; then chown root:xray "$XRAY_CONFIG"; fi

  XRAY_PORT="$port"
  XRAY_TARGET="$target"
  XRAY_SNI="$sni"
  save_conf

  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q 'Status: active'; then
    ufw allow "${port}/tcp" comment 'Xray VLESS REALITY' >/dev/null || warn "Não foi possível adicionar a regra UFW automaticamente."
  fi
  systemctl daemon-reload
  if ! systemctl enable --now xray; then
    err "Xray não iniciou. Consulte: journalctl -u xray -n 80 --no-pager"
    return 1
  fi
  if ! systemctl is-active --quiet xray; then
    err "Xray não está ativo após a inicialização."
    return 1
  fi

  local link
  link="vless://${uuid}@${DOMAIN}:${port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sni}&fp=chrome&pbk=${public_key}&sid=${short_id}&type=tcp#Xray-REALITY"
  umask 077
  tmp_client=$(mktemp /root/xray-client.XXXXXX) || return 1
  {
    echo "Xray VLESS + REALITY"
    echo "Servidor: ${DOMAIN}"
    echo "Porta TCP: ${port}"
    echo "UUID: ${uuid}"
    echo "SNI: ${sni}"
    echo "Fingerprint: chrome"
    echo "Public key: ${public_key}"
    echo "Short ID: ${short_id}"
    echo "Flow: xtls-rprx-vision"
    echo
    echo "Link de importação:"
    echo "$link"
  } > "$tmp_client"
  chmod 600 "$tmp_client"
  mv -f "$tmp_client" "$XRAY_CLIENT_FILE"

  ok "Xray VLESS + REALITY instalado e ativo na porta TCP ${port}."
  info "Link de cliente salvo em ${XRAY_CLIENT_FILE} (permissão 600)."
  echo
  echo "$link"
  warn "Libere TCP ${port} também no firewall/security group do provedor da VPS."
  info "Use um cliente compatível com Xray/REALITY (por exemplo, v2rayNG, v2rayN, NekoBox ou Hiddify)."
}

step_xray_status() {
  echo -e "\n${W}== Status Xray ==${N}"
  if command -v xray >/dev/null 2>&1 || [ -x /usr/local/bin/xray ]; then
    xray version 2>&1 | head -2
    systemctl --no-pager --full status xray 2>&1 | head -14 || true
    echo "Portas:"
    ss -ltnp 2>/dev/null | grep -E ":${XRAY_PORT}([[:space:]]|$)" || true
    [ ! -f "$XRAY_CLIENT_FILE" ] || info "Dados do cliente: ${XRAY_CLIENT_FILE}"
  else
    info "Xray não está instalado."
  fi
}

step_xray_remove() {
  local installer
  if ! command -v xray >/dev/null 2>&1 && [ ! -x /usr/local/bin/xray ]; then
    info "Xray não está instalado."
    return 0
  fi
  confirm "Remover Xray, configuração REALITY e link de cliente?" n || return 0
  installer=$(mktemp /tmp/xray-remove.XXXXXX.sh) || return 1
  if ! curl -fsSL --retry 3 --connect-timeout 15 "$XRAY_INSTALL_URL" -o "$installer"; then
    rm -f "$installer"
    err "Não foi possível baixar o removedor oficial do Xray."
    return 1
  fi
  systemctl disable --now xray 2>/dev/null || true
  if ! bash "$installer" remove --purge; then
    rm -f "$installer"
    err "Falha na remoção oficial do Xray."
    return 1
  fi
  rm -f "$installer" "$XRAY_CLIENT_FILE"
  if command -v ufw >/dev/null 2>&1; then ufw delete allow "${XRAY_PORT}/tcp" >/dev/null 2>&1 || true; fi
  ok "Xray removido. AmneziaWG e os demais serviços foram mantidos."
}

xray_menu() {
  while :; do
    ui_section "Xray VLESS + REALITY"
    echo "  1) Instalar / reconfigurar Xray"
    echo "  2) Status do Xray"
    echo "  3) Remover somente Xray"
    echo "  0) Voltar"
    local xopt
    read -rp "${W}$(t option) > ${N}" xopt
    case "$xopt" in
      1) step_xray_install; pause ;;
      2) step_xray_status; pause ;;
      3) step_xray_remove; pause ;;
      0|q|Q) return 0 ;;
      *) warn "Opção inválida."; sleep 1 ;;
    esac
  done
}

#---------------------------------------------------------------------
# 10) Status / verificação
#---------------------------------------------------------------------
step_status() {
  ensure_config || return 1
  echo -e "\n${W}== Status ==${N}"
  echo -e "${B}-- Container --${N}"; docker ps --filter name=amneziawg-ui 2>/dev/null
  echo -e "${B}-- Xray --${N}"; systemctl is-active xray 2>/dev/null || echo "inativo/não instalado"
  echo -e "${B}-- Portas --${N}"; ss -tulpn 2>/dev/null | grep -E ":(${SSH_PORT}|80|443|${VPN_PORT}|${PANEL_PORT}|${XRAY_PORT}) " || true
  echo -e "${B}-- UFW --${N}"; ufw status 2>/dev/null | head -20
  echo -e "${B}-- Fail2Ban --${N}"
  if command -v fail2ban-client >/dev/null 2>&1; then
    local j
    for j in sshd nginx-4xx nginx-auth nginx-botsearch nginx-exploit recidive; do
      echo "[$j]"; fail2ban-client status "$j" 2>/dev/null | grep -E "Currently banned|Total banned" || echo "  inativa"
    done
  fi
  echo -e "${B}-- Nginx --${N}"; nginx -t 2>&1 | tail -2
  if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
  fi
  echo -e "${B}-- HTTPS --${N}"; curl -skI --max-time 8 "https://${DOMAIN}" | head -8
  echo -e "${B}-- Geo-block SSH --${N}"
  ipset list br_ips -terse 2>/dev/null | grep -E "Name|Number" || echo "  inativo"
  echo -e "${B}-- Timers --${N}"; systemctl list-timers 'awg-*' --no-pager 2>/dev/null | head -6
}

#---------------------------------------------------------------------
# Instalação completa e resumo
#---------------------------------------------------------------------
#---------------------------------------------------------------------
# Remoção completa (opções avançadas)
#---------------------------------------------------------------------
step_remove() {
  ensure_config || return 1
  echo -e "\n${W}== $(t remove_title) ==${N}"
  info "Será considerado para remoção:"
  echo "  - Container amneziawg-ui e imagem myceliummesh/amneziawg-ui"
  echo "  - ${INSTALL_DIR}/data (perguntado)"
  echo "  - ${INSTALL_DIR}/docker-compose.yml"
  echo "  - ${CONF_FILE}, ${WL_FILE}"
  echo "  - Nginx site amneziawg-ui + symlink"
  echo "  - Certificado Let's Encrypt de ${DOMAIN} (perguntado)"
  echo "  - Fail2Ban jail.local + filter.d/nginx-*.conf"
  echo "  - Units/timers awg-geo-ssh.*, awg-maintenance.*"
  echo "  - /usr/local/bin/update-br-ips.sh, awg-maintenance.sh"
  echo "  - ipset br_ips / regras iptables geo"
  echo "  - /var/log/awg-maintenance.log"
  echo
  confirm "$(t remove_warn)" n || return 0
  local word expected
  expected="$(t remove_type_word)"
  read -rp "$(t remove_confirm) [${expected}]: " word
  [ "$word" = "$expected" ] || { warn "Confirmação incorreta; abortado."; return 1; }

  # Xray é independente; oferecer remoção separada para evitar apagar sem consentimento.
  step_xray_remove
  # a) container
  if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    (cd "$INSTALL_DIR" && dc down --remove-orphans) 2>/dev/null || docker rm -f amneziawg-ui 2>/dev/null || true
  else
    docker rm -f amneziawg-ui 2>/dev/null || true
  fi
  # b) image
  docker image rm myceliummesh/amneziawg-ui:latest 2>/dev/null || true
  # c) data
  if [ -d "$INSTALL_DIR/data" ]; then
    confirm "$(t remove_data_q) $INSTALL_DIR/data?" n && rm -rf "$INSTALL_DIR/data"
  fi
  rm -f "$INSTALL_DIR/docker-compose.yml" 2>/dev/null || true
  # d) cert
  if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
    if confirm "$(t remove_cert_q) $DOMAIN?" n; then
      rm -rf "/etc/letsencrypt/live/${DOMAIN}" "/etc/letsencrypt/renewal/${DOMAIN}.conf" 2>/dev/null || true
    fi
  fi
  # e/f) timers/units
  systemctl disable --now awg-geo-ssh.timer awg-maintenance.timer 2>/dev/null || true
  rm -f /etc/systemd/system/awg-geo-ssh.service /etc/systemd/system/awg-geo-ssh.timer \
        /etc/systemd/system/awg-maintenance.service /etc/systemd/system/awg-maintenance.timer
  systemctl daemon-reload 2>/dev/null || true
  # g) scripts
  rm -f /usr/local/bin/update-br-ips.sh /usr/local/bin/awg-maintenance.sh
  # h) nginx site
  rm -f /etc/nginx/sites-enabled/amneziawg-ui /etc/nginx/sites-available/amneziawg-ui
  if command -v nginx >/dev/null 2>&1; then
    nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true
  fi
  # i) fail2ban
  rm -f /etc/fail2ban/jail.local /etc/fail2ban/filter.d/nginx-4xx.conf \
        /etc/fail2ban/filter.d/nginx-auth.conf /etc/fail2ban/filter.d/nginx-botsearch.conf \
        /etc/fail2ban/filter.d/nginx-exploit.conf
  systemctl restart fail2ban 2>/dev/null || true
  # j) geo
  step_geoblock_off
  # k) conf / logs
  rm -f "$CONF_FILE" "$WL_FILE" /var/log/awg-maintenance.log
  # l) install dir if empty
  rmdir "$INSTALL_DIR" 2>/dev/null || true

  ok "$(t remove_done)"
  info "$(t remove_kept)"
}

advanced_menu() {
  while :; do
    ui_section "$(t adv_title)"
    t adv_opt1
    t adv_opt2
    t adv_opt3
    echo "  4) Instalar / gerenciar Xray VLESS + REALITY"
    t adv_opt0
    echo
    local aopt
    read -rp "${W}$(t option) > ${N}" aopt
    case "$aopt" in
      1) toggle_lang; pause ;;
      2) step_remove; pause ;;
      3) step_awg_params; pause ;;
      4) xray_menu ;;
      0|q|Q) return 0 ;;
      *) warn "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

step_summary() {
  load_conf
  ui_section "RESUMO DA INSTALAÇÃO"
  echo "Script:      amneziawg-setup v${SCRIPT_VERSION}"
  echo "Painel:      https://${DOMAIN}   (usuário: ${PANEL_USER})"
  echo "VPN:         ${DOMAIN}:${VPN_PORT}/udp (AmneziaWG)"
  echo "Xray:        ${DOMAIN}:${XRAY_PORT}/tcp (VLESS + REALITY; se instalado)"
  echo "SSH:         porta ${SSH_PORT}"
  echo "Config:      ${CONF_FILE}   Compose: ${INSTALL_DIR}/docker-compose.yml"
  local https_ok="FALHOU"
  curl -skI --max-time 5 "https://${DOMAIN}" >/dev/null 2>&1 && https_ok="OK"
  echo "HTTPS:       ${https_ok}"
  if systemctl is-active --quiet xray 2>/dev/null; then
    echo "Xray:        ${DOMAIN}:${XRAY_PORT}/tcp (VLESS + REALITY, ativo)"
  else
    echo "Xray:        não instalado/inativo"
  fi
  echo
  echo "Próximos passos:"
  echo "  1. Entre no painel, crie o servidor/clientes e ajuste I1/Jc/Jmin/Jmax."
  echo "  2. Importe o cliente no app AmneziaVPN (não use o WireGuard oficial)."
  echo "  3. Se o login do painel falhar, confira o formato da senha na doc da imagem."
}

full_install() {
  ui_banner
  ui_section "INSTALAÇÃO COMPLETA"
  ensure_config || return 1

  ui_stage 1 8 "Preparação do sistema e Docker"
  step_system || return 1

  ui_stage 2 8 "Configuração do firewall"
  step_firewall || return 1

  # Senha: se ainda não existir, pedir agora.
  if [ -z "$PANEL_PASS_HASH" ]; then
    ui_stage 3 8 "Credenciais do painel"
    set_panel_password || return 1
  fi

  ui_stage 4 8 "Implantação do AmneziaWG"
  step_deploy || return 1

  ui_stage 5 8 "Nginx e certificado SSL"
  step_nginx || warn "Nginx/SSL falhou; a instalação continuará, mas HTTPS não deve ser considerado operacional. Corrija e rode a opção 5."

  ui_stage 6 8 "Proteção Fail2Ban"
  step_fail2ban || warn "Fail2Ban falhou; a proteção contra tentativas de login pode estar incompleta. Corrija e rode a opção 5."

  ui_stage 7 8 "Manutenção automática"
  step_maintenance || warn "Configuração da manutenção falhou; verifique timers e permissões."

  ui_stage 8 8 "Endurecimento SSH e restrição geográfica opcional"
  step_ssh || warn "A configuração SSH não foi validada; mantenha a sessão atual aberta e corrija antes de sair."
  confirm "Ativar também a restrição de SSH somente Brasil?" n && step_geoblock

  ui_section "INSTALAÇÃO — RESUMO FINAL"
  step_summary
}

#---------------------------------------------------------------------
# Menu (máx. 9 itens)
#---------------------------------------------------------------------
menu() {
  while :; do
    load_conf
    clear 2>/dev/null || true
    ui_banner
    echo -e "\n${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "${W}  $(t menu_title)${N}  ${C}v${SCRIPT_VERSION}${N}"
    echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
    echo -e "  ${B}DOMÍNIO${N}  ${C}${DOMAIN:-não configurado}${N}"
    echo -e "  ${B}SSH${N}      ${C}${SSH_PORT}${N}     ${B}VPN${N}  ${C}${VPN_PORT}/udp${N}"
    echo -e "\n${Y}$(t menu_hint)${N}\n"
    echo -e "${W}  MENU PRINCIPAL${N}"
    echo -e "${B}  ────────────────────────────────────────────────────────${N}"
    t menu_opt1
    t menu_opt2
    t menu_opt3
    t menu_opt4
    t menu_opt5
    t menu_opt6
    t menu_opt7
    t menu_opt8
    t menu_opt9
    echo -e "${B}  ────────────────────────────────────────────────────────${N}"
    echo
    read -rp "${W}$(t option) > ${N}" opt
    case "$opt" in
      1) step_config; pause ;;
      2) full_install; pause ;;
      3)
        step_system || { pause; continue; }
        step_firewall
        pause
        ;;
      4) step_deploy; pause ;;
      5)
        step_nginx || warn "Nginx/SSL falhou; corrija antes de confiar no HTTPS."
        step_fail2ban || warn "Fail2Ban falhou; proteção incompleta."
        pause
        ;;
      6)
        step_ssh || { pause; continue; }
        if confirm "Ativar restrição de SSH somente Brasil (geo-block)?" n; then
          step_geoblock
        elif confirm "Desativar geo-block se estiver ativo?" n; then
          step_geoblock_off
        fi
        pause
        ;;
      7)
        step_maintenance
        step_status
        pause
        ;;
      8) advanced_menu ;;
      9|0|q|Q) exit 0 ;;
      *) warn "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

load_conf
case "${1:-}" in
  --full) full_install ;;
  *) menu ;;
esac
