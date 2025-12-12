#!/usr/bin/env bash

# DevOps Reto - Check de salud de VM (AlmaLinux / systemd)
# * Lista servicios fallidos
# * Muestra uso de memoria RAM
# * Muestra espacio en disco por partición

set -euo pipefail

echo "Reto DevOps - Chequeo salud VM"
echo

# 1. Servicios fallidos
echo "---Servicios fallidos (systemd)---"
if systemctl --failed --no-legend --plain | grep -q .; then
  systemctl --failed --no-legend --plain
else
  echo "No se encontraron servicios fallidos"
fi
echo

# 2. Uso de memoria RAM
echo "---Uso memoria RAM---"
free -h
echo

# 3. Espacio en disco
echo "---Espacio en disco por partición---"
df -h -x tmpfs -x devtmpfs
echo

echo "Chequeo exitoso"
