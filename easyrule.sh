#!/bin/bash

#declaración de variables
tabla="filter"
comando=""
cadena=""
parametros=("" "" "" "" "" "" "" "")
accion=""
sintaxisIpTables="iptables [-t tabla] -comando cadena [opciones] -j acción"
interfaces=($(ip -o link show | awk -F': ' '{print $2}'))
opcionesListado=()
posicionCadena=""
posicionCadenaTemp=""

#declaración de constantes
TABLAS=("filter" "nat" "mangle" "raw" "security")
COMANDOS=("-L" "-A" "-I" "-D" "-F" "-X")
COMANDOS_FILTER=(${COMANDOS[@]} "-P")

CADENAS_FILTER=("INPUT" "OUTPUT" "FORWARD")
CADENAS_NAT=("PREROUTING" "POSTROUTING" "OUTPUT")
CADENAS_MANGLE=("PREROUTING" "INPUT" "FORWARD" "OUTPUT" "POSTROUTING")
CADENAS_RAW=("PREROUTING" "OUTPUT")
CADENAS_SECURITY=("INPUT" "FORWARD" "OUTPUT")

#Separación temporal
PARAMETROS_GENERAL=("-s" "-d" "-p" "--dport" "--sport" "-i" "-o")
PARAMETROS=("${PARAMETROS_GENERAL[@]}" "-m")
#Para -m
MATCH_MODULES=("state --state" "conntrack --ctstate")
ESTADOS_MM=("NEW" "ESTABLISHED" "RELATED" "INVALID")

PROTOCOLOS=("tcp" "udp" "icmp")

ACCIONES_FILTER=("ACCEPT" "DROP" "REJECT" "LOG")
#ACCIONES_NAT=("SNAT" "DNAT" "REDIRECT")
#ACCIONES_MANGLE=("MARK" "ACCEPT" "DROP" "LOG")
ACCIONES_MANGLE=("ACCEPT" "DROP" "LOG")
ACCIONES_RAW=("NOTRACK")
#utiles con modulos de seguridad
#ACCIONES_SECURITY=()

#para listado de reglas
OPCIONES_LISTADO=("-n" "--line-numbers")

#Personalización
# Colores ANSI (constantes)
COLOR_RESET="\e[0m"
COLOR_INFO="\e[36m"      # Cian claro
COLOR_SUCCESS="\e[32m"   # Verde
COLOR_WARNING="\e[33m"   # Amarillo
COLOR_ERROR="\e[31m"     # Rojo
COLOR_TITLE="\e[35m"     # Magenta
COLOR_BOLD="\e[1m"       # Negrita (sin color)



#declaración de funciones

#Funciones
bienvenido (){
    echo -e "\e[36m"
    echo "███╗   ██╗██╗██╗  ██╗███████╗██╗     "
    echo "████╗  ██║██║██║ ██╔╝██╔════╝██║     "
    echo "██╔██╗ ██║██║█████╔╝ █████╗  ██║     "
    echo "██║╚██╗██║██║██╔═██╗ ██╔══╝  ██║     "
    echo "██║ ╚████║██║██║  ██╗███████╗███████╗"
    echo "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝"
    echo -e "\e[0m"

    echo "Bienvenido"
    # Descripción del programa
    echo -e "\e[36mEste programa está diseñado para ayudarte a construir reglas de iptables"
    echo "sin necesidad de memorizar su sintaxis complicada cada vez."
    echo
    echo -e "\e[36m✔️  Puedes construir reglas paso a paso."
    echo -e "✔️  Guardar tus reglas personalizados para usarlos más adelante."
    echo -e "✔️  Revisar o ejecutar reglas guardadas en cualquier momento.\e[0m"
    echo

    mensajeContinuacion "comenzar"
    if [ $modoLimpio == true ]
    then
        clear
    fi
}

