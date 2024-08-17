
# TiKV

On your server, run
```console
tikv/start-playground-server.sh
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