#!/bin/bash

# include demo-magic
. ../tools/demo-magic.sh -n

# hide the evidence
clear

POD_1_NAME="pod1"
# Will wait until user presses enter
PROMPT_TIMEOUT=0

p "# Add a network namespace named ${POD_1_NAME}"
pe "ip netns add ${POD_1_NAME}"

p "# Show network namespace list"
pe "ip netns list"

p "# Show current network interfaces in root network namespace"
pe "ip addr"
wait

p "# Show current network interfaces in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr"
wait

p "# Set lo interface up"
pe "ip netns exec ${POD_1_NAME} ip link set lo up"

p "# Show current network interfaces in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr"
wait

# p "# Add veth pairs for ${POD_1_NAME}"
# pe "ip netns exec ${POD_1_NAME} ip link add veth0 type veth peer name veth1"

# p "# Show current network interfaces in ${POD_1_NAME}"
# pe "ip netns exec ${POD_1_NAME} ip addr"
# wait

p "# Start a simpler HTTP server in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} python3 -m http.server 8000 --bind 127.0.0.1 &"

p "# Curl the HTTP server ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} curl localhost:8000"
wait

p "# Delete network namespace"
pe "ip netns del ${POD_1_NAME}"
