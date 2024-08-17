package common

type SerialLastNag struct {
	Serial []byte
	LastNag string
}

type SerialCertData struct {
	SAN []string
	Issued string
	Profile string
}
