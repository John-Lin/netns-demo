#!/bin/bash

# include demo-magic
. ~/tools/demo-magic.sh -n -d

# hide the evidence
clear

BRIDGE_NAME="br0"

POD_1_NAME="pod1"

# namespace side
VETH_0_NAME="veth0" 

# bridge side
VETH_1_NAME="veth0-br"

# Will wait until user presses enter
PROMPT_TIMEOUT=0

EXEC_NETNS="ip netns exec"

p "# Add a network namespace named ${POD_1_NAME}"
pe "ip netns add ${POD_1_NAME}"

p "# Show network namespace list"
pe "ip netns list"
wait

p "# Set ${POD_1_NAME} lo interface up"
pe "${EXEC_NETNS} ${POD_1_NAME} ip link set lo up"

p "# Create a bridge named br0"
pe "ip link add ${BRIDGE_NAME} type bridge"

p "# Set ${BRIDGE_NAME} interface up"
pe "ip link set dev br0 up"

p "# Add veth pairs from root network namespace"
pe "ip link add ${VETH_0_NAME} type veth peer name ${VETH_1_NAME}"
pe "ip addr"
wait

p "# Put veth pairs in to ${POD_1_NAME} network namespace"
p "# Doing this operation at root network namespace"
pe "ip link set ${VETH_0_NAME} netns ${POD_1_NAME}"

p "# Show current network interfaces in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr"
wait

p "# Set network interface up and give a IP address in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr add 10.0.1.10/24 dev ${VETH_0_NAME}"

pe "ip link set dev ${VETH_1_NAME} up"

pe "ip netns exec ${POD_1_NAME} ip link set ${VETH_0_NAME} up"

p "# Set bridge interface as master and all interfaces up"
pe "ip link set dev ${VETH_1_NAME} master ${BRIDGE_NAME}"

# p "# Check bridge filter bridge-nf-call-iptables option"
# pe "cat /proc/sys/net/bridge/bridge-nf-call-iptables"
# wait

pe "iptables -A FORWARD -i ${BRIDGE_NAME} -j ACCEPT"
pe "iptables -A FORWARD -o ${BRIDGE_NAME} -j ACCEPT"
wait

# pe "echo 1 > /proc/sys/net/ipv4/ip_forward"
# wait

pe "ip addr add 10.0.1.1/24 brd + dev br0"
wait

pe "ip netns exec ${POD_1_NAME} ip route add default via 10.0.1.1"
wait

pe "ip netns exec ${POD_1_NAME} ip route"

pe "iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -j MASQUERADE"

p "# Ping 8.8.8.8 from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 4 8.8.8.8"
wait

p "# Delete network namespace and bridge"
pe "ip netns del ${POD_1_NAME}"
pe "ip link delete ${BRIDGE_NAME} type bridge"

p "# Remove iptables rules"
pe "iptables -D FORWARD -i br0 -j ACCEPT"
pe "iptables -D FORWARD -o br0 -j ACCEPT"
pe "iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -j MASQUERADE"
