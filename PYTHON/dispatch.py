#!/usr/bin/env python
import subprocess

machines = ["r1i1n0","r1i1n1","r1i1n2"]

#cmd = "uname"
cmd = "free  -g | grep Mem | awk '{print $2}' | sed s'/$/Gb/g'"

for machine in machines:
#	subprocess.call("ssh %s %s" % (machine, cmd), shell=True)
        mem = subprocess.check_output("ssh %s %s" % (machine, cmd), shell=True)
        print machine, " : " , mem