verificacionGeneral(){
    echo "verificando general"
    if [ "$comando" != "-I" ] && [ "$comando" != "-D" ]
    then
        posicionCadena=""
    else
        posicionCadena="$posicionCadenaTemp"
    fi

    if [ "$tabla" != "filter" ] && [ "$comando" == "-P" ]
    then
        comando=""
    fi
}

modoVerbosoTabla(){
    if [ $modoLimpio == true ]
    then
        clear
    fi

    echo -e "${COLOR_INFO}Información sobre la tabla: $tabla ${COLOR_RESET}"
    echo;

    if [ $tabla == "filter" ]
    then
        echo "Proposito: fitlrado básico de paquetes."
        echo "Cadenas: INPUT, OUTPUT, FORWARD."
        echo "Uso: Permitir o denegar tráfico"
    elif [ $tabla == "nat" ]
    then
        echo "Proposito: Modificación de direcciones IP y puertos."
        echo "PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING.."
        echo "Uso: Enmascaramiento IP, redirección de puertos"
    elif [ $tabla == "mangle" ]
    then
        echo "Proposito: Modificación avanzada de paquetes"
        echo "Cadenas: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING."
        echo "Uso: Marcado de paquetes, modificación en TTL, QoS"
    elif [ $tabla == "raw" ]
    then
        echo "Proposito: Configuración de seguimiento de conexiones"
        echo "Cadenas: PREROUTING, OUTPUT"
        echo "Uso: Marcar paquetes para evitar connection tracking"
    elif [ $tabla == "security" ]
    then
        echo "Proposito: Reglas de seguridad obligatorias"
        echo "Cadenas: INPUT, FORWARD, OUTPUT"
        echo "Uso: Modificar paquetes"
    fi
    echo;
    mensajeContinuacion "continuar"

}

modoVerbosoComando(){
    if [ $modoLimpio == true ]
    then
        clear
    fi

    comando=$( echo "$comando" | xargs)

    echo -e "${COLOR_INFO}Información sobre el comando: $comando ${COLOR_RESET}"
    echo;

    if [ "$comando" == "-L" ]
    then
        echo "Listar reglas de cadena"
        echo "Muestra todas las reglas existentes en una cadena (por defecto muestra todas si no se especifica ninguna). Es útil para ver qué reglas están activas actualmente."
    elif [ "$comando" == "-A" ]
    then
        echo "Añadir regla a cadena"
        echo "Añade una nueva regla al final de la cadena especificada. Es el método más común para agregar reglas al firewall."
    elif [ "$comando" == "-I" ]
    then
        echo "Insertar regla a cadena"
        echo "Inserta una nueva regla al inicio (posición 1 por defecto) o en una posición específica dentro de la cadena. Útil para que la regla tenga prioridad sobre otras."
    elif [ "$comando" == "-D" ]
    then
        echo "Eliminar regla de cadena"
        echo "Elimina una regla específica de una cadena. Puedes eliminar por número de posición o replicando exactamente la regla que deseas borrar."
    elif [ "$comando" == "-F" ]
    then
        echo "Vaciar cadena (Flush)"
        echo "Elimina todas las reglas de una cadena. Si no se indica cadena, vacía todas las cadenas de la tabla seleccionada. Útil para resetear configuraciones."
    elif [ "$comando" == "-X" ]
    then
        echo "Eliminar cadenas personalizadas"
        echo "Borra cadenas definidas por el usuario (no las predeterminadas como INPUT, OUTPUT, etc.). Solo puedes eliminar una cadena si está vacía."
    elif [ "$comando" == "-P" ]
    then
        echo "Establecer política predeterminada"
        echo "Define qué hacer con los paquetes que no coinciden con ninguna regla: ACCEPT, DROP, etc. Aplica a cadenas como INPUT, OUTPUT, FORWARD."
    fi

    #casos especificos
    if [ "$comando" == "-L --line-numbers" ] || [ "$comando" == "-L -n" ]
    then
        echo "Listar reglas con numeración"
        echo "Muestra las reglas activas y añade números de línea. Esto es especialmente útil si deseas eliminar o modificar reglas por posición con -D o -R."
        echo "-n: evita resolver DNS para direcciones IP (más rápido)."
        echo "--line-numbers: añade números de línea para facilitar modificaciones."
    fi
    echo;
    mensajeContinuacion "continuar"
}

