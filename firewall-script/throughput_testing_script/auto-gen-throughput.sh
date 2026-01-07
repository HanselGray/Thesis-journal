#!/bin/bash

FWTYPE=${1:-"iptables"}      # iptables | nftable | xdp
RULECOUNT_START=${2:-100}
RULECOUNT_END=${3:-10000}
STEP=${4:-500}
IF=${5:-"ens33"}
PROTO=${6:-"udp"}
PKT_SIZE=${7:-128}
DURATION=115

OUTCSV="results_${FWTYPE}.csv"

# --------------------------
# Forwarded packet counters
# --------------------------

get_iptables_forwarded() {
    # Count packets accepted in FORWARD chain
    iptables -v -x -L FORWARD -n \
      | awk '$1 ~ /^[0-9]+$/ {sum+=$1} END {print sum}'
}

get_nft_forwarded() {
    # Extract packet counter from forward chain
    nft list chain ip filter forward \
      | awk '/counter packets/ {print $3}'
}

get_xdp_forwarded() {
    # Sum per-CPU XDP forwarded counters
    bpftool map dump pinned /sys/fs/bpf/tx_cnt \
      | awk '/cpu/ {sum+=$NF} END {print sum}'
}

# --------------------------
# Test runner
# --------------------------

run_a_test() {
    echo "[$FWTYPE] Deploying firewall with rule_count=$RULECOUNT"
    ./gen_${FWTYPE}_throughput.sh "$RULECOUNT"

    # Reset counters BEFORE test
    case "$FWTYPE" in
        iptables)
            iptables -Z FORWARD
            ;;
        nftable)
            nft reset counters
            ;;
        xdp)
            bpftool map update pinned /sys/fs/bpf/tx_cnt key 0 0 0 0 value 0 0 0 0
            ;;
    esac

    # Traffic is generated externally (iperf3 sender)
    sleep "$DURATION"

    # Read counters
    case "$FWTYPE" in
        iptables)
            FWD=$(get_iptables_forwarded)
            ;;
        nftable)
            FWD=$(get_nft_forwarded)
            ;;
        xdp)
            FWD=$(get_xdp_forwarded)
            ;;
    esac

    PPS=$(awk "BEGIN {printf \"%.2f\", $FWD / $DURATION}")

    echo "$FWTYPE,$RULECOUNT,$FWD,$PPS" >> "$OUTCSV"

    echo "Forwarded packets: $FWD  (~${PPS} pps)"

    # Cleanup
    ./clear_${FWTYPE}.sh
    sleep 5
}

# --------------------------
# Main
# --------------------------

echo "firewall_type,rule_count,forwarded_packets,pps" > "$OUTCSV"

echo "Starting $FWTYPE forwarding benchmark"
echo "Rules: $RULECOUNT_START → $RULECOUNT_END (step $STEP)"
echo "Duration per test: ${DURATION}s"
echo

for (( RULECOUNT=RULECOUNT_START; RULECOUNT<=RULECOUNT_END; RULECOUNT+=STEP )); do
    run_a_test
done

echo
echo "Benchmark complete. Results saved to $OUTCSV"
