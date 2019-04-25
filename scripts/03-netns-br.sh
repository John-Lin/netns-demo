#!/bin/bash

# include demo-magic
. ../tools/demo-magic.sh -n

# hide the evidence
clear

BRIDGE_NAME="br0"

POD_1_NAME="pod1"
POD_2_NAME="pod2"
POD_3_NAME="pod3"

# namespace side
VETH_0_NAME="veth0" 
VETH_2_NAME="veth1"
VETH_4_NAME="veth2"

# bridge side
VETH_1_NAME="veth0-br"
VETH_3_NAME="veth1-br"
VETH_5_NAME="veth2-br"

# Will wait until user presses enter
PROMPT_TIMEOUT=0

p "# Add a network namespace named ${POD_1_NAME}, ${POD_2_NAME} and ${POD_3_NAME}"
pe "ip netns add ${POD_1_NAME}"
pe "ip netns add ${POD_2_NAME}"
pe "ip netns add ${POD_3_NAME}"

p "# Show network namespace list"
pe "ip netns list"
wait

# p "# Show current network interfaces in ${POD_1_NAME}, ${POD_2_NAME} and ${POD_3_NAME}"
# pe "ip netns exec ${POD_1_NAME} ip addr"
# pe "ip netns exec ${POD_2_NAME} ip addr"
# pe "ip netns exec ${POD_3_NAME} ip addr"
# wait

p "# Create a bridge named br0"
pe "ip link add ${BRIDGE_NAME} type bridge"

p "# Set ${BRIDGE_NAME} interface up"
pe "ip link set dev br0 up"

p "# Add veth pairs from root network namespace"
pe "ip link add ${VETH_0_NAME} type veth peer name ${VETH_1_NAME}"
pe "ip link add ${VETH_2_NAME} type veth peer name ${VETH_3_NAME}"
pe "ip link add ${VETH_4_NAME} type veth peer name ${VETH_5_NAME}"
pe "ip addr"
wait

p "# Put veth pairs in to ${POD_1_NAME}, ${POD_2_NAME} and ${POD_3_NAME} network namespace"
p "# Doing this operation at root network namespace"
pe "ip link set ${VETH_0_NAME} netns ${POD_1_NAME}"
pe "ip link set ${VETH_2_NAME} netns ${POD_2_NAME}"
pe "ip link set ${VETH_4_NAME} netns ${POD_3_NAME}"

p "# Show current network interfaces in ${POD_1_NAME}, ${POD_2_NAME} and ${POD_3_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr"
pe "ip netns exec ${POD_2_NAME} ip addr"
pe "ip netns exec ${POD_3_NAME} ip addr"
wait

p "# Set network interface up and give a IP address in ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ip addr add 10.0.1.10/24 dev ${VETH_0_NAME}"
pe "ip netns exec ${POD_1_NAME} ip link set ${VETH_0_NAME} up"
pe "ip netns exec ${POD_1_NAME} ip link set lo up"

p "# Set network interface up and give a IP address in ${POD_2_NAME}"
pe "ip netns exec ${POD_2_NAME} ip addr add 10.0.1.20/24 dev ${VETH_2_NAME}"
pe "ip netns exec ${POD_2_NAME} ip link set ${VETH_2_NAME} up"
pe "ip netns exec ${POD_2_NAME} ip link set lo up"

p "# Set network interface up and give a IP address in ${POD_3_NAME}"
pe "ip netns exec ${POD_3_NAME} ip addr add 10.0.1.30/24 dev ${VETH_4_NAME}"
pe "ip netns exec ${POD_3_NAME} ip link set ${VETH_4_NAME} up"
pe "ip netns exec ${POD_3_NAME} ip link set lo up"

pe "ip link set dev ${VETH_1_NAME} up"
pe "ip link set dev ${VETH_3_NAME} up"
pe "ip link set dev ${VETH_5_NAME} up"
wait

p "# Set bridge interface as master and all interfaces up"
pe "ip link set dev ${VETH_1_NAME} master ${BRIDGE_NAME}"
pe "ip link set dev ${VETH_3_NAME} master ${BRIDGE_NAME}"
pe "ip link set dev ${VETH_5_NAME} master ${BRIDGE_NAME}"
wait

p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.20"
p "# Ping ${POD_2_NAME} from ${POD_3_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.30"
wait

p "# Unable to ping? Why"

p "# Check bridge filter bridge-nf-call-iptables option"
pe "cat /proc/sys/net/bridge/bridge-nf-call-iptables"
wait

p "# Check iptables FORWARD table default policy is DROP"
pe "iptables -x -v -n --line-numbers -L FORWARD"
wait

pe "iptables -A FORWARD -i ${BRIDGE_NAME} -j ACCEPT"
wait

p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 4 10.0.1.20"
wait
p "# Ping ${POD_2_NAME} from ${POD_3_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 4 10.0.1.30"
wait

p "# Delete network namespace and bridge"
pe "ip netns del ${POD_1_NAME}"
pe "ip netns del ${POD_2_NAME}"
pe "ip netns del ${POD_3_NAME}"
pe "ip link delete ${BRIDGE_NAME} type bridge"
pe "iptables -D FORWARD -i br0 -j ACCEPT"