modoVerbosoCadena(){
    if [ $modoLimpio == true ]
    then
        clear
    fi

    echo -e "${COLOR_INFO}Información sobre la cadena: $cadena ${COLOR_RESET}"
    echo;

    if [ $cadena == "INPUT" ]
    then
        echo "Procesa paquetes que van dirigidos al sistema local."
    elif [ $cadena == "OUTPUT" ]
    then
        echo "Procesa paquetes que se originan desde el sistema local hacia fuera."
    elif [ $cadena == "FORWARD" ]
    then
        echo "Procesa paquetes que atraviesan el sistema (de una interfaz a otra)."
    elif [ $cadena == "PREROUTING" ]
    then
        echo "Procesa paquetes apenas llegan al sistema, antes de decidir su ruta."
    elif [ $cadena == "POSTROUTING" ]
    then
        echo "Procesa paquetes justo antes de salir del sistema."
    fi
    echo;
    mensajeContinuacion "continuar"
}

modoVerbosoAccion(){
    if [ $modoLimpio == true ]
    then
        clear
    fi

    echo -e "${COLOR_INFO}Información sobre la acción: $accion ${COLOR_RESET}"
    echo;

    if [ "$accion" == "-j ACCEPT" ]
    then
        echo "Permitir el paquete"
    elif [ "$accion" == "-j DROP" ]
    then
        echo "Descartar silenciosamente"
    elif [ "$accion" == "-j REJECT" ]
    then
        echo "Rechazar con mensaje de error"
    elif [ "$accion" == "-j LOG" ]
    then
        echo "Registrar en syslog"
    elif [ "$accion" == "-j REDIRECT" ]
    then
        echo "Redireccionar a puerto local"
    elif [ "$accion" == "-j SNAT" ]
    then
        echo "Netword Address Translation"
    elif [ "$accion" == "-j DNAT" ]
    then
        echo "Netword Address Translation"
    fi
    echo;
    mensajeContinuacion "continuar"
}

seleccionarTabla(){
    echo -e "${COLOR_BOLD}Selecciona una tabla${COLOR_RESET}"
    echo;
    n=1
    for i in "${TABLAS[@]}"; do
        echo "$n: $i"
        ((n+=1))
    done
    echo "$n: Volver al menu principal"
    echo;
    echo -n "Opcion: "
    read numero
    if [ "$numero" -eq "$n" ]
    then
        return
    fi

    tabla=${TABLAS[$numero-1]}

    if [ "$modoVerboso" == true ]
    then
        modoVerbosoTabla
    fi
}
seleccionarComando(){
    echo "Selecciona un comando"
    echo;
    n=1
    if [ "$tabla" == "filter" ]
    then
        for i in "${COMANDOS_FILTER[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
    else
        for i in "${COMANDOS[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
    fi

    echo "$n: Volver al menu principal"
    echo;
    echo;
    echo -n "Opcion: "
    read numero
    if [ "$numero" -eq "$n" ]
    then
        return
    fi

    echo -e "\e[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    if [ "$tabla" == "filter" ]
    then
        comando="${COMANDOS_FILTER[$numero-1]}"
    else
        comando="${COMANDOS[$numero-1]}"
    fi

    if [ "$comando" == "-L" ]
    then
        echo "Selecciona opciones de listado"
        n=1
        for i in "${OPCIONES_LISTADO[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        echo "$n: ninguna"
        ((n+=1))
        echo "$n: Volver al menu principal"
        echo;
        echo -n "Opcion: "
        read numero
        if [ "$numero" -eq "$n" ]
        then
            return
        fi

        echo "valor de n: $n"
        if [ "$numero" -eq "$((n-1))" ]
        then
            opcionesListado=()
        else
            opcionesListado[$numero-1]="${OPCIONES_LISTADO[$numero-1]}"
            echo "${OPCIONES_LISTADO[$numero-1]}"
        fi

        comando="$comando ${opcionesListado[@]}"
    fi


    if [ "$modoVerboso" == true ]
    then
        modoVerbosoComando
    fi
}

