#!/bin/bash -e

# Copyright 2020 The Vitess Authors.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

sleeptime=${SLEEPTIME:-0}
targettab=${TARGETTAB:-"${CELL}-0000000101"}
load_file=${POST_LOAD_FILE:-''}
external_db=${EXTERNAL_DB:-'0'}
export PATH=/vt/bin:$PATH

sleep $sleeptime

if [ ! -f schema_run ]; then
  while true; do
    vtctldclient --server vtctld:$GRPC_PORT GetTablet $targettab && break
    sleep 1
  done

  echo "Applying Schemas"
  vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql-file /script/tables/keyspace-registrations.sql boulder
  vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql-file /script/tables/keyspace-serial.sql boulder
  vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql-file /script/tables/keyspace-sethash.sql boulder
  vtctldclient --server vtctld:$GRPC_PORT ApplySchema --sql-file /script/tables/keyspace-unsharded.sql boulder-unsharded

  echo "Applying VSchemas"
  vtctldclient --server vtctld:$GRPC_PORT ApplyVSchema --vschema-file /script/vschema/boulder_vschema.json boulder
  vtctldclient --server vtctld:$GRPC_PORT ApplyVSchema --vschema-file /script/vschema/boulder_unsharded_vschema.json boulder-unsharded

  echo "List All Tablets"
  vtctldclient --server vtctld:$GRPC_PORT GetTablets
    
  if [ -n "$load_file" ]; then
    # vtgate can take a REALLY long time to come up fully
    sleep 60
    mysql --port=15306 --host=vtgate < /script/$load_file
  fi

  touch /vt/schema_run
  echo "Time: $(date). SchemaLoad completed at $(date "+%FT%T") " >> /vt/schema_run
  echo "Done Loading Schema at $(date "+%FT%T")"
fi
