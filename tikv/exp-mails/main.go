// Copyright 2021 TiKV Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"math/big"
	"os"
	"time"

	"github.com/jcjones/boulder-kv-playground/v2/common"

	"github.com/letsencrypt/boulder/core"
	"github.com/pingcap/kvproto/pkg/kvrpcpb"
	"github.com/tikv/client-go/v2/rawkv"
)

var (
	client  *rawkv.Client
	pdAddr  = flag.String("pd", "cr1.pugha.us:2379", "pd address")
	expDate = flag.String("exp", time.Now().Format("2006-01-02"), "expiration date")
)

// Init initializes information.
func initStore() {
	var err error
	client, err = rawkv.NewClientWithOpts(context.TODO(), []string{*pdAddr}, rawkv.WithAPIVersion(kvrpcpb.APIVersion_V2))
	if err != nil {
		panic(err)
	}
}

// PeriodicExpMailer

// For each expiration window, determine the Expiration Date in the future to check: ExpDate
// Scan ExpDate-*
// For each response
// - If LastNag too recent
// -- Skip
// - Look up SANHAsh-RegID.
// -- If that serial is not equal to this serial
// --- It was replaced. Delete this key.
// -- If there are any remaining SANHashes expiring for this RegID
// --- Take note of this RegID/Date, these need emailing
// --- Put Key=ExpirationMailer-CurrentRun-RegID-ExpDate, Value=Serial, TTL=tomorrow, for next pass

// Scan ExpirationMailer-CurrentRun-*
// For each RegID-ExpDate
// - Scan ExpDate-RegID-*
// - For each response
// -- Lookup Serial
// -- Build an email containing the Serials, SANs, and ExpDate and send it
// -- Update the LastNag in ExpDate-RegID-SANHash
// -- Delete the ExpirationMailer-CurrentRun-RegID-ExpDate key

func FindExpiring(ctx context.Context, expiration time.Time) error {
	prefix := bytes.Buffer{}
	_, err := fmt.Fprintf(&prefix, "E:%s|", expiration.Format("2006-01-02"))
	if err != nil {
		return err
	}

	startKey := prefix.Bytes()
	count := 0
	ttl := uint64(60 * 60 * 2) // two hour TTL for expiration jobs

	for {
		keys, values, err := client.Scan(ctx, startKey, []byte{}, 12)
		if err != nil {
			return err
		}
		if len(keys) == 0 {
			break
		}

		for i := range len(keys) {
			fmt.Printf("%d: %s = %s\n", count, keys[i], values[i])
			count += 1

			if !bytes.HasPrefix(keys[i], prefix.Bytes()) {
				// Done
				fmt.Printf("Done, %s doesn't have %s\n", keys[i], startKey)
				break
			}

			var sln common.SerialLastNag
			err = json.Unmarshal(values[i], &sln)
			if err != nil {
				return err
			}

			// Is LastNag too recent?
			_, err := time.Parse("2006-01-02", sln.LastNag)
			if err != nil {
				// TODO check lastNagTime for real
				// Already nagged
				continue
			}

			// Was this cert reissued?
			keySanHashRegId, err := common.ToKeySanHashRegId(keys[i])
			if err != nil {
				return err
			}
			keySanHash := common.KeySanHashRegId{SANHash: keySanHashRegId.SANHash, RegID: keySanHashRegId.RegID}
			serialBytes, err := client.Get(ctx, keySanHash.Bytes())
			if err != nil {
				return err
			}
			var serial big.Int
			serial.SetBytes(serialBytes)
			if sln.Serial.Cmp(&serial) != 0 {
				// This was reissued, this key is irrelevant, delete it
				err = client.Delete(ctx, keys[i])
				if err != nil {
					return err
				}
				fmt.Printf("The certificate for SANHash %s was reissued from %s to %s\n",
					keySanHashRegId.SANHash,
					core.SerialToString(&sln.Serial),
					core.SerialToString(&serial))
				continue
			}

			// This SanHash/RegID/Serial is expiring, note it for pass 2
			keyExpMailerSerial := common.KeyExpirationMailerCurrentRunRegIdSerial{RegID: keySanHashRegId.RegID, Serial: serial}
			err = client.PutWithTTL(ctx, keyExpMailerSerial.Bytes(), []byte{}, ttl)
			if err != nil {
				return err
			}

			// Also put down a note that this RegID has work waiting, for pass 2
			// This will probably overwrite something, but it's empty, no biggie. It's
			// faster to do extra PUTs than a conditional
			keyExpMailerRegMarker := common.KeyExpirationMailerCurrentRun{RegID: keySanHashRegId.RegID}
			err = client.PutWithTTL(ctx, keyExpMailerRegMarker.Bytes(), []byte{}, ttl)
			if err != nil {
				return err
			}
		}
		// We append a null to the startKey so we skip that one and avoid transferring
		// the dupe across the wire
		finalKey := keys[len(keys)-1]
		startKey = append(finalKey, byte(0))
	}

	// Now perform pass two, finding all RegIDs with work
	prefix = bytes.Buffer{}
	_, err = fmt.Fprintf(&prefix, "ExpirationMailer-RegIds:")
	if err != nil {
		return err
	}

	startKey = prefix.Bytes()
	count = 0

	for {
		keys, _, err := client.Scan(ctx, startKey, []byte{}, 12)
		if err != nil {
			return err
		}
		if len(keys) == 0 {
			break
		}

		for i := range len(keys) {
			key, err := common.ToKeyExpirationMailerCurrentRun(keys[i])
			if err != nil {
				return err
			}
			fmt.Printf("%d: Working on RegID=%d\n", count, key.RegID)
			count += 1
		}

		// We append a null to the startKey so we skip that one and avoid transferring
		// the dupe across the wire
		finalKey := keys[len(keys)-1]
		startKey = append(finalKey, byte(0))
	}
	return nil
}

func main() {
	pdAddr := os.Getenv("PD_ADDR")
	if pdAddr != "" {
		os.Args = append(os.Args, "-pd", pdAddr)
	}
	flag.Parse()
	initStore()

	expirationDate, err := time.Parse("2006-01-02", *expDate)
	if err != nil {
		panic(err)
	}
	err = FindExpiring(context.TODO(), expirationDate)
	if err != nil {
		panic(err)
	}

	client.Close()
}
