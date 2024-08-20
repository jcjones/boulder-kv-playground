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
	"log/slog"
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
	client     *rawkv.Client
	pdAddr     = flag.String("pd", "cr1.pugha.us:2379", "pd address")
	startDate  = flag.String("s", time.Now().Format("2006-01-02"), "issuance start date")
	numDays    = flag.Int("n", 90, "number of days to issue for")
	count      = flag.Int64("c", 100, "count of certificates to issue per day")
	verbose    = flag.Bool("v", false, "be verbose")
	slush      = time.Hour * 3                                      // TTL overlap for ease of debug
	goroutines = flag.Int("g", 1024, "number of goroutines to use") // default seems a sweet spot
)

// Init initializes information.
func initStore() {
	var err error
	client, err = rawkv.NewClientWithOpts(context.TODO(), []string{*pdAddr}, rawkv.WithAPIVersion(kvrpcpb.APIVersion_V2))
	if err != nil {
		panic(err)
	}
}

func issueCert(ctx context.Context, serial string, san []string, regID int, issued time.Time, expiration time.Time) error {
	// OnIssuance:
	// Put key=SANHash-RegID value={Serial}, ttl=expDate
	// Put key=ExpDate-RegID-SANHash value={Serial, LastNag=0}, ttl=expDate
	// Put key=Serial value={SAN, Expires, Issued, Profile, etc.} ttl=expDatePlusLookback

	sanHash := core.HashNames(san)

	exp_plus_slush := expiration.Add(slush)
	seconds_to_live := exp_plus_slush.Sub(issued).Seconds()
	ttl_sec := uint64(seconds_to_live)

	slog.Debug("Issuing cert", "sanHash", sanHash, "ttl_sec", ttl_sec, "issued", issued,
		"expiring", expiration, "regID", regID, "serial", serial, "exp_plus_slush", exp_plus_slush, "seconds_to_live", seconds_to_live)

	keySanHashRegId := common.KeySanHashRegId{SANHash: sanHash, RegID: regID}
	err := client.PutWithTTL(context.TODO(), keySanHashRegId.Bytes(), []byte(serial), ttl_sec)
	if err != nil {
		return err
	}

	keyExpiration := common.KeyExpirationRegIdSanHash{
		Expiration: expiration.Format("2006-01-02"),
		RegID:      regID,
		SANHash:    sanHash,
	}

	sln := &common.SerialLastNag{
		Serial:  serial,
		LastNag: "0000-00-00",
	}
	value, err := json.Marshal(sln)
	if err != nil {
		return err
	}
	err = client.PutWithTTL(ctx, keyExpiration.Bytes(), value, ttl_sec)
	if err != nil {
		return err
	}

	keySerial := common.KeySerial{
		Serial: serial,
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
	err = client.PutWithTTL(ctx, keySerial.Bytes(), value, ttl_sec)
	if err != nil {
		return err
	}
	return nil
}

func issueRandomCert(ctx context.Context, issuanceTime time.Time, expirationTime time.Time) error {
	var serialBytes [16]byte
	_, _ = rand.Read(serialBytes[:])
	serial := big.NewInt(0).SetBytes(serialBytes[:]).String()

	// Keep the randomstring small so we deliberately get some certs "reissued"
	host := fmt.Sprintf("%s.lencr.org", core.RandomString(1))
	san := []string{"lencr.org", host}
	err := issueCert(ctx, serial, san, 10, issuanceTime, expirationTime)
	if err != nil {
		return err
	}

	return nil
}

func worker(wg *sync.WaitGroup, bar *progressbar.ProgressBar, workChan <-chan *time.Time) {
	lifespan := time.Hour * 24 * 90

	defer wg.Done()
	for issueDate := range workChan {
		expirationTime := issueDate.Add(lifespan)
		slog.Info("worker", "i", issueDate, "e", expirationTime, "l", lifespan)
		err := issueRandomCert(context.TODO(), *issueDate, expirationTime)
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

	if *verbose {
		slog.SetLogLoggerLevel(slog.LevelDebug)
	}

	initStore()

	issueDate, err := time.Parse("2006-01-02", *startDate)
	if err != nil {
		panic(err)
	}
	endDate := issueDate.AddDate(0, 0, *numDays)

	slog.Info("Filling DB", "certs/day", *count, "startDate", *startDate, "endDate", endDate)

	for {
		slog.Info("Issuing", "issueDate", issueDate)

		workChan := make(chan *time.Time, 100) // Buffered channel
		bar := progressbar.Default(*count)
		wg := sync.WaitGroup{}

		for range *goroutines {
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
