#!/bin/bash

# Tunel con LocalXpose - Carga index.html y styles.css
# Author: Adaptado del script original de Zphisher

# Variables por defecto
HOST='127.0.0.1'
PORT='8080'
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# Colores
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"  WHITE="$(printf '\033[37m')"  RESET="$(printf '\033[0m')"

# Directorios
if [[ ! -d ".server" ]]; then
	mkdir -p ".server"
fi
if [[ -d ".server/www" ]]; then
	rm -rf ".server/www"
fi
mkdir -p ".server/www"

# Terminar con CTRL+C
trap "echo -e \"\n${RED}[!] Programa interrumpido.${RESET}\"; exit 0" SIGINT

# Reset de colores
reset_color() {
	tput sgr0
	tput op
	return
}

# Dependencias
dependencies() {
	if ! command -v php &>/dev/null; then
		echo -e "${RED}[!] PHP no instalado. Instalando...${RESET}"
		if command -v pkg &>/dev/null; then
			pkg install php -y
		elif command -v apt &>/dev/null; then
			sudo apt install php -y
		fi
	fi
	if ! command -v curl &>/dev/null; then
		echo -e "${RED}[!] curl no instalado. Instalando...${RESET}"
		if command -v pkg &>/dev/null; then
			pkg install curl -y
		elif command -v apt &>/dev/null; then
			sudo apt install curl -y
		fi
	fi
}

# Descargar LocalXpose
download() {
	url="$1"
	output="$2"
	curl --silent --insecure --fail --retry 3 --retry-delay 2 --location --output "$output" "$url"
	chmod +x "$output"
	mv "$output" .server/
}

install_localxpose() {
	if [[ ! -e ".server/loclx" ]]; then
		echo -e "${GREEN}[+] Instalando LocalXpose...${RESET}"
		arch=$(uname -m)
		if [[ "$arch" == *"arm"* ]] || [[ "$arch" == *"Android"* ]]; then
			download "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" "loclx"
		elif [[ "$arch" == *"aarch64"* ]]; then
			download "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" "loclx"
		elif [[ "$arch" == *"x86_64"* ]]; then
			download "https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" "loclx"
		else
			download "https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" "loclx"
		fi
	fi
}

# Autenticación LocalXpose
localxpose_auth() {
	./.server/loclx -help > /dev/null 2>&1 &
	sleep 1
	auth_f="$HOME/.localxpose/.access"
	if [[ "$(./.server/loclx account status | grep Error)" ]]; then
		echo -e "${RED}[!] Necesitas un token de LocalXpose${RESET}"
		read -p "Introduce tu token: " loclx_token
		if [[ -z "$loclx_token" ]]; then
			echo -e "${RED}[!] Debes ingresar un token.${RESET}"
			exit 1
		fi
		# Crear carpeta si no existe
		if [[ ! -d "$HOME/.localxpose" ]]; then
			mkdir -p "$HOME/.localxpose"
		fi
		echo -n "$loclx_token" > "$auth_f"
	fi
}

# Elegir puerto
cusport() {
	read -p "Puerto (1024-9999, default 8080): " CU_P
	if [[ "$CU_P" =~ ^[0-9]{4}$ ]] && [[ "$CU_P" -ge 1024 ]]; then
		PORT="$CU_P"
	else
		PORT=8080
	fi
	echo "Puerto establecido a $PORT"
}

# Setup sitio web
setup_site() {
	if [[ -f "index.html" ]]; then
		cp index.html .server/www/
	fi
	if [[ -f "styles.css" ]]; then
		cp styles.css .server/www/
	fi
	echo -e "${GREEN}[+] Iniciando servidor PHP en http://$HOST:$PORT${RESET}"
	cd .server/www && php -S "$HOST:$PORT" > /dev/null 2>&1 &
}

# Iniciar LocalXpose
start_loclx() {
	cusport
	setup_site
	localxpose_auth
	echo -e "${GREEN}[+] Iniciando LocalXpose...${RESET}"
	if command -v termux-chroot &>/dev/null; then
		termux-chroot ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$PORT" > .server/.loclx 2>&1 &
	else
		./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$PORT" > .server/.loclx 2>&1 &
	fi
	sleep 5
	loclx_url=$(grep -o '[0-9a-zA-Z.]*.loclx.io' .server/.loclx)
	echo -e "${GREEN}[+] Acceso público: https://$loclx_url${RESET}"
	echo -e "${GREEN}[+] Servidor corriendo, Ctrl+C para detener.${RESET}"
}

# Main
killall php loclx 2>/dev/null
dependencies
install_localxpose
start_loclx
