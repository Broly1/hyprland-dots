#!/bin/bash

# Function to convert bytes to human-readable format
human_readable() {
  local bytes=$1
  local units=(B K M G T P)
  local unit=0

  while (( bytes > 1024 )); do
    (( bytes /= 1024 ))
    (( unit++ ))
  done

  echo "${bytes}${units[$unit]}"
}

# Function to display error message and exit
exit_err() {
  echo "{\"text\": \"Error: $@\", \"class\": \"error\"}" >&2
  exit 1
}

# Function to calculate network traffic speed
calculate_network_speed() {
  local isecs=${1:-1}
  local interfaces=("${@:2}")
  local rate_max=${RATE_MAX:-1000000}

  for iface in "${interfaces[@]}"; do
    [[ -h "/sys/class/net/${iface}" ]] || exit_err "$iface is not an existing network interface name"
  done

  declare -A prev_rx_bytes
  declare -A prev_tx_bytes

  while true; do
    for iface in "${interfaces[@]}"; do
      local rx_bytes=$(<"/sys/class/net/${iface}/statistics/rx_bytes")
      local tx_bytes=$(<"/sys/class/net/${iface}/statistics/tx_bytes")

      local rx_speed=$(( (rx_bytes - prev_rx_bytes["${iface}"]) / isecs ))
      local tx_speed=$(( (tx_bytes - prev_tx_bytes["${iface}"]) / isecs ))

      prev_rx_bytes["${iface}"]=$rx_bytes
      prev_tx_bytes["${iface}"]=$tx_bytes

      local total_speed=$((rx_speed + tx_speed))
      local percentage=$((total_speed * 100 / rate_max))

      echo "{\"text\": \"$(human_readable $rx_speed)⇣ $(human_readable $tx_speed)⇡\", \"percentage\": $percentage}"
    done

    sleep $isecs
  done
}

# Main function
main() {
  local isecs=1
  local interfaces=()

  while getopts "t:" opt; do
    case $opt in
      t) isecs=$OPTARG ;;
      *) exit_err "Invalid option: -$opt" ;;
    esac
  done
  shift $((OPTIND - 1))

  [[ $# -gt 0 ]] && interfaces=("$@")

  calculate_network_speed $isecs "${interfaces[@]}"
}

main "$@"
