#Listado de reglas
Iptables –L : Lista todas las reglas
Iptables –L INPUT : Lista de reglas de INPUT
Iptables –L –n : Sin resolución DNS
Iptables –L  - - line-numbers : Con números de línea. 

#Agregar reglas
Iptables  -A INPUT … : agregar al final.
Iptables –I INPUT 1 … : insertar en posición 1

#Eliminar reglas
Iptables –D INPUT 1: Eliminar regla N° 1.
Iptables –D INPUT –s 192.168.1.1 –j DROP : Eliminar regla específica.

#Limpiar reglas
Iptables  -F : Eliminar todas las reglas
Iptables –F INPUT … : Eliminar reglas de INPUT
Iptables –X … : Eliminar cadenas personalizadas

#Comandos principales

#Politicas por defecto
Iptables –P INPUT ACCEPT : Permitir por defecto
Iptables –P INPUT DROP : Denegar por defecto
Iptables –P FORWARD DROP
Iptables –P OUTPUT ACCEPT

#Configuraciones basicas de firewall

#Politicas restrictivas
Iptables –P INPUT DROP
Iptables –P FORWARD DROP
Iptables –P OUTPUT DROP
Iptables –A INPUT –i lo –j ACCEPT
Iptables –A OUTPUT –o lo –j ACCEPT

#Permitir conexiones establecidas
Iptables –A INPUT –m state  - -state  ESTABLISHED, RELATED –j ACCEPT
Iptables –A OUTPUT –m state  - -state  ESTABLISHED –j ACCEPT

#Servicios específicos
Iptables –A INPUT  -p  tcp  --dport 22 –m state  - -state NEW  -j ACCEPT 

#HTTP y HTTPS 
Iptables -A INPUT -p tcp --dport 80 -j ACCEPT 
iptables -A INPUT -p tcp --dport 443 -j ACCEPT 

#DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT 
PING (ICMP) iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT iptables -A OUTPUT -p icmp -j ACCEPT
