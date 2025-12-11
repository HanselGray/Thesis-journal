#!/bin/bash

sudo -u gray python3 xdp_script/gen_xdp.py ${1:-100}

sudo -u gray clang -target bpf -I/usr/include/$(uname -m)-linux-gnu -g -O2 -o xdp_script/xdp_rules.o -c xdp_script/xdp_rules.c


RULE="./xdp_script/xdp_rules.o"

bpftool prog load $RULE /sys/fs/bpf/xdp_prog
bpftool net attach xdp name xdp_drop_ip dev ens33
