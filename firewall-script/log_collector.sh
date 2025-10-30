#!/bin/bash

IFACE=${1:-eth0}
DURATION=${2:-120}
INTERVAL=${3:-1}
OUTFILE="./logs/${4:-pps_cpu_log.csv}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (to read /proc files)."
  exit 1
fi

echo "ts,rx_packets,delta_rx,pps,mpps,idle_pct,iowait_pct,irq_per_s,softirq_per_s" > "$OUTFILE"

# helpers to read counters
read_rx_packets() { cat /sys/class/net/$IFACE/statistics/rx_packets; }
read_irq_sum() {
  # sum all interrupts from /proc/interrupts
  awk 'NR>1 {for (i=2;i<=NF;i++) s[i]+=$i} END{sum=0; for (i in s) sum+=s[i]; print sum}' /proc/interrupts
}
read_softirq_sum() {
  # sum all softirq counters
  awk 'NR>1 {sum=0; for (i=1;i<=NF;i++) sum += $i; print sum}' /proc/softirqs | awk '{print $NF; exit}' 
  # Note: different kernels list softirq types per line. We'll sum all values by reading columns.
  # (Alternative approach below if above isn't correct for a specific kernel.)
}
# Better robust softirq sum:
read_softirq_sum2() { awk 'NR>1 {for (i=1;i<=NF;i++){s[i]+=$i}} END{sum=0; for (i in s) sum+=s[i]; print sum}' /proc/softirqs; }

# read total CPU fields from /proc/stat (first line "cpu ...")
read_cpu_fields() {
  awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8,$9,$10}' /proc/stat
  # fields: user nice system idle iowait irq softirq steal guest guest_nice (some may be missing depending on kernel)
}

RX1=$(read_rx_packets)
IRQ1=$(read_irq_sum)
SOFT1=$(read_softirq_sum2)
read -r U1 N1 S1 ID1 IOW1 IRQF1 SOFTF1 STEAL1 G1 GN1 <<< $(read_cpu_fields)
T1=$((U1+N1+S1+ID1+IOW1+IRQF1+SOFTF1+ (STEAL1?STEAL1:0) ))
START_TS=$(date +%s)

ELAPSED=0
while [ $ELAPSED -lt $DURATION ]; do
  sleep $INTERVAL

  RX2=$(read_rx_packets)
  IRQ2=$(read_irq_sum)
  SOFT2=$(read_softirq_sum2)
  read -r U2 N2 S2 ID2 IOW2 IRQF2 SOFTF2 STEAL2 G2 GN2 <<< $(read_cpu_fields)
  T2=$((U2+N2+S2+ID2+IOW2+IRQF2+SOFTF2+ (STEAL2?STEAL2:0) ))

  DELTA_RX=$((RX2 - RX1))
  PPS=$(( DELTA_RX / INTERVAL ))
  # float Mpps (6 decimal)
  MPPS=$(awk -v p=$PPS 'BEGIN{printf "%.6f", p/1000000}')

  # CPU percentages computed as deltas of total jiffies
  DELTA_TOTAL=$(( T2 - T1 ))
  DELTA_IDLE=$(( ID2 - ID1 ))
  DELTA_IOW=$(( IOW2 - IOW1 ))
  # Avoid division by zero:
  if [ $DELTA_TOTAL -gt 0 ]; then
    IDLE_PCT=$(awk -v dI=$DELTA_IDLE -v dT=$DELTA_TOTAL 'BEGIN{printf "%.2f", (dI/dT)*100}')
    IOWAIT_PCT=$(awk -v dI=$DELTA_IOW -v dT=$DELTA_TOTAL 'BEGIN{printf "%.2f", (dI/dT)*100}')
  else
    IDLE_PCT="0.00"
    IOWAIT_PCT="0.00"
  fi

  # interrupts per second (hard IRQs)
  DELTA_IRQ=$((IRQ2 - IRQ1))
  IRQ_PER_S=$(awk -v d=$DELTA_IRQ -v i=$INTERVAL 'BEGIN{printf "%.0f", d / i}')

  # softirqs per second
  DELTA_SOFT=$((SOFT2 - SOFT1))
  SOFTIRQ_PER_S=$(awk -v d=$DELTA_SOFT -v i=$INTERVAL 'BEGIN{printf "%.0f", d / i}')

  TS=$(date -Iseconds)
  echo "${TS},${RX2},${DELTA_RX},${PPS},${MPPS},${IDLE_PCT},${IOWAIT_PCT},${IRQ_PER_S},${SOFTIRQ_PER_S}" >> "$OUTFILE"

  # rotate samples
  RX1=$RX2
  IRQ1=$IRQ2
  SOFT1=$SOFT2
  U1=$U2; N1=$N2; S1=$S2; ID1=$ID2; IOW1=$IOW2; IRQF1=$IRQF2; SOFTF1=$SOFTF2; STEAL1=$STEAL2
  T1=$T2

  NOW=$(date +%s)
  ELAPSED=$(( NOW - START_TS ))
done

echo "Done. CSV -> $OUTFILE"

