#!/bin/bash
cp ~/git/boulder-kv-playground/vitess/*.sql tables/
cp ~/git/boulder-kv-playground/vitess/boulder_vschema.json .

go run vtcompose/vtcompose.go --keyspaceData="registration:2:1:keyspace-registrations.sql;serial:2:1:keyspace-serial.sql;sethash:2:1:keyspace-sethash.sql;unsharded:0:2:keyspace-unsharded.sql" --base_vschema="boulder_vschema.json"