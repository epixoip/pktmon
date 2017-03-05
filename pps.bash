#!/bin/bash
# Sun Mar  5 00:03:32 CST 2017 by epixoip
# quick 'n' dirty script to monitor packets per second and bandwidth
# please excuse the bashisms :(

export LC_ALL=C

trap ctrl_c INT

secs=0
tx_pps_tot=0
rx_pps_tot=0
tx_bps_tot=0
rx_bps_tot=0
tx_pps_max=0
rx_pps_max=0
tx_bps_max=0
rx_bps_max=0

ctrl_c()
{
    printf "\n\neth0 tx: %d pkts, %.2f kB in %d secs (%.2f avg pps, %d max pps, %.2f kB/s avg, %.2f kB/s max)\n" \
        "$tx_pps_tot" "$tx_bps_tot" "$secs" "$(echo "$tx_pps_tot / $secs" | bc -l)" \
        "$tx_pps_max" "$(echo "$tx_bps_tot / $secs" | bc -l)" "$tx_bps_max"

    printf "eth0 rx: %d pkts, %.2f kB in %d secs (%.2f avg pps, %d max pps, %.2f kB/s avg, %.2f kB/s max)\n\n" \
        "$rx_pps_tot" "$rx_bps_tot" "$secs" "$(echo "$rx_pps_tot / $secs" | bc -l)" \
        "$rx_pps_max" "$(echo "$rx_bps_tot / $secs" | bc -l)" "$rx_bps_max"

    exit
}

while :; do
    tx1_pps=$(< /sys/class/net/eth0/statistics/tx_packets)
    rx1_pps=$(< /sys/class/net/eth0/statistics/rx_packets)
    tx1_bps=$(< /sys/class/net/$1/statistics/tx_bytes)
    rx1_bps=$(< /sys/class/net/$1/statistics/rx_bytes)

    sleep 1
    ((secs++))

    tx2_pps=$(< /sys/class/net/eth0/statistics/tx_packets)
    rx2_pps=$(< /sys/class/net/eth0/statistics/rx_packets)
    tx2_bps=$(< /sys/class/net/$1/statistics/tx_bytes)
    rx2_bps=$(< /sys/class/net/$1/statistics/rx_bytes)

    tx_pps_last=$((tx2_pps - tx1_pps))
    rx_pps_last=$((rx2_pps - rx1_pps))
    tx_bps_last=$(echo "($tx2_bps - $tx1_bps) / 1024" | bc -l)
    rx_bps_last=$(echo "($rx2_bps - $rx1_bps) / 1024" | bc -l)

    if test "$tx_pps_last" -gt "$tx_pps_max"; then tx_pps_max="$tx_pps_last"; fi
    if test "$rx_pps_last" -gt "$rx_pps_max"; then rx_pps_max="$rx_pps_last"; fi

    if test -n "$(echo "$tx_bps_last $tx_bps_max" | awk '{if ($1 > $2) print "1"}')"; then tx_bps_max="$tx_bps_last"; fi
    if test -n "$(echo "$rx_bps_last $rx_bps_max" | awk '{if ($1 > $2) print "1"}')"; then rx_bps_max="$rx_bps_last"; fi

    ((tx_pps_tot += tx_pps_last))
    ((rx_pps_tot += rx_pps_last))

    tx_bps_tot=$(echo "$tx_bps_tot + $tx_bps_last" | bc -l)
    rx_bps_tot=$(echo "$rx_bps_tot + $rx_bps_last" | bc -l)

    printf "eth0 tx: %5d pps (%8.2f kB/s) / rx: %5d pps (%8.2f kB/s) \n" \
        "$tx_pps_last" "$tx_bps_last" "$rx_pps_last" "$rx_bps_last"
done
