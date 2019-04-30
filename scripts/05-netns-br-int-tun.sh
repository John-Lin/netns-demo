#!/bin/bash

# include demo-magic
. ../tools/demo-magic.sh -n -d

# hide the evidence
clear

BRIDGE_0_NAME="br0"
BRIDGE_1_NAME="br1"
BRIDGE_2_NAME="br2"

VLAN_TAG_100="100"
VLAN_TAG_200="200"

BRIDGE_TUN_NAME="br-tun"
BRIDGE_INT_NAME="br-int"

PATCH_INT_PORT_NAME="patch-int"
PATCH_TUN_PORT_NAME="patch-tun"

POD_1_NAME="pod1"
POD_2_NAME="pod2"
POD_3_NAME="pod3"

# namespace side
VETH_0_NAME="p1-net0" 
VETH_2_NAME="p2-net0"
VETH_4_NAME="p3-net0"

# bridge side
VETH_1_NAME="neth0-br0"
VETH_3_NAME="neth0-br1"
VETH_5_NAME="neth0-br2"

# pair of brX - br-int

# bridge side
VETH_BR="veth-br0"
VETH_BR_1="veth-br1"
VETH_BR_2="veth-br2"

VETH_0_OVSBR="br0-ovsbr"
VETH_1_OVSBR="br1-ovsbr"
VETH_2_OVSBR="br2-ovsbr"


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

p "# Create linux bridges"
pe "ip link add ${BRIDGE_0_NAME} type bridge"
pe "ip link add ${BRIDGE_1_NAME} type bridge"
pe "ip link add ${BRIDGE_2_NAME} type bridge"

p "# Set vlan filter for bridges"
pe "ip link set dev ${BRIDGE_0_NAME} type bridge vlan_filtering ${VLAN_TAG_100}"
pe "ip link set dev ${BRIDGE_1_NAME} type bridge vlan_filtering ${VLAN_TAG_200}"
pe "ip link set dev ${BRIDGE_2_NAME} type bridge vlan_filtering ${VLAN_TAG_100}"

p "# Create Open vSwitches"
pe "ovs-vsctl add-br ${BRIDGE_TUN_NAME}"
pe "ovs-vsctl add-br ${BRIDGE_INT_NAME}"

p "# Set bridges interface up"
pe "ip link set dev ${BRIDGE_0_NAME} up"
pe "ip link set dev ${BRIDGE_1_NAME} up"
pe "ip link set dev ${BRIDGE_2_NAME} up"
# ovsbr no need to up ?
pe "ip link set dev ${BRIDGE_TUN_NAME} up"
pe "ip link set dev ${BRIDGE_INT_NAME} up"

p "# Patch br-int to br-tun"
pe "ovs-vsctl add-port ${BRIDGE_INT_NAME} ${PATCH_INT_PORT_NAME} -- set Interface ${PATCH_INT_PORT_NAME} type=patch options:peer=${PATCH_TUN_PORT_NAME}"
pe "ovs-vsctl add-port ${BRIDGE_TUN_NAME} ${PATCH_TUN_PORT_NAME} -- set Interface ${PATCH_TUN_PORT_NAME} type=patch options:peer=${PATCH_INT_PORT_NAME}"

p "# Add veth pairs from root network namespace"
pe "ip link add ${VETH_0_NAME} type veth peer name ${VETH_1_NAME}"
pe "ip link add ${VETH_2_NAME} type veth peer name ${VETH_3_NAME}"
pe "ip link add ${VETH_4_NAME} type veth peer name ${VETH_5_NAME}"
pe "ip link add ${VETH_BR} type veth peer name ${VETH_0_OVSBR}"
pe "ip link add ${VETH_BR_1} type veth peer name ${VETH_1_OVSBR}"
pe "ip link add ${VETH_BR_2} type veth peer name ${VETH_2_OVSBR}"
wait

p "Add veth into ${BRIDGE_INT_NAME}"
pe "ovs-vsctl add-port ${BRIDGE_INT_NAME} ${VETH_0_OVSBR} tag=${VLAN_TAG_100}"
pe "ovs-vsctl add-port ${BRIDGE_INT_NAME} ${VETH_1_OVSBR} tag=${VLAN_TAG_200}"
pe "ovs-vsctl add-port ${BRIDGE_INT_NAME} ${VETH_2_OVSBR} tag=${VLAN_TAG_100}"

