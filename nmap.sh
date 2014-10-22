nmap scripts

1) mostly needs root access
2) hashcat - decrypt passwords
3) Sniffing - passive / active


on server (192.168.10.10): tcpdump -i eth0 host 192.168.10.10 and tcp portrange 1-1024

from client to server: telnet 192.168.10.10

save to pcap -> import in wireshark. Analyze!


TYPES OF SCANNING:


nmap -sS: SYN
TCP-SYN - default type. 
1) Fast. Can scan a lot of ports in short time. No full TCP connection. Any TCP stack. No hardware dependant. 
Is port closed/open/filtltered?
Send TCP-SYN -< SYN-ACK = OPEN
Send TCP-SYN -< RST = CLOSED
Send TCP-SYN -< no reply? filtered. (ICMP unreachable)

nmap -sT: Connect (in case you cant use raw socket or IPv6)
Use system call. Full TCP connection. Can be traced (more info in the logs)

