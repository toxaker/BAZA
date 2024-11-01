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