seleccionarCadena(){

    if [ "$comando" == "" ]
    then
        echo -e "${COLOR_WARNING}Sin un comando, no es posible asignar una cadena${COLOR_RESET}"
        echo;
        mensajeContinuacion "volver al menu principal"
        return
    fi

    echo "Selecciona una cadena"
    n=1
    CADENAS=()
    echo "$cadena"

    if [ "$tabla" == "filter" ]
    then
        for i in "${CADENAS_FILTER[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        CADENAS=("${CADENAS_FILTER[@]}")
    elif [ "$tabla" == "nat" ]
    then
        for i in "${CADENAS_NAT[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        CADENAS=("${CADENAS_NAT[@]}")
    elif [ "$tabla" == "mangle" ]
    then
        for i in "${CADENAS_MANGLE[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        CADENAS=("${CADENAS_MANGLE[@]}")
    elif [ "$tabla" == "raw" ]
    then
        for i in "${CADENAS_RAW[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        CADENAS=("${CADENAS_RAW[@]}")
    elif [ "$tabla" == "security" ]
    then
        for i in "${CADENAS_SECURITY[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        CADENAS=("${CADENAS_SECURITY[@]}")
    fi
    echo "$n: Volver al menu principal"
    echo;
    echo -n "Opcion: "
    read numero

    if [ "$numero" -eq "$n" ]
    then
        return
    fi
    cadena="${CADENAS[$((numero-1))]}"

    if [ "$comando" == "-I" ] || [ "$comando" == "-D" ]
    then
        echo -n "¿ Desear especificar la posición dentro de la cadena? (s/n): "
        read opcion
        if [ "$opcion" == "S" ] || [ "$opcion" == "s" ]
        then
            echo -n "Ingresa la posición dentro de la cadena: "
            read numero
            posicionCadena="$numero"
            posicionCadenaTemp="$numero"
        fi
    fi

    if [ "$modoVerboso" == true ]
    then
        modoVerbosoCadena
    fi
    
}

