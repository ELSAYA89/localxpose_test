#!/data/data/com.termux/files/usr/bin/bash

echo "=== Servidor Flask + LocalXpose ==="

# 1. Instalar dependencias si no están
pkg install -y python wget unzip

pip install flask --quiet

# 2. Instalar LocalXpose si no está
if ! command -v lxh &> /dev/null
then
    echo "[*] Instalando LocalXpose..."
    wget https://files.localxpose.io/localxpose-linux-arm64.zip -O lx.zip
    unzip lx.zip -d $HOME/.local/bin/
    rm lx.zip
    chmod +x $HOME/.local/bin/lxh
    export PATH=$HOME/.local/bin:$PATH
fi

# 3. Configurar token
if [ ! -f "$HOME/.lxh_token" ]; then
    read -p "Introduce tu token de LocalXpose: " TOKEN
    echo $TOKEN > $HOME/.lxh_token
    lxh authtoken $TOKEN
else
    TOKEN=$(cat $HOME/.lxh_token)
    lxh authtoken $TOKEN
fi

# 4. Iniciar servidor Flask en background
echo "[*] Iniciando servidor Flask en puerto 5000..."
python server.py &

# Guardar el PID para poder cerrarlo luego
FLASK_PID=$!

# 5. Crear túnel con LocalXpose
echo "[*] Creando túnel..."
lxh http 5000

# 6. Si se cierra el túnel, detener Flask
kill $FLASK_PID
