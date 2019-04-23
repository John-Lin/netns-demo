#!/bin/bash

# include demo-magic
. ~/tools/demo-magic.sh -n -d

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

p "# Delete network namespace and bridge"
pe "ip netns del ${POD_1_NAME}"
pe "ip netns del ${POD_2_NAME}"
pe "ip netns del ${POD_3_NAME}"
pe "ip link delete ${BRIDGE_NAME} type bridge"
pe "iptables -D FORWARD -i br0 -j ACCEPT"
pe "iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -j MASQUERADE"

