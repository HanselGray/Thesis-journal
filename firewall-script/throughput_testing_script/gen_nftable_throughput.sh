#!/bin/bash

N="${1:-100}"
OUT="/tmp/nft_bench.nft"
TABLE="ip"        # raw tables are typically 'ip' or 'ip6'
TABNAME="raw_bench"
CHAIN="bench"

cat > "$OUT" <<EOF
table $TABLE $TABNAME {
  chain $CHAIN {
    type filter hook prerouting priority -300; policy accept;
EOF

for i in $(seq 1 $N); do
  C=$(( (i-1) / 256 ))
  D=$(( i % 256 ))
  printf "    ip saddr 10.211.%d.%d drop\n" "$C" "$D" >> "$OUT"
done

# echo "    ip saddr 10.10.1.2 drop" >> "$OUT"

cat >> "$OUT" <<'EOF'
  }
}
EOF

# Apply rules atomically
sudo nft -f "$OUT"

