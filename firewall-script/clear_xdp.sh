#!/bin/bash

sudo bpftool net detach xdp dev ens33
sudo rm /sys/fs/bpf/xdp_drop_ip
