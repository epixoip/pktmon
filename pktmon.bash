#!/usr/bin/env bash
# created: Sun Mar  5 00:03:32 CST 2017 by epixoip
# updated: Wed Nov  8 14:06:32 CST 2017 by epixoip
# please excuse the bashisms.

trap ctrl_c INT

eth="$1"
time=0
all_pps_rx=0
all_pps_tx=0
all_bps_rx=0
all_bps_tx=0
max_pps_rx=0
max_pps_tx=0
max_bps_rx=0
max_bps_tx=0

ctrl_c()
{
    printf "\nSummary:\n"

    printf "$eth rx: %d pkts (%sB) in %d seconds (%dpps avg, %dpps max, %sbps avg, %sbps max)\n" \
        "$all_pps_rx" \
        "$(numfmt --to=iec --format='%f' <<<"$((all_bps_rx / 8))")" \
        "$time" \
        "$((all_pps_rx / time))" \
        "$max_pps_rx" \
        "$(numfmt --to=iec --format='%f' <<<"$((all_bps_rx / time))")" \
        "$(numfmt --to=iec --format='%f' <<<"$max_bps_rx")"

    printf "$eth tx: %d pkts (%sB) in %d seconds (%dpps avg, %dpps max, %sbps avg, %sbps max)\n" \
        "$all_pps_tx" \
        "$(numfmt --to=iec --format='%f' <<<"$((all_bps_tx / 8))")" \
        "$time" \
        "$((all_pps_tx / time))" \
        "$max_pps_tx" \
        "$(numfmt --to=iec --format='%f' <<<"$((all_bps_tx / time))")" \
        "$(numfmt --to=iec --format='%f' <<<"$max_bps_tx")"

    exit
}

if test "$(id -u)" != "0"; then
    echo "you are not root" >&2
    exit
fi

if test -z "$eth"; then
    echo "missing interface name" >&2
    exit
fi

if ! test -d "/sys/class/net/$eth/statistics"; then
    echo "interface '$eth' does not exist" >&2
    exit
fi

while :; do
    pps_rx1="$(</sys/class/net/$eth/statistics/rx_packets)"
    pps_tx1="$(</sys/class/net/$eth/statistics/tx_packets)"
    bps_rx1="$(</sys/class/net/$eth/statistics/rx_bytes)"
    bps_tx1="$(</sys/class/net/$eth/statistics/tx_bytes)"

    sleep 1
    ((time++))

    pps_rx2="$(< /sys/class/net/$eth/statistics/rx_packets)"
    pps_tx2="$(< /sys/class/net/$eth/statistics/tx_packets)"
    bps_rx2="$(< /sys/class/net/$eth/statistics/rx_bytes)"
    bps_tx2="$(< /sys/class/net/$eth/statistics/tx_bytes)"

    last_pps_rx="$((pps_rx2 - pps_rx1))"
    last_pps_tx="$((pps_tx2 - pps_tx1))"
    last_bps_rx="$(((bps_rx2 - bps_rx1) * 8))"
    last_bps_tx="$(((bps_tx2 - bps_tx1) * 8))"

    if test "$last_pps_rx" -gt "$max_pps_rx"; then
        max_pps_rx="$last_pps_rx"
    fi

    if test "$last_pps_tx" -gt "$max_pps_tx"; then
        max_pps_tx="$last_pps_tx"
    fi

    if test "$last_bps_rx" -gt "$max_bps_rx"; then
        max_bps_rx="$last_bps_rx"
    fi

    if test "$last_bps_tx" -gt "$max_bps_tx"; then
        max_bps_tx="$last_bps_tx"
    fi

    ((all_pps_rx += last_pps_rx))
    ((all_pps_tx += last_pps_tx))
    ((all_bps_rx += last_bps_rx))
    ((all_bps_tx += last_bps_tx))

    printf "$eth rx: %7dpps %sbps    tx: %7dpps %sbps\n" \
        "$last_pps_rx" "$(numfmt --to=iec --format='%6f' <<<"$last_bps_rx")" \
        "$last_pps_tx" "$(numfmt --to=iec --format='%6f' <<<"$last_bps_tx")"
done
