#! /bin/bash

# Obtengo información de la placa de red
h1=$(ip addr show $(awk 'NR==3{print $1}' /proc/net/wireless | tr -d :) | awk '/ether/{print $2}')

# filtro mac
h2=$(echo $h1 | awk '{print$1}')

# paso a mayusculas los caracteres de la mac
h3=${h2^^}

# elimino los ":" 
h4=${h3//:/}

# genero hash SHA1
h5=$(echo -n $h4 | sha1sum | awk '{print $1}')

# retorna el hash SHA1 generado con caracteres en mayusculas
echo ${h5^^}
