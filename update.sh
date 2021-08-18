#! /bin/bash

# eliminar
sudo rm -rf ./jm-image-repare
sleep 1

# descargar
sudo git clone https://github.com/jcvels/jm-image-repare
sleep 1

# permisos
sudo chmod +x ./jm-image-repare/*.sh
sudo chmod +x ./jm-image-repare/sys/*.sh
sleep 1
