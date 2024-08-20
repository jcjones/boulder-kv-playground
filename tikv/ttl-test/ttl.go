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
	"context"
	"flag"
	"log/slog"
	"os"
	"time"

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

func main() {
	pdAddr := os.Getenv("PD_ADDR")
	if pdAddr != "" {
		os.Args = append(os.Args, "-pd", pdAddr)
	}
	flag.Parse()
	initStore()

	err := client.PutWithTTL(context.TODO(), []byte{0xFF}, []byte{0x42}, 60)
	if err != nil {
		slog.Error("Couldn't put", "err", err)
	}

	for {
		ttl, err := client.GetKeyTTL(context.TODO(), []byte{0xFF})
		if err != nil {
			slog.Error("Couldn't get", "err", err)
			break
		}
		slog.Info("TTL was", "ttl", *ttl)

		time.Sleep(1 * time.Second)
	}

	client.Close()
}
