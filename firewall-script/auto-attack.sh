#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 FIREWALL_TYPE RULECOUNT_START RULECOUNT_END STEP"
    exit 1
fi

# Read arguments
FIREWALL_TYPE=$1
RULECOUNT_START=$2
RULECOUNT_END=$3
STEP=$4

# Server settings
SERVER="10.10.2.2"
PORT=9000
DURATION=60
LOG_DIR="./logs"

# Loop 20 times
for i in $(seq 1 20); do
    echo "Iteration $i..."

    # Sleep 8 seconds before starting iperf3
    sleep 8
    echo "Attack started!"
    # Calculate current rule count
    CURRENT_RULECOUNT=$((RULECOUNT_START + ((i - 1) * STEP)))

    # Run iperf3 and save JSON output
    OUTPUT_FILE="${LOG_DIR}/${FIREWALL_TYPE}_${CURRENT_RULECOUNT}_rule.json"
    iperf3 -c $SERVER -p $PORT -t $DURATION -J > "$OUTPUT_FILE"

    echo "Saved iperf3 output to $OUTPUT_FILE"
	
    # Sleep 7 seconds after iperf3
    sleep 8 
done

echo "All iterations completed."

