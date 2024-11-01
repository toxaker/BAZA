import subprocess

class Firewall:
    def __init__(self):
        self.init_firewall()

    def run_command(self, command):
        """Выполняет команду в shell и выводит результат."""
        try:
            subprocess.run(command, check=True, shell=True)
        except subprocess.CalledProcessError as e:
            print(f"Ошибка выполнения команды: {e}")

    def init_firewall(self):
        """Настраивает базовые правила файрвола."""
        # Сброс всех текущих правил
        self.run_command("iptables -F")
        self.run_command("iptables -X")

        # Базовая политика
        self.run_command("iptables -P INPUT DROP")
        self.run_command("iptables -P FORWARD DROP")
        self.run_command("iptables -P OUTPUT ACCEPT")

    # Защита от TCP-сканирований (NULL, XMAS, FIN и т.д.)
    def add_port_scanning_protection(self):
        """Блокировка типов сканирования TCP."""
        self.run_command("iptables -A INPUT -p tcp --tcp-flags ALL FIN -j DROP")
        self.run_command("iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP")
        self.run_command("iptables -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP")
        self.run_command("iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP")

    # Ограничение частоты соединений для предотвращения DDoS
    def add_rate_limiting(self, rate="10/s", burst=20):
        """Ограничение частоты соединений для предотвращения DDoS."""
        self.run_command(f"iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP")
        self.run_command("iptables -A INPUT -m conntrack --ctstate INVALID -j DROP")


    # Ограничение количества одновременных соединений с одного IP
    def limit_concurrent_connections(self, limit=10):
        """Ограничение количества одновременных подключений с одного IP."""
        self.run_command(f"iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above {limit} -j REJECT --reject-with tcp-reset")

    # Защита от фрагментированных пакетов и аномальных пакетов
    def enable_fragmentation_protection(self):
        """Защита от фрагментированных пакетов."""
        self.run_command("iptables -A INPUT -f -j DROP")  # Блокирует фрагментированные пакеты
        self.run_command("iptables -A INPUT -m state --state INVALID -j DROP")  # Блокирует пакеты с некорректным состоянием

    # Ограничение SSH-доступа
    def limit_ssh_connections(self, rate="5/m", burst=10):
        """Ограничение для SSH-подключений."""
        self.run_command(f"iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m limit --limit {rate} --limit-burst {burst} -j ACCEPT")
        self.run_command("iptables -A INPUT -p tcp --dport 22 -j DROP")
        self.run_command("iptables -A INPUT -s 192.168.0.7/24 -p tcp --dport 1488 -j ACCEPT")
        self.run_command("iptables -A INPUT -s 192.168.0.7/24 --sport 22 -p tcp --dport 1488 -j ACCEPT")


    # Дополнительные правила и фильтрация
    def enhanced_logging(self):
        """Логирование заблокированных пакетов для анализа."""
        self.run_command("iptables -A INPUT -j LOG --log-prefix 'Blocked Input:' --log-level 4")
        self.run_command("iptables -A OUTPUT -j LOG --log-prefix 'Blocked Output:' --log-level 4")

    # Полная настройка файрвола с использованием всех методов
    def setup_firewall(self):
        """Конфигурация файрвола."""
        # Разрешение для локальных соединений
        self.run_command("iptables -A INPUT -i lo -j ACCEPT")

        # Разрешение для HTTP и HTTPS
        self.allow_port(80)
        self.allow_port(443)

        # Активация всех методов для защиты
        self.add_port_scanning_protection()
        self.add_rate_limiting()
        self.limit_concurrent_connections()
        self.enable_fragmentation_protection()
        self.limit_ssh_connections()
        self.enhanced_logging()

        # Сохранение и загрузка правил
        self.save_rules()

    # Методы для разрешения и блокировки IP-адресов и портов
    def allow_ip(self, ip):
        """Разрешает доступ с указанного IP."""
        self.run_command(f"iptables -A INPUT -s {ip} -j ACCEPT")

    def block_ip(self, ip):
        """Блокирует указанный IP."""
        self.run_command(f"iptables -A INPUT -s {ip} -j DROP")

    def allow_port(self, port, protocol="tcp"):
        """Разрешает доступ к указанному порту и протоколу (TCP/UDP)."""
        self.run_command(f"iptables -A INPUT -p {protocol} --dport {port} -j ACCEPT")

    def block_port(self, port, protocol="tcp"):
        """Блокирует указанный порт и протокол (TCP/UDP)."""
        self.run_command(f"iptables -A INPUT -p {protocol} --dport {port} -j DROP")

    def save_rules(self):
        """Сохраняет правила iptables."""
        self.run_command("iptables-save > /etc/iptables/rules.v4")

    def load_rules(self):
        """Загружает правила iptables."""
        self.run_command("iptables-restore < /etc/iptables/rules.v4")


# Пример использования
if __name__ == "__main__":
    firewall = Firewall()
    firewall.setup_firewall()
    print("Конфигурация файрвола завершена.")
