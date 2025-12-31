#!/bin/bash

N="${1:-100}"
CHAIN="BENCH"
TMP="/tmp/iptables_bench.rules"

# Use the raw table instead of filter
cat >"$TMP" << EOF
*raw
:PREROUTING ACCEPT [0:0]
:$CHAIN - [0:0]
-A PREROUTING -j $CHAIN
EOF

for i in $(seq 1 $N); do
  C=$(( (i-1) / 256 ))
  D=$(( i % 256 ))
  printf -- "-A %s -s 10.210.%d.%d -j DROP\n" "$CHAIN" "$C" "$D" >> "$TMP"
done

echo "-A $CHAIN -s 10.10.1.2 -j DROP" >> "$TMP"

echo "COMMIT" >> "$TMP"

# Load atomically
sudo iptables-restore < "$TMP"

