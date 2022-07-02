#!/usr/bin/env python

import sys
import subprocess
import json


def get_ip():
    """
    $ ifconfig wlp4s0
    wlp4s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.77  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::ba40:8107:ddec:fd91  prefixlen 64  scopeid 0x20<link>
        ether 5c:61:99:0e:75:9b  txqueuelen 1000  (Ethernet)
        RX packets 4190798  bytes 5998453571 (5.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 886072  bytes 90365986 (86.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

     # No internet 
     wlp4s0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        ether 52:dc:f0:41:68:9e  txqueuelen 1000  (Ethernet)
        RX packets 4192682  bytes 6000248214 (5.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 887540  bytes 90584315 (86.3 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    """
    cmd = "ifconfig wlp4s0"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    if "inet" not in output:
        return "!!"
    lines = output.strip().split("\n")
    ip_gateway_line = lines[1].strip()
    ip = ip_gateway_line.split(" ")[1].strip().split(".")[-1]
    gateway = ip_gateway_line.split(" ")[-1].strip().split(".")[-1]
    decorated = f"  {ip}-{gateway}" if int(ip) else "!!"
    return decorated


def get_link_speed():
    cmd = "ping -c 1 google.com"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    lines = output.strip().split("\n")
    if len(lines) < 2:
        return "⇅ !"
    speed = lines[1].split("=")[-1].strip().split(" ")[0]
    return f"⇅ {int(float(speed))}"


def battery():
    percent_map = {
        38: "",
        60: "",
        80: "",
        100: "",
    }
    cmd = "acpi --everything"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    lines = output.strip().split("\n")
    first_line, third_line = lines[0], lines[2]
    percentage = first_line.strip().split(",")[1]
    percentage_int = int(percentage[:-1])
    status = third_line.strip().split(" ")[-1]
    decorated = ""
    if status == "on-line":
        return f" {percentage}"
    for threshold, icon in percent_map.items():
        if percentage_int <= threshold:
            decorated = f"{icon} {percentage}"
            break

    return decorated


def all():
    print(get_link_speed(), get_ip(), "|", battery())


if __name__ == "__main__":
    arg = sys.argv[1:][0]
    if arg == "all":
        all()
    elif arg == "battery":
        print(battery())
    elif arg == "ip":
        print(get_ip())
    elif arg == "wifi-speed":
        print(get_link_speed())

# termux-list-notifications
