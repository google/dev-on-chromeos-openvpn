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

# Run a test to make sure that who setup still works.

set -x

echo calling the testserver without the VPN
results=$(wget -T 5 -O - 10.5.0.3:80)

if [[ $? != 0 ]]; then
  echo SUCCESS
else
  echo FAILURE - the server in the private network should not be visible yet
  exit 1
fi
echo Starting openvpn
echo $TEST_USERNAME > /testclient/testclient.auth
echo $TEST_PASSWORD >>  /testclient/testclient.auth
/usr/sbin/openvpn --config /testclient/testclient.ovpn --auth-user-pass /testclient/testclient.auth &

echo waiting
sleep 5

echo calling the testserver
results=$(wget -T 5 -O - 10.5.0.3:80)

if [[ $? == 0 ]]; then
  echo SUCCESS
else
  echo FAILURE - could not connect to the private server over the VPN
  exit 1
fi