p "# Put veth pairs in to ${POD_1_NAME}, ${POD_2_NAME} and ${POD_3_NAME} network namespaces"
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

pe "ip link set dev ${VETH_0_OVSBR} up"
pe "ip link set dev ${VETH_1_OVSBR} up"
pe "ip link set dev ${VETH_2_OVSBR} up"
pe "ip link set dev ${VETH_1_NAME} up"
pe "ip link set dev ${VETH_3_NAME} up"
pe "ip link set dev ${VETH_5_NAME} up"
pe "ip link set dev ${VETH_BR} up"
pe "ip link set dev ${VETH_BR_1} up"
pe "ip link set dev ${VETH_BR_2} up"
wait

p "# Set bridge interface as master and all interfaces up"
pe "ip link set dev ${VETH_1_NAME} master ${BRIDGE_0_NAME}"
pe "ip link set dev ${VETH_3_NAME} master ${BRIDGE_1_NAME}"
pe "ip link set dev ${VETH_5_NAME} master ${BRIDGE_2_NAME}"
pe "ip link set dev ${VETH_BR} master ${BRIDGE_0_NAME}"
pe "ip link set dev ${VETH_BR_1} master ${BRIDGE_1_NAME}"
pe "ip link set dev ${VETH_BR_2} master ${BRIDGE_2_NAME}"
wait

p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.20"
# p "# Ping ${POD_2_NAME} from ${POD_3_NAME}"
# pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.30"
wait

# p "# Unable to ping? Why"
# 
# p "# Check bridge filter bridge-nf-call-iptables option"
# pe "cat /proc/sys/net/bridge/bridge-nf-call-iptables"
# wait
# 
# p "# Check iptables FORWARD table default policy is DROP"
# pe "iptables -x -v -n --line-numbers -L FORWARD"
# wait

pe "iptables -A FORWARD -i ${BRIDGE_0_NAME} -j ACCEPT"
pe "iptables -A FORWARD -i ${BRIDGE_1_NAME} -j ACCEPT"
pe "iptables -A FORWARD -i ${BRIDGE_2_NAME} -j ACCEPT"

pe "iptables -A FORWARD -o ${BRIDGE_0_NAME} -j ACCEPT"
pe "iptables -A FORWARD -o ${BRIDGE_1_NAME} -j ACCEPT"
pe "iptables -A FORWARD -o ${BRIDGE_2_NAME} -j ACCEPT"
wait

p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.20"
p "# Ping ${POD_2_NAME} from ${POD_3_NAME}"
pe "ip netns exec ${POD_1_NAME} ping -c 1 10.0.1.30"
wait

# p "# Ping ${POD_2_NAME} from ${POD_1_NAME}"
# pe "ip netns exec ${POD_1_NAME} ping -c 4 10.0.1.20"
# wait
# p "# Ping ${POD_2_NAME} from ${POD_3_NAME}"
# pe "ip netns exec ${POD_1_NAME} ping -c 4 10.0.1.30"
# wait
p "DELETE?"
wait

p "# Delete network namespace and bridge"
pe "ip netns del ${POD_1_NAME}"
pe "ip netns del ${POD_2_NAME}"
pe "ip netns del ${POD_3_NAME}"
pe "ip link delete ${BRIDGE_0_NAME} type bridge"
pe "ip link delete ${BRIDGE_1_NAME} type bridge"
pe "ip link delete ${BRIDGE_2_NAME} type bridge"

pe "iptables -D FORWARD -i ${BRIDGE_0_NAME} -j ACCEPT"
pe "iptables -D FORWARD -i ${BRIDGE_1_NAME} -j ACCEPT"
pe "iptables -D FORWARD -i ${BRIDGE_2_NAME} -j ACCEPT"

pe "iptables -D FORWARD -o ${BRIDGE_0_NAME} -j ACCEPT"
pe "iptables -D FORWARD -o ${BRIDGE_1_NAME} -j ACCEPT"
pe "iptables -D FORWARD -o ${BRIDGE_2_NAME} -j ACCEPT"

pe "ovs-vsctl del-br ${BRIDGE_TUN_NAME}"
pe "ovs-vsctl del-br ${BRIDGE_INT_NAME}"
pe "ip link delete ${VETH_BR}"
pe "ip link delete ${VETH_BR_1}"
pe "ip link delete ${VETH_BR_2}"
