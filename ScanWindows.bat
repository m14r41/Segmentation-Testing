@echo off
set "red=[1;31m"
set "green=[1;32m"
set "reset=[0m"

echo %red%Enter your IP range: %reset%
set /p "ip_range="

nmap -sn %ip_range% > live_subnet.txt
nmap -sn %ip_range% | findstr /r /c:"^Nmap scan report" > temp.txt
for /f "tokens=2 delims= " %%A in (temp.txt) do (
    set /a count+=1
    set "ips=!ips!%%A "
)
echo %ips% >> temp.txt
echo %green%Total up IPs in your subnet: %count%%reset% >> temp.txt
type temp.txt
del temp.txt

if exist "live_ip.txt" (
    del "live_ip.txt"
)

echo %red%Enter IP address or list of IPs separated by spaces: %reset%
set /p "ip_list="

echo %red%Checking live IPs...%reset%
for %%i in (%ip_list%) do (
    echo %%i | findstr /R /C:"^[0-9].*" >nul
    if not errorlevel 1 (
        nmap -sn %%i | findstr /C:"Host is up" >nul
        if not errorlevel 1 (
            echo %green%%%i is live.%reset%
            echo %%i>> live_ip.txt
        ) else (
            echo %red%%%i is not reachable.%reset%
        )
    ) else (
        echo %red%%%i is not a valid IP address.%reset%
    )
)

echo %red%Performing TCP scan on live IPs...%reset%
set "tcp_ports=11,13,15,17,19-23,25,37,42,53,66,69-70,79-81,88,98,109-111,113,118-119,123,135,139,143,220,256-259,264,371,389,411,443,445,464-465,512-515,523-524,540,548,554,563,580,593,636,749-751,873,900-901,990,992-993,995,1080,1114,1214,1234,1352,1433,1494,1508,1521,1720,1723,1755,1801,2000-2001,2003,2049,2301,2401,2447,2690,2766,3128,3268-3269,3306,3372,3389,4100,4443-4444,4661-4662,5000,5432,5555-5556,5631-5632,5634,5800-5802,5900-5901,6000,6112,6346,6387,6666-6667,6699,7007,7100,7161,7777-7778,7070,8000-8001,8010,8080-8081,8100,8888,8910,9100,10000,12345-12346,20034,21554,32000,32768-32790"

if exist "live_ip.txt" (
    for /f "usebackq tokens=*" %%i in ("live_ip.txt") do (
        echo %green%Scanning TCP ports on %%i...%reset%
        nmap -Pn -p %tcp_ports% %%i >> tcp_scan.txt
        type tcp_scan.txt
    )
)

echo %red%Performing UDP scan on live IPs...%reset%
set "udp_ports=7,13,17,19,37,53,67-69,111,123,135,137,161,177,407,464,500,517-518,520,1434,1645,1701,1812,2049,3527,4569,4665,5036,5060,5632,6502,7778,15345"

if exist "live_ip.txt" (
    for /f "usebackq tokens=*" %%i in ("live_ip.txt") do (
        echo %green%Scanning UDP ports on %%i...%reset%
        nmap -Pn -sU -p %udp_ports% %%i >> udp_scan.txt
        type udp_scan.txt
    )
)

echo %green%Your all scans are completed.%reset%
echo %red%Enter your folder save the scan result%reset% :
set /p "name="

if exist "%name%" (
    echo Folder '%name%' exists.
    rmdir /s /q "%name%"
)

mkdir "%name%" && (
    move /y live_subnet.txt "%name%"
    move /y live_ip.txt "%name%"
    move /y tcp_scan.txt "%name%"
    move /y udp_scan.txt "%name%"
    echo %green%All your files have been moved to %name%%reset%
)

