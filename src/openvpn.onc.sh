#!/bin/bash -eu
#
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# TODO: High-level file comment.
#!/bin/bash

CLIENT_NAME=${1-""}
USERNAME=${CLIENT_NAME}
GUID1=$( uuidgen )
GUID2=$( uuidgen )
GUID3=$( uuidgen )
CACERT=$( cat /etc/openvpn/pki/ca.crt | tail -n +2 | head -n -1 | tr '\n' '*' | sed -e 's/\*//g' )
TA_KEY=$( cat /etc/openvpn/pki/ta.key | grep -v '#' | tr '\n' '*' | sed -e 's/\*/\\n/g' )
CLIENTCERT=$( openssl pkcs12 -export -password 'pass:' -inkey /etc/openvpn/pki/private/${CLIENT_NAME}.key -in  /etc/openvpn/pki/issued/${CLIENT_NAME}.crt | base64 -w 0 )

cat <<EOF
{
  "Type":"UnencryptedConfiguration",
  "Certificates": [
    {
      "GUID": "{${GUID1}}",
      "Type": "Authority",
      "X509": "${CACERT}"
    },
    {
      "GUID": "{${GUID2}}",
      "Type": "Client",
      "PKCS12": "${CLIENTCERT}"
    }
  ],
  "NetworkConfigurations": [
    {
      "GUID": "{${GUID3}}",
      "Name": "${PUBLIC_HOSTNAME}",
      "Type": "VPN",
      "VPN": {
        "Type": "OpenVPN",
        "Host": "${PUBLIC_HOSTNAME}",
        "OpenVPN": {
          "AuthRetry": "interact",
          "ClientCertType": "Pattern",
          "ClientCertPattern": {              
            "IssuerCARef": [ "{${GUID1}}" ]
          },
          "CompLZO": "true",
          "Port": 1194,
          "Proto": "udp",
          "RemoteCertTLS":"server",
          "RemoteCertEKU": "TLS Web Server Authentication",
          "SaveCredentials": false,
          "ServerPollTimeout": 10,
          "Username": "${USERNAME}",
          "KeyDirection":"1",                    
          "TLSAuthContents":"${TA_KEY}"
        }
      }
    }
  ]
}
EOF
