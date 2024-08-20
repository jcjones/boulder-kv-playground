package common

import (
	"bytes"
	"crypto/sha256"
	"testing"
)

func TestKeySanHashRegId(t *testing.T) {
	hash := sha256.Sum256([]byte{0x42, 0xFF})
	k := KeySanHashRegId{
		SANHash: hash[:],
		RegID:   42,
	}
	arr := k.Bytes()
	res, err := ToKeySanHashRegId(arr)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(k.Bytes(), res.Bytes()) {
		t.Errorf("Expected %v got %v", arr, res)
	}
}

func TestKeyExpirationRegIdSanHash(t *testing.T) {
	hash := sha256.Sum256([]byte{72, 58, 52, 50, 70, 70, 124, 52, 50})
	k := KeyExpirationRegIdSanHash{
		Expiration: "2525-12-30",
		RegID:      123545897,
		SANHash:    hash[:],
	}
	arr := k.Bytes()
	res, err := ToKeyExpirationRegIdSanHash(arr)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(k.Bytes(), res.Bytes()) {
		t.Errorf("Expected %v got %v", arr, res)
	}
}

func TestKeySerial(t *testing.T) {
	k := KeySerial{
		Serial: "111231564891321231564891321231564891",
	}
	arr := k.Bytes()
	res, err := ToKeySerial(arr)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(k.Bytes(), res.Bytes()) {
		t.Errorf("Expected %v got %v", arr, res)
	}
}
