#!/bin/bash
cat <<EOF >$HOME/config-tikv.toml
[storage]
enable-ttl = true
api-version = 2
EOF

tiup playground --db 1 --tiflash 0 --pd 1 --kv 1 --kv.config $HOME/config-tikv.toml --host 10.0.0.80