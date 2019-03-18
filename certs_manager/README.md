# CERTIFICATE MANAGEMENT TOOL
---------

Useful tool to manage your own certificate chain: 

## Supported Features 
This current version of the script supports the following features :

- [x]	Increase entropy level when generating keys.
- [x]	Manage Root-CA.
- [x]	Manage Intermediate-CA. 
- [x]	Manage Sub-intermediate CA.
- [x]	Manage End-user certificate (clients and servers).

## TODO Feature List

- [ ]	Add certificate revocation list (CRL).
- [ ]	Enforce private key management. 
- [ ]	Certificate chain verification.

## How to use this script

```
    Usage:  source certs_manager.sh [OPTIONS]

    Options:
    --root-ca 
        [--req | --ca]          Creates and processes Root certificate
    --intermediate-ca  
        [--req | --ca]          Creates and processes intermediate certificate
    --subinter-ca  
        [--req | --ca]          Creates and processes sub intermediate certificate
    --server 
        [--req | --ca]          Creates and processes server's certificate, only to establish HTTPS connections
    --guest
        [--req | --ca]          Creates and processes guests certificate, to ask for an imei certificate
    --gen-from-file 
```

## Tree 

```
certs_manager
├── certs_manager.sh
├── config
│   ├── guest.conf
│   ├── intermediate-ca.conf
│   ├── openssl.conf
│   ├── pki.conf
│   ├── root-ca.conf
│   ├── server.conf
│   └── subinter-ca.conf
```

To create the root certificate authority pair  *CSR* (certificate Signing Requests) and *Private Key* :      

```
$ source certs_manager.sh --root-ca --req
```
To sign the **root CSR** with the **root CA** private key: 
```
$ source certs_manager.sh --root-ca --ca
```

```
│
├── root_ca
│   ├── certs_archive
│   │   ├── 1000.pem
│   │   └── 1001.pem
│   ├── csr
│   │   └── root-ca.csr
│   ├── db
│   │   ├── crlnumber
│   │   ├── index
│   │   ├── index.attr
│   │   ├── index.attr.old
│   │   ├── index.old
│   │   ├── serial
│   │   └── serial.old
│   ├── private
│   │   └── root-ca.key
│   └── root-ca.crt
```

An intermediate certificate authority (CA) signed by root CA is an entity that can sign end-clients and end-servers certificates. 
For security purposes, the root CA signs only the intermediate certificate forming a chain of trust.

To create the intermediate certificate authority pair *CSR* (certificate Signing Requests) and *Private Key* :      

```
$ source certs_manager.sh --intermediate-ca --req
```
To sign the **intermediate CSR** with the **root CA** private key: 
```
$ source certs_manager.sh --intermediate-ca --ca
```

```
│
├── intermediate_ca
│   ├── certs_archive
│   │   └── 2000.pem
│   ├── csr
│   │   └── intermediate-ca.csr
│   ├── db
│   │   ├── crlnumber
│   │   ├── index
│   │   ├── index.attr
│   │   ├── index.attr.old
│   │   ├── index.old
│   │   ├── serial
│   │   └── serial.old
│   ├── intermediate-ca.crt
│   └── private
│       └── intermediate-ca.key
```

The intermediate certificate authority are allowed to issue another intermediate CA (called sub-intermediate CA) Based on the `pathLen Constraint` variable.

To create the sub-intermediate certificate authority pair *CSR* (certificate Signing Requests) and *Private Key* :      

```
$ source certs_manager.sh --subinter-ca --req
```
To sign the sub-**intermediate CSR** with the **intermediate CA** private key: 
```
$ source certs_manager.sh --subinter-ca --ca
```

```
│
├── sub_inter_ca
│   ├── certs_archive
│   │   └── 3000.pem
│   ├── csr
│   │   └── sub-inter-ca.csr
│   ├── db
│   │   ├── crlnumber
│   │   ├── index
│   │   ├── index.attr
│   │   ├── index.attr.old
│   │   ├── index.old
│   │   ├── serial
│   │   └── serial.old
│   ├── private
│   │   └── sub-inter-ca.key
│   └── sub-inter-ca.crt

```

For server certificates, the CN (Common Name) must be a FQDN (fully qualified domain name): domain name or IP address (in our case).

To create the server certificate pair *CSR* (certificate Signing Requests) and *Private Key* :      

```
$ source certs_manager.sh --server --req
```
To sign the **server CSR** with the **sub-intermediate CA** private key: 
```
$ source certs_manager.sh --server --ca
```

```
│
└── server
    ├── certs_archive
    ├── csr
    │   └── server.csr
    ├── db
    ├── private
    │   └── server.key
    └── server.crt

```


## Contributions or Need Help 

You are welcome to contribute and suggest any improvements.
If you want to point to an issue, Please [file an issue](https://github.com/Rtone/secure-esp32/issues).


If you have questions or need further guidance on using the tool, 
Please [file an issue](https://github.com/Rtone/secure-esp32/issues).

 
## Direct contributions

Fork the repository, file a pull request and You are good to go ;)


## License

This project is licensed under The MIT License terms.

Copyright (c) 2019 Rtone IoT Security