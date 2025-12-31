#!/bin/bash

bpftool net detach xdp dev ens33
rm /sys/fs/bpf/xdp_prog
rm /home/gray/firewall-script/xdp_script/xdp_rules.c
rm /home/gray/firewall-script/xdp_script/xdp_rules.o
