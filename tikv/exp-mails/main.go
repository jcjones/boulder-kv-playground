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
	"time"
	"flag"
	"fmt"
	"os"

	"github.com/pingcap/kvproto/pkg/kvrpcpb"
	"github.com/tikv/client-go/v2/rawkv"
)

var (
	client *rawkv.Client
	pdAddr = flag.String("pd", "cr1.pugha.us:2379", "pd address")
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
	// If LastNag too recent
		// Skip
	// Look up SANHAsh-RegID. 
		// If that serial is not equal to this serial, it was replaced. Delete this key.
	// If there are any remaining SANHashes expiring for this RegID which need emailing,
		// Take note of this RegID/Date:
		// Put ExpirationMailer-CurrentRun-RegID-ExpDate, TTL tomorrow

// Scan ExpirationMailer-CurrentRun-*
// For each RegID-ExpDate
	// Scan ExpDate-RegID-*
	// Lookup Serial
	// Build an email containing the Serials, SANs, and ExpDate and send it
	// Update the LastNag in ExpDate-RegID-SANHash
	// Delete the ExpirationMailer-CurrentRun-RegID-ExpDate key

func FindExpiring(expiration time.Time) error {
	prefix := bytes.Buffer{}
	_, err := fmt.Fprintf(&prefix, "E:%s-", expiration.Format("2006-01-02")); if err != nil {
		return err
	}

	startKey := prefix.Bytes()
	count := 0

	for {
		keys, values, err := client.Scan(context.TODO(), startKey, []byte{}, 12)
		if err != nil {
			return err
		}
		if len(keys) == 0 {
			return nil
		}

		for i := range(len(keys)) {
			fmt.Printf("%d: %s = %s\n", count, keys[i], values[i])
			count += 1

			if !bytes.HasPrefix(keys[i], prefix.Bytes()) {
				// Done
				fmt.Printf("Done, %s doesn't have %s\n", keys[i], startKey)
				return nil
			}
		}
		// We append a null to the startKey so we skip that one and avoid transferring
		// the dupe across the wire
		finalKey := keys[len(keys)-1]
		startKey = append(finalKey, byte(0))
	}
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
	err = FindExpiring(expirationDate); if err != nil {
		panic(err)
	}

	client.Close()
}	