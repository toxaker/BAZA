# basic-infosecurence
I decided to get and collect every set up i know to provide the 99% safety. From last 1 % almost impossible to defend.

## Unit 1. Firewall via iptables

### Подготовительные шаги

Убедись, что установлены необходимые пакеты
Для работы с iptables необходимо установить его

    bash

     sudo apt-get install iptables


Проверь необходимые сетевые интерфейсы!
В скрипте используются интерфейсы lo, wlan0 (WiFi), eth0, и fi-hel-wg-002 (это мой VPN). Убедись, что они соответствуют твоим активным сетевым интерфейсам, скорректируй их под свои.

Необходимые значения можно узнать через команду:


    ip addr show

Вывод будет примерно такой:

![image](https://github.com/user-attachments/assets/874482e0-cd58-4c4e-b41c-ea7a6cb51d0e)

Где 127.х.х.х\х - это lo
192.х.х.х\х (176.х.х.х) (10.х.х.х) - это ваша локальная сеть
Оставшееся - это и есть активные профили, в данном случае это wlan0 и VPN


### Начинаем!

     sudo nano /etc/firewall.sh

1. Очистка правил

        bash

        $IPTABLES -F
        $IPTABLES -X

Эти команды сбрасывают все текущие правила и цепочки, чтобы начать с чистого листа.

2. Основные политики

        bash

        $IPTABLES -P INPUT DROP
        $IPTABLES -P FORWARD DROP
        $IPTABLES -P OUTPUT ACCEPT

Политика по умолчанию для входящего и транзитного трафика — блокировать всё. Разрешён только исходящий трафик.

3. Защита от спуфинга и нелегитимных IP-адресов

        bash

        $IPTABLES -A INPUT -i wlan0 -s 127.0.0.1/8 -j DROP

Блокирует любые пакеты с локальными IP-адресами на внешних интерфейсах, предотвращая IP-спуфинг.

4. Защита от сетевых атак

        bash

        $IPTABLES -N SYNFLOOD
        $IPTABLES -A SYNFLOOD -p tcp --syn -m limit --limit 1/s -j RETURN

Создаёт цепочку SYNFLOOD, которая ограничивает количество новых TCP-соединений для защиты от SYN-флуда.

5. Логирование

        bash

        $IPTABLES -A INPUT -j LOG --log-prefix "IPTABLES-DROP: "

Все пакеты, не подпадающие под разрешённые правила, логируются для дальнейшего анализа.

### В целом - это все!

Основные принципы работы продемонстрированы, осталось только кастомизировать под ваши профили.

### Вот мой готовый скрипт:

    #!/bin/sh

    IPTABLES=/sbin/iptables
    
     @ Wipe out all the exicting rules first
     @ Очистка всех существующих правил
        $IPTABLES -F
        $IPTABLES -X

     @ Установить значения по умолчанию: блокировать весь входящий трафик, разрешить исходящий
        $IPTABLES -P INPUT DROP
        $IPTABLES -P FORWARD DROP
        $IPTABLES -P OUTPUT ACCEPT

     @ Разрешить трафик loopback
        $IPTABLES -A INPUT -i lo -j ACCEPT
        $IPTABLES -A OUTPUT -o lo -j ACCEPT
        $IPTABLES -A INPUT -i wlan0 -j ACCEPT
        $IPTABLES -A OUTPUT -o wlan0 -j ACCEPT

     @ Разрешить исходящий трафик через Wi-Fi, Ethernet, VPN интерфейсы. В зависимости от вашего активного профиля
        $IPTABLES -A INPUT -i wlan0 -j ACCEPT
        $IPTABLES -A OUTPUT -o wlan0 -j ACCEPT
        $IPTABLES -A INPUT -i fi-hel-wg-002 -j ACCEPT
        $IPTABLES -A OUTPUT -o fi-hel-wg-002 -j ACCEPT
        $IPTABLES -A INPUT -i eth0 -j ACCEPT
        $IPTABLES -A OUTPUT -o eth0 -j ACCEPT

     @ Защита от спуфинга
     @ Сбросить пакеты с локальными адресами на внешнем интерфейсе (например, eth0, local)
        $IPTABLES -A INPUT -i wlan0 -s 127.0.0.1/8 -j DROP
        $IPTABLES -A INPUT -i wlan0 -s 10.0.0.0/8 -j DROP
        $IPTABLES -A INPUT -i wlan0 -s 192.168.0.7/24 -j DROP

     @ Заблокировать любой пакет с нулевыми адресами
        $IPTABLES -A INPUT -s 0.0.0.0/8 -j DROP

     @ Отклонить пакеты с адресами broadcast
        $IPTABLES -A INPUT -s 255.255.255.255 -j DROP

     @ Проверка целостности пакетов с некорректными комбинациями флагов (сигнатуры спуфинга)
        $IPTABLES -A INPUT -m conntrack --ctstate INVALID -j DROP

     @ Разрешить только пакеты с допустимыми комбинациями флагов TCP
        $IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

     @ Отклонение пакетов с "многообещающими" (bogus) IP-адресами
        $IPTABLES -A INPUT -s 240.0.0.0/4 -j DROP

     @ Блокировка входящих пакетов с тем же исходящим IP-адресом сервера (предотвращение loopback-атак)
     @ Блокировать недействительные пакеты
        $IPTABLES -A INPUT -m state --state INVALID -j DROP

     @ Защита от сканирования Nmap и других подозрительных пакетов
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


     @ Защита от SYN-флуда
        $IPTABLES -N SYNFLOOD
        $IPTABLES -A SYNFLOOD -p tcp --syn -m limit --limit 1/s -j RETURN
        $IPTABLES -A SYNFLOOD -p tcp -j REJECT --reject-with tcp-reset
        $IPTABLES -A INPUT -p tcp -m state --state NEW -j SYNFLOOD

     @ Защита от ICMP-флуда (ping-флуд)
        $IPTABLES -N PING
        $IPTABLES -A PING -p icmp --icmp-type echo-request -m limit --limit 1/second -j RETURN
        $IPTABLES -A PING -p icmp -j REJECT
        $IPTABLES -A INPUT -p icmp --icmp-type echo-request -m state --state NEW -j 

 @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
 @ @ Allowed connections
 @ @ Разрешенные соединения


     @ Разрешить HTTP и HTTPS
        $IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT       @ HTTP
        $IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT      @ HTTPS

     @ Разрешить SSH, но только с локальной сети (или конкретного диапазона IP)
        $IPTABLES -A INPUT -p tcp -s 192.168.0.0/16 --dport 22 -j ACCEPT   @ SSH

     @ Разрешить DNS и DHCP
        $IPTABLES -A INPUT -p udp --dport 53 -j ACCEPT       @ DNS
        $IPTABLES -A INPUT -p udp --dport 67:68 -j ACCEPT    @ DHCP
        $IPTABLES -A OUTPUT -p udp --sport 53 -j ACCEPT      @ DNS
        $IPTABLES -A OUTPUT -p udp --sport 67:68 -j ACCEPT   @ DHCP

     @ Разрешить VPN трафик (WireGuard)
        $IPTABLES -A INPUT -p udp --dport 51820 -j ACCEPT
        $IPTABLES -A OUTPUT -p udp --sport 51820 -j ACCEPT
        
        $IPTABLES -A INPUT -p tcp --dport 1080 -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp --sport 1080 -j ACCEPT
        $IPTABLES -A OUTPUT -p tcp --dport 1024:65535 -j ACCEPT


        $IPTABLES -A INPUT -j LOG --log-prefix "IPTABLES-DROP: "


     @ Отклонить все остальные соединения
        $IPTABLES -A INPUT -j DROP
        $IPTABLES -A FORWARD -j DROP

     @ Specify ip to be banned

        $IPTABLES -A INPUT -s 185.250.47.97 -j DROP

            
 ### ENGLISH VERSION

 ---

# Basic InfoSec Tools for Server Protection

[![License](https://img.shields.io/github/license/toxaker/basic-infosecurence)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/toxaker/basic-infosecurence)](https://github.com/toxaker/basic-infosecurence/stargazers) ![Contributors](https://img.shields.io/github/contributors/toxaker/basic-infosecurence)

## Overview

The **Basic InfoSec Tools** repository aims to provide a comprehensive set of scripts and configurations to secure your Linux server. The primary goal is to ensure 99% protection against common network-based threats. The last 1% of threats are difficult to defend against, but this project focuses on minimizing exposure to attacks.

The repository includes tools such as a firewall configuration script using `iptables`, designed to protect your server from common network vulnerabilities.

### Key Features

- **Firewall Configuration**: Pre-configured rules using `iptables` to block unwanted traffic and protect from IP spoofing, SYN flooding, and other attacks.
- **Customizability**: Easily modify the script for your specific network interfaces and use case.
- **Essential Security**: Includes rules for protecting SSH, HTTP/HTTPS, DNS, VPN, and more.
  
### Who is it for?

- **System Administrators** looking to improve security on their Linux servers.
- **Developers** who want to secure their development environments.
- **Users** concerned with securing their home servers or personal VPNs.

---

## Installation

### Prerequisites

Make sure that the following dependencies are installed on your system:

- **iptables**: A powerful tool to configure Linux kernel-level firewalls.
- **Linux System**: Tested on Debian-based distributions such as Debian 12, Ubuntu, and Kali Linux.

### Steps to Install

1. **Check Your Network Interfaces**:
   The script uses the following network interfaces by default: `lo` (localhost), `wlan0` (Wi-Fi), `eth0` (Ethernet), and `fi-hel-wg-002` (VPN). To view your active network interfaces, run:
   ```bash
   ip addr show
   ```
   Adapt the interface names in the script if needed.

2. **Install iptables** (if not already installed):
   ```bash
   sudo apt-get install iptables
   ```

3. **Edit the Firewall Script** to match your network interfaces:
   ```bash
   sudo nano /etc/firewall.sh
   ```
   Make the necessary modifications to interface names and save the file.

4. **Run the Firewall Script**:
   ```bash
   sudo ./firewall.sh
   ```

---

## Usage

After installation, you can run the script at any time to enforce the firewall rules. Here are a few examples:

- **Start the firewall**:
  ```bash
  sudo ./firewall.sh
  ```

- **Check firewall status**:
  ```bash
  sudo iptables -L
  ```

You can also set the script to run automatically at boot by adding it to system services (see next section).

---

## Script Details

### 1. Clearing Existing Rules

The script starts by clearing all existing firewall rules:
```bash
$IPTABLES -F
$IPTABLES -X
```

### 2. Default Policy

It sets the default policy to drop all incoming and forwarding traffic while allowing outgoing traffic:
```bash
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT
```

### 3. Loopback and Local Traffic

The script allows traffic for the loopback interface (`lo`) and local network interfaces:
```bash
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT
```

### 4. Spoofing Protection

It includes rules to block IP spoofing:
```bash
$IPTABLES -A INPUT -i wlan0 -s 127.0.0.1/8 -j DROP
```

### 5. SYN Flood Protection

It adds protection against SYN flood attacks:
```bash
$IPTABLES -N SYNFLOOD
$IPTABLES -A SYNFLOOD -p tcp --syn -m limit --limit 1/s -j RETURN
```

### 6. ICMP Flood Protection

Protects from ping (ICMP) floods:
```bash
$IPTABLES -N PING
$IPTABLES -A PING -p icmp --icmp-type echo-request -m limit --limit 1/second -j RETURN
```

### 7. Allowed Services

The script allows specific services like HTTP, HTTPS, SSH, and DNS:
```bash
$IPTABLES -A INPUT -p tcp --dport 80 -j ACCEPT       # HTTP
$IPTABLES -A INPUT -p tcp --dport 443 -j ACCEPT      # HTTPS
$IPTABLES -A INPUT -p tcp --dport 22 -j ACCEPT       # SSH
```

For more details, view the [full script here](./firewall.sh).

---

## Technical Details

- **Technology**: Linux, `iptables`
- **Purpose**: Network security, firewall management
- **Tested on**: Debian, Ubuntu, Kali Linux

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## Contact

For any questions or feedback, you can reach me via:

- Email: [kalinux@hacking.net.ru](mailto:kalinux@hacking.net.ru)
- GitHub Issues: [Submit an issue](https://github.com/toxaker/basic-infosecurence/issues)

---

## Roadmap

- Add more protection features such as DDoS mitigation.
- Implement logging for better tracking of suspicious activity.

---

## Screenshots

If you want to add screenshots of the script in action, you can include them here, such as output examples from running `iptables` commands or other relevant images.

---

## Future Enhancements

- **Additional Security Modules**: Integration with `fail2ban` or other tools.
- **Automated Installations**: Making the setup process even more seamless.
