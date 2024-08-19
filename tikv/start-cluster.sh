#!/bin/bash

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
	echo "$0 [my IP] {PD IP}"
	exit 1
fi

MY_IP="${1}"
PD_IP="${2:-}"

CLUSTER_DIR="$(mktemp -d --tmpdir="${HOME}/.tiup/")"

cat <<EOF >"${CLUSTER_DIR}/config-tikv.toml"
[raftdb]
max-open-files = 256

[rocksdb]
max-open-files = 256

[storage]
api-version = 2
enable-ttl = true
reserve-raft-space = 0
reserve-space = 0
EOF

cat <<EOF >"${CLUSTER_DIR}/config-pd.toml"
[schedule]
patrol-region-interval = "100ms"
EOF

if [ -z "${PD_IP}" ]; then
tiup install pd:v8.2.0

${HOME}/.tiup/components/pd/v8.2.0/pd-server \
	--name=rocinante \
	--config="${CLUSTER_DIR}/config-pd.toml" \
	--data-dir="${CLUSTER_DIR}/pd/data" \
	--peer-urls=http://${MY_IP}:2380 \
	--advertise-peer-urls=http://${MY_IP}:2380 \
	--client-urls=http://${MY_IP}:2379 \
	--advertise-client-urls=http://${MY_IP}:2379 \
	--initial-cluster=pd-0=http://${MY_IP}:2380 &
	# --config=/home/pug/.tiup/data/ULuZ0kQ/pd-0/pd.toml \

	PD_PID=$!

	# PD is running locally
	PD_IP="${MY_IP}"
fi

tiup install tikv:v8.2.0

${HOME}/.tiup/components/tikv/v8.2.0/tikv-server \
	--config="${CLUSTER_DIR}/config-tikv.toml" \
	--data-dir="${CLUSTER_DIR}/tikv/data" \
	--addr="${MY_IP}:20160" \
	--advertise-addr="${MY_IP}:20160" \
	--status-addr="${MY_IP}:20180" \
	--pd-endpoints="http://${PD_IP}:2379"

# Cleanup
if [ -n "${PD_PID}" ]; then
	kill $PD_PID
fi
rm -rf "${CLUSTER_DIR}"
