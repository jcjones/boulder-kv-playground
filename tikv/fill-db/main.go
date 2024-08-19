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
	"crypto/rand"
	"encoding/json"
	"flag"
	"fmt"
	"math/big"
	"os"
	"sync"
	"time"

	"github.com/jcjones/boulder-kv-playground/v2/common"

	"github.com/letsencrypt/boulder/core"
	"github.com/pingcap/kvproto/pkg/kvrpcpb"
	"github.com/schollz/progressbar/v3"
	"github.com/tikv/client-go/v2/rawkv"
)

var (
	client    *rawkv.Client
	pdAddr    = flag.String("pd", "cr1.pugha.us:2379", "pd address")
	startDate = flag.String("s", time.Now().Format("2006-01-02"), "issuance start date")
	numDays   = flag.Int("n", 90, "number of days to issue for")
	count     = flag.Int64("c", 100, "count of certificates to issue per day")
	verbose   = flag.Bool("v", false, "be verbose")
)

// Init initializes information.
func initStore() {
	var err error
	client, err = rawkv.NewClientWithOpts(context.TODO(), []string{*pdAddr}, rawkv.WithAPIVersion(kvrpcpb.APIVersion_V2))
	if err != nil {
		panic(err)
	}
}

func issueCert(ctx context.Context, serial *big.Int, san []string, regID int, issued time.Time) error {
	// OnIssuance:
	// Put key=SANHash-RegID value={Serial}, ttl=expDate
	// Put key=ExpDate-RegID-SANHash value={Serial, LastNag=0}, ttl=expDate
	// Put key=Serial value={SAN, Expires, Issued, Profile, etc.} ttl=expDatePlusLookback

	sanHash := core.HashNames(san)
	expiration := issued.AddDate(0, 0, 90)
	now := time.Now()
	ttl := uint64(expiration.Sub(now).Seconds())

	keySanHashRegId := common.KeySanHashRegId{SANHash: sanHash, RegID: regID}
	err := client.Put(context.TODO(), keySanHashRegId.Bytes(), serial.Bytes())
	if err != nil {
		return err
	}

	keyExpiration := common.KeyExpirationRegIdSanHash{
		Expiration: expiration.Format("2006-01-02"),
		RegID:      regID,
		SANHash:    sanHash,
	}

	sln := &common.SerialLastNag{
		Serial:  *serial,
		LastNag: "0000-00-00",
	}
	value, err := json.Marshal(sln)
	if err != nil {
		return err
	}
	err = client.PutWithTTL(ctx, keyExpiration.Bytes(), value, ttl)
	if err != nil {
		return err
	}

	keySerial := common.KeySerial{
		Serial: *serial,
	}

	certData := &common.SerialCertData{
		SAN:     san,
		Issued:  issued.Format("2006-01-02"),
		Profile: "basic",
	}
	value, err = json.Marshal(certData)
	if err != nil {
		return err
	}
	err = client.PutWithTTL(ctx, keySerial.Bytes(), value, ttl)
	if err != nil {
		return err
	}
	return nil
}

func issueRandomCert(issuanceTime time.Time) error {
	var serialBytes [16]byte
	_, _ = rand.Read(serialBytes[:])
	serial := big.NewInt(0).SetBytes(serialBytes[:])

	// Keep the randomstring small so we deliberately get some certs "reissued"
	host := fmt.Sprintf("%s.lencr.org", core.RandomString(3))
	san := []string{"lencr.org", host}
	err := issueCert(context.TODO(), serial, san, 10, issuanceTime)
	if err != nil {
		return err
	}

	if *verbose {
		fmt.Printf("Issued %s on %s\n", serial, issuanceTime.Format("2006-01-02"))
	}
	return nil
}

func worker(wg *sync.WaitGroup, bar *progressbar.ProgressBar, workChan <-chan *time.Time) {
	defer wg.Done()
	for issueDate := range workChan {
		err := issueRandomCert(*issueDate)
		if err != nil {
			panic(err)
		}
		bar.Add(1)
	}
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
	endDate := issueDate.AddDate(0, 0, *numDays)

	fmt.Printf("Filling DB with %d certs/day between %s and %s\n", *count, *startDate, endDate)

	for {
		fmt.Printf("Issuing on date %s\n", issueDate)

		workChan := make(chan *time.Time, 100) // Buffered channel
		bar := progressbar.Default(*count)
		wg := sync.WaitGroup{}

		// 1024 goroutines is a sweet spot for overall performance
		for range 1024 {
			wg.Add(1)
			go worker(&wg, bar, workChan)
		}

		for range *count {
			workChan <- &issueDate
		}
		close(workChan)
		wg.Wait()

		if !bar.IsFinished() {
			panic("Bar wasn't finished after waitgroup closed, that's a logic error!\n")
		}

		issueDate = issueDate.AddDate(0, 0, 1)
		if issueDate.Equal(endDate) {
			break
		}
	}
	client.Close()
}
