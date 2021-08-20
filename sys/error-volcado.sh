#! /bin/bash

# sonido de error
./sys/error-sonido.sh &

# mensaje de error
clear
COLUMNS=$(tput cols) 
title="ERROR EN EL VOLCADO DE LA IMAGEN O GENERACIÓN DE HASH ( intento #${1} )"
printf "\n\n \033[1;30m %*s \033[0m \n" $(((${#title}+$COLUMNS)/2)) "$title"
printf "\n\n\t 1) Presione 'L' para reintentar."
printf "\n\n\t 2) Presione 'A' para cancelar"
text="PRESIONE 'L' o 'A' PARA CONTINUAR" 
printf "\n\n\n %*s \n" $(((${#text}+$COLUMNS)/2)) "$text"

# espera que se presione una tecla
read -s -n 1 -p "" key
while [ $key != "l" ] && [ $key != "a" ]
	do
		read -s -n 1 -p "" key
done

# ejecuta si se presiona a
if [ $key == "a" ]
	then
	
		# mensaje de apagado
		printf "\n\n\n\033[1;34m APAGANDO EL EQUIPO \033[0m"
		printf "\n Espere hasta que la pantalla quede en negro y el LED indicador\n de encendido se apague"

		sleep 5
		shutdown now
fi

# ejecuta si se presiona l
if [ $key == "l" ]
	then
		sleep .5
fi
