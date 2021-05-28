#!/bin/ash

#Проверяем корректность переменных окружения
[ -z "$INT_IF" ] && echo 'INT_IF not defined.' && exit 2
[ -z "$EXT_IF" ] && echo 'EXT_IF not defined.' && exit 3
ip -o -f inet a s "$INT_IF" >/dev/null         || exit 4
ip -o -f inet a s "$EXT_IF" >/dev/null         || exit 5

#Очищаем все существующие правила
iptables -F
iptables -F -t nat
iptables -F -t mangle
iptables -X
iptables -t nat -X
iptables -t mangle -X

# Закрываем изначально ВСЁ (т.е. изначально все что не разрешено - запрещено):
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# разрешаем локальный траффик для loopback и внутренней сети
iptables -A INPUT -i lo -j ACCEPT

#iptables -A INPUT -i $INT_IF -j ACCEPT
iptables -A INPUT -i $INT_IF -j ACCEPT
iptables -A INPUT -i $EXT_IF -j ACCEPT

iptables -A OUTPUT -o lo -j ACCEPT

#iptables -A OUTPUT -o $INT_IF -j ACCEPT
iptables -A OUTPUT -o $INT_IF -j ACCEPT
iptables -A OUTPUT -o $EXT_IF -j ACCEPT

# Пропускать все уже инициированные соединения, а также дочерние от них
iptables -A INPUT -p all -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Пропускать новые, а так же уже инициированные и их дочерние соединения
iptables -A OUTPUT -p all -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

# Разрешить форвардинг для новых, а так же уже инициированных и их дочерних соединений
iptables -A FORWARD -p all -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

# Включаем фрагментацию пакетов. Необходимо из за разных значений MTU
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Отбрасывать все пакеты, которые не могут быть идентифицированы и поэтому не могут иметь определенного статуса.
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# Приводит к связыванию системных ресурсов, так что реальный обмен данными становится не возможным.
iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
iptables -A OUTPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# Разрешаем доступ из внутренней сети наружу
iptables -A FORWARD -i $INT_IF -o $EXT_IF -j ACCEPT

# Запрещаем доступ снаружи во внутреннюю сеть
#iptables -A FORWARD -i $EXT_IF -o $INT_IF -j REJECT

# Разрешаем доступ снаружи во внутреннюю сеть
iptables -A FORWARD -i $EXT_IF -o $INT_IF -j ACCEPT

echo 'Firewall will done!'
