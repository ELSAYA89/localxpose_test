#!/data/data/com.termux/files/usr/bin/bash

echo "=== Iniciando servidor Flask + LocalXpose ==="

# 1. Iniciar servidor Flask en background
echo "[*] Iniciando servidor Flask en puerto 5000..."
python server.py &

# Guardar el PID para poder cerrarlo luego
FLASK_PID=$!

# 2. Crear túnel con LocalXpose
echo "[*] Creando túnel..."
lxh http 5000

# 3. Si se cierra el túnel, detener Flask
kill $FLASK_PID
