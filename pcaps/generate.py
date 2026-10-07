#!/usr/bin/env python3
"""
Génère les captures (.pcap) des 4 scénarios d'attaque du lab SIEM.
Rejouées par Snort avec `snort -r`, elles déclenchent les règles custom.

Topologie simulée :
    Attaquant : 172.28.0.30
    Cible     : 172.28.0.40
"""
from scapy.all import Ether, IP, TCP, ICMP, Raw, wrpcap
import time

ATTACKER = "172.28.0.30"
TARGET = "172.28.0.40"
MAC_A = "02:42:ac:1c:00:1e"
MAC_T = "02:42:ac:1c:00:28"

base = time.time()


def eth(pkt):
    return Ether(src=MAC_A, dst=MAC_T) / pkt


# -----------------------------------------------------------------------------
# Scénario 1 — Scan de ports Nmap (SID 1000001/1000002/1000003)
# -----------------------------------------------------------------------------
scan = []
# 25 SYN vers des ports différents en < 5 s  -> SID 1000001 (seuil 20/5s)
for i, port in enumerate(range(1, 26)):
    p = eth(IP(src=ATTACKER, dst=TARGET) / TCP(sport=40000 + i, dport=port, flags="S"))
    p.time = base + i * 0.1
    scan.append(p)
# 1 scan NULL (aucun flag) -> SID 1000002
p = eth(IP(src=ATTACKER, dst=TARGET) / TCP(sport=41000, dport=80, flags=""))
p.time = base + 3
scan.append(p)
# 1 scan XMAS (FIN+PSH+URG) -> SID 1000003
p = eth(IP(src=ATTACKER, dst=TARGET) / TCP(sport=41001, dport=80, flags="FPU"))
p.time = base + 3.1
scan.append(p)
wrpcap("01-nmap-scan.pcap", scan)
print(f"01-nmap-scan.pcap : {len(scan)} paquets")

# -----------------------------------------------------------------------------
# Scénario 2 — Brute-force SSH (SID 1000010)
# -----------------------------------------------------------------------------
ssh = []
# 12 SYN vers le port 22 en < 20 s -> SID 1000010 (seuil 10/20s)
for i in range(12):
    p = eth(IP(src=ATTACKER, dst=TARGET) / TCP(sport=42000 + i, dport=22, flags="S"))
    p.time = base + i * 0.5
    ssh.append(p)
wrpcap("02-ssh-bruteforce.pcap", ssh)
print(f"02-ssh-bruteforce.pcap : {len(ssh)} paquets")

# -----------------------------------------------------------------------------
# Scénario 3 — Ping flood ICMP (SID 1000020)
# -----------------------------------------------------------------------------
flood = []
# 60 echo-request en < 5 s -> SID 1000020 (seuil 50/5s)
for i in range(60):
    p = eth(IP(src=ATTACKER, dst=TARGET) / ICMP(type=8, id=0x1234, seq=i))
    p.time = base + i * 0.05
    flood.append(p)
wrpcap("03-ping-flood.pcap", flood)
print(f"03-ping-flood.pcap : {len(flood)} paquets")

# -----------------------------------------------------------------------------
# Scénario 4 — Injection SQL (SID 1000030/1000031/1000032)
# -----------------------------------------------------------------------------
sqli = []
payloads = [
    "GET /index.php?id=1 union select username,password from users HTTP/1.1\r\nHost: %s\r\n\r\n" % TARGET,
    "GET /index.php?id=1 or 1=1 HTTP/1.1\r\nHost: %s\r\n\r\n" % TARGET,
    "GET /index.php?id=admin'-- HTTP/1.1\r\nHost: %s\r\n\r\n" % TARGET,
]
for i, data in enumerate(payloads):
    p = eth(IP(src=ATTACKER, dst=TARGET) /
            TCP(sport=43000 + i, dport=80, flags="PA", seq=1000) /
            Raw(load=data))
    p.time = base + i * 0.5
    sqli.append(p)
wrpcap("04-sql-injection.pcap", sqli)
print(f"04-sql-injection.pcap : {len(sqli)} paquets")

print("Toutes les captures ont été générées.")
