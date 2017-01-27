#!/usr/bin/env python

import csv
import sys

input = str(sys.argv[1])

with open(input) as csvfile:
    reader = csv.DictReader(csvfile)
    reader.fieldnames = "hostname", "mac", "ip", "netmask", "gateway", "nameserver", "port", "seed", "environment", "ironic"
    output = ""
    for row in reader:
        output += row['hostname'] + " ansible_ssh_host=" + row['ip'] + " ansible_ssh_host_ironic=" + row['ironic'] + "\n"

print output
