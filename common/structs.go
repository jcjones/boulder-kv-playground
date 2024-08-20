package common

import (
	"bytes"
	"fmt"
	"math/big"
	"strconv"

	"github.com/letsencrypt/boulder/core"
)

type SerialLastNag struct {
	Serial  big.Int
	LastNag string
}

type SerialCertData struct {
	SAN     []string
	Issued  string
	Profile string
}

type KeySanHashRegId struct {
	SANHash []byte
	RegID   int
}

func (r *KeySanHashRegId) Bytes() []byte {
	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "H:%X|%d", r.SANHash, r.RegID)
	if err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func ToKeySanHashRegId(x []byte) (*KeySanHashRegId, error) {
	buf := bytes.NewBuffer(x)

	prefix, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	if prefix != "H:" {
		return nil, fmt.Errorf("Invalid KeySanHashRegId prefix: %s", prefix)
	}

	hash, err := buf.ReadBytes('|')
	if err != nil {
		return nil, err
	}
	regId, err := strconv.Atoi(buf.String())
	if err != nil {
		return nil, err
	}

	return &KeySanHashRegId{SANHash: hash, RegID: regId}, nil
}

type KeyExpirationRegIdSanHash struct {
	Expiration string
	RegID      int
	SANHash    []byte
}

func (e *KeyExpirationRegIdSanHash) Bytes() []byte {
	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "E:%s|%d|%X", e.Expiration, e.RegID, e.SANHash)
	if err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func ToKeyExpirationRegIdSanHash(x []byte) (*KeyExpirationRegIdSanHash, error) {
	buf := bytes.NewBuffer(x)

	prefix, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	if prefix != "E:" {
		return nil, fmt.Errorf("Invalid KeyExpirationRegIdSanHash prefix: %s", prefix)
	}

	expiration, err := buf.ReadString('|')
	if err != nil {
		return nil, err
	}
	regIdStr, err := buf.ReadString('|')
	if err != nil {
		return nil, err
	}
	regID, err := strconv.Atoi(regIdStr)
	if err != nil {
		return nil, err
	}

	hash := buf.Bytes()

	return &KeyExpirationRegIdSanHash{
		Expiration: expiration,
		RegID:      regID,
		SANHash:    hash,
	}, nil
}

type KeySerial struct {
	Serial big.Int
}

func (s *KeySerial) Bytes() []byte {
	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "S:%s", core.SerialToString(&s.Serial))
	if err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func ToKeySerial(x []byte) (*KeySerial, error) {
	buf := bytes.NewBuffer(x)

	prefix, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	if prefix != "S:" {
		return nil, fmt.Errorf("Invalid KeySerial prefix: %s", prefix)
	}

	var ks KeySerial
	ks.Serial.SetBytes(buf.Bytes())
	return &ks, nil
}

type KeyExpirationMailerCurrentRun struct {
	RegID int
}

func (e *KeyExpirationMailerCurrentRun) Bytes() []byte {
	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "ExpirationMailer-RegIds:%d", e.RegID)
	if err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func ToKeyExpirationMailerCurrentRun(x []byte) (*KeyExpirationMailerCurrentRun, error) {
	buf := bytes.NewBuffer(x)

	prefix, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	if prefix != "ExpirationMailer-RegIds:" {
		return nil, fmt.Errorf("Invalid KeyExpirationMailerCurrentRun prefix: %s", prefix)
	}

	regIdStr := buf.String()
	regID, err := strconv.Atoi(regIdStr)
	if err != nil {
		return nil, err
	}

	return &KeyExpirationMailerCurrentRun{
		RegID: regID,
	}, nil
}

type KeyExpirationMailerCurrentRunRegIdSerial struct {
	RegID  int
	Serial big.Int
}

func (e *KeyExpirationMailerCurrentRunRegIdSerial) Bytes() []byte {
	buf := bytes.Buffer{}
	_, err := fmt.Fprintf(&buf, "ExpirationMailer-Serials:%d|%s", e.RegID, core.SerialToString(&e.Serial))
	if err != nil {
		panic(err)
	}
	return buf.Bytes()
}

func ToKeyExpirationMailerCurrentRunRegIdSerial(x []byte) (*KeyExpirationMailerCurrentRunRegIdSerial, error) {
	buf := bytes.NewBuffer(x)

	prefix, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	if prefix != "ExpirationMailer-Serials:" {
		return nil, fmt.Errorf("Invalid KeyExpirationMailerCurrentRun prefix: %s", prefix)
	}

	regIdStr, err := buf.ReadString(':')
	if err != nil {
		return nil, err
	}
	regID, err := strconv.Atoi(regIdStr)
	if err != nil {
		return nil, err
	}

	ke := KeyExpirationMailerCurrentRunRegIdSerial{
		RegID:  regID,
		Serial: big.Int{},
	}
	ke.Serial.SetBytes(buf.Bytes())
	return &ke, nil
}
