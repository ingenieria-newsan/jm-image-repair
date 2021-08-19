#! /bin/bash

clear
m_pass='\033[1;32m PASS \033[0m' # ${m_pass}
m_fail='\033[1;31m FAIL \033[0m' # ${m_fail}
m_warn='\033[1;34m WARN \033[0m' # ${m_warn}
m_info='\033[1;36m INFO \033[0m' # ${m_info}
m_si='\033[1;32m SI \033[0m' # ${m_pass}
m_no='\033[1;31m NO \033[0m' # ${m_fail}

# directorio de trabajo
SCRIPT=$(readlink -f $0);
dir_base=`dirname $SCRIPT`;

# chequea que nombre tiene el disco de ubuntu y el de huayra
printf "[${m_info}] Detectando discos...\n"
ubuntu=$(lsblk -no pkname $(findmnt -n / | awk '{ print $2 }'))
huayra="sda"

if [ $ubuntu == $huayra ]
	then
		huayra="sdb"
fi

printf "[${m_info}] Discos: repair=${ubuntu} target=${huayra}.\n"

sleep .5

# monta la particion donde se encuentra la imagen del a volcar en /home/partimag
printf "[${m_info}] Montando particiones de reparación...\n"

sudo umount /dev/${ubuntu}3 > /dev/null 2>&1
sudo mount /dev/${ubuntu}3 /home/partimag

sudo umount /jmdisk > /dev/null 2>&1
sudo mkdir /jmdisk > /dev/null 2>&1
sudo mount /dev/${huayra}3 /jmdisk

sleep .5

# chequea la version actual de la BIOS con la que se le da por parametro en el archivo
printf "[${m_info}] Validando bios...\n"
bios_check=false
if [ $(cat $dir_base/versiones/bios.version) = $(sudo dmidecode -s bios-version) ]
	then
		printf "[${m_pass}] Validación de bios correcta.\n"
		bios_check=true
	else
		printf "[${m_fail}] Falló la validación de bios.\n"
		bios_check=false
fi

sleep .5

# Validación de sha1
printf "[${m_info}] Validando hash...\n"
hash_check=false
cd $dir_base
hash_equipo=$(./sys/hash.sh)
hash_archivo="sha1-no-detectado"

# leo el archivo sha1 si existe
if [ -e /jmdisk/SHA1/test.txt ]
	then
		hash_archivo=$(tr -dc '[[:print:]]' <<< "$(cat /jmdisk/SHA1/test.txt)")   
fi

# muestra los hash a los fines de hacer debug
printf "[${m_info}] a=${hash_archivo} \n[${m_info}] e=${hash_equipo} \n"

# compara los hash de equipo y archivo
if [ $hash_equipo = $hash_archivo ]
	then
		printf "[${m_pass}] Validación de hash correcta.\n"
		hash_check=true
	else
		printf "[${m_fail}] Validación de hash incorrecta.\n"
		hash_check=false
fi

sleep .5

# analizar cantidad de particiones en el disco
partition_qtty=$(grep -c $huayra /proc/partitions)
printf "[${m_info}] Se detectaron ${partition_qtty} particiones en el disco.\n"

sleep .5

# configuración de recuperación
repair_windows=false
repair_boot=false
repair_hash=false
repair_step="PUESTO-NO-DETERMINADO"

# configuracion de proceso para 0 particiones
if [ $partition_qtty = 0 ] 
	then

		if [ $bios_check == "true" ]

			# con bios actualizado
			then
				printf "[${m_info}] No se detectaron particiones en el disco pero se detectó el bios actualizado.\n[${m_info}] Se restaurará a puesto de BIOS.\n"
				repair_windows=true
				repair_boot=false
				repair_hash=true
				repair_step="BIOS"

			# sin bios actializado
			else
				printf "[${m_info}] No se detectaron particiones en el disco ni bios actualizado.\n[${m_info}] Se restaurará a puesto de INICIO.\n"
				repair_windows=true
				repair_boot=false
				repair_hash=false
				repair_step="INICIO"

		fi

fi

# configuracion de proceso para 4 particiones
if [ $partition_qtty = 4 ] && [ $bios_check == "false" ]
	then

		if [ $bios_check == "true" ]

			# con bios actualizado
			then
				printf "[${m_info}] Se detectaron 4 particiones en el disco y el bios actualizado.\n[${m_info}] Se restaurará a puesto de BIOS.\n"
				repair_windows=false
				repair_boot=true
				repair_hash=true
				repair_step="BIOS"

			# sin bios actializado
			else
				printf "[${m_info}] Detectaron 4 particiones en el disco. El bios no fue actualizado.\n[${m_info}] Se restaurará a puesto de INICIO.\n"
				repair_windows=true
				repair_boot=false
				repair_hash=false
				repair_step="INICIO"

		fi

fi

# configuracion de proceso para 6 particiones	
if [ $partition_qtty = 6 ] && [ $bios_check == "true" ]
	then
		printf "[${m_info}] Se detectaron 6 particiones en el disco y bios actualizado \n[${m_info}] Se restaurará a puesto de BIOS.\n"
		repair_windows=true
		repair_boot=false
		repair_hash=true
		repair_step="BIOS"
fi

sleep .5

