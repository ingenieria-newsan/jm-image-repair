#! /bin/bash

# mensaje de exito
COLUMNS=$(tput cols) 
title="EQUIPO RECUPERADO EXITOSAMENTE" 
printf "\n\n \033[1;30m %*s \033[0m \n" $(((${#title}+$COLUMNS)/2)) "$title"
printf "\n\n  Este equipo debe retornar al puesto: ${1}"
text="-- PRESIONE 'A' PARA APAGAR --" 
printf "\n\n\n%*s\n" $(((${#text}+$COLUMNS)/2)) "$text"

# espera la tecla q
key=""
read -s -n 1 -p "" key 
while [[ $key != "a" ]] 
	do
		read -n1 -s -r -p "" key
done

# mensaje de apagado
clear
title="APAGANDO EL EQUIPO" 
printf "\n\n \033[1;30m %*s \033[0m \n" $(((${#title}+$COLUMNS)/2)) "$title"
printf "\n\n\t Espere hasta que la pantalla quede en negro y el LED indicador \n\t de encendido se apague."
sleep 3

# apagado
shutdown now
