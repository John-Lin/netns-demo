#!/bin/bash

# include demo-magic
. ../tools/demo-magic.sh -n

# hide the evidence
clear

POD_1_NAME="pod1"
POD_2_NAME="pod2"

VETH_0_NAME="veth0"
VETH_1_NAME="veth1"
# Will wait until user presses enter
PROMPT_TIMEOUT=0

p "# Add a network namespace named ${POD_1_NAME} and ${POD_2_NAME}"
pe "ip netns add ${POD_1_NAME}"
pe "ip netns add ${POD_2_NAME}"

p "# Show network namespace list"
pe "ip netns list"

p "# Add veth pairs from root network namespace"
pe "ip link add ${VETH_0_NAME} type veth peer name ${VETH_1_NAME}"
pe "ip addr"
wait

p "# Put veth pairs in to ${POD_1_NAME}, ${POD_2_NAME} network namespace"
pe "ip link set ${VETH_0_NAME} netns ${POD_1_NAME}"
pe "ip link set ${VETH_1_NAME} netns ${POD_2_NAME}"

p "# Show current network interfaces in ${POD_1_NAME} and ${POD_2_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr"
pe "ip netns exec ${POD_2_NAME} ip addr"
wait

p "# Set network interfaces up and give a IP address in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr add 10.0.1.1/24 dev ${VETH_0_NAME}"
pe "ip netns exec ${POD_1_NAME} ip link set ${VETH_0_NAME} up"
pe "ip netns exec ${POD_1_NAME} ip link set lo up"

p "# Set network interfaces up and give a IP address in ${POD_2_NAME}"
pe "ip netns exec ${POD_2_NAME} ip addr add 10.0.1.2/24 dev ${VETH_1_NAME}"
pe "ip netns exec ${POD_2_NAME} ip link set ${VETH_1_NAME} up"
pe "ip netns exec ${POD_2_NAME} ip link set lo up"

p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 4 10.0.1.2"
wait

p "# Start a simpler HTTP server in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} python3 -m http.server 8000 --bind 0.0.0.0 &"

p "# Curl the HTTP server from ${POD_2_NAME}"
pe "ip netns exec ${POD_2_NAME} curl 10.0.1.1:8000"
wait

p "# Delete network namespace"
pe "ip netns del ${POD_1_NAME}"
pe "ip netns del ${POD_2_NAME}"
