#!/bin/bash

if [ $# -eq 0 ] || [ $# -gt 1 ]; then
	echo "$0 [LAN IP]"
	exit 1
fi

MY_IP="${1}"
PD_IP="${2:-}"
LOCAL_IP="$(hostname -I)"
VER="v8.3.0"
PIDS=()

if [ -z "${CLUSTER_DIR}" ]; then
	CLUSTER_DIR="$(mktemp -d --tmpdir="${HOME}/.tiup/")"
fi

debug() {
	gum style "${*}"
}

info() {
	gum style --border="rounded" "${*}"
}

error() {
	gum style --foreground="red" "${*}"
}

shut_down() {
	name="${1}"
	info "Killing ${name}"
	pkill "${name}"
	sleep 2
	for i in $(seq 0 10); do
		pgrep "${name}" >/dev/null && pkill "${name}" || break
		sleep 1
	done

	if pgrep "${name}" >/dev/null; then
		info "Killing -9 "${name}""
		pkill -9 "${name}"
	fi
}

cleanup() {
	info "Cleaning up (PIDs: ${PIDS[@]})..."
	kill "${PIDS[@]}" >/dev/null 2>&1

	shut_down tidb-server
	sleep 2
	shut_down tikv-server
	sleep 2
	shut_down pd-server

	info "Waiting for stoppage..."
	sleep 10

	info "Sending kill -9"
	kill -9 "${PIDS[@]}" >/dev/null 2>&1

	sleep 1
	rm -rf "${CLUSTER_DIR}"
}
trap cleanup EXIT

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

[replication]
location-labels = ["zone", "rack", "host"]

[replication-mode]
replication-mode = "dr-auto-sync"

[replication-mode.dr-auto-sync]
label-key = "zone"
EOF

cat <<EOF >"${CLUSTER_DIR}/config-tidb.toml"
[security]
auto-tls = true
EOF

mkdir -p "${CLUSTER_DIR}/grafana/conf"
rsync -ah ${HOME}/.tiup/grafana-base/* "${CLUSTER_DIR}/grafana"

echo > "${CLUSTER_DIR}/grafana/data/grafana.db"

cat <<EOF >"${CLUSTER_DIR}/grafana/conf/custom.ini"
[server]
# The ip address to bind to, empty will bind to all interfaces
http_addr =

# The http port to use
http_port = 3000
EOF

cat <<EOF >"${CLUSTER_DIR}/grafana/conf/provisioning/dashboards/dashboard.yml"
apiVersion: 1
providers:
  - name: Test-Cluster
    folder: Test-Cluster
    type: file
    disableDeletion: false
    allowUiUpdates: true
    editable: true
    updateIntervalSeconds: 30
    options:
      path: ${CLUSTER_DIR}/grafana/dashboards
EOF

mkdir -p "${CLUSTER_DIR}/prometheus"

cat <<EOF >"${CLUSTER_DIR}/prometheus/prometheus.yml"
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.

scrape_configs:
  - job_name: 'cluster'
    file_sd_configs:
    - files:
      - targets.json
EOF

cat <<EOF >"${CLUSTER_DIR}/prometheus/targets.yml"
[
        {
                "targets": [
                        "127.0.0.1:2379"
                ],
                "labels": {
                        "job": "pd"
                }
        },
        {
                "targets": [
                        "127.0.0.1:20182",
                        "127.0.0.1:20181",
                        "127.0.0.1:20180"
                ],
                "labels": {
                        "job": "tikv"
                }
        },
        {
                "targets": [
                        "127.0.0.1:10080"
                ],
                "labels": {
                        "job": "tidb"
                }
        },
        {
                "targets": [
                        "127.0.0.1:9090"
                ],
                "labels": {
                        "job": "prometheus"
                }
        }
]
EOF

	# --peer-urls=http://0.0.0.0:2380
	# --advertise-peer-urls=http://${MY_IP}:2380

tiup install "pd:${VER}" "tikv:${VER}" "tidb:${VER}" "grafana:${VER}"

for id in 0; do
	PD_FLAGS=(
		--config="${CLUSTER_DIR}/config-pd.toml"
		--data-dir="${HOME}/pd/${id}"
		--client-urls=http://0.0.0.0:2379
		--advertise-client-urls=http://${MY_IP}:2379
		--peer-urls=http://0.0.0.0:2380
		--advertise-peer-urls=http://${MY_IP}:2380
		--log-file="${CLUSTER_DIR}/pd/log.txt"
		--name="$(hostname)"
		--initial-cluster=$(hostname)=http://${MY_IP}:2380
	)

	info "Start the control plane server"
	${HOME}/.tiup/components/pd/${VER}/pd-server "${PD_FLAGS[@]}" &
	PIDS+=( $! )
done

info "Waiting for healthchecks of PD hosts to succeed."
while curl -s --max-time 2 --fail "http://${MY_IP}:2379/metrics" >/dev/null; do
	sleep 1
done

for id in $(seq 0 2); do
	app_port="2016${id}"
	status_port="2018${id}"

	TIKV_FLAGS=(
		--config="${CLUSTER_DIR}/config-tikv.toml"
		--data-dir="${HOME}/tikv/${id}"
		--addr="0.0.0.0:${app_port}"
		--advertise-addr="${MY_IP}:${app_port}"
		--status-addr="0.0.0.0:${status_port}"
		--advertise-status-addr="${MY_IP}:${status_port}"
		--pd-endpoints="http://${LOCAL_IP}:2379"
		--log-file="${CLUSTER_DIR}/tikv/log-${id}.txt"
	)
	if [ $(( id % 2 )) -eq 0  ]; then
		TIKV_FLAGS+=("--labels=zone=den-1,rack=1,host=proxmox")
	else
		TIKV_FLAGS+=("--labels=zone=slc-1,rack=1,host=proxmox")
	fi

	info "Start the KV server"
	${HOME}/.tiup/components/tikv/${VER}/tikv-server "${TIKV_FLAGS[@]}" &
	PIDS+=( $! )
done

info "Waiting for healthchecks of KV hosts to succeed."
for id in $(seq 0 2); do
	status_port="2018${id}"
	while curl -s --max-time 2 --fail "http://${MY_IP}:${status_port}/metrics" >/dev/null; do
		sleep 1
	done
done

info "Healthchecks good."
PROM_FLAGS=(
	--pd.endpoints="${LOCAL_IP}:2379"
	--address="0.0.0.0:9090"
	--advertise-address="${MY_IP}:9090"
	--storage.path="${CLUSTER_DIR}/prometheus/data"
	--log.path="${CLUSTER_DIR}/prometheus/logs"
)

info "Start Prometheus"
pushd "${CLUSTER_DIR}/prometheus" >/dev/null
${HOME}/.tiup/components/prometheus/${VER}/ng-monitoring-server "${PROM_FLAGS[@]}" &
PIDS+=( $! )
popd >/dev/null

GRAFANA_FLAGS=(
	--homepath "${CLUSTER_DIR}/grafana"
	--config "${CLUSTER_DIR}/grafana/conf/custom.ini"
	cfg:default.paths.logs="${CLUSTER_DIR}/grafana/log"
)

info "Start Grafana"
pushd "${CLUSTER_DIR}/grafana" >/dev/null
${HOME}/.tiup/components/grafana/${VER}/bin/grafana-server "${GRAFANA_FLAGS[@]}" &
PIDS+=( $! )
popd >/dev/null

TIDB_FLAGS=(
	--config="${CLUSTER_DIR}/config-tidb.toml"
	-P 3306 
	--status=10080 
	--store=tikv 
	--path="${MY_IP}:2379"
	--advertise-address="${MY_IP}" 
	--log-file="${CLUSTER_DIR}/tidb/log.txt"
)

info "Start TiDB"
${HOME}/.tiup/components/tidb/${VER}/tidb-server "${TIDB_FLAGS[@]}" &
PIDS+=( $! )

info "Dashboard at http://${MY_IP}:2379/dashboard"

wait

# Cleanup
cleanup