# muestra mensaje en pantalla y espera confirmación
title="REPARACIÓN DE IMAGEN"
printf "\n\n \033[1;30m %*s \033[0m \n" $(((${#title}+$COLUMNS)/2)) "$title"
printf "\n\n\tSe realizarán las siguientes acciones:\n\n\t"

if [ $repair_windows == "true" ]
	then
		printf "[${m_si}]"
	else
		printf "[${m_no}]"
fi
printf " Restauración de imagen de testeo.\n\t"

if [ $repair_boot == "true" ]
	then
		printf "[${m_si}]"
	else
		printf "[${m_no}]"
fi
printf " Reparación de booteo en imagen de testeo.\n\t"

if [ $repair_hash == "true" ]
	then
		printf "[${m_si}]"
	else
		printf "[${m_no}]"
fi
printf " Reparación de hash de finalización de runing.\n\n"

printf "\tUna vez finalizado el proceso, disponga el equipo al puesto: \033[1;36m ${repair_step} \033[0m \n"
printf "\n\tRecuerde siempre verificar el estado de la unidad en el trazabilidad \n\tantes de proceder.\n"

text="--- PRESIONE 'P' PARA PROCEDER O 'C' PARA CANCELAR ---"
printf "\n\n %*s \n\n" $(((${#text}+$COLUMNS)/2)) "$text"

# espera que se presione una tecla ---->>> P = Procedeer | C = Cancelar 
read -s -n 1 -p "" key
while [ $key != "p" ] && [ $key != "c" ]
	do
		read -s -n 1 -p "" key
done

sleep .5

# desmonta el disco donde se encuentra el flag del running
sudo umount /jmdisk > /dev/null 2>&1

# main process
if [ $key == "p" ]
	then

		printf "[${m_info}] Procedeer.\n"
		
		# valida que la bateria esté conectada
		bateria=$(cat /sys/class/power_supply/ADP1/online) #bateria=$(cat /sys/class/power_supply/ACAD/online)
		if [ $bateria != 1 ]
			then
				printf "[${m_warn}] Falta conexión a alimentación externa\n"
				gnome-terminal --full-screen --hide-menubar --profile texto-error --wait -- ./sys/error-bateria.sh
			else
				printf "[${m_info}] Conexión a alimentación externa detectada\n"
		fi
		
		# ¿volcado de imagen?
		if [ $repair_windows == "true" ]
			then

				# mensaje volcado de imagen
				printf "[${m_info}] Iniciando volcado de imagen...\n"

				# bucle de volcado y control de imagen		
				image_check=false
				image_counter=0

				while [ $image_check == "false" ]
					do
						# contador de errores y borrado de log previo
						error_counter=0
						if [ -e /var/log/clonezilla.log ]
							then
								sudo rm -f /var/log/clonezilla.log
								printf "[${m_info}] Se eliminó correctamente el log anterior de Clonezilla.\n"
						fi

						# volcado de imagen
						image_name=$(cat $dir_base/versiones/image.version)
						gnome-terminal --full-screen --hide-menubar --profile texto --wait -- ./sys/volcado.sh $image_name $huayra
						printf "[${m_info}] Volcado de imágen finalizado.\n"

						#validaciones
						printf "[${m_info}] Iniciando validaciones...\n"

						# validación de particiones
						if [ $(grep -c $huayra /proc/partitions) = 6 ]
							then
								printf "[${m_pass}]"
							else
								printf "[${m_fail}]"
								error_counter=$((error_counter+1))
						fi
						printf " Particiones en disco de destino.\n"

						sleep .1

						# validafion finalizacion del proceso Clonezilla
						if [ -e /var/log/clonezilla.log ]
							then
								if [ $(cat /var/log/clonezilla.log | grep -c "Ending /usr/sbin/ocs-sr at" ) = 1 ]
									then
										printf "[${m_pass}]"
									else
										printf "[${m_fail}]"
										error_counter=$((error_counter+1))
								fi
							else
								printf "[${m_fail}]"
								error_counter=$((error_counter+1))
						fi
						printf " Finalización del proceso Clonezilla.\n"
						sleep .1

						# validafion errores del proceso Clonezilla
						if [ -e /var/log/clonezilla.log ]
							then
								if [ $(tail -1 /var/log/clonezilla.log | cut -d'!' -f 1 | grep -c "Program terminated" ) = 0 ]
									then
										printf "[${m_pass}]"
									else
										printf "[${m_fail}]"
										error_counter=$((error_counter+1))
								fi
							else
								printf "[${m_fail}]"
								error_counter=$((error_counter+1))
						fi
						printf " Control de errores en proceso Clonezilla.\n"
						sleep .1
					
						# valida si hay un error y muestra el mensaje correspondiente
						printf "[${m_info}] Errores encontrados = ${error_counter}\n"
						if [ $error_counter != 0 ]
							then
								image_counter=$((image_counter+1))
								gnome-terminal --full-screen --hide-menubar --profile texto-error --wait -- ./sys/error-volcado.sh $image_counter
							else
								gnome-terminal --full-screen --hide-menubar --profile texto-ok --wait -- ./sys/volcado-ok.sh $ubuntu
								image_check=true
						fi

					done
		fi


### WORKING !!!



	else
		printf "[${m_info}] Cancelar.\n"
fi

printf "[${m_info}] Apagando el equipo...\n"

# mensaje de apagado
printf "\n\n\n\033[1;30m APAGANDO EL EQUIPO \033[0m"
printf "\n Espere hasta que la pantalla quede en negro y el LED indicador\n de encendido se apague"

sleep 5
shutdown now
