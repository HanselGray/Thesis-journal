#!/bin/bash

FWTYPE=${1:-"iptables"}
RULECOUNT=${2:-100}
RULECOUNT_END=${3:-10000}
STEP=${4:-500}
IF=${5:-"ens33"}
PROTO=${6:-"udp"}
PKT_SIZE=${7:-128}
run_a_test(){
	echo "$FWTYPE firewall deployed, current rule_count: $RULECOUNT"
	./gen_${FWTYPE}_throughput.sh $RULECOUNT
	sleep 115
	# echo "Running log collecting script, please run attack with packet data size: ${PKT_SIZE}b"       	
	# ./log_collector.sh $IF 70 1 ${FWTYPE}_${RULECOUNT}_${PROTO}_${PKT_SIZE}b.csv
	
	echo "Log collecting done >> Clearing firewall rule ..." 
	./clear_${FWTYPE}.sh
	echo "firewall rule cleared."
	sleep 5 
	echo
	echo
}

if [ "$FWTYPE" = "iptables" ]; then
	echo "Testing with iptables with rule count from $RULECOUNT to $RULECOUNT_END, step is $STEP" 
	# TESTING BLOCK
	for (( i=RULECOUNT; i<=RULECOUNT_END; i+=STEP )); do
                RULECOUNT="$i"
                run_a_test
        done

elif [ "$FWTYPE" = "nftable" ]; then
	echo "Testing with nftable with rule count from $RULECOUNT to $RULECOUNT_END, step is $STEP" 
	# TESTING BLOCK
	for (( i=RULECOUNT; i<=RULECOUNT_END; i+=STEP )); do
                RULECOUNT="$i"
                run_a_test
        done
elif [ "$FWTYPE" = "xdp" ]; then
	echo "Testing with xdp with rule count from $RULECOUNT to $RULECOUNT_END, step is $STEP" 
	#TESTING BLOCK
	for (( i=RULECOUNT; i<=RULECOUNT_END; i+=STEP )); do
        	RULECOUNT="$i"
        	run_a_test
    	done
else
	echo "Invalid firewall type."
fi	
