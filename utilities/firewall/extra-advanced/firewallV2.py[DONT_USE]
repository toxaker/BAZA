import subprocess

class Firewall:
    def __init__(self):
        self.init_firewall()

    def run_command(self, command):
        """Execute a shell command and output result."""
        try:
            subprocess.run(command, check=True, shell=True)
        except subprocess.CalledProcessError as e:
            print(f"Command execution error: {e}")

    def init_firewall(self):
        """Initialize firewall with basic policies and reset all rules."""
        # Clear all existing rules
        self.run_command("iptables -F")
        self.run_command("iptables -X")
        self.run_command("ip6tables -F")
        self.run_command("ip6tables -X")

        # Basic policies
        self.run_command("iptables -P INPUT DROP")
        self.run_command("iptables -P FORWARD DROP")
        self.run_command("iptables -P OUTPUT ACCEPT")
        self.run_command("ip6tables -P INPUT DROP")
        self.run_command("ip6tables -P FORWARD DROP")
        self.run_command("ip6tables -P OUTPUT ACCEPT")

    # Block TCP scans (NULL, XMAS, FIN, etc.)
    def add_port_scanning_protection(self):
        """Block specific types of TCP scans."""
        rules = [
            "iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP",
            "iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP",
            "iptables -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP",
            "iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP",
            "ip6tables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP",
            "ip6tables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP",
            "ip6tables -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP",
            "ip6tables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP"
        ]
        for rule in rules:
            self.run_command(rule)

    # Limit connection rate to prevent DDoS attacks
    def add_rate_limiting(self, rate="10/s", burst=20):
        """Limit connection rate to prevent DDoS attacks."""
        self.run_command(f"iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP")
        self.run_command("ip6tables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("ip6tables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP")

    # Limit simultaneous connections from a single IP
    def limit_concurrent_connections(self, limit=10):
        """Limit concurrent connections from a single IP address."""
        self.run_command(f"iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above {limit} -j REJECT --reject-with tcp-reset")
        self.run_command(f"ip6tables -A INPUT -p tcp --syn -m connlimit --connlimit-above {limit} -j REJECT --reject-with tcp-reset")

    # Protection against SYN flood attacks
    def add_syn_flood_protection(self):
        """Enable protection against SYN flood attacks."""
        self.run_command("iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT")
        self.run_command("iptables -A INPUT -p tcp --syn -j DROP")
        self.run_command("ip6tables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT")
        self.run_command("ip6tables -A INPUT -p tcp --syn -j DROP")

    # Protection against fragmented packets
    def enable_fragmentation_protection(self):
        """Enable protection against fragmented packets for IPv4 and IPv6."""
        self.run_command("iptables -A INPUT -f -j DROP")
        self.run_command("ip6tables -A INPUT -f -j DROP")
        self.run_command("iptables -A INPUT -m state --state INVALID -j DROP")
        self.run_command("ip6tables -A INPUT -m state --state INVALID -j DROP")

    # Limit SSH connections
    def limit_ssh_connections(self, rate="5/m", burst=10):
        """Limit SSH connections to prevent brute-force attacks."""
        self.run_command(f"iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("iptables -A INPUT -p tcp --dport 22 -j DROP")
        self.run_command(f"ip6tables -A INPUT -p tcp --dport 22 -m state --state NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("ip6tables -A INPUT -p tcp --dport 22 -j DROP")

    # Block known malicious IP addresses
    def block_malicious_ips(self, blacklist):
        """Block known malicious IP addresses from the given blacklist."""
        for ip in blacklist:
            self.run_command(f"iptables -A INPUT -s {ip} -j DROP")
            self.run_command(f"ip6tables -A INPUT -s {ip} -j DROP")

    # Enhanced logging for analysis of blocked packets
    def enhanced_logging(self):
        """Log blocked packets for analysis."""
        self.run_command("iptables -A INPUT -j LOG --log-prefix 'Blocked Input IPv4:' --log-level 4")
        self.run_command("ip6tables -A INPUT -j LOG --log-prefix 'Blocked Input IPv6:' --log-level 4")

    # Full firewall setup with enhanced protection
    def setup_firewall(self):
        """Full configuration of the firewall with all protection methods."""
        # Allow loopback interface traffic
        self.run_command("iptables -A INPUT -i lo -j ACCEPT")
        self.run_command("ip6tables -A INPUT -i lo -j ACCEPT")

        # Allow essential ports (HTTP, HTTPS)
        self.allow_port(80)
        self.allow_port(443)
        self.allow_port(80, protocol="tcp", ipv6=True)
        self.allow_port(443, protocol="tcp", ipv6=True)

        # Activate protection methods
        self.add_port_scanning_protection()
        self.add_rate_limiting()
        self.limit_concurrent_connections()
        self.add_syn_flood_protection()
        self.enable_fragmentation_protection()
        self.limit_ssh_connections()
        self.enhanced_logging()

        # Optional: Block known malicious IPs
        blacklist = ["203.0.113.5", "198.51.100.23"]  # Replace with actual malicious IPs
        self.block_malicious_ips(blacklist)

        # Save and load rules
        self.save_rules()

    # Allow/block IPs and ports
    def allow_ip(self, ip, ipv6=False):
        """Allow traffic from the specified IP."""
        command = f"{'ip6tables' if ipv6 else 'iptables'} -A INPUT -s {ip} -j ACCEPT"
        self.run_command(command)

    def block_ip(self, ip, ipv6=False):
        """Block traffic from the specified IP."""
        command = f"{'ip6tables' if ipv6 else 'iptables'} -A INPUT -s {ip} -j DROP"
        self.run_command(command)

    def allow_port(self, port, protocol="tcp", ipv6=False):
        """Allow traffic on the specified port and protocol."""
        command = f"{'ip6tables' if ipv6 else 'iptables'} -A INPUT -p {protocol} --dport {port} -j ACCEPT"
        self.run_command(command)

    def block_port(self, port, protocol="tcp", ipv6=False):
        """Block traffic on the specified port and protocol."""
        command = f"{'ip6tables' if ipv6 else 'iptables'} -A INPUT -p {protocol} --dport {port} -j DROP"
        self.run_command(command)

    def save_rules(self):
        """Save firewall rules to be persistent across reboots."""
        self.run_command("iptables-save > /etc/iptables/rules.v4")
        self.run_command("ip6tables-save > /etc/iptables/rules.v6")

    def load_rules(self):
        """Load saved firewall rules."""
        self.run_command("iptables-restore < /etc/iptables/rules.v4")
        self.run_command("ip6tables-restore < /etc/iptables/rules.v6")


# Usage example
if __name__ == "__main__":
    firewall = Firewall()
    firewall.setup_firewall()
