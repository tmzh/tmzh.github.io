---
author: thamizh85
comments: true
date: 2017-08-20 09:55:20+00:00
layout: post
slug: self-signed-certificate-chain-using-openssl-x509-module
title: Self-signed certificate chain using OpenSSL X509 module
wordpress_id: 103
categories:
- Notes
- SysAdmin
tags:
- openssl
- pki
- web
---

Generating a self-signed CA certificate or signing a web server certificate using openssl is very easy. But creating a certificate, which works without any warning on most modern browsers is a challenge. This challenge is compounded by ever-growing stringent requirements from the popular browsers (See footnote 1).

There are two ways to use openssl to mimic a CA. The first option is to use ‘openssl ca’ module, for which there are many guides in the internet. This module mimics a full-fledged CA and useful when you are setting up something for long term requiring features such as CRL and OCSP.

The other option is to use ‘openssl x509’ module which is what we will be focusing on. I chose this because I just needed a certificate pair for one-off use and didn't want to be bothered in setting up an elaborate CA configuration. The guide will be useful for someone with a similar objective.

As always, let us start with the requirement:
  1. Create a certificate chain with as little configuration and minimum number of hosts, which means no intermediate CA.
  2. The CA cert would be imported manually in to Trusted Root Authorities on the client machines.	
  3. The certificate should work on modern browsers. We will use latest versions of Chrome and Mozilla as benchmarks.

## Steps:
	
  1. Generate private key & self-signed cert for the CA in a single statement:
 
    root@EARWA:openssl req -new -x509 <span style="color:blue;">-sha256</span> -newkey rsa:2048 -nodes -keyout <span style="color:#ff0000;">ca.key</span> -days 1000 -out <span style="color:#808000;">ca.pem</span>
    root@EARWA:~/ca2# ls -ltr
    total 8
    -rw-r--r-- 1 root root 1704 Jul 30 20:01 <span style="color:#ff0000;">ca.key</span>
    -rw-r--r-- 1 root root 1261 Jul 30 20:01 <span style="color:#808000;">ca.pem</span>




<blockquote>Note: Always use SHA256 as highlighted above. SHA-1 has been deprecated since Jan 2017 (See footnote 2)</blockquote>





	
  2. Preparing a config file for CSR: We need to generate a CSR (Certificate Signing Request). This process involves generating a private key and a PEM encoded CSR file. The contents of our Web cert are determined by the information we provide in the CSR.




Modern browsers expect a field called sAN(subjectAltName) (See footnote 3). This field should hold all possible URI’s from which our webserver may get accessed.




