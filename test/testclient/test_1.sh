#!/bin/bash

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
