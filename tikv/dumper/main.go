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
	"flag"
	"fmt"
	"os"

	"github.com/pingcap/kvproto/pkg/kvrpcpb"
	"github.com/tikv/client-go/v2/rawkv"
)

var (
	client     *rawkv.Client
	pdAddr     = flag.String("pd", "cr1.pugha.us:2379", "pd address")
	windowSize = 128
)

// Init initializes information.
func initStore() {
	var err error
	client, err = rawkv.NewClientWithOpts(context.TODO(), []string{*pdAddr}, rawkv.WithAPIVersion(kvrpcpb.APIVersion_V2))
	if err != nil {
		panic(err)
	}
}

func list(ctx context.Context) error {
	prefix := bytes.Buffer{}
	startKey := prefix.Bytes()
	count := 0

	for {
		keys, values, err := client.Scan(ctx, startKey, []byte{}, 12, rawkv.ScanKeyOnly())
		if err != nil {
			return err
		}
		if len(keys) == 0 {
			break
		}

		for i := range len(keys) {
			ttl, err := client.GetKeyTTL(ctx, keys[i])
			if err != nil {
				return err
			}
			fmt.Printf("%d: key=%s valLen=%d ttl=%d\n", count, keys[i], len(values[i]), ttl)
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

	err := list(context.TODO())
	if err != nil {
		panic(err)
	}

	client.Close()
}