seleccionarParametros(){

    if [ "$comando" == "" ]
    then
        echo "Sin una cadena, no es posible asignar parámetros"
        echo;
        mensajeContinuacion "volver al menu principal"
        return
    fi

    echo "Selecciona parametros"
    echo;
    n=1
    temp=""
    temp2=""

    if [ "$tabla" == "raw" ] || [ "$tabla" == "security" ]
    then
        for i in "${PARAMETROS_GENERAL[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
    else
        for i in "${PARAMETROS[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
    fi
    echo "$n: Volver al menu principal"
    echo;
    echo -n "Opcion: "
    read subNum

    if [ "$subNum" -eq "$n" ]
    then
        return
    fi
    echo;
    if [ "$subNum" == 1 ]
    then
        echo -n "Ingresa dirección IP ó red de origen: "
        read temp
    elif [ "$subNum" == 2 ]
    then
        echo -n "Ingresa IP de destino: "
        read temp
    elif [ "$subNum" == 3 ]
    then
        echo "Selecciona protocolo"
        n=1
        for i in "${PROTOCOLOS[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        echo -n "Opcion: "
        read temp
        temp=${PROTOCOLOS[$temp-1]}
    elif [ "$subNum" == 4 ]
    then
        echo -n "Ingresa puerto/s de destino: "
        read temp
    elif [ "$subNum" == 5 ]
    then
        echo "Ingresa rango de puertos de origen"
        echo -n "Inicio: "
        read temp
        echo -n "Fin: "
        read temp2

        if [ "$temp" == "" ] || [ "$temp2" == "" ]
        then
            echo;
            echo -e "${COLOR_WARNING}EL rango de puertos debe tener un valor inicial y final${COLOR_RESET}"
            echo;
            mensajeContinuacion "volver al menu principal"
            return
        fi
        if [ "$temp" -gt "$temp2" ]
        then
            temp="$temp2:$temp"
        else
            temp="$temp:$temp2"
        fi

    elif [ "$subNum" == 6 ]
    then
        echo "Elige una interfaz de entrada: "
        echo;
        n=1
        for i in "${interfaces[@]}"; do
            echo "$n:$i"
            ((n+=1))
        done
        echo;
        echo -n "Opcion: "
        read temp
        temp=${interfaces[$temp-1]}
    elif [ "$subNum" == 7 ]
    then
        echo "Elige la interfaz de salida: "
        echo;
        n=1
        for i in "${interfaces[@]}"; do
            echo "$n:$i"
            ((n+=1))
        done
        echo;
        echo -n "Opcion: "
        read temp
        temp=${interfaces[(($temp-1))]}
    elif [ "$subNum" == 8 ]
    then
        echo "Elige un módulo"
        echo;
        n=1
        for i in "${MATCH_MODULES[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        echo "$n: Volver al menu principal"
        echo;
        echo -n "Opcion: "
        read temp
        temp=${MATCH_MODULES[$temp-1]}
        echo;

        echo "Ingresa un estado"
        n=1
        for i in "${ESTADOS_MM[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        echo "$n: Volver al menu principal"
        echo;
        echo -n "Opcion: "
        read temp2
        temp="$temp ${ESTADOS_MM[$temp2-1]}"
    fi

    if [ "$temp" != "" ]
    then
        parametros[$subNum-1]="${PARAMETROS[$subNum-1]} $temp"
    fi
    
}


seleccionarAccion(){

    if [ "$comando" == "" ] || [ "$cadena" == "" ]
    then
        echo "Sin un comando y cadena, no es posible asignar una acción"
        echo;
        mensajeContinuacion "volver al menu principal"
        return
    fi

    if [ "$comando" != "-I" ] && [ "$comando" != "-D" ] && [ "$comando" != "-A" ]
    then
        echo "Solo se puede asignar una acción a una regla, el comando utilizado no lo admite"
        echo;
        mensajeContinuacion "volver al menu principal"
        return
    fi

    echo "Selecciona una acción"
    echo;
    n=1
    if [ "$tabla" == "filter" ]
    then
        for i in "${ACCIONES_FILTER[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        ACCIONES=("${ACCIONES_FILTER[@]}")
    #elif [ "$tabla" == "nat" ]
    #then
        #for i in "${ACCIONES_NAT[@]}"; do
            #echo "$n: $i"
            #((n+=1))
        #done
        #ACCIONES="$ACCIONES_NAT"
    elif [ "$tabla" == "mangle" ]
    then
        for i in "${ACCIONES_MANGLE[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        ACCIONES=("${ACCIONES_MANGLE[@]}")
    elif [ "$tabla" == "raw" ]
    then
        for i in "${ACCIONES_RAW[@]}"; do
            echo "$n: $i"
            ((n+=1))
        done
        ACCIONES=("${ACCIONES_RAW[@]}")
    fi
    echo "$n: Volver al menu principal"
    echo;
    echo -n "Opcion: "
    read numero
    if [ "$numero" -eq "$n" ]
    then
        return
    fi
    accion="-j ${ACCIONES[$((numero-1))]}"

    if [ "$modoVerboso" == true ]
    then
        modoVerbosoAccion
    fi
}


