#!/bin/bash

FWTYPE=${1:-iptables}
RULE_START=${2:-100}
RULE_END=${3:-10000}
STEP=${4:-500}
IFACE=${5:-ens33}
PROTO=${6:-udp}
PKT_SIZE=${7:-128}

run_a_test() {
    local RULECOUNT=$1

    echo "========================================"
    echo "[INFO] Firewall: $FWTYPE"
    echo "[INFO] Rule count: $RULECOUNT"

    ./gen_${FWTYPE}.sh "$RULECOUNT"  
    sleep 1 

    echo "[INFO] Collecting logs (packet size: ${PKT_SIZE}B)"
    ./log_collector.sh \
        "$IFACE" \
        78 \
        1 \
        "${FWTYPE}_${RULECOUNT}_${PROTO}_${PKT_SIZE}b.csv"

    echo "[INFO] Clearing firewall rules"
    ./clear_${FWTYPE}.sh
    sleep 1 
}

echo "[START] Testing $FWTYPE from $RULE_START to $RULE_END (step $STEP)"

for (( RULECOUNT=RULE_START; RULECOUNT<=RULE_END; RULECOUNT+=STEP )); do
    run_a_test "$RULECOUNT"
done

echo "[DONE] All tests completed"