Since OpenSSL's default interactive process of CSR generation doesn't support this field, we need to specify it in a config file and generate the CSR. based on this file Create a config file for Web server request. The highlighted sections are the reason we are using a config file. Otherwise rest of the attributes can be passed interactively.




    
    root@EARWA:~/ca2# more <span style="color:#ff0000;">web.earwa.com.conf</span>
    [ subject ]
    countryName             = Country Name (2 letter code)
    countryName_default     = HK
    
    organizationName            = Organization Name (eg, company)
    organizationName_default    = Scarlet Spires
    
    basicConstraints    = CA:FALSE
    keyUsage            = digitalSignature, keyEncipherment
    <span style="color:#0000ff;">subjectAltName      = @alternate_names</span>
    nsComment           = "OpenSSL Generated Certificate"
    
    <span style="color:#0000ff;">[ alternate_names ]
    DNS.1       = web.earwa.com
    DNS.2       = www.web.earwa.com</span>





	
  3. Submit a request based on the config file



    
    openssl req -config <span style="color:#ff0000;">web.earwa.com.conf</span> -new -sha256 -newkey rsa:2048 -nodes -keyout web.earwa.com.key -days 1000 -out web.earwa.com.csr





	
  4. Check the generated request file before signing. The highlighted section shows the portions we are interested to validate.



    
    root@EARWA:~/ca2# openssl req -in web.earwa.com.csr -text -noout
    
    Certificate Request:
        Data:
            Version: 0 (0x0)
            Subject: C=HK, O=Scarlet Spires
            Subject Public Key Info:
                Public Key Algorithm: rsaEncryption
                    Public-Key: (2048 bit)
                    Modulus:
                        00:c6:f9:32:79:11:20:ff:97:da:38:a0:61:b9:41:
                        1f:51:c0:1f:a1:48:05:74:54:81:23:9b:22:24:8d:
                        35:f2:25:83:15:f2:9b:30:a5:43:2d:4d:08:2f:c7:
                        9e:42:1d:f7:66:68:07:8f:da:0b:f9:5c:51:97:b1:
                        0e:dc:44:d1:a4:5c:a1:ef:35:43:84:52:99:34:9f:
                        7d:41:54:9f:65:21:4c:1c:21:6f:9c:73:d5:f2:3d:
                        3c:6d:da:fe:85:88:98:4d:02:42:52:ea:9c:61:fe:
                        e7:bc:c2:d6:44:9d:9f:f6:3d:cb:32:c6:e4:8d:d1:
                        74:47:80:87:ac:8d:8a:64:8a:4e:54:ce:54:4e:75:
                        3a:85:af:f5:96:9b:5f:a0:a0:6d:27:06:1c:8d:0b:
                        4b:c5:1e:15:ff:16:4a:87:1e:9b:cc:98:a9:c5:8f:
                        4f:f1:19:28:cd:90:6c:85:ab:58:37:14:d6:58:cb:
                        7d:ab:8b:34:62:2a:72:b4:17:96:0b:6f:84:31:54:
                        55:aa:06:56:00:04:5e:2d:d1:14:fa:7f:2d:b3:44:
                        d3:1d:95:c2:93:ec:4e:17:e8:30:fa:e7:f5:be:b1:
                        5f:9a:59:59:ac:0d:b7:04:4a:19:35:a2:a5:44:64:
                        d4:a0:93:f8:dc:9f:3a:20:7b:5c:d7:26:67:28:67:
                        87:73
                    Exponent: 65537 (0x10001)
            Attributes:
    <span style="color:#0000ff;">        Requested Extensions:
                X509v3 Subject Key Identifier:
                    30:47:85:A6:4E:9C:E0:D4:F7:CC:9F:FF:FF:38:03:FC:E7:0E:87:00
                X509v3 Basic Constraints:
                    CA:FALSE
                X509v3 Key Usage:
                    Digital Signature, Key Encipherment
                X509v3 Subject Alternative Name:
                    DNS:web.earwa.com, DNS:www.web.earwa.com
                Netscape Comment:
                    OpenSSL Generated Certificate</span>
    
        Signature Algorithm: sha256WithRSAEncryption
             aa:be:6d:d1:95:8a:1e:87:d8:72:7a:95:2e:01:18:f5:76:6e:
             28:e9:f8:a7:f0:ff:f5:5c:b3:95:99:ad:84:fd:bb:c3:fe:71:
             cc:a5:52:26:ce:2e:d0:d8:78:11:b9:33:98:f9:7c:42:e8:29:
             7e:8e:86:6c:b4:84:93:04:65:8e:d1:05:fd:6e:c2:94:bd:b1:
             c9:06:59:b7:8e:de:f4:42:9a:af:f8:96:c2:e9:85:2d:74:f6:
             24:41:96:da:f9:79:a5:3b:c7:42:8b:49:39:b6:9f:2b:a3:de:
             b1:9c:b3:66:f4:5b:7f:e7:b7:f4:c9:cb:60:cc:38:01:59:d1:
             61:c3:05:51:2d:c1:f8:63:d5:c5:40:e6:4d:06:3b:1b:06:93:
             ca:80:23:13:0d:79:7a:b3:2a:a3:8d:0f:a7:94:38:35:09:e4:
             69:5a:93:d4:c3:c6:26:ce:71:1f:0b:f1:03:d2:ae:0a:9e:06:
             04:1c:7d:4e:fd:07:d7:e8:bf:45:a0:c9:48:bb:38:a6:fb:09:
             5f:f0:84:42:ee:d9:fe:71:2b:24:6c:04:49:cb:f5:eb:7a:81:
             67:56:e8:9a:6f:fc:45:da:0a:2c:31:42:72:43:01:d0:e7:b9:
             a7:25:77:9a:21:f5:70:33:b6:b0:e0:75:00:29:d5:ce:77:61:
             f5:ec:00:a0





	
  5. This is the portion that tripped me up for a while. Note that earlier I said that the info provided in CSR will be used for certificate generation. It is only partially true, the x509 module cannot copy the extensions info directly from CSR. We need to manually add extensions by using the options -extensions and -extfile. So let us create the V3 extension file first.



    
    root@EARWA:~/ca2# more <span style="color:#ff0000;">v3.ext</span>
    [ <span style="color:#0000ff;">v3_req</span> ]
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName      = @alternate_names
    
    
    [ alternate_names ]
    DNS.1       = web.earwa.com
    DNS.2       = www.web.earwa.com





	
  6. Sign the cert. The highlighted portions refers back to the extension file and the section mentioned above.



    
    openssl x509 -extensions <span style="color:#0000ff;">v3_req</span> -extfile <span style="color:#ff0000;">v3.ext</span> -req -sha256 -days 1000 -in web.earwa.com.csr -CA ca.pem -CAcreateserial -CAkey ca.key -out web.earwa.com.pem





	
  7. Verify the cert



    
    root@EARWA:~/ca2# openssl x509 -in web.earwa.com.pem -text -noout
    
    Certificate:
        Data:
            Version: 3 (0x2)
            Serial Number: 14178612693219512833 (0xc4c48d1f7b319201)
        Signature Algorithm: sha256WithRSAEncryption
            Issuer: C=HK, ST=Some-State, O=Scarlet Spires
            Validity
                Not Before: Jul 31 16:36:03 2017 GMT
                Not After : Apr 26 16:36:03 2020 GMT
            Subject: C=HK, O=Scarlet Spires
            Subject Public Key Info:
                Public Key Algorithm: rsaEncryption
                    Public-Key: (2048 bit)
                   Modulus:
                        00:c6:f9:32:79:11:20:ff:97:da:38:a0:61:b9:41:
                        1f:51:c0:1f:a1:48:05:74:54:81:23:9b:22:24:8d:
                        35:f2:25:83:15:f2:9b:30:a5:43:2d:4d:08:2f:c7:
                        9e:42:1d:f7:66:68:07:8f:da:0b:f9:5c:51:97:b1:
                        0e:dc:44:d1:a4:5c:a1:ef:35:43:84:52:99:34:9f:
                        7d:41:54:9f:65:21:4c:1c:21:6f:9c:73:d5:f2:3d:
                        3c:6d:da:fe:85:88:98:4d:02:42:52:ea:9c:61:fe:
                        e7:bc:c2:d6:44:9d:9f:f6:3d:cb:32:c6:e4:8d:d1:
                        74:47:80:87:ac:8d:8a:64:8a:4e:54:ce:54:4e:75:
                        3a:85:af:f5:96:9b:5f:a0:a0:6d:27:06:1c:8d:0b:
                        4b:c5:1e:15:ff:16:4a:87:1e:9b:cc:98:a9:c5:8f:
                        4f:f1:19:28:cd:90:6c:85:ab:58:37:14:d6:58:cb:
                        7d:ab:8b:34:62:2a:72:b4:17:96:0b:6f:84:31:54:
                        55:aa:06:56:00:04:5e:2d:d1:14:fa:7f:2d:b3:44:
                        d3:1d:95:c2:93:ec:4e:17:e8:30:fa:e7:f5:be:b1:
                        5f:9a:59:59:ac:0d:b7:04:4a:19:35:a2:a5:44:64:
                        d4:a0:93:f8:dc:9f:3a:20:7b:5c:d7:26:67:28:67:
                        87:73
                    Exponent: 65537 (0x10001)
            <span style="color:#0000ff;">X509v3 extensions:</span>
                X509v3 Authority Key Identifier:
                    keyid:32:33:41:52:11:5A:AE:F9:89:4E:8E:EE:26:E3:D2:7D:CA:C9:BC:63
    
                X509v3 Basic Constraints:
                    CA:FALSE
                X509v3 Key Usage:
                   Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
                X509v3 <span style="color:#0000ff;">Subject Alternative Name:
                    DNS:web.earwa.com, DNS:www.web.earwa.com</span>
        Signature Algorithm: <span style="color:#0000ff;">sha256WithRSAEncryption</span>
             59:d5:45:b3:ca:60:32:a8:37:85:3b:bf:6f:d1:b3:26:f6:4b:
             f2:26:2c:68:6f:cb:5c:3b:a8:6f:a9:32:53:71:98:74:26:be:
             4f:3e:a9:13:e6:ba:e4:3e:52:83:86:0d:9d:53:4a:1e:e8:a5:
             94:36:bf:c2:17:62:b9:8e:87:8d:32:f1:34:1a:e3:81:6b:0b:
             5a:b7:a8:55:c4:24:ca:b2:65:75:e2:4b:ac:c4:9b:9e:d1:94:
             45:31:92:1d:6b:30:6c:29:03:fd:1e:49:8e:8e:d5:30:6f:68:
             fc:01:82:f8:57:83:85:47:15:e9:78:96:39:86:94:cb:96:29:
             5b:61:f0:d9:23:d1:25:ca:a0:ea:80:ce:42:bb:12:40:b9:64:
             c6:a5:4f:99:dc:f3:26:74:49:bc:b2:70:49:d2:22:f2:75:07:
             6e:8f:96:9b:e6:67:ad:21:01:23:57:46:ea:78:12:3b:c8:ba:
             dc:ae:39:ee:d6:30:6d:58:ab:f0:fe:c1:68:fb:0a:68:09:fc:
             93:28:84:27:2d:1d:c0:c2:06:53:1b:3b:ff:ec:d8:a1:90:1c:
             c4:59:c0:c3:d5:f4:bb:d4:79:35:dd:7f:05:60:3f:a9:ba:b0:
             5c:b3:66:13:03:4f:ac:31:0c:8a:e9:82:8d:36:c1:78:bf:d6:
             5e:6d:f9:13
    
    
    


