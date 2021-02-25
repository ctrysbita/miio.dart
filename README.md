# MIIO

Dart implementation for MIIO LAN protocol.

The protocol an encrypted, binary protocol based on UDP (port 54321), which is used to configure & control smart home devices made by Xiaomi Ecosystem.

## CLI

The package contains a simple CLI program that built on top of miio.

### Example

```
miio discover --ip 192.168.1.255

miio send --ip 192.168.1.100 --token ffffffffffffffffffffffffffffffff --payload '{\"id\": 1, \"method\": \"miIO.info\", \"params\": []}'
```

## Protocol

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Magic Number = 0x2131         | Packet Length (incl. header)  |
|-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
| Unknown                                                       |
|-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
| Device ID ("did")                                             |
|-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
| Stamp                                                         |
|-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
| MD5 Checksum                                                  |
| ... or Device Token in response to the "Hello" packet         |
|-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
| Optional variable-sized payload (encrypted)                   |
|...............................................................|


Packet Length: 16 bits unsigned int
    Length in bytes of the whole packet, including header(0x20 bytes).

Unknown: 32 bits
    This value is always 0.
    0xFFFFFFFF in "Hello" packet.

Device ID: 32 bits
    Unique number. Possibly derived from the MAC address.
    0xFFFFFFFF in "Hello" packet.

Stamp: 32 bit unsigned int
    Continously increasing counter.

MD5 Checksum:
    Calculated for the whole packet including the MD5 field itself,
    which must be initialized with token.

    In "Hello" packet,
    this field contains the 128-bit 0xFF.

    In the response to the first "Hello" packet,
    this field contains the 128-bit device token.

Optional variable-sized payload:
    Payload encrypted with AES-128-CBC (PKCS#7 padding).

        Key = MD5(Token)
        IV  = MD5(MD5(Key) + Token)
```
