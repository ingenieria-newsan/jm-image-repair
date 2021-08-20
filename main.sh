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

# muestra la version de la herramienta
version=$(cat $dir_base/.git/refs/heads/master)
printf "[${m_info}] tool_version=${version}\n"

# chequea que nombre tiene el disco de ubuntu y el de huayra
ubuntu=$(lsblk -no pkname $(findmnt -n / | awk '{ print $2 }'))
huayra="sda"

if [ $ubuntu == $huayra ]
	then
		huayra="sdb"
fi

printf "[${m_info}] repair_disk=${ubuntu} target_disk=${huayra}.\n"

sleep .5

# monta la particion donde se encuentra la imagen del a volcar en /home/partimag
sudo umount /dev/${ubuntu}3 > /dev/null 2>&1
sudo umount /jmdisk > /dev/null 2>&1

sudo mkdir /jmdisk > /dev/null 2>&1

sudo mount /dev/${ubuntu}3 /home/partimag
sudo mount /dev/${huayra}3 /jmdisk > /dev/null 2>&1

sleep .5

# chequea la version actual de la BIOS con la que se le da por parametro en el archivo
bios_check=false
if [ $(cat $dir_base/versiones/bios.version) = $(sudo dmidecode -s bios-version) ]
	then
		printf "[${m_pass}]"
		bios_check=true
	else
		printf "[${m_fail}]"
		bios_check=false
fi
printf " Validación de bios.\n"

sleep .5

# Validación de sha1
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
printf "[${m_info}] hash_archivo=${hash_archivo} \n[${m_info}] hash_equipo=${hash_equipo} \n"

# compara los hash de equipo y archivo
if [ $hash_equipo = $hash_archivo ]
	then
		printf "[${m_pass}]"
		hash_check=true
	else
		printf "[${m_fail}]"
		hash_check=false
fi
printf " Validación de hash.\n"

sleep .5

# analizar cantidad de particiones en el disco
partition_qtty=$(grep -c $huayra /proc/partitions)
printf "[${m_info}] partition_qtty=${partition_qtty} \n"

sleep .5

# configuración de recuperación
repair_2_bios=false

# configuracion de proceso para 0 particiones
if [ $hash_check == "true" ] || [ $bios_check == "true" ]
	then
		repair_2_bios=true
fi
printf "[${m_info}] repair_2_bios=${repair_2_bios} \n"

sleep .5

# muestra mensaje en pantalla y espera confirmación
printf "\n\n\t\033[1;30m\033[1;41m REPARACIÓN DE IMAGEN DE TESTEO \033[0m \n"
printf "\n\tOpciones habilitadas:\n"
printf "\n\t[\033[1;32m LETRA T \033[0m] Reparación a puesto TESTEO 01.\n\t"

if [ $repair_2_bios == "true" ]
	then
		printf "[\033[1;32m LETRA B \033[0m] Reparación a puesto BIOS.\n\t"
fi

printf "\n\t- Recuerde que si el equipo fue abierto debe disponerse al puesto TESTEO 01.\n"
printf "\t- Recuerde siempre verificar el estado de la unidad en TRAZABILIDAD tantes de proceder.\n"

printf "\n\n\tPRESIONE UNA DE LAS OPCIONES PARA CONTINUAR, O 'C' PARA CANCELAR \n\n"

# espera que se presione una tecla 
read -s -n 1 -p "" key
while [ $key != "c" ] && [ $key != "t" ] && [ $key != "b" ]
	do
		read -s -n 1 -p "" key
done

sleep .5

# main process
if [ $key == "t" ] || [ $key == "b" ]
	then

		printf "[${m_info}] Proceder.\n"
		
		# valida que la bateria esté conectada
		bateria=$(cat /sys/class/power_supply/ADP1/online) #bateria=$(cat /sys/class/power_supply/ACAD/online)
		if [ $bateria != 1 ]
			then
				printf "[${m_warn}] Falta conexión a alimentación externa\n"
				gnome-terminal --full-screen --hide-menubar --profile texto-error --wait -- ./sys/error-bateria.sh
		fi

		# bucle de volcado y control de imagen		
		image_check=false
		image_counter=0

		while [ $image_check == "false" ]
			do
			
				# mensaje volcado de imagen
				printf "[${m_info}] Iniciando volcado de imagen...\n"

				# desmonta particiones del disco target
				sudo umount /jmdisk > /dev/null 2>&1

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

				# ¿generar hash?
				if [ $repair_2_bios == "true" ] && [ $key == "b" ]
					then

						# mensaje volcado de imagen
						printf "[${m_info}] Generando hash.\n"

						# monta nuevamente la partición del disco target
						sudo umount /jmdisk > /dev/null 2>&1
						sudo mkdir /jmdisk > /dev/null 2>&1
						sudo mount /dev/${huayra}3 /jmdisk > /dev/null 2>&1

						# guarda el hash en el disco 
						echo $hash_equipo >> /jmdisk/SHA1/test

						# leo el archivo sha1 si existe
						if [ -e /jmdisk/SHA1/test.txt ]
							then
								hash_archivo=$(tr -dc '[[:print:]]' <<< "$(cat /jmdisk/SHA1/test.txt)")   
						fi

						# muestra los hash a los fines de hacer debug
						printf "[${m_info}] hash_archivo=${hash_archivo} \n[${m_info}] hash_equipo=${hash_equipo} \n"

						sleep .5

				fi

				#validaciones
				printf "[${m_info}] Iniciando validaciones...\n"

				# validacion de hash
				if [ $repair_2_bios == "true" ] && [ $key == "b" ]
					then
						if [ $hash_equipo = $hash_archivo ] 
							then
								printf "[${m_pass}]"
							else
								printf "[${m_fail}]"
								error_counter=$((error_counter+1))
						fi
						printf " Validación de hash.\n"
				fi

				# validación de particiones
				if [ $(grep -c $huayra /proc/partitions) = 5 ]
					then
						printf "[${m_pass}]"
					else
						printf "[${m_fail}]"
						error_counter=$((error_counter+1))
				fi
				printf " Particiones en disco de destino.\n"

				sleep .5

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
				
				sleep .5

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
				
				sleep .5
			
				# valida si hay un error y muestra el mensaje correspondiente
				printf "[${m_info}] Errores encontrados = ${error_counter}\n"
				if [ $error_counter != 0 ]
					then
						image_counter=$((image_counter+1))
						gnome-terminal --full-screen --hide-menubar --profile texto-error --wait -- ./sys/error-volcado.sh $image_counter
					else
						image_check=true

						puesto="TESTEO 01"

						if [ $repair_2_bios == "true" ] && [ $key == "b" ]
							then
								puesto="BIOS"
						fi

						sleep .5

						gnome-terminal --full-screen --hide-menubar --profile texto-ok --wait -- ./sys/volcado-ok.sh $puesto
				fi

			done

	else
		printf "[${m_info}] Cancelar.\n"
fi

printf "[${m_info}] Apagando el equipo...\n"

# mensaje de apagado
printf "\n\n\n\033[1;34m APAGANDO EL EQUIPO \033[0m"
printf "\n Espere hasta que la pantalla quede en negro y el LED indicador\n de encendido se apague"

sleep 5
shutdown now
