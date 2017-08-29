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

# Read in the secret password and make it available in an env var
export OPENVPN_CA_PASSWORD=$( cat /run/secrets/ca_master_password )

if [[ ${1-''} != "" ]]; then
  if [[ ${1-''} == "chromeos_client" ]]; then
    if [[ ${2-''} == "" ]]; then
      echo "chromeos_client requires the name of the client, e.g."
      echo "docker-compose --rm -p openvpn chromeos_client MyAwesomeChromebookVPNClientCert"
      exit 1
    fi
    set -x
    # Invoke kylemanna's setup
    expect -f /asacamano/openvpn/openvpn.client.expect ${2}
    # Now make the PKCS12 and ONC file
    # See https://docs.google.com/document/d/18TU22gueH5OKYHZVJ5nXuqHnk2GN6nDvfu2Hbrb4YLE/pub
    mkdir -p /etc/openvpn/client-config/${2}
    /asacamano/openvpn/openvpn.onc.sh ${2} > /etc/openvpn/client-config/${2}/${PUBLIC_HOSTNAME}.onc
    echo
    echo "Client config in /etc/openvpn/client-config/${2}/${PUBLIC_HOSTNAME}.onc"
    echo
    cat /etc/openvpn/client-config/${2}/${PUBLIC_HOSTNAME}.onc
    exit 0
  else
    set +euo pipefail
    exec "$@"
  fi
fi

# Log the commands and the output
set -x
if [[ ${CERTBOT_STAGING_FLAG-'--staging'} == "--staging" ]]; then
  CERTBOT_CONFIG=/etc/letsencrypt/staging
else
  CERTBOT_CONFIG=/etc/letsencrypt
fi

if [[ -f /etc/openvpn/setup-done ]]; then
  echo "Using existing setup - checking for cert renewal"
  certbot renew --config-dir $CERTBOT_CONFIG
else
  echo "Running first-time setup"
  # Set up the cert and keys
  certbot certonly --standalone --non-interactive --config-dir $CERTBOT_CONFIG --agree-tos ${CERTBOT_STAGING_FLAG-'--staging'} --email ${ADMIN_EMAIL} -d ${PUBLIC_HOSTNAME}

  if [[ ${CERTBOT_STAGING_FLAG-'--staging'} == "--staging" ]]; then
    echo "Certboth staging finished. Run with CERTBOT_STAGING_FLAG= to complete setup"
    exit 0
  fi

  # Set up openvpn
  # See https://github.com/kylemanna/docker-openvpn
  # and https://github.com/kylemanna/docker-openvpn/blob/master/bin/ovpn_genconfig
  # Some other options to consider making exposed via ENV vars:
  # Username / password verification
  # -e "auth-user-pass-verify /asacamano/openvpn/openvpn_check_pasword.sh via-file" -e "tmp-dir /dev/shm" -e "script-security 2"
  # Verbose logging
  # -e "verb 6"
  ovpn_genconfig -u udp://${PUBLIC_HOSTNAME} -N -z -s 10.8.0.0/24 -n 10.8.0.1

  # Run ovpn_initpki with some scripted values
  expect -f /asacamano/openvpn/openvpn.pki.expect

  # Now update openvpn to use the certbot cert to identify itself
  mv /etc/openvpn/pki/private/${PUBLIC_HOSTNAME}.key /etc/openvpn/pki/private/${PUBLIC_HOSTNAME}.key.localca
  ln -s ${CERTBOT_CONFIG}/live/${PUBLIC_HOSTNAME}/privkey.pem /etc/openvpn/pki/private/${PUBLIC_HOSTNAME}.key
  mv /etc/openvpn/pki/issued/${PUBLIC_HOSTNAME}.crt /etc/openvpn/pki/issued/${PUBLIC_HOSTNAME}.crt.localca
  ln -s ${CERTBOT_CONFIG}/live/${PUBLIC_HOSTNAME}/fullchain.pem /etc/openvpn/pki/issued/${PUBLIC_HOSTNAME}.crt

  set +x
  touch /etc/openvpn/setup-done
fi

set +euo pipefail
echo exec supervisord -c /asacamano/openvpn/supervisord.config
exec supervisord -c /asacamano/openvpn/supervisord.config