That is it! Now you have a web server cert which would be trusted by most browsers, provided you import the root CA public cert in to the browsers' trust chain.


#### Footnote #1


[https://cabforum.org/baseline-requirements-documents/](https://cabforum.org/baseline-requirements-documents/)


#### Footnote #2


SHA-1 disabled on Chrome 56 and FireFox (Jan 2017)

[https://www.chromestatus.com/features/6601657605423104](https://www.chromestatus.com/features/6601657605423104)

[https://sites.google.com/a/chromium.org/dev/Home/chromium-security/education/tls/sha-1](https://sites.google.com/a/chromium.org/dev/Home/chromium-security/education/tls/sha-1)

[https://blog.mozilla.org/security/2017/02/23/the-end-of-sha-1-on-the-public-web/](https://blog.mozilla.org/security/2017/02/23/the-end-of-sha-1-on-the-public-web/)


#### Footnote #3


SAN mandatory

[https://www.chromestatus.com/features/4981025180483584](https://www.chromestatus.com/features/4981025180483584)

[https://bugzilla.mozilla.org/show_bug.cgi?id=1245280](https://bugzilla.mozilla.org/show_bug.cgi?id=1245280)

[https://tools.ietf.org/html/rfc2818](https://tools.ietf.org/html/rfc2818)
