#!/bin/bash

# Tunel.sh - LocalXpose Auto PHP Server
# Solo index.html y styles.css

HOST="127.0.0.1"
PORT="8080"

# Colores
GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"
WHITE="\033[37m"
RESET="\033[0m"

# Directorios
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

if [[ ! -d ".server" ]]; then
    mkdir -p ".server"
fi

if [[ -d ".server/www" ]]; then
    rm -rf ".server/www"
fi
mkdir -p ".server/www"

# Detectar arquitectura
ARCH=$(uname -m)

download_localxpose() {
    echo -e "${GREEN}[+]${WHITE} Instalando LocalXpose...${RESET}"
    if [[ -e ".server/loclx" ]]; then
        echo -e "${GREEN}[+]${WHITE} LocalXpose ya instalado.${RESET}"
        return
    fi

    case "$ARCH" in
        aarch64)
            URL="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip"
            ;;
        arm* | armv7l)
            URL="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip"
            ;;
        x86_64)
            URL="https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip"
            ;;
        *)
            echo -e "${RED}[!]${WHITE} Arquitectura no soportada: $ARCH${RESET}"
            exit 1
            ;;
    esac

    FILE=$(basename $URL)
    curl -sSL "$URL" -o "$FILE"
    unzip -o "$FILE" -d ".server"
    chmod +x .server/loclx
    rm -f "$FILE"
}

# Puerto personalizado
cusport() {
    read -n4 -p "Puerto (1024-9999, default $PORT): " PUERTO
    if [[ $PUERTO =~ ^[1-9][0-9]{3}$ ]] && [[ $PUERTO -ge 1024 ]]; then
        PORT=$PUERTO
    fi
    echo -e "\nPuerto establecido a $PORT"
}

# Iniciar servidor PHP
start_php() {
    cp -f index.html styles.css .server/www/
    echo -e "${GREEN}[+]${WHITE} Iniciando servidor PHP en http://$HOST:$PORT${RESET}"
    cd .server/www && php -S "$HOST:$PORT" > /dev/null 2>&1 &
}

# Autenticación LocalXpose
localxpose_auth() {
    echo -e "${GREEN}[+]${WHITE} Necesitas un token de LocalXpose${RESET}"
    read -p "Introduce tu token: " LOC_TOKEN
    AUTH_DIR="$HOME/.localxpose"
    mkdir -p "$AUTH_DIR"
    echo -n "$LOC_TOKEN" > "$AUTH_DIR/.access"
}

# Iniciar LocalXpose
start_localxpose() {
    echo -e "${GREEN}[+]${WHITE} Iniciando LocalXpose...${RESET}"
    if command -v termux-chroot > /dev/null; then
        termux-chroot ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$PORT" > .server/.loclx 2>&1 &
    else
        ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$PORT" > .server/.loclx 2>&1 &
    fi
    sleep 5
    URL=$(grep -o '[0-9a-zA-Z.]*.loclx.io' .server/.loclx)
    echo -e "${GREEN}[+]${WHITE} Acceso público: https://$URL${RESET}"
}

# Main
download_localxpose
cusport
start_php
localxpose_auth
start_localxpose

echo -e "${GREEN}[+]${WHITE} Servidor corriendo, Ctrl+C para detener.${RESET}"
wait