ejecutaRegla(){
    if [ "$tabla" == "" ] || [ "$comando" == "" ]
    then
        echo -e "${COLOR_BOLD}Ejeución de reglas${COLOR_RESET}"
        echo;
        echo -e "${COLOR_WARNING}Debes seleccionar una tabla y un comando para ejecución${COLOR_RESET}"
        echo;
        mensajeContinuacion "retornar"
        return
    fi

    comandoAEjecutar=$( echo "$1" | xargs)
    
    echo;
    if [ "$modoLimpio" == true ]
    then
        clear
    fi
    echo -e "\e[32mEjecutando regla $comandoAEjecutar\e[0m"
    echo;
    sudo bash -c "$comandoAEjecutar"
    echo;
    mensajeContinuacion "continuar"
}

resetearRegla(){
    if [ "$hayAdvertencias" == true ]
    then
        echo -e -n "${COLOR_WARNING}Se eliminará la regla actual ¿estás seguro? (s/n): ${COLOR_RESET}"
        read resp
        echo;
        if [ "$resp" != "s" ]
        then
            return
        fi
    fi
    
    tabla="filter"; comando=""; cadena=""; posicionCadena=""; posicionCadenaTemp=""; parametros=(); accion=""; parametros=(); 
    
    echo;
    echo "Se eliminó la regla actual"
    echo;
    mensajeContinuacion "continuar"
}

