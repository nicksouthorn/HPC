#!/usr/bin/env python
import subprocess
import ConfigParser


def readconfig(file="config.ini"):
    ips = []
    cmds = []
    Config = ConfigParser.ConfigParser()
    Config.read(file)
    machines = Config.items("MACHINES")
    commands = Config.items("COMMANDS")
    for ip in machines:
        ips.append(ip[1])
    for cmd in commands:
        cmds.append(cmd[1])
    return ips, cmds


ips, cmds = readconfig()

for ip in ips:
    for cmd in cmds:
        mem = subprocess.check_output("ssh %s %s" % (machine, cmd), shell=True)
        print(ip, " : ", mem)
        subprocess.call("ssh %s %s" % (ip, cmd), shell=True)
        mem = subprocess.check_output("ssh %s %s" % (machine, cmd), shell=True)
        print(ip, mem)
