#!/bin/bash

# Define colors for output
red="\033[1;31m"
green="\033[1;32m"
reset="\033[0m"

# Input: IP range
echo -e "${red}Enter your IP range:${reset}"
read ip_range

# Perform ICMP ping sweep for live_subnet.txt
echo -e "${red}Performing ICMP ping sweep...${reset}"
nmap -sn "$ip_range" | tee live_subnet.txt

# Count live IPs and print
count=$(nmap -sn "$ip_range" | awk '/^Nmap scan report/{ips = ips $NF " "; count++} END{print ips "\n\033[1;32mTotal up IPs in your subnet: " count "\033[0m"}')
echo -e "$count"

# Remove live_ip.txt if it exists
[ -f "live_ip.txt" ] && sudo rm "live_ip.txt"

# Input: List of IPs
echo -e "${red}Enter IP address or list of IPs separated by spaces:${reset}"
read ip_list

# Check live IPs and store in live_ip.txt
echo -e "${red}Checking live IPs...${reset}"
for ip in $ip_list; do
  if sudo nmap -sn $ip | grep -q "Host is up"; then
    echo -e "${green}$ip is live.${reset}"
    echo "$ip" >> live_ip.txt
  else
    echo -e "${red}$ip is not reachable.${reset}"
  fi
done

# Define TCP and UDP port lists
tcp_ports="11,13,15,17,19-23,25,37,42,53,66,69-70,79-81,88,98,109-111,113,118-119,123,135,139,143,220,256-259,264,371,389,411,443,445,464-465,512-515,523-524,540,548,554,563,580,593,636,749-751,873,900-901,990,992-993,995,1080,1114,1214,1234,1352,1433,1494,1508,1521,1720,1723,1755,1801,2000-2001,2003,2049,2301,2401,2447,2690,2766,3128,3268-3269,3306,3372,3389,4100,4443-4444,4661-4662,5000,5432,5555-5556,5631-5632,5634,5800-5802,5900-5901,6000,6112,6346,6387,6666-6667,6699,7007,7100,7161,7777-7778,7070,8000-8001,8010,8080-8081,8100,8888,8910,9100,10000,12345-12346,20034,21554,32000,32768-32790"
udp_ports="7,13,17,19,37,53,67-69,111,123,135,137,161,177,407,464,500,517-518,520,1434,1645,1701,1812,2049,3527,4569,4665,5036,5060,5632,6502,7778,15345"

# Perform TCP scans on live IPs and store results in tcp_scan.txt
echo -e "${red}Performing TCP scan on live IPs...${reset}"
while read -r live_ip; do
  echo -e "${green}Scanning TCP ports on $live_ip...${reset}"
  sudo nmap -Pn -p $tcp_ports $live_ip | tee -a tcp_scan.txt
done < live_ip.txt

# Perform UDP scans on live IPs and store results in udp_scan.txt
echo -e "${red}Performing UDP scan on live IPs...${reset}"
while read -r live_ip; do
  echo -e "${green}Scanning UDP ports on $live_ip...${reset}"
  sudo nmap -Pn -sU -p $udp_ports $live_ip | tee -a udp_scan.txt
done < live_ip.txt

# Input: Folder name and move output files
echo -e "${green}All your scans are completed.\n"
echo -e "Enter your folder to move the files:${reset}"
read name

if [ -d "$name" ]; then
  echo "Folder '$name' exists."
  rm -rf "$name"
fi

mkdir "$name" && mv live_subnet.txt live_ip.txt tcp_scan.txt udp_scan.txt "$name"
echo -e "${green}All your files have been moved to $name${reset}"
