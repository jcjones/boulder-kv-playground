#!/bin/bash

tiup playground --kv 3 --pd 1 --db 1 --tiflash 0 --db.port 3306 --host $(hostname -I)

# This one has forward issues for the UI
#tiup playground --kv 3 --pd 3 --db 3 --tiflash 0 --db.port 3306 --host $(hostname -I)
