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

# Setup strict mode to make life easy
# See http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

echo
echo Cleaning up from old runs
echo

sudo mkdir -p runtime/etc/openvpn
sudo mkdir -p runtime/etc/letsencrypt
sudo mkdir -p runtime/etc/testclient
sudo rm -Rf \
  runtime/etc/openvpn/pki/issued/testclient.crt \
  runtime/etc/openvpn/pki/reqs/testclient.req \
  runtime/etc/openvpn/pki/private/testclient.key \
  runtime/etc/openvpn/client-config/testclient \
  runtime/etc/openvpn/client-config/testclient/testclient.pkcs12 \
  runtime/testclient.ovpn

echo
echo Initializing openvpn
echo

docker-compose up -d
# Wait for openvpn to be available
sh -c 'docker-compose logs -f openvpn | { sed "/success: openvpn entered RUNNING state/ q" && kill $$ ;}' || echo "OK"

# Allow multiple certs with the same name
sudo sh -c 'echo "unique_subject = no" > runtime/etc/openvpn/pki/index.txt.attr'

echo
echo Building a client
echo

docker-compose exec openvpn /asacamano/openvpn/openvpn.sh chromeos_client testclient testuser
docker-compose exec openvpn ovpn_getclient testclient | sudo sh -c 'cat > ./runtime/testclient/testclient.ovpn'

echo
echo Testing the client
echo

docker-compose run --rm testclient ./test_1.sh

