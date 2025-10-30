#!/bin/bash

sudo iptables -F BENCH
sudo iptables -D FORWARD -j BENCH || true
sudo iptables -X BENCH
