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
	"crypto/rand"
	"encoding/json"
	"flag"
	"fmt"
	"math/big"
	"os"
	"time"

	"github.com/jcjones/boulder-kv/v2/common"

	"github.com/schollz/progressbar/v3"
	"github.com/letsencrypt/boulder/core"
	"github.com/pingcap/kvproto/pkg/kvrpcpb"
	"github.com/tikv/client-go/v2/rawkv"
)

var (
	client *rawkv.Client
	pdAddr = flag.String("pd", "cr1.pugha.us:2379", "pd address")
	startDate = flag.String("s", time.Now().Format("2006-01-02"), "issuance start date")
	numDays = flag.Int("n", 90, "number of days to issue for")
	count = flag.Int64("c", 100, "count of certificates to issue per day")
	verbose = flag.Bool("v", false, "be verbose")
)

// Init initializes information.
func initStore() {
	var err error
	client, err = rawkv.NewClientWithOpts(context.TODO(), []string{*pdAddr}, rawkv.WithAPIVersion(kvrpcpb.APIVersion_V2))
	if err != nil {
		panic(err)
	}
}

func issueCert(serial *big.Int, san []string, regID int, issued time.Time) error {
	// OnIssuance:
	// Put key=SANHash-RegID value={Serial}, ttl=expDate
	// Put key=ExpDate-RegID-SANHash value={Serial, LastNag=0}, ttl=expDate
	// Put key=Serial value={SAN, Expires, Issued, Profile, etc.} ttl=expDatePlusLookback

	sanHash := core.HashNames(san)
	expiration := issued.AddDate(0,0,90)

	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "H:%X-%d", sanHash, regID); if err != nil {
		return err
	}
	err = client.Put(context.TODO(), buf.Bytes(), serial.Bytes()); if err != nil {
		return err
	}

	buf.Reset()
	_, err = fmt.Fprintf(&buf, "E:%s-%d-%X", expiration.Format("2006-01-02"), regID, sanHash); if err != nil {
		return err
	}
	sln := &common.SerialLastNag{
		Serial: serial.Bytes(), 
		LastNag: "0000-00-00",
	}
	value, err := json.Marshal(sln)
	if err != nil {
		return err
	}
	err = client.Put(context.TODO(), buf.Bytes(), value); if err != nil {
		return err
	}

	buf.Reset()
	_, err = fmt.Fprintf(&buf, "S:%s", serial); if err != nil {
		return err
	}
	certData := &common.SerialCertData{ 
		SAN: san,
		Issued: issued.Format("2006-01-02"),
		Profile: "basic",
	}
	value, err = json.Marshal(certData)
	if err != nil {
		return err
	}
	err = client.Put(context.TODO(), buf.Bytes(), value); if err != nil {
		return err
	}
	return nil
}

func issueRandomCert(issuanceTime time.Time) error {
	var serialBytes [16]byte
	_, _ = rand.Read(serialBytes[:])
	serial := big.NewInt(0).SetBytes(serialBytes[:])


	host := fmt.Sprintf("%s.lencr.org", core.RandomString(6))
	san := []string{"lencr.org", host}
	err := issueCert(serial, san, 10, issuanceTime)
	if err != nil {
		return err
	}

	if (*verbose) {
		fmt.Printf("Issued %s on %s\n", serial, issuanceTime.Format("2006-01-02"))
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

	issueDate, err := time.Parse("2006-01-02", *startDate)
	if err != nil {
		panic(err)
	}
	endDate := issueDate.AddDate(0,0,*numDays)

	fmt.Printf("Filling DB with %d certs/day between %s and %s\n", *count, *startDate, endDate)

	for {
		fmt.Printf("Issuing on date %s\n", issueDate)

		bar := progressbar.Default(*count)

		for range(*count) {
			err := issueRandomCert(issueDate); if err != nil {
				panic(err)
			}
			bar.Add(1)
		}
		issueDate = issueDate.AddDate(0,0,1)
		if issueDate.After(endDate) {
			break
		}
	}
	client.Close()
}	