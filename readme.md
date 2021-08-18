# Sistema de reparación de imagen
Realiza las acciones necesarias para reacondicionar el equipo al puesto de grabado de BIOS.

## Compativilidad
- NOBLEX SF20GM7 ( Proyecto Juana Manso )

## Dependencias
- gnome-terminal
- clonezilla

## Instalación
Siga los siguientes pasos para instalar el sistema:

1. Clone el repositorio actual en `/home`.
2. Asigne permiso de ejecución: `sudo chmod +x /home/jm-image-repare/*.sh /home/jm-image-repare/sys/*.sh`
3. Copie el archivo `./iniciar.sh` en el escritorio.
4. Copir el archivo `./update` en el directorio `/home`.
5. Instale las dependencias.
6. Agregue `/iniciar.sh` en la lista de auto-arranque.

## Update
Para actualizar la solución siga los siguientes pasos:

1. Bootee en un equipo compatible usando el disco de volcado.
2. Cancela la ejecucion de los procesos precionando `Alt` + `F4`.
3. Habra una terminal y posicionese en el directorio `/home`.
4. Ejecute el comando `sudo ./update.sh`.
5. Espere que el proceso finalice y apague el equipo.  

## Opciones de operacion
- Disco rigido vácio        -->     Volcado de imagen Windows
- Disco con 6 particiones   -->     Volcado de imagen Windows + Generación de SHA1
- Disco con 4 particiones   -->     Recuperar archivos de arranque.