#!/bin/bash

N="${1:-100}"
CHAIN="BENCH"
TMP="/tmp/iptables_bench.rules"

cat >"$TMP" << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:$CHAIN - [0:0]

-A FORWARD -j $CHAIN
EOF

for i in $(seq 1 "$N"); do
  C=$(( (i - 1) / 256 ))
  D=$(( i % 256 ))
  printf -- "-A %s -s 10.210.%d.%d -j DROP\n" "$CHAIN" "$C" "$D" >> "$TMP"
done

# FINAL DROP — kernel sink
echo "-A $CHAIN -s 10.10.1.2 -j DROP" >> "$TMP"

echo "COMMIT" >> "$TMP"

sudo iptables-restore < "$TMP"
