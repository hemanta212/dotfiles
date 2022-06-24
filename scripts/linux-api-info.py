#!/usr/bin/env python

import sys
import subprocess
import json


def get_ip():
    """
    Connection-specific DNS Suffix  . :
    Link-local IPv6 Address . . . . . : fe80::9532:ceb0:3146:d851%19
    IPv4 Address. . . . . . . . . . . : 192.168.1.72
    Subnet Mask . . . . . . . . . . . : 255.255.255.0
    Default Gateway . . . . . . . . . : 192.168.1.254'"
    """
    cmd = "ipconfig.exe | grep -A 6 'Wireless LAN adapter Wi-Fi:'"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    if "Media disconnected" in output:
        return "!!"
    lines = output.strip().split("\n")
    ip, gateway = lines[4].strip(), lines[6].strip()
    ip = ip.split(":")[-1].strip().split(".")[-1]
    gateway = gateway.split(":")[-1].strip().split(".")[-1]
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


def termux_battery():
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
    print(get_link_speed(), get_ip(), "|", termux_battery())


if __name__ == "__main__":
    arg = sys.argv[1:][0]
    if arg == "all":
        all()
    elif arg == "battery":
        print(termux_battery())
    elif arg == "ip":
        print(get_ip())
    elif arg == "wifi-speed":
        print(get_link_speed())

# termux-list-notifications
