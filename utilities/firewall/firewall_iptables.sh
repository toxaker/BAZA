#!/bin/sh

IPTABLES=/sbin/iptables

# Wipe out all the exicting rules first
# Очистка всех существующих правил
$IPTABLES -F
$IPTABLES -X

# Установить политики по умолчанию: блокировать весь входящий трафик, разрешить исходящий
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

# Разрешить локальный трафик (loopback)
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT
$IPTABLES -A INPUT -i wlan0 -j ACCEPT
$IPTABLES -A OUTPUT -o wlan0 -j ACCEPT

# Разрешить исходящий трафик через Wi-Fi и VPN интерфейсы
$IPTABLES -A INPUT -i wlan0 -j ACCEPT
$IPTABLES -A OUTPUT -o wlan0 -j ACCEPT
$IPTABLES -A INPUT -i fi-hel-wg-002 -j ACCEPT
$IPTABLES -A OUTPUT -o fi-hel-wg-002 -j ACCEPT
$IPTABLES -A INPUT -i eth0 -j ACCEPT
$IPTABLES -A OUTPUT -o eth0 -j ACCEPT

# Защита от спуфинга
# Сбросить пакеты с локальными адресами на внешнем интерфейсе (например, eth0)
$IPTABLES -A INPUT -i wlan0 -s 127.0.0.1/8 -j DROP
$IPTABLES -A INPUT -i wlan0 -s 10.0.0.0/8 -j DROP
$IPTABLES -A INPUT -i wlan0 -s 192.168.0.7/24 -j DROP

# Заблокировать любой пакет с нулевыми адресами
$IPTABLES -A INPUT -s 0.0.0.0/8 -j DROP

# Отклонить пакеты с адресами broadcast
$IPTABLES -A INPUT -s 255.255.255.255 -j DROP

# Проверка целостности пакетов с некорректными комбинациями флагов (сигнатуры спуфинга)
$IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

# Разрешить только пакеты с допустимыми комбинациями флагов TCP
$IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# Отклонение пакетов с "многообещающими" (bogus) IP-адресами
$IPTABLES -A INPUT -s 240.0.0.0/4 -j DROP

# Блокировка входящих пакетов с тем же исходящим IP-адресом сервера (предотвращение loopback-атак)
# Блокировать недействительные пакеты
$IPTABLES -A INPUT -m state --state INVALID -j DROP

# Защита от сканирования Nmap и других подозрительных пакетов
$IPTABLES -A INPUT -i wlan0 -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPTABLES -A INPUT -i wlan0 -p tcp --tcp-flags ALL ALL -j DROP
$IPTABLES -A INPUT -i wlan0 -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
$IPTABLES -A INPUT -i wlan0 -p tcp --tcp-flags ALL NONE -j DROP
$IPTABLES -A INPUT -i fi-hel-wg-002 -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPTABLES -A INPUT -i fi-hel-wg-002 -p tcp --tcp-flags ALL ALL -j DROP
$IPTABLES -A INPUT -i fi-hel-wg-002 -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
$IPTABLES -A INPUT -i fi-hel-wg-002 -p tcp --tcp-flags ALL NONE -j DROP
$IPTABLES -A INPUT -i eth0 -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPTABLES -A INPUT -i eth0 -p tcp --tcp-flags ALL ALL -j DROP
$IPTABLES -A INPUT -i eth0 -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP


# Защита от SYN-флуда
$IPTABLES -N SYNFLOOD
$IPTABLES -A SYNFLOOD -p tcp --syn -m limit --limit 1/s -j RETURN
$IPTABLES -A SYNFLOOD -p tcp -j REJECT --reject-with tcp-reset
$IPTABLES -A INPUT -p tcp -m state --state NEW -j SYNFLOOD

# Защита от ICMP-флуда (ping-флуд)
$IPTABLES -N PING
$IPTABLES -A PING -p icmp --icmp-type echo-request -m limit --limit 1/second -j RETURN
$IPTABLES -A PING -p icmp -j REJECT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -m state --state NEW -j 

#################################
## Allowed connections
## Разрешенные соединения


# Разрешить HTTP и HTTPS
$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT      # HTTP
$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT     # HTTPS

# Разрешить SSH, но только с локальной сети (или конкретного диапазона IP)
$IPTABLES -A INPUT -p tcp -s 192.168.0.0/16 --dport 22 -j ACCEPT  # SSH

# Разрешить DNS и DHCP
$IPTABLES -A INPUT -p udp --dport 53 -j ACCEPT      # DNS
$IPTABLES -A INPUT -p udp --dport 67:68 -j ACCEPT   # DHCP
$IPTABLES -A OUTPUT -p udp --sport 53 -j ACCEPT     # DNS
$IPTABLES -A OUTPUT -p udp --sport 67:68 -j ACCEPT  # DHCP

# Разрешить VPN трафик (WireGuard)
$IPTABLES -A INPUT -p udp --dport 51820 -j ACCEPT
$IPTABLES -A OUTPUT -p udp --sport 51820 -j ACCEPT

$IPTABLES -A INPUT -p tcp --dport 1080 -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --sport 1080 -j ACCEPT
$IPTABLES -A OUTPUT -p tcp --dport 1024:65535 -j ACCEPT


$IPTABLES -A INPUT -j LOG --log-prefix "IPTABLES-DROP: "


# Отклонить все остальные соединения
$IPTABLES -A INPUT -j DROP
$IPTABLES -A FORWARD -j DROP

# Specify ip to be banned

$IPTABLES -A INPUT -s 185.250.47.97 -j DROP
