#!/usr/bin/env python

import sys
import subprocess
import json

def get_ip():
    cmd = "termux-wifi-connectioninfo"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    data = json.loads(output.strip())
    ip = data["ip"].split('.')[-1]
    decorated = f" {ip}" if int(ip) else "!!"
    return decorated

def get_link_speed():
    cmd = "termux-wifi-connectioninfo"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    data = json.loads(output.strip())
    speed = data["link_speed_mbps"]
    decorated = f"⇅ {speed}"
    return decorated

def termux_battery():
    percent_map = {
        38:"",
        60:"",
        80:"",
        100:"",
        }
    cmd = "termux-battery-status"
    output = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, shell=True).stdout
    data = json.loads(output.strip())
    status, percentage = data['status'], data['percentage']
    decorated = None
    if (status == 'CHARGING'):
        return f" {percentage}"
    for threshold, icon in percent_map.items():
        if percentage <= threshold:
            decorated = f"{icon} {percentage}"
            break
    
    return decorated

def all():
    print(get_link_speed(), get_ip(), '|', termux_battery())

if __name__ == '__main__':
    arg = sys.argv[1:][0]
    if (arg == "all"):
        all()
    elif (arg == "battery"):
        print(termux_battery())
    elif (arg == "ip"):
        print(get_ip())
    elif (arg == "wifi-speed"):
        print(get_link_speed())

 # termux-list-notifications
