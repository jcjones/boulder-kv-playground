
# TiKV

On your server, run
```console
tikv/start-playground-server.sh
```
or on one host, run this script with the IP:
```console
# Start a cluster leader on .80
./start-cluster.sh 10.0.0.80
```

Then on another host, run this script with both its IP and then the leader's IP:
```console
# Start a cluster member on .81 pointing to .80
./start-cluster.sh 10.0.0.81 10.0.0.80
```

Then fill the database:
```console
# Put 5 million certs in the DB for 2024-05-01
NODE=n1:2379
go run tikv/fill-db/main.go -pd ${NODE} -c 5000000 -s 2024-05-01 -n 1
```

Then try demos
```console
# Generate expiration emails
go run tikv/exp-emails/main.go -pd ${NODE} -exp 2024-07-30
```