guardarRegla(){
    if [ "$tabla" == "" ] || [ "$comando" == "" ]
    then
        echo -e "${COLOR_BOLD}Guardar regla${COLOR_RESET}"
        echo;
        echo -e "${COLOR_WARNING}Debes seleccionar una tabla y un comando para guardar la regla${COLOR_RESET}"
        echo;
        mensajeContinuacion "volver al menu principal"
        return
    fi

    echo -n "Dale una descipción a tu regla: "
    read descripcion
    reglasGuardadas[${#reglasGuardadas[@]}]="$reglaIpTables"
    descripcionesGuardadas[${#descripcionesGuardadas[@]}]="$descripcion"
    reconstruirDatosGuardados
    echo "regla $reglaIpTables guardada"
}

cargarDatosGuardados(){
    if [ -f config.sh ]
    then
        return;
    fi
    touch config.sh
    reconstruirDatosGuardados
}

reconstruirDatosGuardados(){
    echo '#!/bin/bash' > config.sh
    echo -n 'reglasGuardadas=(' >> config.sh

    for cmd in "${reglasGuardadas[@]}"; do
        echo -n "\"$cmd\" " >> config.sh
    done

    echo ')' >> config.sh

    echo -n 'descripcionesGuardadas=(' >> config.sh

    for cmd in "${descripcionesGuardadas[@]}"; do
        echo -n "\"$cmd\" " >> config.sh
    done

    echo ')' >> config.sh

    
    if [ "$esNuevo" == "" ]
    then
        echo "esNuevo=true" >> config.sh
        echo "modoLimpio=false" >> config.sh
        echo "modoVerboso=true" >> config.sh
        echo "hayAdvertencias=true" >> config.sh
    else
        echo "esNuevo=$esNuevo" >> config.sh
        echo "modoLimpio=$modoLimpio" >> config.sh
        echo "modoVerboso=$modoVerboso" >> config.sh
        echo "hayAdvertencias=$hayAdvertencias" >> config.sh
    fi
}

visualizarReglasGuardados(){
    echo "Reglas guardadas"
    n=1
    echo;
    for i in "${reglasGuardadas[@]}"; do
        echo "## $n: "
        echo "Regla: $i"
        echo "Descripción: ${descripcionesGuardadas[$n-1]}"
        ((n+=1))
        echo;
    done
    
    echo "$n. Volver"; 
    echo;
    echo -n "Opcion: "
    read numero
    if [ "$numero" -ge "$n" ]
    then
        return
    fi
    ejecutaRegla "${reglasGuardadas[$numero-1]}"
    
}

configurarEntorno(){
    #Cambios en ejecución
    echo "Opciones de configuración"
    echo;
    echo "1. Modo limpio : $modoLimpio"
    echo "2. Modo verboso : $modoVerboso"
    echo "3. Hay advertencias : $hayAdvertencias"
    echo "4. Volver al menu principal"
    echo;
    echo -n "Opcion: "
    read numero
    
    echo;
    case $numero in
        1)
            if [ "$modoLimpio" == true ]
            then
                modoLimpio=false
            elif [ "$hayAdvertencias" == true ]
            then
                echo -n -e "${COLOR_WARNING}Este modo limpiara constantemente su consola, ¿desea continuar? (s/n): ${COLOR_RESET}"
                read resp
                
                if [ "$resp" == "n" ]
                then
                    return
                fi
                modoLimpio=true
            else
                modoLimpio=true
            fi

            reconstruirDatosGuardados
            echo "Configurando modo limpio : $modoLimpio"
            ;;
        2)
            if [ "$modoVerboso" == true ]
            then
                modoVerboso=false
            else
                modoVerboso=true
            fi
            reconstruirDatosGuardados
            echo "Configurando modo verboso : $modoVerboso"
            ;;
        3)
            if [ "$hayAdvertencias" == true ]
            then
                hayAdvertencias=false
            else
                hayAdvertencias=true
            fi
            reconstruirDatosGuardados
            echo "Configurando hayAdvertencias : $hayAdvertencias"
    esac
}

mensajeContinuacion(){
    read -e -p "$(echo -e "${COLOR_SUCCESS}Presiona enter para $1${COLOR_RESET}")"
}

leerDocumentacion(){
    if [ "$modoLimpio" == true ]
    then
        clear
    fi
    echo -e "${COLOR_INFO}Leyendo documentación${COLOR_RESET}"
    echo;
    echo -e "\e[36m"
    echo "██╗██████╗ ███████╗████████╗ █████╗ ██████╗ ██╗     ███████╗  ██████╗"
    echo "██║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝ ██╔════╝"
    echo "██║██████╔╝█████╗     ██║   ███████║██████╔╝██║     █████╗   ╚█████╗ "
    echo "██║██╔═══╝ ██╔══╝     ██║   ██╔══██║██╔══██╗██║     ██╔══╝    ╚═══██╗"
    echo "██║██║     ███████╗   ██║   ██║  ██║██████╔╝███████╗███████╗ ██████╔╝"
    echo "╚═╝╚═╝     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═════╝ "
    echo -e "\e[0m"

        echo -e "${COLOR_TITLE}Netfilter e iptables: Fundamentos y funcionamiento${COLOR_RESET}"
        echo;
        echo -e "${COLOR_BOLD}Origen de iptables${COLOR_RESET}"
        echo "iptables fue desarrollado en 1998 por Rusty Russell como sucesor de herramientas anteriores como ipfwadm e ipchains. Según el propio Russell (2000), la necesidad de crear iptables surgió por las limitaciones técnicas de sus predecesores, principalmente en cuanto a flexibilidad, rendimiento y soporte para seguimiento de conexiones (stateful)."
        echo;
        echo -e "${COLOR_BOLD}¿Qué es Netfilter?${COLOR_RESET}"
        echo -e "Netfilter es el framework de filtrado de paquetes integrado en el kernel de Linux desde la versión 2.4. Actúa como un conjunto de hooks (ganchos) dentro de la pila de red del kernel. Estos hooks son puntos específicos del procesamiento de paquetes en los que se pueden aplicar reglas definidas por el usuario."
        echo;
        echo -e "${COLOR_BOLD}¿Qué es iptables?${COLOR_RESET}"
        echo "iptables es la herramienta de espacio de usuario que permite configurar las reglas que serán aplicadas por Netfilter. En otras palabras, es la interfaz que se utiliza para definir qué hacer con los paquetes que atraviesan el sistema."
        echo;
        echo -e "${COLOR_BOLD}Conceptos clave${COLOR_RESET}"
        echo -e "${COLOR_BOLD}Filtrado de paquetes:${COLOR_RESET}"
        echo "Proceso de examinar paquetes de red y decidir si permitirlos, rechazarlos o modificarlos, según reglas definidas por el administrador del sistema."
        echo;
        echo -e "${COLOR_BOLD}Stateful firewall (cortafuegos con estado):${COLOR_RESET}"
        echo "Capacidad de rastrear el estado de las conexiones de red (por ejemplo, conexiones nuevas, establecidas o inválidas), lo que permite tomar decisiones más inteligentes sobre qué paquetes permitir o denegar."
        echo;
        echo -e "${COLOR_BOLD}Hooks de Netfilter:${COLOR_RESET}"
        echo "Puntos de la trayectoria de un paquete donde Netfilter permite que se apliquen reglas. Estos puntos incluyen:"
        echo "PREROUTING , INPUT, FORWARD, OUTPUT, POSTROUTING"

    echo;
    mensajeContinuacion "continuar"
}

construirRegla(){
    reglaIpTables="iptables -t $tabla $comando $cadena $posicionCadena"
    for i in "${parametros[@]}"; do
        reglaIpTables="$reglaIpTables $i"
    done
    reglaIpTables="$reglaIpTables $accion"

    #quita espacios innecesarios
    reglaIpTables=$( echo "$reglaIpTables" | xargs)
}

#------------------------------------------------------------------------------
cargarDatosGuardados
source ./config.sh
if [ "$esNuevo" == true ]
then
    bienvenido
    esNuevo=false
    reconstruirDatosGuardados
fi

while true; do

    verificacionGeneral
    echo;
    if [ "$modoLimpio" == true ]
    then 
        clear
    fi
    
    construirRegla

    echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[1;35m🛡️  Creado para ayudarte, construye tu regla iptables\e[0m"
    echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo

    echo "sintaxis: $sintaxisIpTables"
    echo;
    echo "1. Seleccionar tabla"
    #filter, nat, mangle, raw, security
    echo "2. Seleccionar comando"
    #-L -A -I -D -F -X -P
    echo "3. Seleccionar cadena"
    # filter: INPUT, OUTPUT, FORWARD
    # nat: PREROUTING, POSTROUTING, OUTPUT, FORWARD
    # mangle: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING
    #raw: PREROUTING, OUTPUT 
    #security: INPUT, FORWARD, OUTPUT
    echo "4. Seleccionar parámetros"
    #-s direcciónIp -s redOrigen -d ipDestino -p tcp -p udp -p icmp --dport puertoDestino --sport rangoPuertosOrigen --dport multiplesPuertos -i interfazEntrada -o interfazSalida  
    echo "5. Seleccionar acción"
    #-j previamente
    # -j( ACCEPT, DROP, REJECT, LOG, REDIRECT, SNAT, DNAT)
    echo "6. Ejecutar regla"
    echo "7. Resetear regla"
    echo "8. Guardar regla"
    echo "9. Visualizar reglas guardados"
    echo "10. Configurar entorno"
    echo "11. Leer documentación"
    echo "12. Salir del programa"
    echo;
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "${COLOR_BOLD}Regla actual:${COLOR_RESET} $reglaIpTables"
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo;
    echo -n "Ingresa un número por favor: "
    read numero
    echo;
    echo -e "\e[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    case $numero in
        1)
            seleccionarTabla
            ;;
        2)
            seleccionarComando
            ;;
        3)
            seleccionarCadena
            ;;
        4)
            seleccionarParametros
            ;;
        5)
            seleccionarAccion
            ;;
        6)
            ejecutaRegla "$reglaIpTables"
            ;;
        7)
            resetearRegla
            ;;
        8)
            guardarRegla
            ;;
        9)
            visualizarReglasGuardados
            ;;
        10)
            configurarEntorno
            ;;
        11)
            leerDocumentacion
            ;;
        *)
            break;
            ;;
    esac
done
